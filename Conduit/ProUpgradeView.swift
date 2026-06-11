//
//  ProUpgradeView.swift
//  Conduit
//

import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ZStack {
                ConduitTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroSection
                            .padding(.top, 8)
                            .padding(.bottom, 28)

                        featureList
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)

                        if entitlements.isPro {
                            alreadyProSection
                                .padding(.horizontal, 20)
                        } else {
                            productSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                            ctaSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(ConduitTheme.secondary)
                }
            }
            .task { await entitlements.loadProducts() }
            .onChange(of: entitlements.products) {
                if selectedProduct == nil {
                    selectedProduct = entitlements.products.first(where: {
                        $0.id == EntitlementManager.ProductID.proAnnual
                    }) ?? entitlements.products.first
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ConduitTheme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(ConduitTheme.accent)
            }

            VStack(spacing: 6) {
                Text("Conduit Pro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(ConduitTheme.primary)

                Text("Everything you need to manage unlimited\nclient deployments, synced and secure.")
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Feature list

    private var featureList: some View {
        GlassCard {
            VStack(spacing: 0) {
                ForEach(Array(ProFeature.allCases.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(ConduitTheme.accent.opacity(0.14))
                                .frame(width: 34, height: 34)
                            Image(systemName: feature.systemImage)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ConduitTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ConduitTheme.primary)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(ConduitTheme.muted)
                        }

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ConduitTheme.online)
                    }
                    .padding(.vertical, 11)

                    if index < ProFeature.allCases.count - 1 {
                        DividerLine()
                    }
                }
            }
        }
    }

    // MARK: - Product picker

    @ViewBuilder
    private var productSection: some View {
        if entitlements.isLoadingProducts {
            HStack {
                Spacer()
                ProgressView()
                    .tint(ConduitTheme.secondary)
                Spacer()
            }
            .padding(.vertical, 20)
        } else if entitlements.products.isEmpty {
            EmptyStateCard(
                systemImage: "exclamationmark.triangle",
                title: "Products unavailable",
                message: "Could not load pricing from the App Store. Check your connection and try again."
            )
        } else {
            VStack(spacing: 10) {
                ForEach(entitlements.products) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private var ctaSection: some View {
        VStack(spacing: 12) {
            if let error = entitlements.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(ConduitTheme.offline)
                    .multilineTextAlignment(.center)
            }

            // ── Buy button ────────────────────────────────────────────────────
            Button {
                guard let product = selectedProduct else { return }
                isPurchasing = true
                Task {
                    await entitlements.purchase(product)
                    isPurchasing = false
                    if entitlements.isPro { dismiss() }
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(selectedProduct.map { "Get Pro — \($0.displayPrice)" } ?? "Get Conduit Pro")
                            .font(.body.weight(.bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ConduitTheme.accent)
                )
                .foregroundStyle(.white)
            }
            .disabled(selectedProduct == nil || isPurchasing || isRestoring)

            // ── Already-bought button ─────────────────────────────────────────
            Button {
                isRestoring = true
                Task {
                    await entitlements.restorePurchases()
                    isRestoring = false
                    if entitlements.isPro { dismiss() }
                }
            } label: {
                HStack(spacing: 8) {
                    if isRestoring {
                        ProgressView()
                            .controlSize(.small)
                            .tint(ConduitTheme.secondary)
                        Text("Checking…")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ConduitTheme.secondary)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .font(.subheadline.weight(.semibold))
                        Text("I already bought this")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .foregroundStyle(isRestoring ? ConduitTheme.secondary : ConduitTheme.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ConduitTheme.accent.opacity(isRestoring ? 0.06 : 0.10))
                )
            }
            .disabled(isPurchasing || isRestoring)

            Text("Subscriptions auto-renew unless cancelled. Lifetime is a one-time purchase.")
                .font(.caption2)
                .foregroundStyle(ConduitTheme.muted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Already Pro

    private var alreadyProSection: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(ConduitTheme.online)

                VStack(alignment: .leading, spacing: 4) {
                    Text("You have Conduit Pro")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ConduitTheme.primary)
                    Text("All features are unlocked.")
                        .font(.caption)
                        .foregroundStyle(ConduitTheme.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Product card

private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.primary)

                    if let sub = product.subscription {
                        Text(subscriptionPeriodLabel(sub.subscriptionPeriod))
                            .font(.caption)
                            .foregroundStyle(ConduitTheme.muted)
                    } else {
                        Text("One-time purchase")
                            .font(.caption)
                            .foregroundStyle(ConduitTheme.muted)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? ConduitTheme.accent : ConduitTheme.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? ConduitTheme.accent.opacity(0.12) : ConduitTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? ConduitTheme.accent : ConduitTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func subscriptionPeriodLabel(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:   return period.value == 7 ? "Per week" : "Per \(period.value) days"
        case .week:  return "Per week"
        case .month: return period.value == 1 ? "Per month" : "Per \(period.value) months"
        case .year:  return "Per year"
        @unknown default: return ""
        }
    }
}
