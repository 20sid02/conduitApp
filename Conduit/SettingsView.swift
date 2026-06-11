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

    let clients: [Client]
    @State private var showingDeleteAllConfirmation = false
    @State private var showingUpgrade = false

    var body: some View {
        NavigationStack {
            List {
                proSection
                syncSection

                Section("About Conduit") {
                    Text("Conduit is my local-first workspace for tracking clients, deployments, ports, URLs, and credentials without needing an account or backend.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !entitlements.isPro {
                        LabeledContent(
                            "Free Limits",
                            value: "\(FreeTierLimits.maxClients) clients, \(FreeTierLimits.maxDeploymentsPerClient) deployments each"
                        )
                    }
                }

                Section {
                    Text("I am building Conduit to make server and client work easier to keep track of. If something feels confusing, broken, or genuinely useful, I would really like to hear it.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Privacy") {
                    Text("Conduit does not use an account or backend. Project details stay on this device, and saved credentials are stored separately in the iOS Keychain.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
                        Label("Delete All Local Data", systemImage: "trash")
                    }
                    .disabled(clients.isEmpty)
                } header: {
                    Text("Testing")
                } footer: {
                    Text("Removes all clients, deployments, custom options, and saved Conduit credentials from this device.")
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
            .confirmationDialog(
                "Delete all local Conduit data?",
                isPresented: $showingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Local Data", role: .destructive) { deleteAllLocalData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. It removes all local project records and saved credentials from this device.")
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
                    Text("Conduit Pro — Active")
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
                            Text("Upgrade to Conduit Pro")
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
                    Task { await entitlements.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Conduit Pro")
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
