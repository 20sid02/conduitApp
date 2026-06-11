//
//  WidgetDataCache.swift
//  Conduit
//
//  Writes a lightweight JSON snapshot of the top deployments into App Group
//  UserDefaults so the ConduitWidget extension can read it without needing
//  access to the main SwiftData store.
//

import Foundation
import SwiftData
import WidgetKit

// MARK: - Snapshot model (Codable — no @Model dependencies)

struct WidgetDeploymentSnapshot: Codable, Identifiable {
    var id: String
    var appName: String
    var clientName: String
    var isOnline: Bool
    var deploymentURL: String?
    var systemPort: Int?
}

// MARK: - Cache

enum WidgetDataCache {
    static let appGroupID    = "group.xyz.mahajan.conduit"
    private static let snapshotsKey = "conduit.widget.deployments"
    private static let themeKey     = "conduit.widget.theme"

    private static var suite: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    // Called by the main app whenever data or theme changes.
    static func write(snapshots: [WidgetDeploymentSnapshot], theme: String) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        suite?.set(data, forKey: snapshotsKey)
        suite?.set(theme, forKey: themeKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Convenience: fetches deployments from a live ModelContainer and writes.
    static func refresh(using container: ModelContainer, theme: String) {
        let ctx = ModelContext(container)
        let descriptor = FetchDescriptor<Deployment>(
            sortBy: [SortDescriptor(\.dateDeployed, order: .reverse)]
        )
        guard let deployments = try? ctx.fetch(descriptor) else { return }
        let snapshots: [WidgetDeploymentSnapshot] = deployments.prefix(8).map { d in
            WidgetDeploymentSnapshot(
                id: d.id.uuidString,
                appName: d.appName ?? "Unnamed App",
                clientName: d.client?.name ?? "",
                isOnline: d.isOnline,
                deploymentURL: d.deploymentURL,
                systemPort: d.systemPort
            )
        }
        write(snapshots: snapshots, theme: theme)
    }

    // Read-side (also used by the widget target via a mirrored reader).
    static func readSnapshots() -> [WidgetDeploymentSnapshot] {
        guard let data = suite?.data(forKey: snapshotsKey),
              let items = try? JSONDecoder().decode([WidgetDeploymentSnapshot].self, from: data)
        else { return [] }
        return items
    }

    static func readTheme() -> String {
        suite?.string(forKey: themeKey) ?? "midnight"
    }
}
