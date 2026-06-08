//
//  ContentView.swift
//  Conduit
//
//  Created by Siddharth Mahajan on 07/06/26.
//

import SwiftUI
import SwiftData

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
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(ConduitTheme.primary)

            Spacer()

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

    var body: some View {
        NavigationStack {
            ConduitBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScreenHeader(title: "Client") {
                            showingAddSheet = true
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
            }
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search clients")
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
                Text("This removes the client, deployments, tunnels, and saved credentials from this device.")
            }
            .sheet(isPresented: $showingAddSheet) {
                AddClientView()
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

private extension Deployment {
    var displayName: String {
        let trimmedAppName = appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedAppName.isEmpty ? "Unnamed App" : trimmedAppName
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
    ["dbPassword", "systemAccessPassword", "djangoAdminPassword", "adminAccessPassword"].forEach { keySuffix in
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
                    .textInputAutocapitalization(.words)
            }
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
                    ScreenHeader(title: client.name) {
                        showingAddDeploymentSheet = true
                    }

                    if client.deployments.isEmpty {
                        EmptyStateCard(
                            systemImage: "server.rack",
                            title: "No deployments yet",
                            message: "Add the first app running for this client, then attach routing, database, tunnel, and vault details."
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
            Text("This removes the deployment, tunnels, and saved credentials from this device.")
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
    @State private var adminURLOverride = ""
    @State private var systemPort = ""
    @State private var gunicornPort = ""
    @State private var nginxPort = ""
    @State private var dbName = ""
    @State private var dbPort = ""
    @State private var dbPassword = ""
    @State private var username = ""
    @State private var systemAccessPassword = ""
    @State private var adminAccessPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("App Name", text: $appName)
                        .textInputAutocapitalization(.words)

                    Toggle("Online System", isOn: $isOnline)

                    TextField("Admin URL Override", text: $adminURLOverride)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    TextField("System Port (e.g., 8000)", text: $systemPort)
                        .keyboardType(.numberPad)
                }

                Section("Internal Routing") {
                    TextField("Gunicorn Port", text: $gunicornPort)
                        .keyboardType(.numberPad)

                    TextField("Nginx Port", text: $nginxPort)
                        .keyboardType(.numberPad)
                }

                Section("Database Config") {
                    TextField("Database Name", text: $dbName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Database Port", text: $dbPort)
                        .keyboardType(.numberPad)

                    SecureField("Database Password", text: $dbPassword)
                        .textContentType(.password)
                }

                Section("System Access") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $systemAccessPassword)
                        .textContentType(.password)
                }

                Section("Admin Access") {
                    SecureField("Admin Password", text: $adminAccessPassword)
                        .textContentType(.password)
                }
            }
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
                    .disabled(trimmedAppName.isEmpty)
                }
            }
        }
    }

    private func saveDeployment() {
        let trimmedURL = adminURLOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDbName = dbName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let deployment = Deployment(
            client: client,
            appName: trimmedAppName,
            dateDeployed: Date(),
            isOnline: isOnline,
            adminURLOverride: trimmedURL.isEmpty ? nil : trimmedURL,
            systemPort: intValue(from: systemPort),
            gunicornPort: intValue(from: gunicornPort),
            nginxPort: intValue(from: nginxPort),
            dbName: trimmedDbName.isEmpty ? nil : trimmedDbName,
            dbPort: intValue(from: dbPort),
            username: trimmedUsername.isEmpty ? nil : trimmedUsername
        )

        client.deployments.append(deployment)
        modelContext.insert(deployment)
        savePassword(dbPassword, keySuffix: "dbPassword", deployment: deployment)
        savePassword(systemAccessPassword, keySuffix: "systemAccessPassword", deployment: deployment)
        savePassword(adminAccessPassword, keySuffix: "adminAccessPassword", deployment: deployment)
        dismiss()
    }

    private var trimmedAppName: String {
        appName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func intValue(from text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func savePassword(_ password: String, keySuffix: String, deployment: Deployment) {
        guard !password.isEmpty else {
            return
        }

        _ = KeychainManager.save(key: "\(deployment.id)-\(keySuffix)", value: password)
    }
}

struct DeploymentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Bindable var deployment: Deployment
    @State private var showingAddOptionSheet = false

    var body: some View {
        ConduitBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: deploymentDisplayName) {
                        showingAddOptionSheet = true
                    }

                    HStack(spacing: 8) {
                        StatusDot(isOnline: deployment.isOnline)
                        Text(deployment.isOnline ? "System Online" : "System Offline")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ConduitTheme.secondary)
                    }
                    .padding(.top, -8)

                    GlassCard {
                        VStack(spacing: 0) {
                            EditableRow(title: "App Name") {
                                darkTextField("Not Set", text: appNameBinding)
                                    .textInputAutocapitalization(.words)
                            }

                            DividerLine()

                            Toggle("System Online", isOn: $deployment.isOnline)
                                .tint(ConduitTheme.online)
                                .foregroundStyle(ConduitTheme.primary)
                                .padding(.vertical, 8)

                            DividerLine()

                            EditableRow(title: "Admin URL") {
                                darkTextField("None", text: adminURLOverrideBinding)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                            }

                            if let adminURL {
                                DividerLine()

                                Button {
                                    openURL(adminURL)
                                } label: {
                                    Label("Open Admin URL", systemImage: "safari")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(ConduitTheme.accent)
                            }

                            DividerLine()

                            EditableRow(title: "Local System Port") {
                                darkTextField("Not Set", text: systemPortBinding)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }

                    editableSection("Internal Routing") {
                        EditableRow(title: "Gunicorn") {
                            darkTextField("Not Set", text: optionalIntBinding(\.gunicornPort))
                                .keyboardType(.numberPad)
                        }

                        DividerLine()

                        EditableRow(title: "Nginx") {
                            darkTextField("Not Set", text: optionalIntBinding(\.nginxPort))
                                .keyboardType(.numberPad)
                        }
                    }

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
                    }

                    editableSection("System Access") {
                        EditableRow(title: "Username") {
                            darkTextField("Not Set", text: optionalStringBinding(\.username))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }

                    customSettingsSections

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Secure Vault")

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SecureCredentialView(
                                    deployment: deployment,
                                    title: "Admin Password",
                                    keySuffix: "adminAccessPassword",
                                    legacyKeySuffix: "djangoAdminPassword"
                                )
                                SecureCredentialView(deployment: deployment, title: "Database Password", keySuffix: "dbPassword")
                                SecureCredentialView(deployment: deployment, title: "System Access", keySuffix: "systemAccessPassword")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Cloudflare Tunnels")

                        GlassCard {
                            if deployment.tunnels.isEmpty {
                                Text("No tunnels configured")
                                    .foregroundStyle(ConduitTheme.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(deployment.tunnels.enumerated()), id: \.element.id) { index, tunnel in
                                        @Bindable var editableTunnel = tunnel

                                        HStack(spacing: 12) {
                                            TextField("Tunnel Name", text: $editableTunnel.name)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(ConduitTheme.primary)
                                                .textInputAutocapitalization(.never)
                                                .autocorrectionDisabled()

                                            TextField("Port", text: tunnelPortBinding(for: editableTunnel))
                                                .keyboardType(.numberPad)
                                                .multilineTextAlignment(.trailing)
                                                .foregroundStyle(ConduitTheme.secondary)
                                                .fontWeight(.semibold)
                                                .frame(width: 72)

                                            Button(role: .destructive) {
                                                deleteTunnel(tunnel)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(ConduitTheme.offline)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 9)
                                        .swipeActions {
                                            Button("Delete", role: .destructive) {
                                                deleteTunnel(tunnel)
                                            }
                                        }

                                        if index < deployment.tunnels.count - 1 {
                                            DividerLine()
                                        }
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
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddOptionSheet) {
            AddDeploymentOptionView(deployment: deployment)
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

    private var adminURLOverrideBinding: Binding<String> {
        optionalStringBinding(\.adminURLOverride)
    }

    private var adminURL: URL? {
        let rawValue = deployment.adminURLOverride?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

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

    private var customSettingsSections: some View {
        Group {
            ForEach(sortedCustomSections) { section in
                @Bindable var editableSection = section

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Custom Section", text: $editableSection.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ConduitTheme.secondary)
                            .tint(ConduitTheme.accent)

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
                TextField("Label", text: $editableField.label)
                    .foregroundStyle(ConduitTheme.primary)
                    .fontWeight(.semibold)
                    .tint(ConduitTheme.accent)

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
                customValueField("Port", text: customFieldValueBinding(for: field))
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
            let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            deployment[keyPath: keyPath] = trimmedValue.isEmpty ? nil : Int(trimmedValue)
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

    private func tunnelPortBinding(for tunnel: Tunnel) -> Binding<String> {
        Binding {
            String(tunnel.port)
        } set: { newValue in
            let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

            if let port = Int(trimmedValue) {
                tunnel.port = port
            }
        }
    }

    private func deleteTunnel(_ tunnel: Tunnel) {
        deployment.tunnels.removeAll { $0.id == tunnel.id }
        modelContext.delete(tunnel)
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
    case cloudflareTunnel = "Cloudflare Tunnel"
    case internalRouting = "Internal Routing"
    case databaseConfig = "Database Config"
    case systemAccess = "System Access"
    case adminAccess = "Admin Access"
    case customSetting = "Custom Setting"

    var id: Self { self }
}

struct AddDeploymentOptionView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var deployment: Deployment
    @State private var selectedOption: DeploymentAddOption = .cloudflareTunnel
    @State private var tunnelName = ""
    @State private var tunnelPort = ""
    @State private var gunicornPort = ""
    @State private var nginxPort = ""
    @State private var dbName = ""
    @State private var dbPort = ""
    @State private var dbPassword = ""
    @State private var username = ""
    @State private var systemAccessPassword = ""
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
                        ForEach(DeploymentAddOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                switch selectedOption {
                case .cloudflareTunnel:
                    Section("Cloudflare Tunnel") {
                        TextField("Tunnel Name", text: $tunnelName, prompt: Text("staging-auth-tunnel"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Port", text: $tunnelPort, prompt: Text("8000"))
                            .keyboardType(.numberPad)
                    }

                case .internalRouting:
                    Section("Internal Routing") {
                        TextField("Gunicorn Port", text: $gunicornPort)
                            .keyboardType(.numberPad)

                        TextField("Nginx Port", text: $nginxPort)
                            .keyboardType(.numberPad)
                    }

                case .databaseConfig:
                    Section("Database Config") {
                        TextField("Database Name", text: $dbName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Database Port", text: $dbPort)
                            .keyboardType(.numberPad)

                        SecureField("Database Password", text: $dbPassword)
                            .textContentType(.password)
                    }

                case .systemAccess:
                    Section("System Access") {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $systemAccessPassword)
                            .textContentType(.password)
                    }

                case .adminAccess:
                    Section("Admin Access") {
                        SecureField("Admin Password", text: $adminAccessPassword)
                            .textContentType(.password)
                    }

                case .customSetting:
                    Section("Custom Setting") {
                        TextField("Section Name", text: $customSectionTitle, prompt: Text("Hosting Panel"))
                            .textInputAutocapitalization(.words)

                        TextField("Field Label", text: $customFieldLabel, prompt: Text("Dashboard URL"))
                            .textInputAutocapitalization(.words)

                        Picker("Field Type", selection: $customFieldType) {
                            ForEach(CustomSettingFieldType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }

                        switch customFieldType {
                        case .password:
                            SecureField("Password", text: $customFieldPassword)
                                .textContentType(.password)

                        case .url:
                            TextField("URL", text: $customFieldValue, prompt: Text("https://panel.example.com"))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                        case .port:
                            TextField("Port", text: $customFieldValue, prompt: Text("8080"))
                                .keyboardType(.numberPad)

                        case .text:
                            TextField("Value", text: $customFieldValue)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ConduitTheme.background)
            .navigationTitle("Add Option")
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
                        saveOption()
                    }
                    .disabled(saveDisabled)
                }
            }
        }
    }

    private var saveDisabled: Bool {
        switch selectedOption {
        case .cloudflareTunnel:
            return trimmedTunnelName.isEmpty || intValue(from: tunnelPort) == nil
        case .internalRouting:
            return intValue(from: gunicornPort) == nil && intValue(from: nginxPort) == nil
        case .databaseConfig:
            return trimmedDbName.isEmpty && intValue(from: dbPort) == nil && dbPassword.isEmpty
        case .systemAccess:
            return trimmedUsername.isEmpty && systemAccessPassword.isEmpty
        case .adminAccess:
            return adminAccessPassword.isEmpty
        case .customSetting:
            return trimmedCustomSectionTitle.isEmpty
                || trimmedCustomFieldLabel.isEmpty
                || (customFieldType == .password ? customFieldPassword.isEmpty : false)
        }
    }

    private var trimmedTunnelName: String {
        tunnelName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDbName: String {
        dbName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCustomSectionTitle: String {
        customSectionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCustomFieldLabel: String {
        customFieldLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveOption() {
        switch selectedOption {
        case .cloudflareTunnel:
            guard let port = intValue(from: tunnelPort) else {
                return
            }

            let tunnel = Tunnel(deployment: deployment, name: trimmedTunnelName, port: port)
            deployment.tunnels.append(tunnel)

        case .internalRouting:
            if let port = intValue(from: gunicornPort) {
                deployment.gunicornPort = port
            }

            if let port = intValue(from: nginxPort) {
                deployment.nginxPort = port
            }

        case .databaseConfig:
            if !trimmedDbName.isEmpty {
                deployment.dbName = trimmedDbName
            }

            if let port = intValue(from: dbPort) {
                deployment.dbPort = port
            }

            savePassword(dbPassword, keySuffix: "dbPassword")

        case .systemAccess:
            deployment.username = trimmedUsername.isEmpty ? nil : trimmedUsername
            savePassword(systemAccessPassword, keySuffix: "systemAccessPassword")

        case .adminAccess:
            savePassword(adminAccessPassword, keySuffix: "adminAccessPassword")

        case .customSetting:
            saveCustomSetting()
        }

        dismiss()
    }

    private func intValue(from text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
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
        .modelContainer(for: [Client.self, Deployment.self, Tunnel.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}

#Preview("AddClientView") {
    AddClientView()
        .modelContainer(for: [Client.self, Deployment.self, Tunnel.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}
