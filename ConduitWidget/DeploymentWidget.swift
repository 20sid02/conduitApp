//
//  DeploymentWidget.swift
//  ConduitWidget
//
//  Reads deployment snapshots written by the main app into App Group
//  UserDefaults and renders glanceable infrastructure cards for Home and
//  Lock Screen placements.
//

import WidgetKit
import SwiftUI

// MARK: - Shared snapshot model (mirrors WidgetDataCache in main target)

struct WidgetDeploymentSnapshot: Codable, Identifiable {
    var id: String
    var appName: String
    var clientName: String
    var isOnline: Bool
    var deploymentURL: String?
    var systemPort: Int?
}

// MARK: - App Group reader

private enum WidgetCache {
    static let appGroupID    = "group.xyz.mahajan.conduit"
    static let snapshotsKey  = "conduit.widget.deployments"
    static let themeKey      = "conduit.widget.theme"

    static var deployments: [WidgetDeploymentSnapshot] {
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: snapshotsKey),
              let items = try? JSONDecoder().decode([WidgetDeploymentSnapshot].self, from: data)
        else { return [] }
        return items
    }

    static var theme: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: themeKey) ?? "midnight"
    }
}

// MARK: - Theme helpers (mirrors AppTheme in main target)

private enum WidgetColors {
    static func accent(for theme: String) -> Color {
        switch theme {
        case "matrixGreen":    return Color(red: 0.10, green: 0.85, blue: 0.45)
        case "cyberpunkAmber": return Color(red: 1.00, green: 0.70, blue: 0.10)
        case "draculaSlate":   return Color(red: 0.74, green: 0.51, blue: 0.98)
        default:               return Color(red: 0.16, green: 0.55, blue: 1.00) // midnight
        }
    }

    static let background    = Color(red: 0.04, green: 0.07, blue: 0.12)
    static let cardFill      = Color.white.opacity(0.06)
    static let primary       = Color.white
    static let secondary     = Color.white.opacity(0.55)
    static let muted         = Color.white.opacity(0.30)
    static let online        = Color(red: 0.15, green: 0.92, blue: 0.38)
    static let offline       = Color(red: 0.95, green: 0.24, blue: 0.24)
}

// MARK: - Timeline entry

struct DeploymentEntry: TimelineEntry {
    let date: Date
    let snapshots: [WidgetDeploymentSnapshot]
    let theme: String
}

// MARK: - Provider

struct DeploymentProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeploymentEntry {
        DeploymentEntry(date: .now, snapshots: placeholders, theme: "midnight")
    }

    func getSnapshot(in context: Context, completion: @escaping (DeploymentEntry) -> Void) {
        let snapshots = context.isPreview ? placeholders : WidgetCache.deployments
        completion(DeploymentEntry(date: .now, snapshots: snapshots, theme: WidgetCache.theme))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeploymentEntry>) -> Void) {
        let entry = DeploymentEntry(date: .now, snapshots: WidgetCache.deployments, theme: WidgetCache.theme)
        // Refresh every 30 minutes as a fallback; app reloads timelines on foreground.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private var placeholders: [WidgetDeploymentSnapshot] {
        [
            WidgetDeploymentSnapshot(id: "p1", appName: "Production API",  clientName: "Acme Corp",  isOnline: true,  deploymentURL: "api.acme.com",    systemPort: 8080),
            WidgetDeploymentSnapshot(id: "p2", appName: "Staging Server",  clientName: "Acme Corp",  isOnline: false, deploymentURL: "staging.acme.com", systemPort: 3000),
            WidgetDeploymentSnapshot(id: "p3", appName: "Database Node",   clientName: "Internal",   isOnline: true,  deploymentURL: "db.internal",      systemPort: 5432),
        ]
    }
}

// MARK: - Root widget view (dispatches by family)

struct DeploymentWidgetView: View {
    let entry: DeploymentEntry
    @Environment(\.widgetFamily) private var family

    private var accent: Color { WidgetColors.accent(for: entry.theme) }

    var body: some View {
        switch family {
        case .systemSmall:          SmallView(entry: entry, accent: accent)
        case .systemMedium:         MediumView(entry: entry, accent: accent)
        case .systemLarge:          LargeView(entry: entry, accent: accent)
        case .accessoryRectangular: AccessoryRectView(entry: entry)
        default:                    SmallView(entry: entry, accent: accent)
        }
    }
}

// MARK: - Brand header row

private struct BrandHeader: View {
    let accent: Color
    let trailingText: String?

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "server.rack")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(accent)
            Text("CONDUIT")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
            Spacer()
            if let t = trailingText {
                Text(t)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(WidgetColors.muted)
            }
        }
    }
}

