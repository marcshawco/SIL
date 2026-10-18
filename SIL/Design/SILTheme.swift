//
//  SILTheme.swift
//  SIL
//
//  The SIL 2.0 design language, ported from the `SIL Prototype` design file.
//
//  Quiet, typographic, near-monochrome. One accent, used sparingly, for the
//  things the system is telling you about — never for decoration. Surfaces are
//  soft-cornered cards on a near-black (or near-paper) ground; emphasis comes
//  from size and weight, not from colour or glow.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Accent

/// The single accent colour. User-selectable; violet is the default.
enum SILAccent: String, CaseIterable, Identifiable {
    case violet, orange, mono

    var id: String { rawValue }

    var label: String {
        switch self {
        case .violet: return "Violet"
        case .orange: return "Orange"
        case .mono:   return "Mono"
        }
    }

    /// (dark, light) hex pairs straight from the prototype's `A` table.
    fileprivate var ramp: (dark: Ramp, light: Ramp) {
        switch self {
        case .violet:
            return (Ramp(accent: "5B3CFF", accentInk: "B0A3FF", onAccent: "FFFFFF", glow: ("5B3CFF", 0.38)),
                    Ramp(accent: "4A2BEF", accentInk: "3F22D4", onAccent: "FFFFFF", glow: ("4A2BEF", 0.16)))
        case .orange:
            return (Ramp(accent: "FF6A2B", accentInk: "FF9A6B", onAccent: "0A0A0C", glow: ("FF6A2B", 0.34)),
                    Ramp(accent: "F2551A", accentInk: "B83C0B", onAccent: "0E0E10", glow: ("F2551A", 0.16)))
        case .mono:
            return (Ramp(accent: "F4F4F5", accentInk: "F4F4F5", onAccent: "0A0A0C", glow: ("FFFFFF", 0.12)),
                    Ramp(accent: "0E0E10", accentInk: "0E0E10", onAccent: "FFFFFF", glow: ("000000", 0.07)))
        }
    }

    fileprivate struct Ramp {
        let accent: String
        let accentInk: String
        let onAccent: String
        let glow: (hex: String, alpha: Double)
    }
}

/// Observable holder so the accent can be changed from Settings and picked up
/// everywhere without threading an environment value through every view.
final class SILAppearance: ObservableObject {
    static let shared = SILAppearance()

    @AppStorage("sil.accent") var accentRaw: String = SILAccent.violet.rawValue {
        willSet { objectWillChange.send() }
    }

    var accent: SILAccent {
        get { SILAccent(rawValue: accentRaw) ?? .violet }
        set { accentRaw = newValue.rawValue }
    }

    private init() {}
}

// MARK: - Tokens

/// `S` is the SIL design system namespace. Every colour resolves through a
/// trait closure, so a single token is correct in both light and dark and no
/// screen ever needs to force a `colorScheme`.
enum S {

    // MARK: Helpers

    static func hex(_ hex: String, _ alpha: Double = 1) -> Color {
        Color(uiColor: UIColor(silHex: hex).withAlphaComponent(alpha))
    }

