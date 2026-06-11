//
//  EntitlementManager.swift
//  Conduit
//

import StoreKit
import Observation

// MARK: - Pro feature registry
// Add new Pro features here. Every gated view reads isEnabled(_:) from the environment.

enum ProFeature: CaseIterable {
    case unlimitedClients
    case unlimitedDeployments
    case search
    case cloudSync
    case apiKeyVault
    case portDiagnostics

    var displayName: String {
        switch self {
        case .unlimitedClients:     "Unlimited Clients"
        case .unlimitedDeployments: "Unlimited Deployments"
        case .search:               "Search"
        case .cloudSync:            "iCloud Sync"
        case .apiKeyVault:          "API Key Vault"
        case .portDiagnostics:      "Port & Ping Diagnostics"
        }
    }

    var description: String {
        switch self {
        case .unlimitedClients:     "Track as many clients and projects as you need."
        case .unlimitedDeployments: "Add unlimited deployments per client."
        case .search:               "Instantly search across clients and deployments."
        case .cloudSync:            "Keep your data in sync across all your devices."
        case .apiKeyVault:          "Store and organise API keys with biometric unlock."
        case .portDiagnostics:      "Ping hosts and detect port conflicts in real time."
        }
    }

    var systemImage: String {
        switch self {
        case .unlimitedClients:     "person.2.fill"
        case .unlimitedDeployments: "server.rack"
        case .search:               "magnifyingglass"
        case .cloudSync:            "icloud.and.arrow.up.fill"
        case .apiKeyVault:          "key.fill"
        case .portDiagnostics:      "network"
        }
    }
}

// MARK: - EntitlementManager

@Observable
final class EntitlementManager {
    static let shared = EntitlementManager()

    /// Persisted so the UI never flashes free-tier state after a confirmed purchase,
    /// even if StoreKit's server takes a moment to reflect the entitlement.
    /// Only set to false when currentEntitlements explicitly contains a revoked product.
    private(set) var isPro: Bool = UserDefaults.standard.bool(forKey: EntitlementManager.proKey)
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts: Bool = false
    private(set) var purchaseError: String?

    private static let proKey = "conduit.isProUser"
    private var transactionListener: Task<Void, Never>?

    enum ProductID {
        static let proLifetime = "com.siddharthmahajan.conduit.pro.lifetime"
        static let proAnnual   = "com.siddharthmahajan.conduit.pro.annual"
        static let proMonthly  = "com.siddharthmahajan.conduit.pro.monthly"

        static var all: [String] { [proLifetime, proAnnual, proMonthly] }
    }

    init() {
        transactionListener = listenForTransactions()
        Task { await refreshEntitlements() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: Limit helpers — read these instead of FreeTierLimits in views

    var maxClients: Int            { isPro ? .max : FreeTierLimits.maxClients }
    var maxDeploymentsPerClient: Int { isPro ? .max : FreeTierLimits.maxDeploymentsPerClient }
    var isSearchEnabled: Bool      { isPro || FreeTierLimits.searchEnabled }

    func isEnabled(_ feature: ProFeature) -> Bool { isPro }

    // MARK: - Pro flag persistence

    /// Sets `isPro` and writes the value to UserDefaults so it survives the race
    /// window between a verified transaction and Apple's server propagation delay.
    /// Call this only when the outcome is known with certainty (verified transaction
    /// or confirmed revocation from currentEntitlements).
    @MainActor
    private func setProStatus(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.proKey)
    }

    // MARK: Product loading

    func loadProducts() async {
        guard products.isEmpty else { return }
        await MainActor.run { isLoadingProducts = true }
        defer { Task { await MainActor.run { self.isLoadingProducts = false } } }
        do {
            let fetched = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
            await MainActor.run { products = fetched }
        } catch {
            await MainActor.run { purchaseError = error.localizedDescription }
        }
    }

    // MARK: Purchase

    func purchase(_ product: Product) async {
        await MainActor.run { purchaseError = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Cryptographically valid — persist Pro immediately.
                    // Do NOT call refreshEntitlements() here; the server may have a
                    // propagation delay and currentEntitlements can return 0 items for
                    // several seconds after a successful payment.
                    await transaction.finish()
                    await setProStatus(true)

                case .unverified(let transaction, let error):
                    // Local JWS check failed; fall back to server-side entitlement check.
                    print("[StoreKit] Purchase unverified locally (\(error)) — checking entitlements.")
                    await transaction.finish()
                    await refreshEntitlements()
                }

            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            await MainActor.run { purchaseError = error.localizedDescription }
            print("[StoreKit] Purchase threw: \(error)")
        }
    }

    // MARK: Restore

    func restorePurchases() async {
        await MainActor.run { purchaseError = nil }

        do {
            try await AppStore.sync()
        } catch {
            print("[StoreKit] AppStore.sync() threw: \(error). Proceeding anyway.")
        }

        await refreshEntitlements()

        if !isPro {
            await MainActor.run {
                purchaseError = "No active purchase found for this Apple ID."
            }
        }
    }

    // MARK: Entitlement refresh

    func refreshEntitlements() async {
        // Finish any unacknowledged transactions from other devices first.
        for await result in Transaction.unfinished {
            switch result {
            case .verified(let t):   await t.finish()
            case .unverified(let t, _): _ = t  // leave it; StoreKit will retry
            }
        }

        // Walk current entitlements.
        // • hasValidEntitlement  → confirmed active Pro purchase
        // • hasRevokedEntitlement → confirmed revocation/refund
        // • neither              → server propagation delay or no purchase; leave state alone
        var hasValidEntitlement    = false
        var hasRevokedEntitlement  = false

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let t) where ProductID.all.contains(t.productID):
                if t.revocationDate != nil {
                    hasRevokedEntitlement = true
                } else {
                    hasValidEntitlement = true
                }
            case .verified:
                break   // unrelated product
            case .unverified:
                break   // can't trust it; ignore
            }
        }

        await MainActor.run {
            if hasValidEntitlement {
                // Confirmed active — persist Pro.
                isPro = true
                UserDefaults.standard.set(true, forKey: Self.proKey)
            } else if hasRevokedEntitlement {
                // Explicit revocation (refund, cancellation) — remove Pro.
                isPro = false
                UserDefaults.standard.set(false, forKey: Self.proKey)
            }
            // Zero entitlements returned → Apple's servers haven't propagated yet,
            // or the user has never purchased. Either way, leave `isPro` at its
            // current persisted value so we don't clobber a just-completed purchase.
        }
    }

    // MARK: Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    if EntitlementManager.ProductID.all.contains(transaction.productID) {
                        if transaction.revocationDate == nil {
                            // Active purchase delivered outside the app (cross-device restore,
                            // subscription renewal, etc.) — persist Pro immediately.
                            await self?.setProStatus(true)
                        } else {
                            // Revocation arrived — do a full entitlement refresh to confirm.
                            await self?.refreshEntitlements()
                        }
                    }
                case .unverified(let transaction, let error):
                    print("[StoreKit] Unverified update: \(transaction.productID) — \(error)")
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
