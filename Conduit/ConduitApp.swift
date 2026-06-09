//
//  ConduitApp.swift
//  Conduit
//
//  Created by Siddharth Mahajan on 07/06/26.
//

import SwiftUI
import SwiftData

@main
struct ConduitApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Client.self,
            Deployment.self,
            InternalRoute.self,
            CustomSettingSection.self,
            CustomSettingField.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedDemoProjectIfNeeded(in: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    private static func seedDemoProjectIfNeeded(in container: ModelContainer) {
        let seedKey = "hasCreatedDemoProject"

        guard !UserDefaults.standard.bool(forKey: seedKey) else {
            return
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Client>()

        do {
            guard try context.fetchCount(descriptor) == 0 else {
                UserDefaults.standard.set(true, forKey: seedKey)
                return
            }

            let client = Client(name: "Demo Client")
            context.insert(client)

            let deployment = Deployment(
                client: client,
                appName: "Demo Server",
                dateDeployed: Date(),
                isOnline: true,
                deploymentURL: "demo.example.test",
                systemPort: 8080,
                dbName: "demo_app",
                dbPort: 5432,
                adminUsername: "demo-admin",
                username: "deploy"
            )
            client.deployments.append(deployment)
            context.insert(deployment)

            let route = InternalRoute(
                deployment: deployment,
                serviceName: "Web App",
                port: 8080
            )
            deployment.internalRoutes.append(route)
            context.insert(route)

            let section = CustomSettingSection(
                deployment: deployment,
                title: "Notes",
                sortOrder: 0
            )
            let field = CustomSettingField(
                section: section,
                label: "Environment",
                value: "Beta demo",
                type: .text,
                sortOrder: 0
            )
            section.fields.append(field)
            deployment.customSections.append(section)
            context.insert(section)
            context.insert(field)

            _ = KeychainManager.save(key: "\(deployment.id)-dbPassword", value: "demo-password")
            _ = KeychainManager.save(key: "\(deployment.id)-systemAccessPassword", value: "demo-password")
            _ = KeychainManager.save(key: "\(deployment.id)-adminAccessPassword", value: "demo-password")

            try context.save()
            UserDefaults.standard.set(true, forKey: seedKey)
        } catch {
            print("Could not seed demo project: \(error)")
        }
    }
}
