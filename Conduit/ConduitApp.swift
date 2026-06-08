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
            Tunnel.self,
            CustomSettingSection.self,
            CustomSettingField.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
}
