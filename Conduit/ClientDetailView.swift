//
//  ClientDetailView.swift
//  Conduit
//

import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlements

    @Bindable var client: Client
    @State private var showingAddDeploymentSheet = false
    @State private var showingUpgrade = false
    @State private var deploymentPendingDeletion: Deployment?
    @State private var showingDeleteDeploymentConfirmation = false
    @State private var showingAddContactSheet = false
    @State private var contactPendingDeletion: ContactEntry?
    @State private var showingDeleteContactConfirmation = false

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

                    VaultSectionView(client: client)

                    emergencyDirectorySection
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
        .sheet(isPresented: $showingAddContactSheet) {
            AddContactView(client: client)
        }
        .alert("Delete this contact?", isPresented: $showingDeleteContactConfirmation) {
            Button("Delete Contact", role: .destructive) {
                if let contact = contactPendingDeletion { deleteContact(contact) }
            }
            Button("Cancel", role: .cancel) { contactPendingDeletion = nil }
        } message: {
            Text("This removes the contact entry from this client's emergency directory.")
        }
    }

    private func deleteDeployment(_ deployment: Deployment) {
        deleteStoredCredentials(for: deployment)
        client.deployments.removeAll { $0.id == deployment.id }
        modelContext.delete(deployment)
        deploymentPendingDeletion = nil
    }

    // MARK: - Emergency Directory

    private var sortedContacts: [ContactEntry] {
        (client.contacts ?? []).sorted {
            $0.sortOrder == $1.sortOrder
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : $0.sortOrder < $1.sortOrder
        }
    }

    private var emergencyDirectorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(title: "Emergency Directory")
                Spacer()
                Button {
                    showingAddContactSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Add Contact")
            }

            if sortedContacts.isEmpty {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ConduitTheme.muted)
                        Text("No contacts — add on-call staff, support lines, or vendor portals.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedContacts.enumerated()), id: \.element.id) { index, contact in
                            contactCard(contact)
                            if index < sortedContacts.count - 1 {
                                DividerLine()
                            }
                        }
                    }
                }
            }
        }
    }

    private func contactCard(_ contact: ContactEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(contact.name)
                    .font(.body.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)

                if let role = contact.role {
                    Text(role)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ConduitTheme.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.08), in: Capsule())
                }

                Spacer()

                Button(role: .destructive) {
                    contactPendingDeletion = contact
                    showingDeleteContactConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.offline)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete contact")
            }

            if let phone = contact.phone {
                Button {
                    let digits = phone.filter { $0.isNumber || $0 == "+" }
                    if let url = URL(string: "tel:\(digits)") { openURL(url) }
                } label: {
                    Label(phone, systemImage: "phone.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ConduitTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if let email = contact.email {
                Button {
                    if let url = URL(string: "mailto:\(email)") { openURL(url) }
                } label: {
                    Label(email, systemImage: "envelope.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ConduitTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if let portal = contact.supportPortal {
                Button {
                    let raw = portal.trimmingCharacters(in: .whitespacesAndNewlines)
                    let url = URL(string: raw)?.scheme != nil
                        ? URL(string: raw)
                        : URL(string: "https://\(raw)")
                    if let url { openURL(url) }
                } label: {
                    Label(portal, systemImage: "globe")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ConduitTheme.accent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .buttonStyle(.plain)
            }

            if let notes = contact.accountNotes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(ConduitTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
    }

    private func deleteContact(_ contact: ContactEntry) {
        client.contacts.removeAll { $0.id == contact.id }
        modelContext.delete(contact)
        contactPendingDeletion = nil
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
