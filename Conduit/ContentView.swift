//
//  ContentView.swift
//  Conduit
//
//  Created by Siddharth Mahajan on 07/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Client.createdAt, order: .reverse) private var clients: [Client]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List(clients) { client in
                NavigationLink {
                    ClientDetailView(client: client)
                } label: {
                    ClientRow(client: client)
                }
            }
            .navigationTitle("Conduit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Client")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddClientView()
            }
        }
    }
}

private struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.headline)

                Text(client.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !client.deployments.isEmpty {
                Text("\(client.deployments.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 4)
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
            .navigationTitle("Add Client")
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
    @Bindable var client: Client
    @State private var showingAddDeploymentSheet = false

    var body: some View {
        List {
            ForEach(client.deployments) { deployment in
                NavigationLink {
                    DeploymentDetailView(deployment: deployment)
                } label: {
                    DeploymentRow(deployment: deployment)
                }
            }
        }
        .navigationTitle(client.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddDeploymentSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Deployment")
            }
        }
        .sheet(isPresented: $showingAddDeploymentSheet) {
            AddDeploymentView(client: client)
        }
    }
}

private struct DeploymentRow: View {
    let deployment: Deployment

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundStyle(deployment.isOnline ? .green : .red)

            Text(deploymentDisplayName)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var deploymentDisplayName: String {
        let trimmedAppName = deployment.appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedAppName.isEmpty ? "Unnamed App" : trimmedAppName
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
    @State private var djangoAdminPassword = ""

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

                Section("Django Admin") {
                    SecureField("Superuser Password", text: $djangoAdminPassword)
                        .textContentType(.password)
                }
            }
            .navigationTitle("Add Deployment")
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
            appName: appName.trimmingCharacters(in: .whitespacesAndNewlines),
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
        savePassword(djangoAdminPassword, keySuffix: "djangoAdminPassword", deployment: deployment)
        dismiss()
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

    @Bindable var deployment: Deployment
    @State private var showingAddOptionSheet = false

    var body: some View {
        Form {
            Section {
                LabeledContent("App Name") {
                    TextField("Not Set", text: appNameBinding)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .textInputAutocapitalization(.words)
                }

                Toggle("System Online", isOn: $deployment.isOnline)

                LabeledContent("Admin URL Override") {
                    TextField("None", text: adminURLOverrideBinding)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }

                LabeledContent("Local System Port") {
                    TextField("Not Set", text: systemPortBinding)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .keyboardType(.numberPad)
                }
            }

            Section("Internal Routing") {
                LabeledContent("Gunicorn Port") {
                    TextField("Not Set", text: optionalIntBinding(\.gunicornPort))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .keyboardType(.numberPad)
                }

                LabeledContent("Nginx Port") {
                    TextField("Not Set", text: optionalIntBinding(\.nginxPort))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .keyboardType(.numberPad)
                }
            }

            Section("Database Config") {
                LabeledContent("Database Name") {
                    TextField("Not Set", text: optionalStringBinding(\.dbName))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                LabeledContent("Database Port") {
                    TextField("Not Set", text: optionalIntBinding(\.dbPort))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .keyboardType(.numberPad)
                }

                SecureCredentialView(deployment: deployment, title: "Database Password", keySuffix: "dbPassword")
            }

            Section("System Access") {
                LabeledContent("Username") {
                    TextField("Not Set", text: optionalStringBinding(\.username))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                SecureCredentialView(deployment: deployment, title: "Password", keySuffix: "systemAccessPassword")
            }

            Section("Django Admin") {
                SecureCredentialView(deployment: deployment, title: "Superuser Password", keySuffix: "djangoAdminPassword")
            }

            Section("Cloudflare Tunnels") {
                ForEach(deployment.tunnels) { tunnel in
                    @Bindable var editableTunnel = tunnel

                    HStack {
                        TextField("Tunnel Name", text: $editableTunnel.name)
                            .fontWeight(.semibold)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Port", text: tunnelPortBinding(for: editableTunnel))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            deleteTunnel(tunnel)
                        }
                    }
                }
            }
        }
        .navigationTitle("Deployment")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddOptionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Option")
            }
        }
        .sheet(isPresented: $showingAddOptionSheet) {
            AddDeploymentOptionView(deployment: deployment)
        }
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
}

private enum DeploymentAddOption: String, CaseIterable, Identifiable {
    case cloudflareTunnel = "Cloudflare Tunnel"
    case internalRouting = "Internal Routing"
    case databaseConfig = "Database Config"
    case systemAccess = "System Access"
    case djangoAdmin = "Django Admin"

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
    @State private var djangoAdminPassword = ""

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

                case .djangoAdmin:
                    Section("Django Admin") {
                        SecureField("Superuser Password", text: $djangoAdminPassword)
                            .textContentType(.password)
                    }
                }
            }
            .navigationTitle("Add Option")
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
        case .djangoAdmin:
            return djangoAdminPassword.isEmpty
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

        case .djangoAdmin:
            savePassword(djangoAdminPassword, keySuffix: "djangoAdminPassword")
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
}

#Preview("ContentView") {
    ContentView()
        .modelContainer(for: [Client.self, Deployment.self, Tunnel.self], inMemory: true)
}

#Preview("AddClientView") {
    AddClientView()
        .modelContainer(for: [Client.self, Deployment.self, Tunnel.self], inMemory: true)
}
