//
//  GlassworkComponents.swift
//  SIL
//
//  The last three Glasswork primitives, now drawn on SIL surfaces.
//
//  The habit editor (`QuestFormSheet`) is a long form that round-trips every
//  field a habit has — HealthKit types, the location picker, subtasks,
//  scheduling, reminders. Rather than rewrite it and risk losing behaviour,
//  its three building blocks were reimplemented here against `S`, so the
//  screen adopts the SIL language without being touched.
//
//  Nothing else uses these. When the editor is rebuilt, this file goes.
//

import SwiftUI

// MARK: - Background

/// Was an aurora wash of pink and cyan radial gradients over a dotted grid.
/// SIL has a flat ground, so this is now just that ground.
struct GWAurora: View {
    var body: some View {
        S.bg
            .allowsHitTesting(false)
    }
}

// MARK: - Card

/// Was a frosted glass panel with a gradient tint and an edge highlight. Now
/// the standard SIL card: flat fill, hairline border, soft-cornered.
struct GWCard<Content: View>: View {
    var padding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
    var corner: CGFloat = S.R.small
    /// Kept so existing call sites compile. SIL cards do not carry an accent
    /// rule, so it is ignored.
    var accent: Color?
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
                shape
                    .fill(S.card)
                    .overlay(shape.strokeBorder(S.line, lineWidth: 1))
            }
    }
}

extension GWCard {
    init(
        padding paddingValue: CGFloat,
        corner: CGFloat = S.R.small,
        accent: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            padding: EdgeInsets(top: paddingValue, leading: paddingValue,
                                bottom: paddingValue, trailing: paddingValue),
            corner: corner,
            accent: accent,
            content: content
        )
    }

    init(
        paddingX: CGFloat,
        paddingY: CGFloat,
        corner: CGFloat = S.R.small,
        accent: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            padding: EdgeInsets(top: paddingY, leading: paddingX,
                                bottom: paddingY, trailing: paddingX),
            corner: corner,
            accent: accent,
            content: content
        )
    }
}

// MARK: - Button

enum GWButtonVariant { case primary, ghost, danger, gold }

/// Was a gradient capsule with a coloured glow. Now the SIL button: inverted
/// ink for the primary action, an outline for the secondary, and the one warn
/// colour for destructive.
struct GWButton: View {
    let label: String
    var variant: GWButtonVariant = .primary
    var size: GWButtonSize = .md
    var icon: String?
    var action: () -> Void = {}

    enum GWButtonSize { case sm, md }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Text(icon).font(S.mono(11, .medium))
                }
                Text(label)
            }
            .font(S.text(size == .sm ? 14 : 16, .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .sm ? 16 : 20)
            .frame(maxWidth: .infinity)
            .frame(height: size == .sm ? 40 : 52)
            .background(background)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary, .gold:
            Capsule().fill(S.inv)
        case .danger:
            Capsule().fill(S.warn)
        case .ghost:
            Capsule().strokeBorder(S.line2, lineWidth: 1.5)
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary, .gold: return S.onInv
        case .danger:         return .white
        case .ghost:          return S.ink
        }
    }
}
