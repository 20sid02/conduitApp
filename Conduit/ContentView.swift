//
//  ContentView.swift
//  Conduit
//
//  Created by Siddharth Mahajan on 07/06/26.
//

import SwiftUI
import SwiftData
import UIKit

private enum ConduitTheme {
    static let backgroundTop = Color(red: 0.04, green: 0.11, blue: 0.17)
    static let backgroundBottom = Color(red: 0.00, green: 0.02, blue: 0.03)
    static let card = Color.white.opacity(0.075)
    static let inset = Color.white.opacity(0.07)
    static let stroke = Color.white.opacity(0.12)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.66)
    static let muted = Color.white.opacity(0.42)
    static let accent = Color(red: 0.16, green: 0.55, blue: 1.0)
    static let online = Color(red: 0.15, green: 0.92, blue: 0.38)
    static let offline = Color(red: 0.95, green: 0.24, blue: 0.24)

    static var background: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private let validPortRange = 1...65_535

private func sanitizedNumericText(_ text: String) -> String {
    String(text.unicodeScalars.filter { scalar in
        (48...57).contains(Int(scalar.value))
    })
}

private func sanitizedText(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func portValue(from text: String) -> Int? {
    let numericText = sanitizedNumericText(text)
    guard let port = Int(numericText), validPortRange.contains(port) else {
        return nil
    }

    return port
}

private func numericTextBinding(_ binding: Binding<String>) -> Binding<String> {
    Binding {
        sanitizedNumericText(binding.wrappedValue)
    } set: { newValue in
        binding.wrappedValue = sanitizedNumericText(newValue)
    }
}

private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

private extension View {
    func keyboardDismissControls() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
    }
}

private struct ConduitBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ConduitTheme.background
                .ignoresSafeArea()

            content
        }
        .preferredColorScheme(.dark)
    }
}

private struct ScreenHeader: View {
    let title: String
    var settingsAction: (() -> Void)?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(ConduitTheme.primary)

            Spacer()

            if let settingsAction {
                Button(action: settingsAction) {
                    Image(systemName: "gearshape")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ConduitTheme.secondary)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Settings")
            }

            if let action {
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ConduitTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Add")
            }
        }
    }
}

private struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ConduitTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ConduitTheme.stroke, lineWidth: 1)
            )
    }
}

private struct StatusDot: View {
    let isOnline: Bool
    var offlineColor: Color = ConduitTheme.offline

    var body: some View {
        Circle()
            .fill(isOnline ? ConduitTheme.online : offlineColor)
            .frame(width: 12, height: 12)
            .shadow(color: (isOnline ? ConduitTheme.online : offlineColor).opacity(0.45), radius: 8)
    }
}

private struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(ConduitTheme.secondary)
            .padding(.horizontal, 2)
    }
}

private struct EditableRow<Field: View>: View {
    let title: String
    @ViewBuilder var field: Field

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .foregroundStyle(ConduitTheme.primary)

            Spacer(minLength: 12)

            field
        }
        .font(.body)
        .padding(.vertical, 8)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.09))
            .frame(height: 1)
    }
}

private struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ConduitTheme.accent)

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.createdAt, order: .reverse) private var clients: [Client]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var clientPendingDeletion: Client?
    @State private var showingDeleteClientConfirmation = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ConduitBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScreenHeader(
                            title: "Keyring",
                            settingsAction: {
                                showingSettings = true
                            },
                            action: clients.count < FreeTierLimits.maxClients ? {
                                showingAddSheet = true
                            } : nil
                        )

                        if clients.count >= FreeTierLimits.maxClients {
                            EmptyStateCard(
                                systemImage: "lock",
                                title: "Free client limit reached",
                                message: "Conduit Free supports up to \(FreeTierLimits.maxClients) clients. Delete a client to add another."
                            )
                        }

                        if filteredClients.isEmpty {
                            EmptyStateCard(
                                systemImage: searchText.isEmpty ? "lock.square.stack" : "magnifyingglass",
                                title: searchText.isEmpty ? "No clients yet" : "No clients found",
                                message: searchText.isEmpty ? "Add your first client, server, or project to start mapping deployments." : "Try a different client or deployment name."
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredClients) { client in
                                    NavigationLink {
                                        ClientDetailView(client: client)
                                    } label: {
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
            .freeTierSearchable(text: $searchText)
            .confirmationDialog(
                "Delete this client?",
                isPresented: $showingDeleteClientConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Client", role: .destructive) {
                    if let client = clientPendingDeletion {
                        deleteClient(client)
                    }
                }

                Button("Cancel", role: .cancel) {
                    clientPendingDeletion = nil
                }
            } message: {
                Text("This removes the client, deployments, and saved credentials from this device.")
            }
            .sheet(isPresented: $showingAddSheet) {
                AddClientView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(clients: clients)
            }
        }
    }

    private var filteredClients: [Client] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return clients
        }

        return clients.filter { client in
            client.name.localizedCaseInsensitiveContains(query)
                || client.deployments.contains { deployment in
                    deployment.displayName.localizedCaseInsensitiveContains(query)
                }
        }
    }

    private func deleteClient(_ client: Client) {
        client.deployments.forEach(deleteStoredCredentials)
        modelContext.delete(client)
        clientPendingDeletion = nil
    }
}

