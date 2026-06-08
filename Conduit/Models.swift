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
        self.appName = appName
        self.dateDeployed = dateDeployed
        self.isOnline = isOnline
        self.deploymentURL = deploymentURL
        self.systemPort = systemPort
        self.dbName = dbName
        self.dbPort = dbPort
        self.adminUsername = adminUsername
        self.username = username
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
        self.serviceName = serviceName
        self.port = port
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
