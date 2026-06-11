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

    private(set) var isPro: Bool = false
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts: Bool = false
    private(set) var purchaseError: String?

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

    // MARK: Product loading

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: Purchase

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return }
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: Restore

    func restorePurchases() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: Entitlement refresh

    /// Checks `Transaction.currentEntitlements` — valid on every device signed into the
    /// same Apple ID, so this is the canonical cross-device entitlement source.
    /// Always dispatches the final `isPro` write to MainActor to avoid data races on
    /// the @Observable property, which is read directly by SwiftUI on the main thread.
    func refreshEntitlements() async {
        var hasValidEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProductID.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasValidEntitlement = true
                break
            }
        }
        await MainActor.run {
            isPro = hasValidEntitlement
        }
    }

    // MARK: Transaction listener

    /// Observes `Transaction.updates`, which delivers cross-device transactions
    /// (purchases, renewals, revocations from any device on the same Apple ID)
    /// while the app is running. Calls `refreshEntitlements()` so the verified
    /// currentEntitlements set — not just the single arriving transaction — drives state.
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }
}
