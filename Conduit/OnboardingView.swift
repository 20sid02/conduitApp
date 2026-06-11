//
//  OnboardingView.swift
//  Conduit
//

import SwiftUI

struct OnboardingView: View {
    let isPro: Bool
    let onDismiss: () -> Void

    var body: some View {
        ConduitBackground {
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ConduitTheme.secondary)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.10), in: Circle())
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Header
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: isPro ? "crown.fill" : "terminal.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(ConduitTheme.accent)
                                Text(isPro ? "Conduit Plus" : "Welcome to Conduit")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(ConduitTheme.primary)
                            }
                            Text(isPro
                                 ? "Your premium features are active. Here's what's unlocked."
                                 : "Your offline-first infrastructure vault. Everything in one place, nothing leaves your device.")
                                .font(.subheadline)
                                .foregroundStyle(ConduitTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if isPro {
                            proContent
                        } else {
                            freeContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Free tier

    private var freeContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Core concept
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    conceptRow(
                        icon: "person.crop.square.fill",
                        title: "Clients",
                        body: "A client is a project, company, or server group. Everything lives under a client."
                    )
                    DividerLine()
                    conceptRow(
                        icon: "server.rack",
                        title: "Deployments",
                        body: "Each deployment is a running app or environment — with its URL, ports, database config, and credentials."
                    )
                    DividerLine()
                    conceptRow(
                        icon: "lock.fill",
                        title: "Credentials",
                        body: "Passwords and secrets are stored in the device Keychain, locked behind Face ID. Nothing is sent anywhere."
                    )
                }
            }

            // How to use
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle(title: "Getting started")
                        .padding(.bottom, 2)
                    stepRow(number: "1", text: "Tap  +  on the Keyring screen to add a client.")
                    DividerLine()
                    stepRow(number: "2", text: "Open the client, then tap  +  again to add a deployment.")
                    DividerLine()
                    stepRow(number: "3", text: "Inside a deployment, use the  +  button to attach database config, ports, admin access, and custom fields.")
                    DividerLine()
                    stepRow(number: "4", text: "Long-press any section card to delete it. Swipe down to dismiss.")
                }
            }

            // Free tier limits
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .foregroundStyle(ConduitTheme.accent)
                            .font(.body.weight(.semibold))
                        Text("Free tier")
                            .font(.body.weight(.bold))
                            .foregroundStyle(ConduitTheme.primary)
                    }
                    Text("Up to **3 clients** and **3 deployments per client**. Upgrade to Conduit Plus for unlimited access, iCloud sync, port diagnostics, search, and more.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Dismiss
            Button(action: onDismiss) {
                Text("Got it")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ConduitTheme.background.opacity(1))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ConduitTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Plus tier

    private var proContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(ProFeature.allCases.enumerated()), id: \.element) { index, feature in
                        proFeatureRow(feature)
                        if index < ProFeature.allCases.count - 1 {
                            DividerLine()
                        }
                    }
                }
            }

            // Emergency Directory — newest feature
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ConduitTheme.accent)
                        Text("Emergency Directory")
                            .font(.body.weight(.bold))
                            .foregroundStyle(ConduitTheme.primary)
                    }
                    Text("Attach on-call contacts, support lines, and vendor portals to any client. Tap to call, email, or open a support portal instantly from the client screen.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: onDismiss) {
                Text("Let's go")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ConduitTheme.background.opacity(1))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ConduitTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Row helpers

    private func conceptRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(ConduitTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(ConduitTheme.background.opacity(1))
                .frame(width: 20, height: 20)
                .background(ConduitTheme.accent, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(ConduitTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private func proFeatureRow(_ feature: ProFeature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(ConduitTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.body.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
    }
}
