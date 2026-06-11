//
//  ContentView.swift
//  Conduit
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements

    @Query(sort: \Client.createdAt, order: .reverse) private var clients: [Client]
    @State private var navigationPath = NavigationPath()
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var clientPendingDeletion: Client?
    @State private var showingDeleteClientConfirmation = false
    @State private var showingSettings = false
    @State private var showingUpgrade = false

    private let router = DeepLinkRouter.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ConduitBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScreenHeader(
                            title: "Keyring",
                            settingsAction: { showingSettings = true },
                            action: {
                                if clients.count < entitlements.maxClients {
                                    showingAddSheet = true
                                } else {
                                    showingUpgrade = true
                                }
                            }
                        )

                        if clients.count >= entitlements.maxClients {
                            ProGateCard(feature: .unlimitedClients)
                        }

                        if filteredClients.isEmpty {
                            EmptyStateCard(
                                systemImage: searchText.isEmpty ? "lock.square.stack" : "magnifyingglass",
                                title: searchText.isEmpty ? "No clients yet" : "No clients found",
                                message: searchText.isEmpty
                                    ? "Add your first client, server, or project to start mapping deployments."
                                    : "Try a different client or deployment name."
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredClients) { client in
                                    NavigationLink(value: client) {
                                        ClientCard(client: client)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Delete Client", systemImage: "trash", role: .destructive) {
                                            clientPendingDeletion = client
                                            showingDeleteClientConfirmation = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
                .keyboardDismissControls()
            }
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            .modifier(SearchableIfEnabled(text: $searchText, isEnabled: entitlements.isSearchEnabled))
            .alert("Delete this client?", isPresented: $showingDeleteClientConfirmation) {
                Button("Delete Client", role: .destructive) {
                    if let client = clientPendingDeletion { deleteClient(client) }
                }
                Button("Cancel", role: .cancel) { clientPendingDeletion = nil }
            } message: {
                Text("This removes the client, deployments, and saved credentials from this device.")
            }
            .navigationDestination(for: Client.self) { ClientDetailView(client: $0) }
            .navigationDestination(for: Deployment.self) { DeploymentDetailView(deployment: $0) }
            .sheet(isPresented: $showingAddSheet) { AddClientView() }
            .sheet(isPresented: $showingSettings) { SettingsView(clients: clients) }
            .sheet(isPresented: $showingUpgrade) { ProUpgradeView() }
            .onAppear { handlePendingDeepLink() }
            .onChange(of: router.pendingDeploymentID) { handlePendingDeepLink() }
        }
    }

    private func handlePendingDeepLink() {
        guard let idString = router.pendingDeploymentID,
              let id = UUID(uuidString: idString),
              let deployment = clients.flatMap({ $0.deployments ?? [] }).first(where: { $0.id == id }),
              let client = deployment.client
        else { return }
        navigationPath = NavigationPath()
        navigationPath.append(client)
        navigationPath.append(deployment)
        router.pendingDeploymentID = nil
    }

    private var filteredClients: [Client] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clients }
        return clients.filter { client in
            client.name.localizedCaseInsensitiveContains(query)
                || (client.deployments ?? []).contains { $0.displayName.localizedCaseInsensitiveContains(query) }
        }
    }

    private func deleteClient(_ client: Client) {
        (client.deployments ?? []).forEach(deleteStoredCredentials)
        modelContext.delete(client)
        clientPendingDeletion = nil
    }
}

// Applies .searchable only when enabled, avoiding the free-tier stub.
private struct SearchableIfEnabled: ViewModifier {
    @Binding var text: String
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: "Search clients")
        } else {
            content
        }
    }
}

private struct ClientCard: View {
    let client: Client

    private var hasOnlineDeployment: Bool {
        (client.deployments ?? []).contains { $0.isOnline }
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(client.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ConduitTheme.primary)

                    HStack(spacing: 8) {
                        Text((client.deployments ?? []).isEmpty
                             ? "No deployments"
                             : "\(client.deployments!.count) deployment\(client.deployments!.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ConduitTheme.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.08), in: Capsule())

                        Text(client.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(ConduitTheme.muted)
                    }
                }

                Spacer()

                StatusDot(isOnline: hasOnlineDeployment, offlineColor: Color.white.opacity(0.28))
            }
        }
    }
}

#Preview("ContentView") {
    ContentView()
        .modelContainer(for: [Client.self, Deployment.self, InternalRoute.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
        .environment(EntitlementManager.shared)
}

#Preview("AddClientView") {
    AddClientView()
        .modelContainer(for: [Client.self, Deployment.self, InternalRoute.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}
