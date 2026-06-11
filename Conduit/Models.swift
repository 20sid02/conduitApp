import Foundation
import SwiftData

private let conduitValidPortRange = 1...65_535

private func conduitTrimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func conduitTrimmedOptional(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmedValue = conduitTrimmed(value)
    return trimmedValue.isEmpty ? nil : trimmedValue
}

private func conduitOptionalPort(_ port: Int?) -> Int? {
    guard let port, conduitValidPortRange.contains(port) else { return nil }
    return port
}

private func conduitRequiredPort(_ port: Int) -> Int {
    conduitValidPortRange.contains(port) ? port : 1
}

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var keychainVaultId: String

    @Relationship(deleteRule: .cascade, inverse: \Deployment.client)
    var deployments: [Deployment] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), keychainVaultId: String = UUID().uuidString) {
        self.id = id
        self.name = conduitTrimmed(name)
        self.createdAt = createdAt
        self.keychainVaultId = conduitTrimmed(keychainVaultId)
    }
}

@Model
final class Deployment {
    @Attribute(.unique) var id: UUID
    var appName: String?
    var dateDeployed: Date
    var isOnline: Bool
    var deploymentURL: String?
    var systemPort: Int?
    var dbName: String?
    var dbPort: Int?
    var adminUsername: String?
    @Attribute(originalName: "itsUsername") var username: String?

    var client: Client

    @Relationship(deleteRule: .cascade, inverse: \InternalRoute.deployment)
    var internalRoutes: [InternalRoute] = []

    @Relationship(deleteRule: .cascade, inverse: \CustomSettingSection.deployment)
    var customSections: [CustomSettingSection] = []

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

@Model
final class InternalRoute {
    @Attribute(.unique) var id: UUID
    var serviceName: String
    var port: Int
    var sortOrder: Int

    var deployment: Deployment

    init(id: UUID = UUID(), deployment: Deployment, serviceName: String, port: Int, sortOrder: Int = 0) {
        self.id = id
        self.deployment = deployment
        self.serviceName = conduitTrimmed(serviceName)
        self.port = conduitRequiredPort(port)
        self.sortOrder = sortOrder
    }
}

@Model
final class CustomSettingSection {
    @Attribute(.unique) var id: UUID
    var title: String
    var sortOrder: Int

    var deployment: Deployment

    @Relationship(deleteRule: .cascade, inverse: \CustomSettingField.section)
    var fields: [CustomSettingField] = []

    init(id: UUID = UUID(), deployment: Deployment, title: String, sortOrder: Int = 0) {
        self.id = id
        self.deployment = deployment
        self.title = conduitTrimmed(title)
        self.sortOrder = sortOrder
    }
}

@Model
final class CustomSettingField {
    @Attribute(.unique) var id: UUID
    var label: String
    var value: String?
    var typeRawValue: String
    var sortOrder: Int

    var section: CustomSettingSection

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
