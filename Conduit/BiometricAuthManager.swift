 //
//  BiometricAuthManager.swift
//  Conduit
//

import Foundation
import LocalAuthentication

final class BiometricAuthManager {
    func authenticateUser(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        let policy: LAPolicy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            policy = .deviceOwnerAuthentication
        } else {
            print("Authentication unavailable: \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }

        context.evaluatePolicy(policy, localizedReason: reason) { success, authenticationError in
            if let authenticationError {
                print("Authentication failed: \(authenticationError.localizedDescription)")
            }

            DispatchQueue.main.async {
                completion(success, authenticationError)
            }
        }
    }
}
