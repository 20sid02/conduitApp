//
//  DeploymentDetailView.swift
//  Conduit
//

import SwiftUI
import SwiftData

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
            Button("Cancel", role: .cancel) { routePendingDeletion = nil }
        } message: {
            Text("This removes the saved service name and port from this deployment.")
        }
        .confirmationDialog(
            "Delete database config?",
            isPresented: $showingDeleteDatabaseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Database Config", role: .destructive) { deleteDatabaseConfig() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the database fields and saved database credentials for this deployment.")
        }
        .confirmationDialog(
            "Delete admin access?",
            isPresented: $showingDeleteAdminConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Admin Access", role: .destructive) { deleteAdminAccess() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the admin username and saved admin password for this deployment.")
        }
    }

    // MARK: - Sections

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

    // MARK: - Custom field row

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

                Text(field.fieldType.displayName)
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

            switch field.fieldType {
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

    // MARK: - Helpers

    private var deploymentDisplayName: String {
        let trimmedAppName = deployment.appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedAppName.isEmpty ? "Deployment" : trimmedAppName
    }

    private var deploymentURL: URL? {
        let rawValue = deployment.deploymentURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawValue.isEmpty else { return nil }
        if let url = URL(string: rawValue), url.scheme != nil { return url }
        return URL(string: "https://\(rawValue)")
    }

    private var sortedCustomSections: [CustomSettingSection] {
        deployment.customSections.sorted {
            $0.sortOrder == $1.sortOrder
                ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                : $0.sortOrder < $1.sortOrder
        }
    }

    private var sortedInternalRoutes: [InternalRoute] {
        deployment.internalRoutes.sorted {
            $0.sortOrder == $1.sortOrder
                ? $0.serviceName.localizedCaseInsensitiveCompare($1.serviceName) == .orderedAscending
                : $0.sortOrder < $1.sortOrder
        }
    }

    private func sortedFields(for section: CustomSettingSection) -> [CustomSettingField] {
        section.fields.sorted {
            $0.sortOrder == $1.sortOrder
                ? $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
                : $0.sortOrder < $1.sortOrder
        }
    }

    private func editableSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: title)
            GlassCard {
                VStack(spacing: 0) { content() }
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

    // MARK: - Bindings

    private var systemPortBinding: Binding<String> { optionalIntBinding(\.systemPort) }
    private var appNameBinding: Binding<String> { optionalStringBinding(\.appName) }
    private var deploymentURLBinding: Binding<String> { optionalStringBinding(\.deploymentURL) }

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

    // MARK: - Mutations

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
            .filter { $0.fieldType == .password }
            .forEach { field in _ = KeychainManager.delete(key: field.keychainKey) }
        deployment.customSections.removeAll { $0.id == section.id }
        modelContext.delete(section)
    }

    private func deleteCustomField(_ field: CustomSettingField) {
        if field.fieldType == .password {
            _ = KeychainManager.delete(key: field.keychainKey)
        }
        field.section.fields.removeAll { $0.id == field.id }
        modelContext.delete(field)
    }
}