private enum FreeTierLimits {
    static let maxClients = 4
    static let maxDeploymentsPerClient = 3
    static let searchEnabled = false
}

private extension View {
    @ViewBuilder
    func freeTierSearchable(text: Binding<String>) -> some View {
        if FreeTierLimits.searchEnabled {
            searchable(text: text, prompt: "Search clients")
        } else {
            self
        }
    }
}

private extension Deployment {
    var displayName: String {
        let trimmedAppName = appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedAppName.isEmpty ? "Unnamed App" : trimmedAppName
    }

    var hasDatabaseConfig: Bool {
        dbName != nil
            || dbPort != nil
            || KeychainManager.read(key: "\(id)-dbHost") != nil
            || KeychainManager.read(key: "\(id)-dbPassword") != nil
    }

    var hasSystemAccess: Bool {
        username != nil
            || KeychainManager.read(key: "\(id)-systemAccessPassword") != nil
    }

    var hasAdminAccess: Bool {
        adminUsername != nil
            || KeychainManager.read(key: "\(id)-adminAccessPassword") != nil
            || KeychainManager.read(key: "\(id)-djangoAdminPassword") != nil
    }
}

private extension CustomSettingField {
    var type: CustomSettingFieldType {
        get { CustomSettingFieldType(rawValue: typeRawValue) ?? .text }
        set { typeRawValue = newValue.rawValue }
    }

    var keychainKey: String {
        "customField-\(id.uuidString)"
    }

    var resolvedURL: URL? {
        guard type == .url else {
            return nil
        }

        let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawValue.isEmpty else {
            return nil
        }

        if let url = URL(string: rawValue), url.scheme != nil {
            return url
        }

        return URL(string: "https://\(rawValue)")
    }
}

private func deleteStoredCredentials(for deployment: Deployment) {
    ["dbHost", "dbPassword", "systemAccessPassword", "djangoAdminPassword", "adminAccessPassword"].forEach { keySuffix in
        _ = KeychainManager.delete(key: "\(deployment.id)-\(keySuffix)")
    }

    deployment.customSections
        .flatMap(\.fields)
        .filter { $0.type == .password }
        .forEach { field in
            _ = KeychainManager.delete(key: field.keychainKey)
        }
}

private struct ClientCard: View {
    let client: Client

