//
//  ThemeManager.swift
//  Conduit
//

import SwiftUI
import Observation
import UIKit

// MARK: - AppTheme

enum AppTheme: String, CaseIterable, Identifiable {
    case midnight
    case matrixGreen
    case cyberpunkAmber
    case draculaSlate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight:       "Midnight"
        case .matrixGreen:    "Matrix Green"
        case .cyberpunkAmber: "Cyberpunk Amber"
        case .draculaSlate:   "Dracula Slate"
        }
    }

    var accent: Color {
        switch self {
        case .midnight:       Color(red: 0.16, green: 0.55, blue: 1.00)
        case .matrixGreen:    Color(red: 0.10, green: 0.85, blue: 0.45)
        case .cyberpunkAmber: Color(red: 1.00, green: 0.70, blue: 0.10)
        case .draculaSlate:   Color(red: 0.74, green: 0.51, blue: 0.98)
        }
    }

    var backgroundTop: Color {
        switch self {
        case .midnight:       Color(red: 0.04, green: 0.11, blue: 0.17)
        case .matrixGreen:    Color(red: 0.02, green: 0.10, blue: 0.04)
        case .cyberpunkAmber: Color(red: 0.10, green: 0.08, blue: 0.02)
        case .draculaSlate:   Color(red: 0.08, green: 0.06, blue: 0.12)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .midnight:       Color(red: 0.00, green: 0.02, blue: 0.03)
        case .matrixGreen:    Color(red: 0.00, green: 0.02, blue: 0.01)
        case .cyberpunkAmber: Color(red: 0.04, green: 0.03, blue: 0.00)
        case .draculaSlate:   Color(red: 0.03, green: 0.02, blue: 0.05)
        }
    }

    // Matches CFBundleAlternateIcons key in Info.plist.
    // nil → revert to the default app icon.
    var alternateIconName: String? {
        switch self {
        case .midnight:       nil
        case .matrixGreen:    "AppIconGreen"
        case .cyberpunkAmber: "AppIconAmber"
        case .draculaSlate:   "AppIconSlate"
        }
    }
}

// MARK: - ThemeManager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private static let themeKey = "conduit.selectedTheme"

    private(set) var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Self.themeKey)
        }
    }

    var accent: Color { selectedTheme.accent }

    var background: LinearGradient {
        LinearGradient(
            colors: [selectedTheme.backgroundTop, selectedTheme.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.themeKey) ?? ""
        selectedTheme = AppTheme(rawValue: saved) ?? .midnight
    }

    @MainActor
    func applyTheme(_ theme: AppTheme) {
        selectedTheme = theme
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(theme.alternateIconName) { error in
            if let error {
                print("[ThemeManager] Icon switch failed: \(error.localizedDescription)")
            }
        }
        // iOS presents a system "You Have Changed the Icon" UIAlertController
        // automatically. Dismiss it silently — the tile selection is confirmation enough.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let root = scene.keyWindow?.rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            if top is UIAlertController { top.dismiss(animated: false) }
        }
    }
}
