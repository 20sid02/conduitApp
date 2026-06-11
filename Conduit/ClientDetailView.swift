//
//  ClientDetailView.swift
//  Conduit
//

import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements

    @Bindable var client: Client
    @State private var showingAddDeploymentSheet = false
    @State private var showingUpgrade = false
    @State private var deploymentPendingDeletion: Deployment?
    @State private var showingDeleteDeploymentConfirmation = false

    var body: some View {
        ConduitBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    let deploymentCount = client.deployments?.count ?? 0
                    let atDeploymentLimit = deploymentCount >= entitlements.maxDeploymentsPerClient
                    ScreenHeader(
                        title: client.name,
                        action: {
                            if atDeploymentLimit {
                                showingUpgrade = true
                            } else {
                                showingAddDeploymentSheet = true
                            }
                        }
                    )

                    if atDeploymentLimit {
                        ProGateCard(feature: .unlimitedDeployments)
                    }

                    if client.deployments?.isEmpty ?? true {
                        EmptyStateCard(
                            systemImage: "server.rack",
                            title: "No deployments yet",
                            message: "Add the first app running for this client, then attach routing, database, access, and vault details."
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(client.deployments ?? []) { deployment in
                                NavigationLink(value: deployment) {
                                    DeploymentRow(deployment: deployment)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete Deployment", systemImage: "trash", role: .destructive) {
                                        deploymentPendingDeletion = deployment
                                        showingDeleteDeploymentConfirmation = true
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
        .alert("Delete this deployment?", isPresented: $showingDeleteDeploymentConfirmation) {
            Button("Delete Deployment", role: .destructive) {
                if let deployment = deploymentPendingDeletion { deleteDeployment(deployment) }
            }
            Button("Cancel", role: .cancel) { deploymentPendingDeletion = nil }
        } message: {
            Text("This removes the deployment and saved credentials from this device.")
        }
        .sheet(isPresented: $showingAddDeploymentSheet) {
            AddDeploymentView(client: client)
        }
        .sheet(isPresented: $showingUpgrade) {
            ProUpgradeView()
        }
    }

    private func deleteDeployment(_ deployment: Deployment) {
        deleteStoredCredentials(for: deployment)
        client.deployments.removeAll { $0.id == deployment.id }
        modelContext.delete(deployment)
        deploymentPendingDeletion = nil
    }
}

struct DeploymentRow: View {
    let deployment: Deployment

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                StatusDot(isOnline: deployment.isOnline)
                Text(deployment.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)
                Spacer()
            }
        }
    }
}
