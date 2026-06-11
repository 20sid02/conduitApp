//
//  FreeTier.swift
//  Conduit
//
//  Raw free-tier constants. Effective limits are computed by EntitlementManager,
//  which returns .max for these when isPro is true.
//

enum FreeTierLimits {
    static let maxClients = 4
    static let maxDeploymentsPerClient = 3
    static let searchEnabled = false
}
