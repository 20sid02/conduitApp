import Foundation
import SwiftData

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
        self.name = name
        self.createdAt = createdAt
        self.keychainVaultId = keychainVaultId
    }
}

@Model
final class Deployment {
    @Attribute(.unique) var id: UUID
    var appName: String?
    var dateDeployed: Date
    var isOnline: Bool
    var adminURLOverride: String?
    var systemPort: Int?
    var gunicornPort: Int?
    var nginxPort: Int?
    var dbName: String?
    var dbPort: Int?
    @Attribute(originalName: "itsUsername") var username: String?

    var client: Client

    @Relationship(deleteRule: .cascade, inverse: \Tunnel.deployment)
    var tunnels: [Tunnel] = []

    @Relationship(deleteRule: .cascade, inverse: \CustomSettingSection.deployment)
    var customSections: [CustomSettingSection] = []

    init(
        id: UUID = UUID(),
        client: Client,
        appName: String? = nil,
        dateDeployed: Date = Date(),
        isOnline: Bool,
        adminURLOverride: String? = nil,
        systemPort: Int? = nil,
        gunicornPort: Int? = nil,
        nginxPort: Int? = nil,
        dbName: String? = nil,
        dbPort: Int? = nil,
        username: String? = nil
    ) {
        self.id = id
        self.client = client
        self.appName = appName
        self.dateDeployed = dateDeployed
        self.isOnline = isOnline
        self.adminURLOverride = adminURLOverride
        self.systemPort = systemPort
        self.gunicornPort = gunicornPort
        self.nginxPort = nginxPort
        self.dbName = dbName
        self.dbPort = dbPort
        self.username = username
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
        self.title = title
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
        self.label = label
        self.value = value
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
        case .text:
            "Text"
        case .url:
            "URL"
        case .port:
            "Port"
        case .password:
            "Password"
        }
    }
}

@Model
final class Tunnel {
    @Attribute(.unique) var id: UUID
    var name: String
    var port: Int

    var deployment: Deployment

    init(id: UUID = UUID(), deployment: Deployment, name: String, port: Int) {
        self.id = id
        self.deployment = deployment
        self.name = name
        self.port = port
    }
}
