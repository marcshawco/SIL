//
//  SILMark.swift
//  SIL
//
//  The SIL mark — "Three strokes". S, I and L drawn as rising bars, the last
//  turning into an L. Vector so it stays crisp at any size and takes whatever
//  foreground colour it is given.
//
//  Geometry is taken from `sil-logo-pack/mark/svg`: path `M13 52V38M27 52V25
//  M41 12V49H54` at stroke-width 6 inside viewBox `10 12 44 40`, resolved here
//  into filled rectangles so the mitred corner of the L is exact.
//
//  House rules from the logo pack: square ends, never rounded, outlined,
//  rotated, or recoloured stroke by stroke.
//

import SwiftUI

/// The bare mark, sized to fill its frame while keeping the pack's 44:40 ratio.
struct SILMarkShape: Shape {
    /// Source viewBox: x 10…54, y 12…52.
    private static let box = CGRect(x: 10, y: 12, width: 44, height: 40)

    func path(in rect: CGRect) -> Path {
        let box = Self.box
        let scale = min(rect.width / box.width, rect.height / box.height)
        let drawn = CGSize(width: box.width * scale, height: box.height * scale)
        let originX = rect.minX + (rect.width - drawn.width) / 2
        let originY = rect.minY + (rect.height - drawn.height) / 2

        func bar(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
            CGRect(
                x: originX + (x0 - box.minX) * scale,
                y: originY + (y0 - box.minY) * scale,
                width: (x1 - x0) * scale,
                height: (y1 - y0) * scale
            )
        }

        var path = Path()
        // S — the short bar.
        path.addRect(bar(10, 38, 16, 52))
        // I — the middle bar.
        path.addRect(bar(24, 25, 30, 52))
        // L — the tall bar and its foot, overlapping to form the mitre.
        path.addRect(bar(38, 12, 44, 52))
        path.addRect(bar(38, 46, 54, 52))
        return path
    }
}

/// The mark on its own, in a single colour.
struct SILMark: View {
    var color: Color = S.ink

    var body: some View {
        SILMarkShape()
            .fill(color)
            .accessibilityHidden(true)
    }
}

/// The mark inside the app-icon tile — a rounded square ground with the mark
/// inset by roughly one stroke width, matching the exported icon art.
struct SILMarkTile: View {
    var size: CGFloat = 64
    var background: Color = S.card2
    var foreground: Color = S.ink

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.234, style: .continuous)
            .fill(background)
            .frame(width: size, height: size)
            .overlay(
                SILMark(color: foreground)
                    .frame(width: size * 0.64, height: size * 0.58)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        SILMark()
            .frame(width: 120, height: 109)
        HStack(spacing: 16) {
            SILMarkTile(size: 72)
            SILMarkTile(size: 72, background: S.hex("EDEDEB"), foreground: S.hex("0A0A0C"))
            SILMarkTile(size: 72, background: S.hex("5B3CFF"), foreground: .white)
        }
    }
    .padding(40)
    .background(S.bg)
}
