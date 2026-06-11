//
//  AddDeploymentOptionView.swift
//  Conduit
//

import SwiftUI
import SwiftData

enum DeploymentAddOption: String, CaseIterable, Identifiable {
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
            .onAppear { normalizeSelectedOption() }
            .onChange(of: availableOptions.map(\.rawValue)) { normalizeSelectedOption() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveOption() }
                        .disabled(saveDisabled)
                }
            }
        }
    }

    // MARK: - Validation

    private var saveDisabled: Bool {
        switch selectedOption {
        case .internalRouting:
            trimmedRouteServiceName.isEmpty || portValue(from: routePort) == nil
        case .databaseConfig:
            trimmedDbName.isEmpty && portValue(from: dbPort) == nil && dbHost.isEmpty && dbPassword.isEmpty
        case .adminAccess:
            trimmedAdminUsername.isEmpty && adminAccessPassword.isEmpty
        case .customSetting:
            trimmedCustomSectionTitle.isEmpty
                || trimmedCustomFieldLabel.isEmpty
                || (customFieldType == .password ? customFieldPassword.isEmpty : false)
        }
    }

    private var availableOptions: [DeploymentAddOption] {
        DeploymentAddOption.allCases.filter { option in
            switch option {
            case .databaseConfig: !deployment.hasDatabaseConfig
            case .adminAccess: !deployment.hasAdminAccess
            case .internalRouting, .customSetting: true
            }
        }
    }

    private var trimmedRouteServiceName: String { routeServiceName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDbName: String { dbName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedAdminUsername: String { adminUsername.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCustomSectionTitle: String { customSectionTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCustomFieldLabel: String { customFieldLabel.trimmingCharacters(in: .whitespacesAndNewlines) }

    // MARK: - Save

    private func normalizeSelectedOption() {
        guard !availableOptions.contains(selectedOption), let firstOption = availableOptions.first else { return }
        selectedOption = firstOption
    }

    private func saveOption() {
        switch selectedOption {
        case .internalRouting:
            guard let port = portValue(from: routePort) else { return }
            let route = InternalRoute(
                deployment: deployment,
                serviceName: trimmedRouteServiceName,
                port: port,
                sortOrder: deployment.internalRoutes?.count ?? 0
            )
            deployment.internalRoutes.append(route)
            modelContext.insert(route)

        case .databaseConfig:
            if !trimmedDbName.isEmpty { deployment.dbName = trimmedDbName }
            if let port = portValue(from: dbPort) { deployment.dbPort = port }
            savePassword(dbHost, keySuffix: "dbHost")
            savePassword(dbPassword, keySuffix: "dbPassword")

        case .adminAccess:
            if !trimmedAdminUsername.isEmpty { deployment.adminUsername = trimmedAdminUsername }
            savePassword(adminAccessPassword, keySuffix: "adminAccessPassword")

        case .customSetting:
            saveCustomSetting()
        }

        dismiss()
    }

    private func savePassword(_ password: String, keySuffix: String) {
        guard !password.isEmpty else { return }
        _ = KeychainManager.save(key: "\(deployment.id)-\(keySuffix)", value: password)
    }

    private func saveCustomSetting() {
        let section = existingCustomSection() ?? {
            let newSection = CustomSettingSection(
                deployment: deployment,
                title: trimmedCustomSectionTitle,
                sortOrder: deployment.customSections?.count ?? 0
            )
            deployment.customSections.append(newSection)
            return newSection
        }()

        let field = CustomSettingField(
            section: section,
            label: trimmedCustomFieldLabel,
            value: customFieldType == .password ? nil : normalizedCustomFieldValue(),
            type: customFieldType,
            sortOrder: section.fields?.count ?? 0
        )
        section.fields.append(field)

        if customFieldType == .password {
            _ = KeychainManager.save(key: field.keychainKey, value: customFieldPassword)
        }
    }

    private func existingCustomSection() -> CustomSettingSection? {
        (deployment.customSections ?? []).first {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(trimmedCustomSectionTitle) == .orderedSame
        }
    }

    private func normalizedCustomFieldValue() -> String? {
        let trimmedValue = customFieldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
