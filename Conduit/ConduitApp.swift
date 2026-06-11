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
                ContactEntry.self,
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
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(EntitlementManager.shared)
                .environment(syncMonitor)
                .environment(themeManager)
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
                    WidgetDataCache.refresh(
                        using: sharedModelContainer,
                        theme: themeManager.selectedTheme.rawValue
                    )
                }
                .onOpenURL { url in
                    // conduit://deployment/{uuid}  — deep link from widget tap
                    guard url.scheme == "conduit",
                          url.host == "deployment",
                          let idString = url.pathComponents.dropFirst().first,
                          UUID(uuidString: idString) != nil
                    else { return }
                    // Store the pending ID; ContentView can observe DeepLinkRouter
                    // to programmatically navigate once path-based navigation is added.
                    DeepLinkRouter.shared.pendingDeploymentID = idString
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
}
