//
//  SettingsView.swift
//  Conduit
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(CloudSyncMonitor.self) private var syncMonitor
    @Environment(ThemeManager.self) private var themeManager

    let clients: [Client]
    @State private var showingDeleteAllConfirmation = false
    @State private var showingDeleteFinalConfirmation = false
    @State private var showingUpgrade = false
    @State private var isCheckingPurchase = false

    var body: some View {
        NavigationStack {
            List {
                proSection
                syncSection
                appearanceSection

                if entitlements.isPro {
                    Section("About Conduit Plus") {
                        Text("Conduit Plus is a local-first infrastructure workspace for developers. Track unlimited clients, deployments, ports, URLs, and credentials — synced across your Apple devices via iCloud, with no account or backend required.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Section {
                        Text("Conduit Plus is built to make managing servers and client infrastructure less painful. If something feels off, broken, or genuinely useful, I would really like to hear it.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Section("Privacy") {
                        Text("Conduit Plus has no account, no backend, and no telemetry. Your infrastructure data stays on your devices and syncs privately through your personal iCloud container. Credentials are stored exclusively in the iOS Keychain and are never included in iCloud sync.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Section("About Conduit") {
                        Text("Conduit is a local-first infrastructure workspace for developers. Track clients, deployments, ports, URLs, and credentials — all stored privately on your device.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        LabeledContent(
                            "Free Limits",
                            value: "\(FreeTierLimits.maxClients) clients, \(FreeTierLimits.maxDeploymentsPerClient) deployments each"
                        )
                    }

                    Section {
                        Text("Conduit is built to make managing servers and client infrastructure less painful. If something feels off, broken, or genuinely useful, I would really like to hear it.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Section("Privacy") {
                        Text("Conduit has no account, no backend, and no telemetry. Your infrastructure data stays exclusively on your device. Credentials are stored in the iOS Keychain and never leave your device.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Section {
                    Button { sendFeedback() } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteAllConfirmation = true
                    } label: {
                        Label("Nuke Database", systemImage: "trash")
                    }
                    .disabled(clients.isEmpty)
                } header: {
                    Text("Testing")
                } footer: {
                    Text("This will remove all data from database.")
                }
            }
            .keyboardDismissControls()
            .scrollContentBackground(.hidden)
            .background(ConduitTheme.background)
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(ConduitTheme.accent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Nuke Database?", isPresented: $showingDeleteAllConfirmation) {
                Button("Continue", role: .destructive) { showingDeleteFinalConfirmation = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all data from database. This cannot be undone.")
            }
            .alert("Are you absolutely sure?", isPresented: $showingDeleteFinalConfirmation) {
                Button("Nuke Database", role: .destructive) { deleteAllLocalData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Every client, deployment, and credential on this device will be permanently deleted.")
            }
            .sheet(isPresented: $showingUpgrade) {
                ProUpgradeView()
            }
        }
    }

    // MARK: - Pro section

    @ViewBuilder
    private var proSection: some View {
        if entitlements.isPro {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(ConduitTheme.online)
                    Text("Conduit Plus — Active")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.primary)
                    Spacer()
                }
                Button {
                    Task { await entitlements.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Subscription")
            }
        } else {
            Section {
                Button {
                    showingUpgrade = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundStyle(ConduitTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Conduit Plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ConduitTheme.primary)
                            Text("Unlimited clients, sync, API vault & more")
                                .font(.caption)
                                .foregroundStyle(ConduitTheme.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ConduitTheme.muted)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    isCheckingPurchase = true
                    Task {
                        await entitlements.restorePurchases()
                        isCheckingPurchase = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isCheckingPurchase {
                            ProgressView()
                                .controlSize(.small)
                                .tint(ConduitTheme.secondary)
                            Text("Checking…")
                                .foregroundStyle(ConduitTheme.secondary)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(ConduitTheme.accent)
                            Text("I already bought this")
                                .foregroundStyle(ConduitTheme.accent)
                        }
                    }
                }
                .disabled(isCheckingPurchase)

                if let error = entitlements.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ConduitTheme.offline)
                }
            } header: {
                Text("Conduit Plus")
            }
        }
    }

    // MARK: - Sync section

    @ViewBuilder
    private var syncSection: some View {
        Section {
            if entitlements.isEnabled(.cloudSync) {
                CloudSyncView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } else {
                ProGateCard(feature: .cloudSync)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            Text("Conduit syncs your client and deployment records across all your Apple devices using your personal iCloud account. Credentials remain exclusively in the Keychain and are never synced.")
        }
    }

    // MARK: - Appearance section

    @ViewBuilder
    private var appearanceSection: some View {
        Section {
            if entitlements.isEnabled(.customization) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeTile(
                            theme: theme,
                            isSelected: themeManager.selectedTheme == theme
                        ) {
                            themeManager.applyTheme(theme)
                        }
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                ProGateCard(feature: .customization)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        } header: {
            Text("Appearance")
        } footer: {
            if entitlements.isEnabled(.customization) {
                Text("Choose a color theme for the app interface.")
            }
        }
    }

    // MARK: - Helpers

    private func sendFeedback() {
        let device = UIDevice.current
        let body = """
        Conduit Beta Feedback

        What happened?


        ---
        iOS: \(device.systemName) \(device.systemVersion)
        Device: \(device.model)
        App Version: \(appVersion)
        Pro: \(entitlements.isPro)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = ""
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Conduit Beta Feedback"),
            URLQueryItem(name: "body", value: body)
        ]
        if let url = components.url { openURL(url) }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func deleteAllLocalData() {
        clients.forEach { client in
            (client.deployments ?? []).forEach(deleteStoredCredentials)
            modelContext.delete(client)
        }
    }
}

// MARK: - ThemeTile

private struct ThemeTile: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.backgroundTop, theme.backgroundBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected ? theme.accent : Color.white.opacity(0.15),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    Circle()
                        .fill(theme.accent)
                        .frame(width: 14, height: 14)
                        .shadow(color: theme.accent.opacity(0.6), radius: 5)
                }

                Text(theme.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? ConduitTheme.primary : ConduitTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 64)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
