//
//  GlassworkTheme.swift
//  SIL
//
//  Compatibility layer. The screens in this app were written against the old
//  "aurora on velvet" GLASSWORK palette; SIL 2.0 replaces that language with
//  the quiet, near-monochrome system defined in `SILTheme.swift`.
//
//  Rather than rewrite every call site at once, `GW` now forwards each of its
//  old tokens to the closest SIL token. The neon pair (cyan/pink), the gold
//  currency colour and the aurora wash all collapse onto ink and the single
//  accent, so the whole surface de-gamifies in one step. New code should use
//  `S` directly; this shim shrinks as screens are rebuilt.
//

import SwiftUI
import UIKit

enum GW {
    // MARK: Hex / adaptive helpers

    /// Static hex → Color (no trait awareness).
    static func col(_ hex: String, _ a: Double = 1) -> Color {
        S.hex(hex, a)
    }

    /// Adaptive hex token — resolves per trait collection at render time.
    static func adaptive(light: String, dark: String, opacity: Double = 1) -> Color {
        S.adaptive(light: light, dark: dark, opacity: opacity)
    }

    /// Adaptive monochrome — white channel in dark, black channel in light.
    static func adaptiveMono(lightOpacity: Double, darkOpacity: Double) -> Color {
        S.adaptiveMono(lightOpacity: lightOpacity, darkOpacity: darkOpacity)
    }

    // MARK: Surfaces

    static let bg          = S.bg
    static let bg2         = S.bg2
    /// Old "glass tint" — now a flat card fill.
    static let surface     = S.card
    static let surface2    = S.card2
    static let hairline    = S.line
    static let hairlineHi  = S.line2

    // MARK: Ink

    static let ink         = S.ink
    static let inkSoft     = S.ink2
    static let mute        = S.ink3

    // MARK: Accents
    //
    // SIL has one accent, not a palette. Everything that used to carry its own
    // hue now reads as ink; only genuinely accented states keep the accent, and
    // only loss states keep `warn`.

    static var cyan: Color   { S.accentInk }
    static var pink: Color   { S.accent }
    static var amber: Color  { S.ink2 }
    static var good: Color   { S.ink }
    static var danger: Color { S.warn }
    static var gold: Color   { S.ink }

    // MARK: Gradients
    //
    // The two-stop neon gradients are gone. These stay as single-hue ramps so
    // existing fills keep working without reintroducing colour.

    static var grad: LinearGradient {
        LinearGradient(colors: [S.accent, S.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var gradGold: LinearGradient {
        LinearGradient(colors: [S.ink, S.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var gradDanger: LinearGradient {
        LinearGradient(colors: [S.warn, S.warn], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func gradBarHP(_ tint: Color) -> LinearGradient {
        LinearGradient(colors: [tint, tint], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: Aurora
    //
    // SIL has no aurora. The wash is reduced to the accent glow, which is close
    // to invisible on its own and only reads behind level-ups and widget wells.

    static var auroraPink: Color { S.glow }
    static var auroraCyan: Color { S.glow }

    static func auroraOpacity(_ darkValue: Double) -> Color {
        S.glow.opacity(min(darkValue, 1) * 0.35)
    }

    /// True when the trait collection at render time is dark. Useful inside
    /// `Canvas` closures, which paint with concrete colours.
    @MainActor
    static var isDark: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
    }

    // MARK: Type
    //
    // Forwards to the SIL type roles. The old "SIL FONT" setting swapped every
    // role for the bundled Good Times display face — a game face that the new
    // language has no use for — so it no longer affects body or label text.

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        S.mono(size, weight)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        S.text(size, weight)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        S.display(size, weight)
    }
}

// MARK: - HSL helper for goal sigil hues

extension Color {
    static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double, opacity: Double = 1) -> Color {
        let s = saturation / 100
        let l = lightness / 100
        let c = (1 - abs(2 * l - 1)) * s
        let hPrime = (hue.truncatingRemainder(dividingBy: 360)) / 60
        let x = c * (1 - abs(hPrime.truncatingRemainder(dividingBy: 2) - 1))
        let (r1, g1, b1): (Double, Double, Double)
        switch hPrime {
        case 0..<1: (r1, g1, b1) = (c, x, 0)
        case 1..<2: (r1, g1, b1) = (x, c, 0)
        case 2..<3: (r1, g1, b1) = (0, c, x)
        case 3..<4: (r1, g1, b1) = (0, x, c)
        case 4..<5: (r1, g1, b1) = (x, 0, c)
        case 5..<6: (r1, g1, b1) = (c, 0, x)
        default:    (r1, g1, b1) = (0, 0, 0)
        }
        let m = l - c / 2
        return Color(red: r1 + m, green: g1 + m, blue: b1 + m, opacity: opacity)
    }
}
