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
