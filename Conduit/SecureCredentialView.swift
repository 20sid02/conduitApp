//
//  SecureCredentialView.swift
//  Conduit
//

import SwiftUI

struct SecureCredentialView: View {
    let deployment: Deployment
    let title: String
    let keySuffix: String

    @State private var isUnlocked = false
    @State private var password = ""

    private let authManager = BiometricAuthManager()

    init(deployment: Deployment, title: String = "Database Password", keySuffix: String = "dbPassword") {
        self.deployment = deployment
        self.title = title
        self.keySuffix = keySuffix
    }

    var body: some View {
        Group {
            if isUnlocked {
                VStack(alignment: .leading, spacing: 16) {
                    SecureField(title, text: $password)
                        .textContentType(.password)

                    Button("Save") {
                        savePassword()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button {
                    unlockCredentials()
                } label: {
                    Label("Unlock \(title)", systemImage: "lock")
                }
            }
        }
    }

    private var keychainKey: String {
        "\(deployment.id)-\(keySuffix)"
    }

    private func unlockCredentials() {
        authManager.authenticateUser(reason: "Unlock saved deployment credentials.") { success, error in
            if let error {
                print("Credential unlock failed: \(error.localizedDescription)")
            }

            guard success else {
                return
            }

            password = KeychainManager.read(key: keychainKey) ?? ""
            isUnlocked = true
        }
    }

    private func savePassword() {
        _ = KeychainManager.save(key: keychainKey, value: password)
        password = ""
        isUnlocked = false
    }
}
