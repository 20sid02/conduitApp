//
//  DeepLinkRouter.swift
//  Conduit
//
//  Receives deep-link IDs from widget taps (conduit://deployment/{uuid}).
//  Views observe `pendingDeploymentID` and navigate when it is set.
//

import Observation

@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()
    private init() {}

    // Set by ConduitApp.onOpenURL; cleared by the receiving view after navigation.
    var pendingDeploymentID: String?
}
