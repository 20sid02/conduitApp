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
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        // NOTE: CloudKit container initialization is intentionally omitted here.
        // Attempting ModelContainer with cloudKitDatabase: .private(...) applies
        // CloudKit schema validation process-wide — even to subsequent local and
        // in-memory containers — causing loadIssueModelContainer on every attempt
        // until the process exits. CloudKit will be enabled once Xcode capabilities
        // (iCloud + Background Modes) are confirmed set up.

        // Each attempt creates a fresh Schema to avoid any shared-state contamination.

        func makeSchema() -> Schema {
            Schema([
                Client.self,
                Deployment.self,
                InternalRoute.self,
                CustomSettingSection.self,
                CustomSettingField.self,
            ])
        }

        // ── Attempt 1: CloudKit-backed persistent store ───────────────────────
        // .automatic → uses NSPersistentCloudKitContainer when the iCloud entitlement
        // is present, falling back to a plain local store when iCloud is unavailable.
        // This means ALL data (free and Pro tier) is silently backed by the user's
        // personal iCloud container, so upgrading to Pro is seamless — no migration.
        let s1 = makeSchema()
        if let container = try? ModelContainer(
            for: s1,
            configurations: [ModelConfiguration(schema: s1,
                                                isStoredInMemoryOnly: false,
                                                cloudKitDatabase: .automatic)]
        ) {
            seedDemoProjectIfNeeded(in: container)
            print("[Conduit] Container ready (CloudKit: automatic).")
            return container
        }
        print("[Conduit] Container failed — running store recovery.")

        // ── Recovery: delete every SQLite / store file in Application Support ──
        let dir = URL.applicationSupportDirectory
        if let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        ) {
            for url in files where isStoreFile(url) {
                try? FileManager.default.removeItem(at: url)
                print("[Conduit] Removed: \(url.lastPathComponent)")
            }
        }

        // ── Attempt 2: fresh store after recovery ─────────────────────────────
        let s2 = makeSchema()
        if let container = try? ModelContainer(
            for: s2,
            configurations: [ModelConfiguration(schema: s2,
                                                isStoredInMemoryOnly: false,
                                                cloudKitDatabase: .automatic)]
        ) {
            seedDemoProjectIfNeeded(in: container)
            print("[Conduit] Post-recovery container ready.")
            return container
        }
        print("[Conduit] Post-recovery attempt failed — using in-memory fallback.")

        // ── Attempt 3: in-memory (data won't persist, but app stays alive) ────
        let s3 = makeSchema()
        guard let container = try? ModelContainer(
            for: s3,
            configurations: [ModelConfiguration(schema: s3,
                                                isStoredInMemoryOnly: true,
                                                cloudKitDatabase: .none)]
        ) else {
            fatalError("[Conduit] Cannot initialise any container. Schema is fundamentally broken.")
        }
        return container
    }()

    @State private var syncMonitor = CloudSyncMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(EntitlementManager.shared)
                .environment(syncMonitor)
                // Re-verify entitlements when the app returns to the foreground.
                // Guard: skip if already Pro — the payment sheet causes an
                // active→inactive→active cycle, so this fires right after a
                // purchase and races against Apple's server propagation delay,
                // clobbering the isPro = true we just set from the verified transaction.
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    if !EntitlementManager.shared.isPro {
                        Task { await EntitlementManager.shared.refreshEntitlements() }
                    }
                    syncMonitor.refreshAccountStatus()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Helpers

    private static func isStoreFile(_ url: URL) -> Bool {
        let ext  = url.pathExtension
        let name = url.lastPathComponent
        return ext == "sqlite" || ext == "store"
            || name.hasSuffix(".sqlite-wal") || name.hasSuffix(".sqlite-shm")
            || name.hasSuffix(".store-wal")  || name.hasSuffix(".store-shm")
    }

    // MARK: - Demo seed

    private static func seedDemoProjectIfNeeded(in container: ModelContainer) {
        let seedKey = "hasCreatedDemoProject"
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        let context = ModelContext(container)
        do {
            guard try context.fetchCount(FetchDescriptor<Client>()) == 0 else {
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
            context.insert(deployment)
            client.deployments.append(deployment)

            let route = InternalRoute(deployment: deployment, serviceName: "Web App", port: 8080)
            context.insert(route)
            deployment.internalRoutes.append(route)

            let section = CustomSettingSection(deployment: deployment, title: "Notes", sortOrder: 0)
            context.insert(section)
            deployment.customSections.append(section)

            let field = CustomSettingField(
                section: section, label: "Environment",
                value: "Beta demo", type: .text, sortOrder: 0
            )
            context.insert(field)
            section.fields.append(field)

            _ = KeychainManager.save(key: "\(deployment.id)-dbPassword",           value: "demo-password")
            _ = KeychainManager.save(key: "\(deployment.id)-systemAccessPassword", value: "demo-password")
            _ = KeychainManager.save(key: "\(deployment.id)-adminAccessPassword",  value: "demo-password")

            try context.save()
            UserDefaults.standard.set(true, forKey: seedKey)
        } catch {
            print("[Conduit] Demo seed failed: \(error)")
        }
    }
}
