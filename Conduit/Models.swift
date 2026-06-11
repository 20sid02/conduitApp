import Foundation
import SwiftData

private let conduitValidPortRange = 1...65_535

private func conduitTrimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func conduitTrimmedOptional(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = conduitTrimmed(value)
    return trimmed.isEmpty ? nil : trimmed
}

private func conduitOptionalPort(_ port: Int?) -> Int? {
    guard let port, conduitValidPortRange.contains(port) else { return nil }
    return port
}

private func conduitRequiredPort(_ port: Int) -> Int {
    conduitValidPortRange.contains(port) ? port : 1
}

// MARK: - Client

@Model
final class Client {
    // Inline defaults are required so CoreData's entity description sees a non-nil
    // defaultValue for every attribute — a CloudKit schema constraint.
    var id: UUID            = UUID()
    var name: String        = ""
    var createdAt: Date     = Date()
    var keychainVaultId: String = ""

    // [Deployment]? (optional to-many) satisfies CloudKit's isOptional = YES requirement.
    @Relationship(deleteRule: .cascade, inverse: \Deployment.client)
    var deployments: [Deployment]?

    @Relationship(deleteRule: .cascade, inverse: \ContactEntry.client)
    var contacts: [ContactEntry]?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        keychainVaultId: String = UUID().uuidString
    ) {
        self.id = id
        self.name = conduitTrimmed(name)
        self.createdAt = createdAt
        self.keychainVaultId = conduitTrimmed(keychainVaultId)
    }
}

// MARK: - Deployment

@Model
final class Deployment {
    var id: UUID            = UUID()
    var appName: String?
    var dateDeployed: Date  = Date()
    var isOnline: Bool      = false
    var deploymentURL: String?
    var systemPort: Int?
    var dbName: String?
    var dbPort: Int?
    var adminUsername: String?
    @Attribute(originalName: "itsUsername") var username: String?

    // Optional so CloudKit can sync a Deployment before its parent Client arrives.
    // No @Relationship annotation — the inverse is already declared on Client.deployments.
    var client: Client?

    @Relationship(deleteRule: .cascade, inverse: \InternalRoute.deployment)
    var internalRoutes: [InternalRoute]?

    @Relationship(deleteRule: .cascade, inverse: \CustomSettingSection.deployment)
    var customSections: [CustomSettingSection]?

    init(
        id: UUID = UUID(),
        client: Client,
        appName: String? = nil,
        dateDeployed: Date = Date(),
        isOnline: Bool,
        deploymentURL: String? = nil,
        systemPort: Int? = nil,
        dbName: String? = nil,
        dbPort: Int? = nil,
        adminUsername: String? = nil,
        username: String? = nil
    ) {
        self.id = id
        self.client = client
        self.appName = conduitTrimmedOptional(appName)
        self.dateDeployed = dateDeployed
        self.isOnline = isOnline
        self.deploymentURL = conduitTrimmedOptional(deploymentURL)
        self.systemPort = conduitOptionalPort(systemPort)
        self.dbName = conduitTrimmedOptional(dbName)
        self.dbPort = conduitOptionalPort(dbPort)
        self.adminUsername = conduitTrimmedOptional(adminUsername)
        self.username = conduitTrimmedOptional(username)
    }
}

// MARK: - InternalRoute

@Model
final class InternalRoute {
    var id: UUID        = UUID()
    var serviceName: String = ""
    var port: Int       = 1
    var sortOrder: Int  = 0

    var deployment: Deployment?

    init(
        id: UUID = UUID(),
        deployment: Deployment,
        serviceName: String,
        port: Int,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.deployment = deployment
        self.serviceName = conduitTrimmed(serviceName)
        self.port = conduitRequiredPort(port)
        self.sortOrder = sortOrder
    }
}

// MARK: - CustomSettingSection

@Model
final class CustomSettingSection {
    var id: UUID        = UUID()
    var title: String   = ""
    var sortOrder: Int  = 0

    var deployment: Deployment?

    @Relationship(deleteRule: .cascade, inverse: \CustomSettingField.section)
    var fields: [CustomSettingField]?

    init(
        id: UUID = UUID(),
        deployment: Deployment,
        title: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.deployment = deployment
        self.title = conduitTrimmed(title)
        self.sortOrder = sortOrder
    }
}

// MARK: - CustomSettingField

@Model
final class CustomSettingField {
    var id: UUID            = UUID()
    var label: String       = ""
    var value: String?
    var typeRawValue: String = CustomSettingFieldType.text.rawValue
    var sortOrder: Int      = 0

    var section: CustomSettingSection?

    init(
        id: UUID = UUID(),
        section: CustomSettingSection,
        label: String,
        value: String? = nil,
        type: CustomSettingFieldType,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.section = section
        self.label = conduitTrimmed(label)
        self.value = conduitTrimmedOptional(value)
        self.typeRawValue = type.rawValue
        self.sortOrder = sortOrder
    }
}

// MARK: - ContactEntry

@Model
final class ContactEntry {
    var id: UUID            = UUID()
    var name: String        = ""
    var role: String?
    var phone: String?
    var email: String?
    var supportPortal: String?
    var accountNotes: String?
    var sortOrder: Int      = 0

    var client: Client?

    init(
        id: UUID = UUID(),
        client: Client,
        name: String,
        role: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        supportPortal: String? = nil,
        accountNotes: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.client = client
        self.name = conduitTrimmed(name)
        self.role = conduitTrimmedOptional(role)
        self.phone = conduitTrimmedOptional(phone)
        self.email = conduitTrimmedOptional(email)
        self.supportPortal = conduitTrimmedOptional(supportPortal)
        self.accountNotes = conduitTrimmedOptional(accountNotes)
        self.sortOrder = sortOrder
    }
}

// MARK: - CustomSettingFieldType

enum CustomSettingFieldType: String, CaseIterable, Identifiable {
    case text
    case url
    case port
    case password

    var id: Self { self }

    var displayName: String {
        switch self {
        case .text:     "Text"
        case .url:      "URL"
        case .port:     "Port"
        case .password: "Password"
        }
    }
}
