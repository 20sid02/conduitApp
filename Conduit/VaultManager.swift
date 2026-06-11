//
//  VaultManager.swift
//  Conduit
//

import Foundation

struct VaultEntry: Identifiable, Codable {
    let id: UUID
    var label: String

    init(id: UUID = UUID(), label: String) {
        self.id = id
        self.label = label
    }
}

enum VaultManager {

    // MARK: - Public API

    static func entries(for vaultId: String) -> [VaultEntry] {
        guard
            let raw = KeychainManager.read(key: indexKey(for: vaultId)),
            let data = raw.data(using: .utf8),
            let decoded = try? JSONDecoder().decode([VaultEntry].self, from: data)
        else { return [] }
        return decoded
    }

    @discardableResult
    static func addEntry(label: String, secret: String, vaultId: String) -> VaultEntry {
        let entry = VaultEntry(label: label.trimmingCharacters(in: .whitespacesAndNewlines))
        var current = entries(for: vaultId)
        current.append(entry)
        persistIndex(current, vaultId: vaultId)
        KeychainManager.save(key: secretKey(vaultId: vaultId, entryId: entry.id), value: secret)
        return entry
    }

    static func readSecret(for entry: VaultEntry, vaultId: String) -> String? {
        KeychainManager.read(key: secretKey(vaultId: vaultId, entryId: entry.id))
    }

    static func deleteEntry(_ entry: VaultEntry, vaultId: String) {
        var current = entries(for: vaultId)
        current.removeAll { $0.id == entry.id }
        persistIndex(current, vaultId: vaultId)
        KeychainManager.delete(key: secretKey(vaultId: vaultId, entryId: entry.id))
    }

    static func deleteAllEntries(for vaultId: String) {
        entries(for: vaultId).forEach {
            KeychainManager.delete(key: secretKey(vaultId: vaultId, entryId: $0.id))
        }
        KeychainManager.delete(key: indexKey(for: vaultId))
    }

    // MARK: - Private

    private static func indexKey(for vaultId: String) -> String {
        "vault-index-\(vaultId)"
    }

    private static func secretKey(vaultId: String, entryId: UUID) -> String {
        "vault-secret-\(vaultId)-\(entryId.uuidString)"
    }

    @discardableResult
    private static func persistIndex(_ entries: [VaultEntry], vaultId: String) -> Bool {
        guard
            let data = try? JSONEncoder().encode(entries),
            let json = String(data: data, encoding: .utf8)
        else { return false }
        return KeychainManager.save(key: indexKey(for: vaultId), value: json)
    }
}
