//
//  SystemTheme.swift
//  SIL
//
//  Legacy token table. The screens outside Glasswork were written against the
//  old neon "System" palette; SIL 2.0 replaces it with the quiet language in
//  `SILTheme.swift`. Every token below now forwards to its closest SIL
//  equivalent, so those screens pick up the new surface without a rewrite.
//
//  New code should use `S` directly. This shim shrinks as screens are rebuilt.
//

import SwiftUI
import UIKit
import CoreText

// MARK: - System Theme

/// The visual identity of SIL — quiet, typographic, one accent.
struct SystemTheme {

    // MARK: - Primary Colors
    //
    // SIL has a single accent instead of a blue/purple/cyan family. The old
    // names are kept so existing call sites compile; they all resolve to the
    // accent or to ink.

    /// The one accent. Primary actions, live state, selected chips.
    static var primaryBlue: Color { S.accent }
    /// Accent as text or a thin stroke.
    static var primaryPurple: Color { S.accentInk }
    static var secondaryPurple: Color { S.accentInk }
    static var accentCyan: Color { S.accentInk }

    /// Warnings read as a desaturated clay, never as alarm red.
    static var warningOrange: Color { S.ink2 }
    static var criticalRed: Color { S.warn }

    /// Success and currency are not colours in SIL — they are just ink.
    static var successGreen: Color { S.ink }
    static var goldColor: Color { S.ink }

    // MARK: - Background Colors

    static var backgroundPrimary: Color { S.bg }
    static var backgroundSecondary: Color { S.card }
    static var backgroundTertiary: Color { S.card2 }
    static var backgroundElevated: Color { S.bg2 }

    // MARK: - Text Colors

    static var textPrimary: Color { S.ink }
    static var textSecondary: Color { S.ink2 }
    static var textTertiary: Color { S.ink3 }
    static var textSystem: Color { S.accentInk }

    // MARK: - Attribute Colors
    //
    // SIL 2.0 merges the six stats into four attributes (Body, Mind, Energy,
    // Spirit) and distinguishes them by glyph, not by hue.

    static var statStrength: Color { S.ink }
    static var statIntelligence: Color { S.ink }
    static var statAgility: Color { S.ink }
    static var statVitality: Color { S.ink }
    static var statWillpower: Color { S.ink }
    static var statSpirit: Color { S.ink }

    // MARK: - Gradients
    //
    // Flat ramps. SIL draws progress with ink on a hairline track, not with
    // two-stop neon fills.

    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [S.accent, S.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var systemGlow: RadialGradient {
        RadialGradient(colors: [S.glow, .clear], center: .center, startRadius: 0, endRadius: 150)
    }

    static var xpGradient: LinearGradient {
        LinearGradient(colors: [S.ink, S.ink], startPoint: .leading, endPoint: .trailing)
    }

    static var hpGradient: LinearGradient {
        LinearGradient(colors: [S.ink, S.ink], startPoint: .leading, endPoint: .trailing)
    }

    static var goldGradient: LinearGradient {
        LinearGradient(colors: [S.ink, S.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Shadows

    static var glowShadow: Color { S.glow }
    static var cardShadow: Color { S.shadowColor }

    // MARK: - Border Colors

    static var borderPrimary: Color { S.line2 }
    static var borderSecondary: Color { S.line }

    // MARK: - Animation Durations

    static let animationFast: Double = 0.2
    static let animationNormal: Double = 0.3
    static let animationSlow: Double = 0.5
    static let animationVeryLong: Double = 1.0
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }

        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - Typography

/// System fonts - Monospace for stats, Sans-serif for content
/// Type roles for the screens that still read through this table. Everything
/// forwards to the SIL roles in `S`; the bundled Good Times display face the
/// old "SIL FONT" switch used is gone with the game styling.
struct SystemTypography {

    static func ensureCustomFontRegistered() {}

    static func uiFont(
        _ size: CGFloat,
        weight: UIFont.Weight = .regular,
        design: UIFontDescriptor.SystemDesign = .default
    ) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }

    // MARK: - Monospace (data and numerals)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        S.mono(size, weight)
    }

    static var statLarge: Font { mono(48, weight: .bold) }
    static var statMedium: Font { mono(32, weight: .bold) }
    static var statSmall: Font { mono(24, weight: .semibold) }
    static var statTiny: Font { mono(14, weight: .medium) }

    static var timer: Font { mono(64, weight: .ultraLight) }
    static var timerSmall: Font { mono(32, weight: .light) }

    static var xpCounter: Font { mono(18, weight: .bold) }
    static var goldCounter: Font { mono(16, weight: .semibold) }

    // MARK: - Sans-serif (content)

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        S.text(size, weight)
    }

    static var titleLarge: Font { sans(34, weight: .bold) }
    static var titleMedium: Font { sans(28, weight: .bold) }
    static var titleSmall: Font { sans(22, weight: .semibold) }

    static var headline: Font { sans(17, weight: .semibold) }
    static var body: Font { sans(17, weight: .regular) }
    static var bodySmall: Font { sans(15, weight: .regular) }

    static var caption: Font { sans(13, weight: .regular) }
    static var captionSmall: Font { sans(11, weight: .regular) }

    // MARK: - System messages

    static var systemMessage: Font { mono(14, weight: .medium) }
    static var systemTitle: Font { mono(18, weight: .bold) }
    static var systemAlert: Font { mono(16, weight: .semibold) }
}

// MARK: - Spacing

struct SystemSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct SystemRadius {
    /// SIL corners are soft. The old 4/8/12/16 ramp read as a HUD; these
    /// values match the prototype's inputs, tiles, cards and sheets.
    static let small: CGFloat = 9
    static let medium: CGFloat = 16
    static let large: CGFloat = S.R.small
    static let xlarge: CGFloat = S.R.card
    static let full: CGFloat = 999
}

// MARK: - View Modifiers

/// Glow effect modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius / 2, x: 0, y: 0)
            .shadow(color: color, radius: radius, x: 0, y: 0)
    }
}

