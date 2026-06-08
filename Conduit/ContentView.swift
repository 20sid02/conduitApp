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
    @AppStorage("hasSeededFreeSampleData") private var hasSeededFreeSampleData = false
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var clientPendingDeletion: Client?
    @State private var showingDeleteClientConfirmation = false

    var body: some View {
        NavigationStack {
            ConduitBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScreenHeader(
                            title: "Client",
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
            .poweredByArksoftFooter()
            .onAppear {
                seedSampleDataIfNeeded()
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

    private func seedSampleDataIfNeeded() {
        guard !hasSeededFreeSampleData, clients.isEmpty else {
            return
        }

        let acme = Client(name: "Acme Studio", createdAt: Date().addingTimeInterval(-86_400 * 3))
        let northstar = Client(name: "Northstar Dental", createdAt: Date().addingTimeInterval(-86_400))

        modelContext.insert(acme)
        modelContext.insert(northstar)

        let portal = Deployment(
            client: acme,
            appName: "Client Portal",
            dateDeployed: Date().addingTimeInterval(-7_200),
            isOnline: true,
            adminURLOverride: "portal.acme.test",
            systemPort: 8080,
            dbName: "acme_portal",
            dbPort: 5432,
            adminUsername: "admin@acme.test",
            username: "deploy"
        )
        let api = Deployment(
            client: acme,
            appName: "Billing API",
            dateDeployed: Date().addingTimeInterval(-3_600),
            isOnline: false,
            adminURLOverride: "billing.acme.test",
            systemPort: 9000,
            dbName: "billing",
            dbPort: 5432,
            adminUsername: "billing-admin",
            username: "ubuntu"
        )
        let booking = Deployment(
            client: northstar,
            appName: "Booking Dashboard",
            dateDeployed: Date().addingTimeInterval(-1_800),
            isOnline: true,
            adminURLOverride: "northstar.local/dashboard",
            systemPort: 3000,
            dbName: "northstar_booking",
            dbPort: 3306,
            adminUsername: "ops",
            username: "deploy"
        )

        [portal, api].forEach { acme.deployments.append($0) }
        northstar.deployments.append(booking)
        [portal, api, booking].forEach(modelContext.insert)

        addRoute("Web app", 8080, to: portal, order: 0)
        addRoute("Worker", 8787, to: portal, order: 1)
        addRoute("API", 9000, to: api, order: 0)
        addRoute("Frontend", 3000, to: booking, order: 0)
        addRoute("Search", 7700, to: booking, order: 1)

        addCustomSetting(sectionTitle: "Hosting Panel", label: "Panel URL", value: "https://panel.acme.test", type: .url, to: portal)
        addCustomSetting(sectionTitle: "Release Notes", label: "Branch", value: "main", type: .text, to: portal)

        saveSampleCredentials(for: portal)
        saveSampleCredentials(for: api)
        saveSampleCredentials(for: booking)

        hasSeededFreeSampleData = true
    }

    private func addRoute(_ serviceName: String, _ port: Int, to deployment: Deployment, order: Int) {
        let route = InternalRoute(deployment: deployment, serviceName: serviceName, port: port, sortOrder: order)
        deployment.internalRoutes.append(route)
        modelContext.insert(route)
    }

    private func addCustomSetting(sectionTitle: String, label: String, value: String, type: CustomSettingFieldType, to deployment: Deployment) {
        let section = CustomSettingSection(deployment: deployment, title: sectionTitle, sortOrder: deployment.customSections.count)
        let field = CustomSettingField(section: section, label: label, value: value, type: type, sortOrder: 0)
        section.fields.append(field)
        deployment.customSections.append(section)
        modelContext.insert(section)
        modelContext.insert(field)
    }

    private func saveSampleCredentials(for deployment: Deployment) {
        _ = KeychainManager.save(key: "\(deployment.id)-dbHost", value: "sample-db.internal")
        _ = KeychainManager.save(key: "\(deployment.id)-dbPassword", value: "sample-db-password")
        _ = KeychainManager.save(key: "\(deployment.id)-systemAccessPassword", value: "sample-system-password")
        _ = KeychainManager.save(key: "\(deployment.id)-adminAccessPassword", value: "sample-admin-password")
    }
}

private struct PoweredByArksoftFooter: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Powered by")
                .foregroundStyle(ConduitTheme.muted)

            Link("ArkSoft", destination: URL(string: "https://arksoft.xyz")!)
                .foregroundStyle(ConduitTheme.accent)
        }
        .font(.caption.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(ConduitTheme.backgroundBottom.opacity(0.96))
    }
}

private extension View {
    func poweredByArksoftFooter() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            PoweredByArksoftFooter()
        }
    }
}

