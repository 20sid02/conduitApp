//
//  ThemeManager.swift
//  Conduit
//

import SwiftUI
import Observation

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

    func applyTheme(_ theme: AppTheme) {
        selectedTheme = theme
    }
}
