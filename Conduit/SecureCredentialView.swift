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
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))

                    HStack(spacing: 10) {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .foregroundStyle(.white)
                            .tint(.blue)

                        Image(systemName: "eye")
                            .foregroundStyle(.white.opacity(0.38))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button("Save") {
                        savePassword()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                Button {
                    unlockCredentials()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("Locked")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.52))
                        }

                        Spacer()

                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.blue.gradient, in: Circle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
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
