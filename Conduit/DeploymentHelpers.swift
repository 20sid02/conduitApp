//
//  DeploymentHelpers.swift
//  Conduit
//

import Foundation

// MARK: - Optional relationship helpers
//
// CloudKit requires all to-many relationships to be typed as [T]?.
// These extensions let call sites keep the same .append / .removeAll
// syntax they used when the arrays were non-optional.

extension Optional where Wrapped: RangeReplaceableCollection {
    /// Appends `newElement`, initialising the collection to empty first if nil.
    mutating func append(_ newElement: Wrapped.Element) {
        if self == nil { self = Wrapped() }
        self!.append(newElement)
    }

    /// Removes all elements satisfying `shouldRemove`, silently ignoring nil.
    mutating func removeAll(where shouldRemove: (Wrapped.Element) throws -> Bool) rethrows {
        try self?.removeAll(where: shouldRemove)
    }
}

extension Deployment {
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

    var hasAdminAccess: Bool {
        adminUsername != nil
            || KeychainManager.read(key: "\(id)-adminAccessPassword") != nil
            || KeychainManager.read(key: "\(id)-djangoAdminPassword") != nil
    }
}

extension CustomSettingField {
    var fieldType: CustomSettingFieldType {
        get { CustomSettingFieldType(rawValue: typeRawValue) ?? .text }
        set { typeRawValue = newValue.rawValue }
    }

    var keychainKey: String {
        "customField-\(id.uuidString)"
    }

    var resolvedURL: URL? {
        guard fieldType == .url else { return nil }
        let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawValue.isEmpty else { return nil }
        if let url = URL(string: rawValue), url.scheme != nil { return url }
        return URL(string: "https://\(rawValue)")
    }
}

func deleteStoredCredentials(for deployment: Deployment) {
    ["dbHost", "dbPassword", "systemAccessPassword", "djangoAdminPassword", "adminAccessPassword"].forEach { keySuffix in
        _ = KeychainManager.delete(key: "\(deployment.id)-\(keySuffix)")
    }
    (deployment.customSections ?? [])
        .flatMap { $0.fields ?? [] }
        .filter { $0.fieldType == .password }
        .forEach { field in
            _ = KeychainManager.delete(key: field.keychainKey)
        }
}