    private var hasOnlineDeployment: Bool {
        client.deployments.contains { $0.isOnline }
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(client.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ConduitTheme.primary)

                    HStack(spacing: 8) {
                        Text(client.deployments.isEmpty ? "No deployments" : "\(client.deployments.count) deployment\(client.deployments.count == 1 ? "" : "s")")
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

struct AddClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .keyboardDismissControls()
            .scrollContentBackground(.hidden)
            .background(ConduitTheme.background)
            .navigationTitle("Add Client")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveClient() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let client = Client(name: trimmedName, createdAt: Date())
        modelContext.insert(client)
        dismiss()
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let clients: [Client]
    @State private var showingDeleteAllConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("About Conduit Free") {
                    Text("Conduit Free is my local-first workspace for tracking clients, deployments, ports, URLs, and credentials without needing an account or backend.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    LabeledContent("Free Limits", value: "\(FreeTierLimits.maxClients) clients, \(FreeTierLimits.maxDeploymentsPerClient) deployments each")
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
                    Button {
                        sendFeedback()
                    } label: {
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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete all local Conduit data?",
                isPresented: $showingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Local Data", role: .destructive) {
                    deleteAllLocalData()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. It removes all local project records and saved credentials from this device.")
            }
        }
    }

    private func sendFeedback() {
        let device = UIDevice.current
        let body = """
        Conduit Beta Feedback

        What happened?


        ---
        iOS: \(device.systemName) \(device.systemVersion)
        Device: \(device.model)
        App Version: \(appVersion)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = ""
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Conduit Beta Feedback"),
            URLQueryItem(name: "body", value: body)
        ]

        if let url = components.url {
            openURL(url)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func deleteAllLocalData() {
        clients.forEach { client in
            client.deployments.forEach(deleteStoredCredentials)
            modelContext.delete(client)
        }
    }
}

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var client: Client
    @State private var showingAddDeploymentSheet = false
    @State private var deploymentPendingDeletion: Deployment?
    @State private var showingDeleteDeploymentConfirmation = false

    var body: some View {
        ConduitBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(
                        title: client.name,
                        action: client.deployments.count < FreeTierLimits.maxDeploymentsPerClient ? {
                            showingAddDeploymentSheet = true
                        } : nil
                    )

                    if client.deployments.count >= FreeTierLimits.maxDeploymentsPerClient {
                        EmptyStateCard(
                            systemImage: "lock",
                            title: "Free deployment limit reached",
                            message: "Conduit Free supports up to \(FreeTierLimits.maxDeploymentsPerClient) deployments per client. Delete one to add another."
                        )
                    }

                    if client.deployments.isEmpty {
                        EmptyStateCard(
                            systemImage: "server.rack",
                            title: "No deployments yet",
                            message: "Add the first app running for this client, then attach routing, database, access, and vault details."
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(client.deployments) { deployment in
                                NavigationLink {
                                    DeploymentDetailView(deployment: deployment)
                                } label: {
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
        .confirmationDialog(
            "Delete this deployment?",
            isPresented: $showingDeleteDeploymentConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Deployment", role: .destructive) {
                if let deployment = deploymentPendingDeletion {
                    deleteDeployment(deployment)
                }
            }

            Button("Cancel", role: .cancel) {
                deploymentPendingDeletion = nil
            }
        } message: {
            Text("This removes the deployment and saved credentials from this device.")
        }
        .sheet(isPresented: $showingAddDeploymentSheet) {
            AddDeploymentView(client: client)
        }
    }

    private func deleteDeployment(_ deployment: Deployment) {
        deleteStoredCredentials(for: deployment)
        client.deployments.removeAll { $0.id == deployment.id }
        modelContext.delete(deployment)
        deploymentPendingDeletion = nil
    }
}

private struct DeploymentRow: View {
    let deployment: Deployment

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                StatusDot(isOnline: deployment.isOnline)

                Text(deploymentDisplayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)

                Spacer()
            }
        }
    }

    private var deploymentDisplayName: String {
        deployment.displayName
    }
}

struct AddDeploymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var client: Client
    @State private var appName = ""
    @State private var isOnline = true
    @State private var deploymentURL = ""
    @State private var systemPort = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("App Name", text: $appName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Toggle("Online System", isOn: $isOnline)

                    TextField("Deployment URL, IP, or Hosting Location", text: $deploymentURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    TextField("System Port (e.g., 8000)", text: numericTextBinding($systemPort))
                        .keyboardType(.numberPad)
                }
            }
            .keyboardDismissControls()
            .scrollContentBackground(.hidden)
            .background(ConduitTheme.background)
            .navigationTitle("Add Deployment")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(ConduitTheme.accent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDeployment()
                    }
                    .disabled(trimmedAppName.isEmpty || client.deployments.count >= FreeTierLimits.maxDeploymentsPerClient)
                }
            }
        }
    }

    private func saveDeployment() {
        let trimmedURL = deploymentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let deployment = Deployment(
            client: client,
            appName: trimmedAppName,
            dateDeployed: Date(),
            isOnline: isOnline,
            deploymentURL: trimmedURL.isEmpty ? nil : trimmedURL,
            systemPort: portValue(from: systemPort)
        )

        client.deployments.append(deployment)
        modelContext.insert(deployment)
        dismiss()
    }

    private var trimmedAppName: String {
        appName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct DeploymentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Bindable var deployment: Deployment
    @State private var showingAddOptionSheet = false
    @State private var routePendingDeletion: InternalRoute?
    @State private var showingDeleteDatabaseConfirmation = false
    @State private var showingDeleteAdminConfirmation = false

    var body: some View {
        ConduitBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: deploymentDisplayName, action: {
                        showingAddOptionSheet = true
                    })

                    HStack(spacing: 8) {
                        StatusDot(isOnline: deployment.isOnline)
                        Text(deployment.isOnline ? "System Online" : "System Offline")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ConduitTheme.secondary)
                    }
                    .padding(.top, -8)

                    systemInfoSection
                    databaseConfigSection
                    internalRoutingSection
                    adminAccessSection
                    customSettingsSections
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .keyboardDismissControls()
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddOptionSheet) {
            AddDeploymentOptionView(deployment: deployment)
        }
        .confirmationDialog(
            "Delete this internal route?",
            isPresented: Binding(
                get: { routePendingDeletion != nil },
                set: { if !$0 { routePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Internal Route", role: .destructive) {
                if let route = routePendingDeletion {
                    deleteInternalRoute(route)
                }
                routePendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {
                routePendingDeletion = nil
            }
        } message: {
            Text("This removes the saved service name and port from this deployment.")
        }
        .confirmationDialog(
            "Delete database config?",
            isPresented: $showingDeleteDatabaseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Database Config", role: .destructive) {
                deleteDatabaseConfig()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the database fields and saved database credentials for this deployment.")
        }
        .confirmationDialog(
            "Delete admin access?",
            isPresented: $showingDeleteAdminConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Admin Access", role: .destructive) {
                deleteAdminAccess()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the admin username and saved admin password for this deployment.")
        }
    }

    private var deploymentDisplayName: String {
        let trimmedAppName = deployment.appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedAppName.isEmpty ? "Deployment" : trimmedAppName
    }

    private var systemPortBinding: Binding<String> {
        optionalIntBinding(\.systemPort)
    }

    private var appNameBinding: Binding<String> {
        optionalStringBinding(\.appName)
    }

    private var deploymentURLBinding: Binding<String> {
        optionalStringBinding(\.deploymentURL)
    }

    private var deploymentURL: URL? {
        let rawValue = deployment.deploymentURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !rawValue.isEmpty else {
            return nil
        }

        if let url = URL(string: rawValue), url.scheme != nil {
            return url
        }

        return URL(string: "https://\(rawValue)")
    }

    private var sortedCustomSections: [CustomSettingSection] {
        deployment.customSections.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    private var sortedInternalRoutes: [InternalRoute] {
        deployment.internalRoutes.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.serviceName.localizedCaseInsensitiveCompare($1.serviceName) == .orderedAscending
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    private var systemInfoSection: some View {
        editableSection("System Info") {
            EditableRow(title: "App Name") {
                darkTextField("Not Set", text: appNameBinding)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            DividerLine()

            Toggle("System Online", isOn: $deployment.isOnline)
                .tint(ConduitTheme.online)
                .foregroundStyle(ConduitTheme.primary)
                .padding(.vertical, 8)

            DividerLine()

            EditableRow(title: "Deployment URL / IP / Location") {
                darkTextField("None", text: deploymentURLBinding)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
            }

            if let deploymentURL {
                DividerLine()

                Button {
                    openURL(deploymentURL)
                } label: {
                    Label("Open Deployment", systemImage: "safari")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(ConduitTheme.accent)
            }

            DividerLine()

            EditableRow(title: "System Port") {
                darkTextField("Not Set", text: systemPortBinding)
                    .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder
    private var databaseConfigSection: some View {
        if deployment.hasDatabaseConfig {
            editableSection("Database Config") {
                EditableRow(title: "Database Name") {
                    darkTextField("Not Set", text: optionalStringBinding(\.dbName))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                DividerLine()

                EditableRow(title: "Database Port") {
                    darkTextField("Not Set", text: optionalIntBinding(\.dbPort))
                        .keyboardType(.numberPad)
                }

                DividerLine()

                SecureCredentialView(deployment: deployment, title: "Database Host / Token", keySuffix: "dbHost")

                DividerLine()

                SecureCredentialView(deployment: deployment, title: "Database Password", keySuffix: "dbPassword")
            }
            .onLongPressGesture {
                showingDeleteDatabaseConfirmation = true
            }
        }
    }

    @ViewBuilder
    private var internalRoutingSection: some View {
        if !deployment.internalRoutes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Internal Routing / Ports Used")

                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedInternalRoutes.enumerated()), id: \.element.id) { index, route in
                            @Bindable var editableRoute = route

                            HStack(spacing: 12) {
                                TextField("Service Name", text: $editableRoute.serviceName)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ConduitTheme.primary)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()

                                TextField("Port", text: internalRoutePortBinding(for: editableRoute))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(ConduitTheme.secondary)
                                    .fontWeight(.semibold)
                                    .frame(width: 72)

                                Button(role: .destructive) {
                                    deleteInternalRoute(route)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ConduitTheme.offline)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete internal route")
                            }
                            .padding(.vertical, 9)

                            if index < sortedInternalRoutes.count - 1 {
                                DividerLine()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var adminAccessSection: some View {
        if deployment.hasAdminAccess {
            editableSection("Admin Access") {
                EditableRow(title: "Admin Username") {
                    darkTextField("Not Set", text: optionalStringBinding(\.adminUsername))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                DividerLine()

                SecureCredentialView(
                    deployment: deployment,
                    title: "Admin Password",
                    keySuffix: "adminAccessPassword",
                    legacyKeySuffix: "djangoAdminPassword"
                )
            }
            .onLongPressGesture {
                showingDeleteAdminConfirmation = true
            }
        }
    }

    private var customSettingsSections: some View {
        Group {
            ForEach(sortedCustomSections) { section in
                @Bindable var editableSection = section

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Option Category", text: $editableSection.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ConduitTheme.secondary)
                            .tint(ConduitTheme.accent)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button(role: .destructive) {
                            deleteCustomSection(section)
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ConduitTheme.offline)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 2)

                    GlassCard {
                        if section.fields.isEmpty {
                            Text("No custom fields")
                                .foregroundStyle(ConduitTheme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(sortedFields(for: section).enumerated()), id: \.element.id) { index, field in
                                    customFieldRow(field)

                                    if index < section.fields.count - 1 {
                                        DividerLine()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func sortedFields(for section: CustomSettingSection) -> [CustomSettingField] {
        section.fields.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    private func customFieldRow(_ field: CustomSettingField) -> some View {
        @Bindable var editableField = field

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("Option Name", text: $editableField.label)
                    .foregroundStyle(ConduitTheme.primary)
                    .fontWeight(.semibold)
                    .tint(ConduitTheme.accent)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Text(field.type.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ConduitTheme.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.08), in: Capsule())

                Button(role: .destructive) {
                    deleteCustomField(field)
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.offline)
                }
                .buttonStyle(.plain)
            }

            switch field.type {
            case .password:
                SecureCredentialView(
                    deployment: deployment,
                    title: field.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Password" : field.label,
                    keySuffix: field.keychainKey,
                    keychainKey: field.keychainKey
                )

            case .url:
                HStack(spacing: 10) {
                    customValueField("URL", text: customFieldValueBinding(for: field))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let url = field.resolvedURL {
                        Button {
                            openURL(url)
                        } label: {
                            Image(systemName: "safari")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ConduitTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open URL")
                    }
                }

            case .port:
                customValueField("Port", text: numericTextBinding(customFieldValueBinding(for: field)))
                    .keyboardType(.numberPad)

            case .text:
                customValueField("Value", text: customFieldValueBinding(for: field))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.vertical, 9)
    }

    private func editableSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: title)
            GlassCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    private func darkTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(ConduitTheme.secondary)
            .fontWeight(.semibold)
            .tint(ConduitTheme.accent)
    }

    private func customValueField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundStyle(ConduitTheme.secondary)
            .fontWeight(.semibold)
            .tint(ConduitTheme.accent)
    }

    private func customFieldValueBinding(for field: CustomSettingField) -> Binding<String> {
        Binding {
            field.value ?? ""
        } set: { newValue in
            let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            field.value = trimmedValue.isEmpty ? nil : trimmedValue
        }
    }

    private func optionalIntBinding(_ keyPath: ReferenceWritableKeyPath<Deployment, Int?>) -> Binding<String> {
        Binding {
            deployment[keyPath: keyPath].map(String.init) ?? ""
        } set: { newValue in
            let numericText = sanitizedNumericText(newValue)
            deployment[keyPath: keyPath] = numericText.isEmpty ? nil : portValue(from: numericText)
        }
    }

    private func optionalStringBinding(_ keyPath: ReferenceWritableKeyPath<Deployment, String?>) -> Binding<String> {
        Binding {
            deployment[keyPath: keyPath] ?? ""
        } set: { newValue in
            let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            deployment[keyPath: keyPath] = trimmedValue.isEmpty ? nil : trimmedValue
        }
    }

    private func internalRoutePortBinding(for route: InternalRoute) -> Binding<String> {
        Binding {
            String(route.port)
        } set: { newValue in
            if let port = portValue(from: newValue) {
                route.port = port
            }
        }
    }

    private func deleteInternalRoute(_ route: InternalRoute) {
        deployment.internalRoutes.removeAll { $0.id == route.id }
        modelContext.delete(route)
    }

    private func deleteDatabaseConfig() {
        deployment.dbName = nil
        deployment.dbPort = nil
        _ = KeychainManager.delete(key: "\(deployment.id)-dbHost")
        _ = KeychainManager.delete(key: "\(deployment.id)-dbPassword")
    }

    private func deleteAdminAccess() {
        deployment.adminUsername = nil
        _ = KeychainManager.delete(key: "\(deployment.id)-adminAccessPassword")
        _ = KeychainManager.delete(key: "\(deployment.id)-djangoAdminPassword")
    }

    private func deleteCustomSection(_ section: CustomSettingSection) {
        section.fields
            .filter { $0.type == .password }
            .forEach { field in
                _ = KeychainManager.delete(key: field.keychainKey)
            }

        deployment.customSections.removeAll { $0.id == section.id }
        modelContext.delete(section)
    }

    private func deleteCustomField(_ field: CustomSettingField) {
        if field.type == .password {
            _ = KeychainManager.delete(key: field.keychainKey)
        }

        field.section.fields.removeAll { $0.id == field.id }
        modelContext.delete(field)
    }
}

private enum DeploymentAddOption: String, CaseIterable, Identifiable {
    case internalRouting = "Internal Routing / Ports Used"
    case databaseConfig = "Database Config"
    case adminAccess = "Admin Access"
    case customSetting = "Custom Option"

    var id: Self { self }
}

struct AddDeploymentOptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var deployment: Deployment
    @State private var selectedOption: DeploymentAddOption = .internalRouting
    @State private var routeServiceName = ""
    @State private var routePort = ""
    @State private var dbName = ""
    @State private var dbPort = ""
    @State private var dbHost = ""
    @State private var dbPassword = ""
    @State private var adminUsername = ""
    @State private var adminAccessPassword = ""
    @State private var customSectionTitle = ""
    @State private var customFieldLabel = ""
    @State private var customFieldValue = ""
    @State private var customFieldPassword = ""
    @State private var customFieldType: CustomSettingFieldType = .text

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Add", selection: $selectedOption) {
                        ForEach(availableOptions) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                switch selectedOption {
                case .internalRouting:
                    Section("Internal Routing / Ports Used") {
                        TextField("Service Name", text: $routeServiceName, prompt: Text("Service"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Port", text: numericTextBinding($routePort), prompt: Text("Port"))
                            .keyboardType(.numberPad)
                    }

                case .databaseConfig:
                    Section("Database Config") {
                        TextField("Database Name", text: $dbName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Database Port", text: numericTextBinding($dbPort))
                            .keyboardType(.numberPad)

                        SecureField("Database Host / Token", text: $dbHost)
                            .textContentType(.password)

                        SecureField("Database Password", text: $dbPassword)
                            .textContentType(.password)
                    }

                case .adminAccess:
                    Section("Admin Access") {
                        TextField("Admin Username", text: $adminUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Admin Password", text: $adminAccessPassword)
                            .textContentType(.password)
                    }

                case .customSetting:
                    Section("Custom Option") {
                        TextField("Option Category", text: $customSectionTitle, prompt: Text("Option Category"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Option Name", text: $customFieldLabel, prompt: Text("Option Name"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Picker("Setting Type", selection: $customFieldType) {
                            ForEach(CustomSettingFieldType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }

                        switch customFieldType {
                        case .password:
                            SecureField("Value", text: $customFieldPassword)
                                .textContentType(.password)

                        case .url:
                            TextField("Value", text: $customFieldValue, prompt: Text("https://panel.example.com"))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                        case .port:
                            TextField("Value", text: numericTextBinding($customFieldValue), prompt: Text("8080"))
                                .keyboardType(.numberPad)

                        case .text:
                            TextField("Value", text: $customFieldValue)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                }
            }
            .keyboardDismissControls()
            .scrollContentBackground(.hidden)
            .background(ConduitTheme.background)
            .navigationTitle("Add Option")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(ConduitTheme.accent)
            .onAppear {
                normalizeSelectedOption()
            }
            .onChange(of: availableOptions.map(\.rawValue)) {
                normalizeSelectedOption()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOption()
                    }
                    .disabled(saveDisabled)
                }
            }
        }
    }

    private var saveDisabled: Bool {
        switch selectedOption {
        case .internalRouting:
            return trimmedRouteServiceName.isEmpty || portValue(from: routePort) == nil
        case .databaseConfig:
            return trimmedDbName.isEmpty && portValue(from: dbPort) == nil && dbHost.isEmpty && dbPassword.isEmpty
        case .adminAccess:
            return trimmedAdminUsername.isEmpty && adminAccessPassword.isEmpty
        case .customSetting:
            return trimmedCustomSectionTitle.isEmpty
                || trimmedCustomFieldLabel.isEmpty
                || (customFieldType == .password ? customFieldPassword.isEmpty : false)
        }
    }

    private var availableOptions: [DeploymentAddOption] {
        DeploymentAddOption.allCases.filter { option in
            switch option {
            case .databaseConfig:
                !deployment.hasDatabaseConfig
            case .adminAccess:
                !deployment.hasAdminAccess
            case .internalRouting, .customSetting:
                true
            }
        }
    }

    private var trimmedRouteServiceName: String {
        routeServiceName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDbName: String {
        dbName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAdminUsername: String {
        adminUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCustomSectionTitle: String {
        customSectionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCustomFieldLabel: String {
        customFieldLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveOption() {
        switch selectedOption {
        case .internalRouting:
            guard let port = portValue(from: routePort) else {
                return
            }

            let route = InternalRoute(
                deployment: deployment,
                serviceName: trimmedRouteServiceName,
                port: port,
                sortOrder: deployment.internalRoutes.count
            )
            deployment.internalRoutes.append(route)
            modelContext.insert(route)

        case .databaseConfig:
            if !trimmedDbName.isEmpty {
                deployment.dbName = trimmedDbName
            }

            if let port = portValue(from: dbPort) {
                deployment.dbPort = port
            }

            savePassword(dbHost, keySuffix: "dbHost")
            savePassword(dbPassword, keySuffix: "dbPassword")

        case .adminAccess:
            if !trimmedAdminUsername.isEmpty {
                deployment.adminUsername = trimmedAdminUsername
            }

            savePassword(adminAccessPassword, keySuffix: "adminAccessPassword")

        case .customSetting:
            saveCustomSetting()
        }

        dismiss()
    }

    private func normalizeSelectedOption() {
        guard !availableOptions.contains(selectedOption), let firstOption = availableOptions.first else {
            return
        }

        selectedOption = firstOption
    }

    private func savePassword(_ password: String, keySuffix: String) {
        guard !password.isEmpty else {
            return
        }

        _ = KeychainManager.save(key: "\(deployment.id)-\(keySuffix)", value: password)
    }

    private func saveCustomSetting() {
        let section = existingCustomSection() ?? {
            let newSection = CustomSettingSection(
                deployment: deployment,
                title: trimmedCustomSectionTitle,
                sortOrder: deployment.customSections.count
            )
            deployment.customSections.append(newSection)
            return newSection
        }()

        let field = CustomSettingField(
            section: section,
            label: trimmedCustomFieldLabel,
            value: customFieldType == .password ? nil : normalizedCustomFieldValue(),
            type: customFieldType,
            sortOrder: section.fields.count
        )

        section.fields.append(field)

        if customFieldType == .password {
            _ = KeychainManager.save(key: field.keychainKey, value: customFieldPassword)
        }
    }

    private func existingCustomSection() -> CustomSettingSection? {
        deployment.customSections.first {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(trimmedCustomSectionTitle) == .orderedSame
        }
    }

    private func normalizedCustomFieldValue() -> String? {
        let trimmedValue = customFieldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

#Preview("ContentView") {
    ContentView()
        .modelContainer(for: [Client.self, Deployment.self, InternalRoute.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}

#Preview("AddClientView") {
    AddClientView()
        .modelContainer(for: [Client.self, Deployment.self, InternalRoute.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}