private enum FreeTierLimits {
    static let maxClients = 4
    static let maxDeploymentsPerClient = 3
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
        .poweredByArksoftFooter()
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
    @State private var routeOneName = ""
    @State private var routeOnePort = ""
    @State private var routeTwoName = ""
    @State private var routeTwoPort = ""
    @State private var routeThreeName = ""
    @State private var routeThreePort = ""
    @State private var dbName = ""
    @State private var dbPort = ""
    @State private var dbHost = ""
    @State private var dbPassword = ""
    @State private var username = ""
    @State private var systemAccessPassword = ""
    @State private var adminUsername = ""
    @State private var adminAccessPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("App Name", text: $appName)
                        .textInputAutocapitalization(.words)

                    Toggle("Online System", isOn: $isOnline)

                    TextField("Deployment URL", text: $adminURLOverride)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    TextField("System Port (e.g., 8000)", text: $systemPort)
                        .keyboardType(.numberPad)
                }

                Section("Internal Routing") {
                    routeInputRow(serviceName: $routeOneName, port: $routeOnePort)
                    routeInputRow(serviceName: $routeTwoName, port: $routeTwoPort)
                    routeInputRow(serviceName: $routeThreeName, port: $routeThreePort)
                }

                Section("Database Config") {
                    TextField("Database Name", text: $dbName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Database Port", text: $dbPort)
                        .keyboardType(.numberPad)

                    SecureField("Database Host / Token", text: $dbHost)
                        .textContentType(.password)

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
                    TextField("Admin Username", text: $adminUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

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
                    .disabled(trimmedAppName.isEmpty || client.deployments.count >= FreeTierLimits.maxDeploymentsPerClient)
                }
            }
        }
    }

    private func saveDeployment() {
        let trimmedURL = adminURLOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDbName = dbName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAdminUsername = adminUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let deployment = Deployment(
            client: client,
            appName: trimmedAppName,
            dateDeployed: Date(),
            isOnline: isOnline,
            adminURLOverride: trimmedURL.isEmpty ? nil : trimmedURL,
            systemPort: intValue(from: systemPort),
            dbName: trimmedDbName.isEmpty ? nil : trimmedDbName,
            dbPort: intValue(from: dbPort),
            adminUsername: trimmedAdminUsername.isEmpty ? nil : trimmedAdminUsername,
            username: trimmedUsername.isEmpty ? nil : trimmedUsername
        )

        client.deployments.append(deployment)
        modelContext.insert(deployment)
        saveRoute(serviceName: routeOneName, port: routeOnePort, deployment: deployment, sortOrder: 0)
        saveRoute(serviceName: routeTwoName, port: routeTwoPort, deployment: deployment, sortOrder: 1)
        saveRoute(serviceName: routeThreeName, port: routeThreePort, deployment: deployment, sortOrder: 2)
        savePassword(dbHost, keySuffix: "dbHost", deployment: deployment)
        savePassword(dbPassword, keySuffix: "dbPassword", deployment: deployment)
        savePassword(systemAccessPassword, keySuffix: "systemAccessPassword", deployment: deployment)
        savePassword(adminAccessPassword, keySuffix: "adminAccessPassword", deployment: deployment)
        dismiss()
    }

    private var trimmedAppName: String {
        appName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func routeInputRow(serviceName: Binding<String>, port: Binding<String>) -> some View {
        HStack(spacing: 12) {
            TextField("Service Name", text: serviceName, prompt: Text("Web app"))
                .textInputAutocapitalization(.words)

            TextField("Port", text: port, prompt: Text("8000"))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 92)
        }
    }

    private func intValue(from text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func saveRoute(serviceName: String, port: String, deployment: Deployment, sortOrder: Int) {
        let trimmedServiceName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedServiceName.isEmpty, let port = intValue(from: port) else {
            return
        }

        let route = InternalRoute(
            deployment: deployment,
            serviceName: trimmedServiceName,
            port: port,
            sortOrder: sortOrder
        )
        deployment.internalRoutes.append(route)
        modelContext.insert(route)
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

                            EditableRow(title: "Deployment URL") {
                                darkTextField("None", text: adminURLOverrideBinding)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                            }

                            if let deploymentURL {
                                DividerLine()

                                Button {
                                    openURL(deploymentURL)
                                } label: {
                                    Label("Open Deployment URL", systemImage: "safari")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(ConduitTheme.accent)
                            }

                            DividerLine()

                            SecureCredentialView(
                                deployment: deployment,
                                title: "Admin Password",
                                keySuffix: "adminAccessPassword",
                                legacyKeySuffix: "djangoAdminPassword"
                            )

                            DividerLine()

                            EditableRow(title: "Admin Username") {
                                darkTextField("Not Set", text: optionalStringBinding(\.adminUsername))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }

                            DividerLine()

                            EditableRow(title: "Local System Port") {
                                darkTextField("Not Set", text: systemPortBinding)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }

                    internalRoutingSection

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

                    editableSection("System Access") {
                        EditableRow(title: "Username") {
                            darkTextField("Not Set", text: optionalStringBinding(\.username))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        DividerLine()

                        SecureCredentialView(deployment: deployment, title: "System Password", keySuffix: "systemAccessPassword")
                    }

                    customSettingsSections
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
        .poweredByArksoftFooter()
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

    private var deploymentURL: URL? {
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

    private var sortedInternalRoutes: [InternalRoute] {
        deployment.internalRoutes.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.serviceName.localizedCaseInsensitiveCompare($1.serviceName) == .orderedAscending
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    private var internalRoutingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Internal Routing")

            GlassCard {
                if deployment.internalRoutes.isEmpty {
                    Text("No internal services configured")
                        .foregroundStyle(ConduitTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedInternalRoutes.enumerated()), id: \.element.id) { index, route in
                            @Bindable var editableRoute = route

                            HStack(spacing: 12) {
                                TextField("Service Name", text: $editableRoute.serviceName)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ConduitTheme.primary)
                                    .textInputAutocapitalization(.words)

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

    private func internalRoutePortBinding(for route: InternalRoute) -> Binding<String> {
        Binding {
            String(route.port)
        } set: { newValue in
            let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

            if let port = Int(trimmedValue) {
                route.port = port
            }
        }
    }

    private func deleteTunnel(_ tunnel: Tunnel) {
        deployment.tunnels.removeAll { $0.id == tunnel.id }
        modelContext.delete(tunnel)
    }

    private func deleteInternalRoute(_ route: InternalRoute) {
        deployment.internalRoutes.removeAll { $0.id == route.id }
        modelContext.delete(route)
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
    case internalRouting = "Internal Routing"
    case databaseConfig = "Database Config"
    case systemAccess = "System Access"
    case adminAccess = "Admin Access"
    case customSetting = "Custom Setting"

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
    @State private var username = ""
    @State private var systemAccessPassword = ""
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
                    Section("Internal Routing") {
                        TextField("Service Name", text: $routeServiceName, prompt: Text("Web app"))
                            .textInputAutocapitalization(.words)

                        TextField("Port", text: $routePort, prompt: Text("8000"))
                            .keyboardType(.numberPad)
                    }

                case .databaseConfig:
                    Section("Database Config") {
                        TextField("Database Name", text: $dbName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Database Port", text: $dbPort)
                            .keyboardType(.numberPad)

                        SecureField("Database Host / Token", text: $dbHost)
                            .textContentType(.password)

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
                        TextField("Admin Username", text: $adminUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Admin Password", text: $adminAccessPassword)
                            .textContentType(.password)
                    }

                case .customSetting:
                    Section("Custom Setting") {
                        TextField("Settings Group", text: $customSectionTitle, prompt: Text("Hosting Panel"))
                            .textInputAutocapitalization(.words)

                        TextField("Setting Name", text: $customFieldLabel, prompt: Text("Dashboard URL"))
                            .textInputAutocapitalization(.words)

                        Picker("Setting Type", selection: $customFieldType) {
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
            return trimmedRouteServiceName.isEmpty || intValue(from: routePort) == nil
        case .databaseConfig:
            return trimmedDbName.isEmpty && intValue(from: dbPort) == nil && dbHost.isEmpty && dbPassword.isEmpty
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

    private var availableOptions: [DeploymentAddOption] {
        DeploymentAddOption.allCases.filter { option in
            switch option {
            case .databaseConfig:
                !deployment.hasDatabaseConfig
            case .systemAccess:
                !deployment.hasSystemAccess
            case .internalRouting, .adminAccess, .customSetting:
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
        case .internalRouting:
            guard let port = intValue(from: routePort) else {
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

            if let port = intValue(from: dbPort) {
                deployment.dbPort = port
            }

            savePassword(dbHost, keySuffix: "dbHost")
            savePassword(dbPassword, keySuffix: "dbPassword")

        case .systemAccess:
            deployment.username = trimmedUsername.isEmpty ? nil : trimmedUsername
            savePassword(systemAccessPassword, keySuffix: "systemAccessPassword")

        case .adminAccess:
            let trimmedAdminUsername = adminUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedAdminUsername.isEmpty {
                deployment.adminUsername = trimmedAdminUsername
            }

            savePassword(adminAccessPassword, keySuffix: "adminAccessPassword")

        case .customSetting:
            saveCustomSetting()
        }

        dismiss()
    }

    private func intValue(from text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
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
        .modelContainer(for: [Client.self, Deployment.self, InternalRoute.self, Tunnel.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}

#Preview("AddClientView") {
    AddClientView()
        .modelContainer(for: [Client.self, Deployment.self, InternalRoute.self, Tunnel.self, CustomSettingSection.self, CustomSettingField.self], inMemory: true)
}
