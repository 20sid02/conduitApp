//
//  VaultSectionView.swift
//  Conduit
//

import SwiftUI

struct VaultSectionView: View {
    let client: Client

    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked = false
    @State private var entries: [VaultEntry] = []
    @State private var secrets: [UUID: String] = [:]
    @State private var revealedIds: Set<UUID> = []
    @State private var lockedEntryCount = 0

    @State private var showingAddEntry = false
    @State private var entryPendingDeletion: VaultEntry?
    @State private var showingDeleteConfirmation = false
    @State private var showingUpgrade = false

    private let authManager = BiometricAuthManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader

            GlassCard {
                if isUnlocked {
                    unlockedContent
                } else {
                    lockedPlaceholder
                }
            }
        }
        .onAppear {
            lockedEntryCount = VaultManager.entries(for: client.keychainVaultId).count
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background { lockVault() }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddVaultEntryView(vaultId: client.keychainVaultId) { newEntry in
                entries.append(newEntry)
                secrets[newEntry.id] = VaultManager.readSecret(for: newEntry, vaultId: client.keychainVaultId) ?? ""
                lockedEntryCount = entries.count
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            ProUpgradeView()
        }
        .alert("Delete this vault entry?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Entry", role: .destructive) {
                if let entry = entryPendingDeletion { performDelete(entry) }
            }
            Button("Cancel", role: .cancel) { entryPendingDeletion = nil }
        } message: {
            Text("This permanently removes the label and its stored secret from the Keychain.")
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            SectionTitle(title: "API Key Vault")
            Spacer()

            if isUnlocked {
                Button {
                    showingAddEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Add vault entry")

                Button {
                    lockVault()
                } label: {
                    Image(systemName: "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.muted)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Lock vault")
            }
        }
    }

    // MARK: - Locked state

    private var lockedPlaceholder: some View {
        Button {
            guard entitlements.isEnabled(.apiKeyVault) else {
                showingUpgrade = true
                return
            }
            unlockVault()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "key.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ConduitTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(ConduitTheme.accent.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(entitlements.isEnabled(.apiKeyVault) ? "Vault Locked" : "API Key Vault")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ConduitTheme.primary)

                    Group {
                        if !entitlements.isEnabled(.apiKeyVault) {
                            Text("Requires Conduit Pro")
                        } else if lockedEntryCount == 0 {
                            Text("Authenticate to add your first entry")
                        } else {
                            Text("\(lockedEntryCount) stored \(lockedEntryCount == 1 ? "entry" : "entries") — authenticate to unlock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(ConduitTheme.muted)
                }

                Spacer()

                Image(systemName: entitlements.isEnabled(.apiKeyVault) ? "faceid" : "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ConduitTheme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Unlocked state

    @ViewBuilder
    private var unlockedContent: some View {
        if entries.isEmpty {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ConduitTheme.muted)
                Text("No entries — tap + to store API keys, tokens, or secrets.")
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    vaultEntryRow(entry)
                    if index < entries.count - 1 {
                        DividerLine()
                    }
                }
            }
        }
    }

    private func vaultEntryRow(_ entry: VaultEntry) -> some View {
        let isRevealed = revealedIds.contains(entry.id)
        let secret = secrets[entry.id] ?? ""

        return VStack(alignment: .leading, spacing: 7) {
            Text(entry.label.isEmpty ? "Unlabeled Key" : entry.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ConduitTheme.primary)

            HStack(spacing: 10) {
                Group {
                    if isRevealed {
                        Text(secret.isEmpty ? "(empty)" : secret)
                            .textSelection(.enabled)
                            .lineLimit(4)
                    } else {
                        Text(secret.isEmpty ? "(empty)" : "••••••••••••")
                            .foregroundStyle(secret.isEmpty ? ConduitTheme.muted : ConduitTheme.secondary)
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(ConduitTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    if isRevealed {
                        revealedIds.remove(entry.id)
                    } else {
                        revealedIds.insert(entry.id)
                    }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ConduitTheme.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRevealed ? "Hide value" : "Reveal value")

                Button(role: .destructive) {
                    entryPendingDeletion = entry
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ConduitTheme.offline)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete vault entry")
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Auth & mutations

    private func unlockVault() {
        authManager.authenticateUser(reason: "Unlock API key vault for \(client.name).") { success, error in
            if let error { print("[Vault] Auth failed: \(error.localizedDescription)") }
            guard success else { return }
            let loaded = VaultManager.entries(for: client.keychainVaultId)
            entries = loaded
            secrets = Dictionary(uniqueKeysWithValues: loaded.compactMap { entry in
                guard let secret = VaultManager.readSecret(for: entry, vaultId: client.keychainVaultId) else { return nil }
                return (entry.id, secret)
            })
            revealedIds = []
            isUnlocked = true
        }
    }

    private func lockVault() {
        isUnlocked = false
        lockedEntryCount = entries.count
        entries = []
        secrets = [:]
        revealedIds = []
    }

    private func performDelete(_ entry: VaultEntry) {
        VaultManager.deleteEntry(entry, vaultId: client.keychainVaultId)
        entries.removeAll { $0.id == entry.id }
        secrets.removeValue(forKey: entry.id)
        revealedIds.remove(entry.id)
        lockedEntryCount = entries.count
        entryPendingDeletion = nil
    }
}

// MARK: - Add Vault Entry Sheet

struct AddVaultEntryView: View {
    let vaultId: String
    let onAdd: (VaultEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var secret = ""
    @State private var isSecretVisible = false

    var body: some View {
        ConduitBackground {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("New Vault Entry")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ConduitTheme.primary)
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ConduitTheme.secondary)
                }
                .padding(.top, 8)

                GlassCard {
                    VStack(spacing: 0) {
                        EditableRow(title: "Label") {
                            TextField("e.g. Stripe Secret Key", text: $label)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(ConduitTheme.secondary)
                                .fontWeight(.semibold)
                                .tint(ConduitTheme.accent)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        DividerLine()

                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text("Secret")
                                .foregroundStyle(ConduitTheme.primary)
                            Spacer(minLength: 12)
                            Group {
                                if isSecretVisible {
                                    TextField("sk_live_...", text: $secret)
                                } else {
                                    SecureField("sk_live_...", text: $secret)
                                        .textContentType(.password)
                                }
                            }
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(ConduitTheme.secondary)
                            .fontWeight(.semibold)
                            .tint(ConduitTheme.accent)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button {
                                isSecretVisible.toggle()
                            } label: {
                                Image(systemName: isSecretVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(ConduitTheme.muted)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isSecretVisible ? "Hide secret" : "Show secret")
                        }
                        .font(.body)
                        .padding(.vertical, 8)
                    }
                }

                Button {
                    guard canSave else { return }
                    let entry = VaultManager.addEntry(label: label, secret: secret, vaultId: vaultId)
                    onAdd(entry)
                    dismiss()
                } label: {
                    Text("Save Entry")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(canSave ? ConduitTheme.accent : ConduitTheme.muted.opacity(0.3))
                        )
                        .foregroundStyle(canSave ? .black : ConduitTheme.muted)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .keyboardDismissControls()
    }

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
