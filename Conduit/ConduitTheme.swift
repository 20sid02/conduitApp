//
//  ConduitTheme.swift
//  Conduit
//

import SwiftUI
import UIKit

enum ConduitTheme {
    // Static colors shared across all themes
    static let card    = Color.white.opacity(0.075)
    static let inset   = Color.white.opacity(0.07)
    static let stroke  = Color.white.opacity(0.12)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.66)
    static let muted   = Color.white.opacity(0.42)
    static let online  = Color(red: 0.15, green: 0.92, blue: 0.38)
    static let offline = Color(red: 0.95, green: 0.24, blue: 0.24)

    // Theme-aware: reading these inside a SwiftUI body subscribes to ThemeManager changes.
    static var accent: Color       { ThemeManager.shared.accent }
    static var background: LinearGradient { ThemeManager.shared.background }
}

let validPortRange = 1...65_535

func sanitizedNumericText(_ text: String) -> String {
    String(text.unicodeScalars.filter { scalar in
        (48...57).contains(Int(scalar.value))
    })
}

func sanitizedText(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}

func portValue(from text: String) -> Int? {
    let numericText = sanitizedNumericText(text)
    guard let port = Int(numericText), validPortRange.contains(port) else {
        return nil
    }
    return port
}

func numericTextBinding(_ binding: Binding<String>) -> Binding<String> {
    Binding {
        sanitizedNumericText(binding.wrappedValue)
    } set: { newValue in
        binding.wrappedValue = sanitizedNumericText(newValue)
    }
}

func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

extension View {
    func keyboardDismissControls() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                }
            }
    }
}
