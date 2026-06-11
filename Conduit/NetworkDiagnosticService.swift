//
//  NetworkDiagnosticService.swift
//  Conduit
//

import Foundation
import Network
import Observation

enum PortStatus: Equatable {
    case idle
    case checking
    case reachable
    case unreachable
}

@Observable
@MainActor
final class NetworkDiagnosticService {
    private(set) var status: PortStatus = .idle

    // TCP socket check — used when a system port is explicitly set.
    func check(host: String, port: UInt16) {
        guard status != .checking else { return }
        status = .checking
        Task {
            let reached = await performTCPCheck(host: host, port: port)
            status = reached ? .reachable : .unreachable
        }
    }

    // HTTP reachability check — used when no port is set; fires a HEAD request against the URL.
    func checkURL(_ urlString: String) {
        guard status != .checking else { return }
        status = .checking
        Task {
            let reached = await performHTTPCheck(urlString)
            status = reached ? .reachable : .unreachable
        }
    }

    func reset() {
        status = .idle
    }

    private func performHTTPCheck(_ urlString: String) async -> Bool {
        let raw = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlStr = raw.hasPrefix("http") ? raw : "https://\(raw)"
        guard let url = URL(string: urlStr) else { return false }

        var request = URLRequest(url: url, timeoutInterval: 2.5)
        request.httpMethod = "HEAD"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return response is HTTPURLResponse
        } catch {
            return false
        }
    }

    private func performTCPCheck(host: String, port: UInt16) async -> Bool {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return false }
        let endpoint = NWEndpoint.hostPort(host: .init(host), port: nwPort)
        let connection = NWConnection(to: endpoint, using: .tcp)

        return await withCheckedContinuation { continuation in
            let box = ContinuationBox(continuation)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    box.resume(returning: true)
                    connection.cancel()
                case .failed, .cancelled:
                    box.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .utility))

            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                box.resume(returning: false)
                connection.cancel()
            }
        }
    }
}

private final class ContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Never>?

    init(_ continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func resume(returning value: Bool) {
        lock.withLock {
            continuation?.resume(returning: value)
            continuation = nil
        }
    }
}
