//
//  AddDeploymentView.swift
//  Conduit
//

import SwiftUI
import SwiftData

struct AddDeploymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlements

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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDeployment() }
                        .disabled(trimmedAppName.isEmpty
                                  || client.deployments.count >= entitlements.maxDeploymentsPerClient)
                }
            }
        }
    }

    private var trimmedAppName: String {
        appName.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