    /// Adaptive hex token — `light` in light mode, `dark` in dark mode.
    static func adaptive(light: String, dark: String, opacity: Double = 1) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(silHex: traits.userInterfaceStyle == .dark ? dark : light)
                .withAlphaComponent(opacity)
        })
    }

    /// Adaptive monochrome — white channel in dark, black channel in light.
    static func adaptiveMono(lightOpacity: Double, darkOpacity: Double) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: darkOpacity)
                : UIColor(white: 0, alpha: lightOpacity)
        })
    }

    // MARK: Surfaces

    /// Page ground.
    static let bg       = adaptive(light: "EDEDEB", dark: "0A0A0C")
    /// Raised ground — sheets, overlays, widget wells.
    static let bg2      = adaptive(light: "F6F6F5", dark: "111114")
    /// Flat card.
    static let card     = adaptive(light: "F8F8F7", dark: "16161A")
    /// Controls, pills, avatar wells — one step up from `card`.
    static let card2    = adaptive(light: "E1E1DF", dark: "222227")
    /// Unselected chips.
    static let chip     = adaptive(light: "D9D9D7", dark: "2B2B31")

    /// Gradient fill used by every elevated card in the prototype.
    static var cardGrad: LinearGradient {
        LinearGradient(
            colors: [
                adaptive(light: "FDFDFC", dark: "1D1D22"),
                adaptive(light: "F2F2F1", dark: "141417")
            ],
            startPoint: .init(x: 0.12, y: 0),
            endPoint: .init(x: 0.88, y: 1)
        )
    }

    // MARK: Lines

    static let line     = adaptiveMono(lightOpacity: 0.06, darkOpacity: 0.07)
    static let line2    = adaptiveMono(lightOpacity: 0.13, darkOpacity: 0.14)
    static let dot      = adaptiveMono(lightOpacity: 0.12, darkOpacity: 0.13)

    // MARK: Ink

    /// Headlines, numerals, anything that has to be read first.
    static let ink      = adaptive(light: "0E0E10", dark: "F4F4F5")
    /// Body and secondary copy.
    static let ink2     = adaptive(light: "52525A", dark: "A6A6AE")
    /// Labels, eyebrows, mono captions.
    static let ink3     = adaptive(light: "66666E", dark: "84848D")

    /// Inverted fill — the primary button and the "done" state.
    static let inv      = adaptive(light: "0E0E10", dark: "F4F4F5")
    /// Content on top of `inv`.
    static let onInv    = adaptive(light: "FFFFFF", dark: "0A0A0C")

    // MARK: Scrims and glass

    static let glass    = adaptive(light: "F8F8F7", dark: "1A1A1E", opacity: 0.78)
    static let scrim    = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.62)
            : UIColor(red: 20/255, green: 20/255, blue: 22/255, alpha: 0.32)
    })

    // MARK: Accent

    private static var ramp: SILAccent.Ramp {
        SILAppearance.shared.accent.ramp.dark
    }

    private static func accentColor(_ keyPath: KeyPath<SILAccent.Ramp, String>) -> Color {
        let pair = SILAppearance.shared.accent.ramp
        return Color(uiColor: UIColor { traits in
            let ramp = traits.userInterfaceStyle == .dark ? pair.dark : pair.light
            return UIColor(silHex: ramp[keyPath: keyPath])
        })
    }

    /// Filled accent — primary call to action, live indicators.
    static var accent: Color { accentColor(\.accent) }
    /// Accent as text or a thin stroke. Readable on both grounds.
    static var accentInk: Color { accentColor(\.accentInk) }
    /// Content on top of `accent`.
    static var onAccent: Color { accentColor(\.onAccent) }

    /// Soft radial wash behind level-ups and widget wells.
    static var glow: Color {
        let pair = SILAppearance.shared.accent.ramp
        return Color(uiColor: UIColor { traits in
            let ramp = traits.userInterfaceStyle == .dark ? pair.dark : pair.light
            return UIColor(silHex: ramp.glow.hex).withAlphaComponent(ramp.glow.alpha)
        })
    }

    // MARK: Semantic

    /// Used only where a state genuinely needs to read as a loss — momentum
    /// drain and recalibration. Deliberately desaturated.
    static let warn     = adaptive(light: "B3401F", dark: "E2714E")

    // MARK: Elevation

    /// The one shadow in the system. Cards, the tab bar, the compose button.
    static var shadowColor: Color { adaptiveMono(lightOpacity: 0.12, darkOpacity: 0.55) }
    static let shadowRadius: CGFloat = 30
    static let shadowY: CGFloat = 18

    /// Top inner highlight that gives cards their lift.
    static var highlight: Color { adaptiveMono(lightOpacity: 0.90, darkOpacity: 0.05) }

    // MARK: Geometry

    enum R {
        /// Big cards, sheets' content blocks.
        static let card: CGFloat   = 28
        /// Small cards, inputs, milestone tiles.
        static let small: CGFloat  = 22
        /// Bottom sheet.
        static let sheet: CGFloat  = 34
        /// Overlay cards.
        static let overlay: CGFloat = 38
        /// Dense data frames (stat strips).
        static let frame: CGFloat  = 4
    }

    /// Standard durations. SIL animates to show a value changed, never to
    /// decorate.
    enum Motion {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }

    enum Space {
        static let screenH: CGFloat = 20
        static let screenTop: CGFloat = 62
        /// Clears the floating tab bar.
        static let screenBottom: CGFloat = 128
        static let stack: CGFloat = 14
        static let section: CGFloat = 18
    }

    // MARK: Type
    //
    // The prototype sets Schibsted Grotesk for text and Martian Mono for
    // labels. Those files are not bundled, so each role falls back to the
    // closest system face: SF Pro (rounded-free, tight tracking) for text and
    // SF Mono for labels. `register()` picks the real faces up automatically
    // if they are ever added to the bundle.

    private static let sansName = "SchibstedGrotesk-Regular"
    private static let monoName = "MartianMono-Regular"

    private static var hasSans: Bool { UIFont(name: sansName, size: 12) != nil }
    private static var hasMono: Bool { UIFont(name: monoName, size: 12) != nil }

    /// Display numerals and screen titles. Tight, heavy, never uppercase.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        hasSans
            ? .custom(sansName, size: size).weight(weight)
            : .system(size: size, weight: weight, design: .default)
    }

    /// Body and control text.
    static func text(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        hasSans
            ? .custom(sansName, size: size).weight(weight)
            : .system(size: size, weight: weight, design: .default)
    }

    /// Eyebrows, captions and data labels. Always paired with `.monoTracking()`.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        hasMono
            ? .custom(monoName, size: size).weight(weight)
            : .system(size: size, weight: weight, design: .monospaced)
    }

    /// The letter-spacing the prototype applies to its display sizes.
    static func displayTracking(_ size: CGFloat) -> CGFloat {
        switch size {
        case ..<24:  return size * -0.02
        case ..<40:  return size * -0.035
        case ..<70:  return size * -0.05
        default:     return size * -0.06
        }
    }
}

// MARK: - Text roles

extension View {
    /// Uppercase mono eyebrow: the small label above a title or beside a value.
    func silEyebrow(_ size: CGFloat = 9.5) -> some View {
        self.font(S.mono(size, .regular))
            .tracking(size * 0.06)
            .textCase(.uppercase)
            .foregroundStyle(S.ink3)
    }

    /// Mono data label, not uppercased — counts, credit totals, timestamps.
    func silData(_ size: CGFloat = 11, color: Color = S.ink2) -> some View {
        self.font(S.mono(size, .regular))
            .tracking(size * 0.02)
            .foregroundStyle(color)
    }

    /// Large screen title — "Today", "Goals", "Settings".
    func silTitle(_ size: CGFloat = 38) -> some View {
        self.font(S.display(size, .semibold))
            .tracking(S.displayTracking(size))
            .foregroundStyle(S.ink)
    }

    /// Big numeral — level, goal value, focus clock.
    func silNumeral(_ size: CGFloat) -> some View {
        self.font(S.display(size, .medium))
            .tracking(S.displayTracking(size))
            .monospacedDigit()
            .foregroundStyle(S.ink)
    }
}

// MARK: - UIColor hex

private extension UIColor {
    convenience init(silHex: String) {
        let cleaned = silHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >>  8) & 0xFF) / 255,
            blue:  CGFloat( value        & 0xFF) / 255,
            alpha: 1
        )
    }
}
