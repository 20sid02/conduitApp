//
//  SharedComponents.swift
//  Conduit
//

import SwiftUI

struct ConduitBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ConduitTheme.background
                .ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
    }
}

struct ScreenHeader: View {
    let title: String
    var settingsAction: (() -> Void)?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(ConduitTheme.primary)

            Spacer()

            if let settingsAction {
                Button(action: settingsAction) {
                    Image(systemName: "gearshape")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ConduitTheme.secondary)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Settings")
            }

            if let action {
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ConduitTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Add")
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ConduitTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ConduitTheme.stroke, lineWidth: 1)
            )
    }
}

struct StatusDot: View {
    let isOnline: Bool
    var offlineColor: Color = ConduitTheme.offline

    var body: some View {
        Circle()
            .fill(isOnline ? ConduitTheme.online : offlineColor)
            .frame(width: 12, height: 12)
            .shadow(color: (isOnline ? ConduitTheme.online : offlineColor).opacity(0.45), radius: 8)
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(ConduitTheme.secondary)
            .padding(.horizontal, 2)
    }
}

struct EditableRow<Field: View>: View {
    let title: String
    @ViewBuilder var field: Field

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .foregroundStyle(ConduitTheme.primary)
            Spacer(minLength: 12)
            field
        }
        .font(.body)
        .padding(.vertical, 8)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.09))
            .frame(height: 1)
    }
}

struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ConduitTheme.accent)

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConduitTheme.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
