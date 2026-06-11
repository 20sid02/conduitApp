//
//  CloudSyncMonitor.swift
//  Conduit
//

import SwiftUI
import CoreData
import CloudKit

// MARK: - Sync state

@Observable
final class CloudSyncMonitor {

    enum SyncState: Equatable {
        case idle
        case initialising   // schema being deployed on first launch
        case syncing
        case finished(at: Date)
        case error(String)

        static func == (lhs: SyncState, rhs: SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.initialising, .initialising), (.syncing, .syncing): true
            case (.finished(let a), .finished(let b)): a == b
            case (.error(let a), .error(let b)): a == b
            default: false
            }
        }
    }

    private(set) var state: SyncState = .idle
    private(set) var isCloudAvailable: Bool = false

    private var observer: NSObjectProtocol?

    init() {
        startObservingCloudKitEvents()
        refreshAccountStatus()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    // MARK: - Public

    func refreshAccountStatus() {
        Task { @MainActor [weak self] in
            do {
                let status = try await CKContainer.default().accountStatus()
                self?.isCloudAvailable = (status == .available)
            } catch {
                self?.isCloudAvailable = false
            }
        }
    }

    // MARK: - Private

    private func startObservingCloudKitEvents() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCloudKitEvent(notification)
        }
    }

    @MainActor
    private func handleCloudKitEvent(_ notification: Notification) {
        guard
            let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event
        else { return }

        if let endDate = event.endDate {
            if event.succeeded {
                state = .finished(at: endDate)
            } else if let ckError = event.error as? CKError {
                switch ckError.code {
                case .partialFailure:
                    // partialFailure (code 2) fires on the first sync while CloudKit deploys
                    // the container schema to the development environment. It is transient —
                    // subsequent syncs succeed once the schema is fully initialised.
                    print("[Conduit] CloudKit schema initialising (partialFailure — expected on first launch).")
                    state = event.type == .setup ? .initialising : .finished(at: endDate)

                case .notAuthenticated, .managedAccountRestricted:
                    // User is not signed into iCloud — surface the account-availability flag
                    // rather than a raw error string.
                    isCloudAvailable = false
                    state = .idle

                case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
                    // Transient connectivity issues — don't alarm the user; they will retry.
                    print("[Conduit] CloudKit transient error (\(ckError.code.rawValue)) — will retry.")
                    state = .idle

                default:
                    let message = ckError.localizedDescription
                    state = .error(message)
                    print("[Conduit] CloudKit sync error (\(ckError.code.rawValue)): \(message)")
                }
            } else {
                let message = event.error?.localizedDescription ?? "Sync failed"
                state = .error(message)
                print("[Conduit] CloudKit sync error: \(message)")
            }
        } else {
            // Event started — endDate is nil while in progress.
            state = .syncing
        }
    }
}
