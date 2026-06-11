//
//  ProGate.swift
//  Conduit
//
//  Pattern for gating any Pro feature:
//    1. Add the feature to ProFeature in EntitlementManager.swift
//    2. Use ProGateCard(...) at limit walls
//    3. Use .proGated(.featureName) on any view that should be locked behind Pro

import SwiftUI

// MARK: - ProGateCard
// Replaces EmptyStateCard at limit walls. Shows an upgrade CTA.

struct ProGateCard: View {
    let feature: ProFeature
    @State private var showingUpgrade = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ConduitTheme.accent)

                    Text("Conduit Plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ConduitTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ConduitTheme.accent.opacity(0.14), in: Capsule())
                }

                Text(feature.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showingUpgrade = true
                } label: {
                    Text("Upgrade to Conduit Plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(ConduitTheme.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showingUpgrade) {
            ProUpgradeView()
        }
    }
}

// MARK: - proGated modifier
// Wraps any view with a locked overlay + upgrade sheet when the user is not Pro.
// Usage: someView.proGated(.apiKeyVault)

extension View {
    func proGated(_ feature: ProFeature) -> some View {
        modifier(ProGateModifier(feature: feature))
    }
}

private struct ProGateModifier: ViewModifier {
    let feature: ProFeature
    @Environment(EntitlementManager.self) private var entitlements
    @State private var showingUpgrade = false

    func body(content: Content) -> some View {
        if entitlements.isEnabled(feature) {
            content
        } else {
            content
                .disabled(true)
                .overlay(lockedOverlay)
                .sheet(isPresented: $showingUpgrade) {
                    ProUpgradeView()
                }
        }
    }

    private var lockedOverlay: some View {
        Button {
            showingUpgrade = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.black.opacity(0.55))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 10) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(ConduitTheme.accent)

                    Text("Pro Feature")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ConduitTheme.primary)

                    Text("Upgrade to unlock \(feature.displayName)")
                        .font(.caption)
                        .foregroundStyle(ConduitTheme.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
}