// MARK: - Deployment row (shared by medium + large)

private struct DeploymentRow: View {
    let snapshot: WidgetDeploymentSnapshot
    let accent: Color
    var showPort: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(snapshot.isOnline ? WidgetColors.online : WidgetColors.offline)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.appName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(WidgetColors.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let url = snapshot.deploymentURL {
                        Text(url)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(WidgetColors.secondary)
                            .lineLimit(1)
                    }
                    if showPort, let port = snapshot.systemPort {
                        Text(":\(port)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(accent.opacity(0.8))
                    }
                }
            }

            Spacer(minLength: 4)

            Text(snapshot.clientName)
                .font(.system(size: 8))
                .foregroundStyle(WidgetColors.muted)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(WidgetColors.cardFill, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Small (single deployment)

private struct SmallView: View {
    let entry: DeploymentEntry
    let accent: Color

    private var top: WidgetDeploymentSnapshot? { entry.snapshots.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandHeader(accent: accent, trailingText: nil)

            if let d = top {
                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(d.isOnline ? WidgetColors.online : WidgetColors.offline)
                        .frame(width: 8, height: 8)
                    Text(d.appName)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(WidgetColors.primary)
                        .lineLimit(1)
                }

                if let url = d.deploymentURL {
                    Text(url)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(WidgetColors.secondary)
                        .lineLimit(1)
                        .padding(.top, 3)
                }

                if let port = d.systemPort {
                    Text(":\(port)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(accent)
                        .padding(.top, 2)
                }

                Spacer()

                Text(d.clientName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetColors.muted)
                    .lineLimit(1)
            } else {
                Spacer()
                Text("No deployments")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(WidgetColors.muted)
                Spacer()
            }
        }
        .padding(14)
        .widgetURL(top.flatMap { URL(string: "conduit://deployment/\($0.id)") })
    }
}

// MARK: - Medium (up to 3 deployments)

private struct MediumView: View {
    let entry: DeploymentEntry
    let accent: Color

    private var onlineCount: Int { entry.snapshots.filter(\.isOnline).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandHeader(
                accent: accent,
                trailingText: entry.snapshots.isEmpty ? nil : "\(onlineCount)/\(entry.snapshots.count) online"
            )

            if entry.snapshots.isEmpty {
                Spacer()
                Text("Open Conduit to add deployments")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(WidgetColors.muted)
                Spacer()
            } else {
                ForEach(entry.snapshots.prefix(3)) { d in
                    Link(destination: URL(string: "conduit://deployment/\(d.id)")!) {
                        DeploymentRow(snapshot: d, accent: accent)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
    }
}

// MARK: - Large (up to 5 deployments)

private struct LargeView: View {
    let entry: DeploymentEntry
    let accent: Color

    private var onlineCount: Int { entry.snapshots.filter(\.isOnline).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandHeader(
                accent: accent,
                trailingText: entry.snapshots.isEmpty ? nil : "\(onlineCount) online · \(entry.snapshots.count) total"
            )

            Rectangle()
                .fill(accent.opacity(0.2))
                .frame(height: 0.5)

            if entry.snapshots.isEmpty {
                Spacer()
                Text("Open Conduit to add deployments")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(WidgetColors.muted)
                Spacer()
            } else {
                ForEach(entry.snapshots.prefix(5)) { d in
                    Link(destination: URL(string: "conduit://deployment/\(d.id)")!) {
                        DeploymentRow(snapshot: d, accent: accent, showPort: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
    }
}

// MARK: - Accessory Rectangular (Lock Screen)

private struct AccessoryRectView: View {
    let entry: DeploymentEntry

    private var top: WidgetDeploymentSnapshot? { entry.snapshots.first }

    var body: some View {
        HStack(spacing: 6) {
            if let d = top {
                Image(systemName: d.isOnline ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(d.isOnline ? WidgetColors.online : WidgetColors.offline)
                VStack(alignment: .leading, spacing: 1) {
                    Text(d.appName)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                    Text(d.isOnline ? "ONLINE" : "OFFLINE")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(d.isOnline ? WidgetColors.online : WidgetColors.offline)
                }
                Spacer()
            } else {
                Image(systemName: "server.rack")
                Text("No deployments")
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .widgetURL(top.flatMap { URL(string: "conduit://deployment/\($0.id)") })
    }
}

// MARK: - Widget configuration

struct DeploymentWidget: Widget {
    let kind = "ConduitDeploymentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeploymentProvider()) { entry in
            DeploymentWidgetView(entry: entry)
                .containerBackground(WidgetColors.background, for: .widget)
        }
        .configurationDisplayName("Deployments")
        .description("Monitor your active infrastructure at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
        ])
    }
}