/// System card style modifier
struct SystemCardModifier: ViewModifier {
    let isElevated: Bool

    func body(content: Content) -> some View {
        content
            .background(isElevated ? SystemTheme.backgroundElevated : SystemTheme.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SystemRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: SystemRadius.large)
                    .stroke(SystemTheme.borderPrimary, lineWidth: 1)
            )
    }
}

/// Holographic border effect
struct HolographicBorderModifier: ViewModifier {
    @State private var animationPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: SystemRadius.large)
                    .stroke(
                        AngularGradient(
                            colors: [
                                SystemTheme.primaryBlue,
                                SystemTheme.primaryPurple,
                                SystemTheme.accentCyan,
                                SystemTheme.primaryBlue
                            ],
                            center: .center,
                            startAngle: .degrees(animationPhase),
                            endAngle: .degrees(animationPhase + 360)
                        ),
                        lineWidth: 2
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationPhase = 360
                }
            }
    }
}

// MARK: - View Extensions

extension View {

    /// Apply a glow effect
    func glow(color: Color = SystemTheme.primaryBlue, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    /// Apply system card styling
    func systemCard(elevated: Bool = false) -> some View {
        modifier(SystemCardModifier(isElevated: elevated))
    }

    /// Apply holographic animated border
    func holographicBorder() -> some View {
        modifier(HolographicBorderModifier())
    }

    /// Apply system background
    func systemBackground() -> some View {
        self.background(SystemTheme.backgroundPrimary)
    }
}

// MARK: - Preview Support

#Preview("System Theme Colors") {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                Text("Primary Colors")
                    .font(SystemTypography.headline)
                    .foregroundStyle(SystemTheme.textPrimary)

                HStack(spacing: 10) {
                    colorSwatch("Blue", SystemTheme.primaryBlue)
                    colorSwatch("Purple", SystemTheme.primaryPurple)
                    colorSwatch("Cyan", SystemTheme.accentCyan)
                }
            }

            Group {
                Text("Stat Colors")
                    .font(SystemTypography.headline)
                    .foregroundStyle(SystemTheme.textPrimary)

                HStack(spacing: 10) {
                    colorSwatch("STR", SystemTheme.statStrength)
                    colorSwatch("INT", SystemTheme.statIntelligence)
                    colorSwatch("AGI", SystemTheme.statAgility)
                }
                HStack(spacing: 10) {
                    colorSwatch("VIT", SystemTheme.statVitality)
                    colorSwatch("WIL", SystemTheme.statWillpower)
                    colorSwatch("SPI", SystemTheme.statSpirit)
                }
            }

            Group {
                Text("Typography")
                    .font(SystemTypography.headline)
                    .foregroundStyle(SystemTheme.textPrimary)

                Text("99")
                    .font(SystemTypography.statLarge)
                    .foregroundStyle(SystemTheme.primaryBlue)

                Text("SYSTEM MESSAGE")
                    .font(SystemTypography.systemMessage)
                    .foregroundStyle(SystemTheme.textSystem)
            }
        }
        .padding()
    }
    .background(SystemTheme.backgroundPrimary)
}

@ViewBuilder
private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 60)
            .glow(color: color, radius: 5)

        Text(name)
            .font(SystemTypography.captionSmall)
            .foregroundStyle(SystemTheme.textSecondary)
    }
}
