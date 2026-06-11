//
//  CloudSyncView.swift
//  Conduit
//

import SwiftUI

struct CloudSyncView: View {
    @Environment(CloudSyncMonitor.self) private var syncMonitor

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 3) {
                Text("iCloud Sync")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ConduitTheme.primary)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                syncMonitor.refreshAccountStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh sync status")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var statusIcon: some View {
        Group {
            switch syncMonitor.state {
            case .idle:
                Image(systemName: syncMonitor.isCloudAvailable ? "icloud" : "icloud.slash")
                    .foregroundStyle(syncMonitor.isCloudAvailable ? ConduitTheme.secondary : ConduitTheme.muted)
            case .initialising, .syncing:
                ProgressView()
                    .controlSize(.small)
                    .tint(ConduitTheme.accent)
            case .finished:
                Image(systemName: "checkmark.icloud")
                    .foregroundStyle(ConduitTheme.online)
            case .error:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundStyle(ConduitTheme.offline)
            }
        }
        .frame(width: 22, height: 22)
    }

    // MARK: - Helpers

    private var statusText: String {
        if !syncMonitor.isCloudAvailable {
            return "Sign in to iCloud in device Settings to enable sync."
        }
        switch syncMonitor.state {
        case .idle:
            return "Waiting to sync"
        case .initialising:
            return "Setting up iCloud container…"
        case .syncing:
            return "Syncing with iCloud…"
        case .finished(let date):
            return "Synced \(date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private var statusColor: Color {
        switch syncMonitor.state {
        case .idle, .initialising, .syncing:
            return ConduitTheme.secondary
        case .finished:
            return ConduitTheme.online
        case .error:
            return ConduitTheme.offline
        }
    }
}
