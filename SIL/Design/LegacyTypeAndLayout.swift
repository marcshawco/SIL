//
//  LegacyTypeAndLayout.swift
//  SIL
//
//  What survives of the pre-SIL token table: the hex helpers, the type roles
//  that forward to `S`, and the spacing, radius and modifier helpers the
//  remaining older screens still call.
//
//  The colour table is gone — every call site now reads `S` directly.
//

import SwiftUI
import UIKit
import CoreText

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
            .background(isElevated ? S.bg2 : S.card2)
            .clipShape(RoundedRectangle(cornerRadius: SystemRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: SystemRadius.large)
                    .stroke(S.line2, lineWidth: 1)
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
                                S.accent,
                                S.accentInk,
                                S.accentInk,
                                S.accent
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
    func glow(color: Color = S.accent, radius: CGFloat = 10) -> some View {
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
        self.background(S.bg)
    }
}

// MARK: - Preview Support

#Preview("System Theme Colors") {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                Text("Primary Colors")
                    .font(SystemTypography.headline)
                    .foregroundStyle(S.ink)

                HStack(spacing: 10) {
                    colorSwatch("Blue", S.accent)
                    colorSwatch("Purple", S.accentInk)
                    colorSwatch("Cyan", S.accentInk)
                }
            }

            Group {
                Text("Typography")
                    .font(SystemTypography.headline)
                    .foregroundStyle(S.ink)

                Text("99")
                    .font(SystemTypography.statLarge)
                    .foregroundStyle(S.accent)

                Text("Mono label")
                    .font(SystemTypography.systemMessage)
                    .foregroundStyle(S.ink2)
            }
        }
        .padding()
    }
    .background(S.bg)
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
            .foregroundStyle(S.ink2)
    }
}
