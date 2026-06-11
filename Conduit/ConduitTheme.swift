//
//  ConduitTheme.swift
//  Conduit
//

import SwiftUI
import UIKit

enum ConduitTheme {
    static let backgroundTop = Color(red: 0.04, green: 0.11, blue: 0.17)
    static let backgroundBottom = Color(red: 0.00, green: 0.02, blue: 0.03)
    static let card = Color.white.opacity(0.075)
    static let inset = Color.white.opacity(0.07)
    static let stroke = Color.white.opacity(0.12)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.66)
    static let muted = Color.white.opacity(0.42)
    static let accent = Color(red: 0.16, green: 0.55, blue: 1.0)
    static let online = Color(red: 0.15, green: 0.92, blue: 0.38)
    static let offline = Color(red: 0.95, green: 0.24, blue: 0.24)

    static var background: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
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
