//
//  SILComponents.swift
//  SIL
//
//  The SIL 2.0 component library, built from `SIL Prototype.dc.html`.
//
//  Everything here is monochrome by default. The accent appears on exactly
//  three things: the primary call to action, live state, and the one number a
//  screen wants you to look at. Emphasis otherwise comes from size, weight and
//  whitespace.
//

import SwiftUI

// MARK: - Screen scaffold

/// Standard scrolling screen: 62pt of head room, 20pt gutters, and enough
/// bottom padding to clear the floating tab bar.
struct SILScreen<Content: View>: View {
    var topPadding: CGFloat = S.Space.screenTop
    var spacing: CGFloat = S.Space.stack
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            S.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, S.Space.screenH)
                .padding(.top, topPadding)
                .padding(.bottom, S.Space.screenBottom)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Header

/// Eyebrow + big title on the left, round controls on the right.
struct SILHeader<Trailing: View>: View {
    var eyebrow: String?
    var title: String
    @ViewBuilder var trailing: () -> Trailing

    init(eyebrow: String? = nil, title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                if let eyebrow {
                    Text(eyebrow).silEyebrow()
                }
                Text(title).silTitle()
            }
            Spacer(minLength: 12)
            HStack(spacing: 10) { trailing() }
        }
        .padding(.top, 6)
    }
}

extension SILHeader where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String) {
        self.init(eyebrow: eyebrow, title: title) { EmptyView() }
    }
}

// MARK: - Card

/// The elevated surface every screen is built from: 28pt corners, a hairline
/// border, the diagonal card gradient and one soft shadow.
struct SILCard<Content: View>: View {
    var radius: CGFloat = S.R.card
    var padding: CGFloat = 20
    var flat: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                ZStack {
                    if flat {
                        shape.fill(S.card)
                    } else {
                        shape.fill(S.cardGrad)
                    }
                    shape.strokeBorder(S.line, lineWidth: 1)
                }
                .compositingGroup()
                .shadow(
                    color: flat ? .clear : S.shadowColor.opacity(0.35),
                    radius: flat ? 0 : S.shadowRadius,
                    x: 0,
                    y: flat ? 0 : S.shadowY
                )
            }
    }
}

// MARK: - Buttons

/// 46pt circular icon button — back, add, settings.
struct SILRoundButton: View {
    var systemImage: String?
    var label: String?
    var size: CGFloat = 46
    var filled: Bool = false
    var action: () -> Void

    @ViewBuilder private var glyph: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .regular))
        } else if let label {
            Text(label).font(S.text(size * 0.37, .medium))
        }
    }

    var body: some View {
        Button(action: action) {
            glyph
                .foregroundStyle(filled ? S.onInv : S.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(filled ? S.inv : S.card2))
        }
        .buttonStyle(.plain)
    }
}

/// Full-width primary action. `accented` paints it with the accent; otherwise
/// it uses the inverted ink fill the prototype uses for "done" actions.
struct SILPrimaryButton: View {
    var title: String
    var accented: Bool = false
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(S.text(17, .semibold))
                .foregroundStyle(accented ? S.onAccent : S.onInv)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Capsule().fill(accented ? S.accent : S.inv))
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
    }
}

/// Outlined secondary action — "End early", "Undo".
struct SILGhostButton: View {
    var title: String
    var height: CGFloat = 46
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(S.text(15, .medium))
                .foregroundStyle(S.ink)
                .padding(.horizontal, 20)
                .frame(height: height)
                .overlay(Capsule().strokeBorder(S.line2, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pills

/// Filter chip. Selected chips invert; the rest sit on `card2`.
struct SILPill: View {
    var label: String
    var selected: Bool
    var height: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(S.text(height > 38 ? 15 : 14, .medium))
                .foregroundStyle(selected ? S.onInv : S.ink2)
                .padding(.horizontal, height > 38 ? 18 : 16)
                .frame(height: height)
                .background(Capsule().fill(selected ? S.inv : S.card2))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Inset segmented control — the two- or three-way switch inside a card.
struct SILSegmented<Value: Hashable>: View {
    var options: [(value: Value, label: String)]
    @Binding var selection: Value
    var height: CGFloat = 36
    /// `true` spreads the segments across the available width. `false` sizes
    /// each one to its label, for a control sitting in a toolbar or a header
    /// where there is no width to divide up.
    var fills: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let on = option.value == selection
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(S.text(height > 34 ? 14 : 13, .medium))
                        .foregroundStyle(on ? S.ink : S.ink2)
                        .fixedSize(horizontal: !fills, vertical: false)
                        .padding(.horizontal, fills ? 0 : 16)
                        .frame(maxWidth: fills ? .infinity : nil)
                        .frame(height: height)
                        .background(
                            RoundedRectangle(cornerRadius: height / 2 - 1, style: .continuous)
                                .fill(on ? S.bg2 : .clear)
                                .shadow(color: on ? S.shadowColor.opacity(0.18) : .clear, radius: 4, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: height / 2 + 2, style: .continuous).fill(S.card2))
    }
}

// MARK: - Toggle

/// 50×30 switch. Off is `card2`, on is the accent — the only place a plain
/// settings row carries colour.
struct SILToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                withAnimation(.easeOut(duration: 0.2)) { configuration.isOn.toggle() }
            } label: {
                Capsule()
                    .fill(configuration.isOn ? S.accent : S.card2)
                    .frame(width: 50, height: 30)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
                            .padding(3)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Rings

/// Progress ring with a numeral in the middle. The track is a hairline; the
/// progress stroke is ink, never a gradient.
struct SILRing<Center: View>: View {
    var progress: Double
    var size: CGFloat
    var lineWidth: CGFloat = 2.5
    var tint: Color = S.ink
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(S.line2, lineWidth: lineWidth)
            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
            center()
        }
        .frame(width: size, height: size)
    }
}

extension SILRing where Center == EmptyView {
    init(progress: Double, size: CGFloat, lineWidth: CGFloat = 2.5, tint: Color = S.ink) {
        self.init(progress: progress, size: size, lineWidth: lineWidth, tint: tint) { EmptyView() }
    }
}

/// The habit tick: a 50pt ring with the attribute glyph inside, which fills
/// solid once the habit is done.
struct SILHabitTick: View {
    var progress: Double
    var done: Bool
    var attribute: SILAttribute
    var size: CGFloat = 50
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(S.card2)
                if done {
                    Circle().fill(S.inv)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundStyle(S.onInv)
                } else {
                    SILRing(progress: progress, size: size - 6, lineWidth: 2)
                    attribute.glyph
                        .frame(width: 12, height: 12)
                        .foregroundStyle(S.ink)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bars

/// 3pt hairline progress bar — level, attribute levels.
struct SILBar: View {
    var progress: Double
    var height: CGFloat = 3
    var tint: Color = S.ink

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(S.line2)
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(.easeOut(duration: 0.6), value: progress)
            }
        }
        .frame(height: height)
    }
}

/// The tick grid used for long goals: N narrow bars, filled left to right.
/// Reads as a measuring stick rather than a health bar.
struct SILTickBar: View {
    var progress: Double
    var count: Int = 36
    var height: CGFloat = 16
    var spacing: CGFloat = 3

    var body: some View {
        let filled = Int((Double(count) * max(0, min(1, progress))).rounded())
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < filled ? S.ink : S.line2)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.4), value: filled)
    }
}

/// Small vertical bars — the momentum sparkline on the You tab.
struct SILMeterBars: View {
    var values: [Double]
    var height: CGFloat = 40

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 1)
                    .fill(S.ink.opacity(0.25 + 0.75 * max(0, min(1, value))))
                    // A floor of 3pt so an empty history reads as a row of
                    // ticks rather than a dashed rule.
                    .frame(height: max(3, height * max(0.05, min(1, value))))
            }
        }
        .frame(height: height, alignment: .bottom)
    }
}

// MARK: - Stat strip

/// A hairline grid of label/value cells — the Start / Now / Target / Pace row
/// on a goal, and the three-up summary on a completion card.
struct SILStatStrip: View {
    struct Cell: Identifiable {
        let id = UUID()
        var label: String
        var value: String
        var accented: Bool = false

        init(_ label: String, _ value: String, accented: Bool = false) {
            self.label = label
            self.value = value
            self.accented = accented
        }
    }

    var cells: [Cell]
    /// `true` puts the value above the label, as the completion card does.
    var valueFirst: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.element.id) { index, cell in
                VStack(alignment: .leading, spacing: 7) {
                    if valueFirst {
                        value(cell)
                        Text(cell.label).silEyebrow(8.5)
                    } else {
                        Text(cell.label).silEyebrow(8.5)
                        value(cell)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(valueFirst ? 12 : 10)
                .overlay(alignment: .leading) {
                    if index > 0 {
                        Rectangle().fill(S.line2).frame(width: 1)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: S.R.frame, style: .continuous)
                .strokeBorder(S.line2, lineWidth: 1)
        )
    }

    @ViewBuilder private func value(_ cell: Cell) -> some View {
        if valueFirst {
            Text(cell.value)
                .font(S.display(22, .medium))
                .tracking(S.displayTracking(22))
                .foregroundStyle(cell.accented ? S.accentInk : S.ink)
        } else {
            Text(cell.value)
                .font(S.mono(12))
                .foregroundStyle(cell.accented ? S.accentInk : S.ink)
                .lineLimit(1)
        }
    }
}

// MARK: - Attributes

/// SIL 2.0 merges the six RPG stats into four attributes, told apart by glyph
/// rather than by hue: square, circle, triangle, diamond.
enum SILAttribute: String, CaseIterable, Identifiable {
    case body, mind, energy, spirit

    var id: String { rawValue }

    var name: String {
        switch self {
        case .body:   return "Body"
        case .mind:   return "Mind"
        case .energy: return "Energy"
        case .spirit: return "Spirit"
        }
    }

    @ViewBuilder var glyph: some View {
        switch self {
        case .body:
            Rectangle()
        case .mind:
            Circle()
        case .energy:
            SILTriangle()
        case .spirit:
            SILDiamond()
        }
    }
}

struct SILTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SILDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Attribute chip used in the Focus picker and the habit form.
struct SILAttributeChip: View {
    var attribute: SILAttribute
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                attribute.glyph
                    .frame(width: 10, height: 10)
                Text(attribute.name)
                    .font(S.text(14, .medium))
            }
            .foregroundStyle(selected ? S.onInv : S.ink2)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(selected ? S.inv : S.card2))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rows

/// A habit in a list: tick on the left, title and subtitle, points on the right.
struct SILHabitRow: View {
    var title: String
    var subtitle: String
    var points: String?
    var progress: Double
    var done: Bool
    var attribute: SILAttribute
    var onToggle: () -> Void
    var onOpen: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            SILHabitTick(progress: progress, done: done, attribute: attribute, action: onToggle)

            Button {
                onOpen?()
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(S.text(17, .medium))
                        .tracking(-0.17)
                        .foregroundStyle(done ? S.ink3 : S.ink)
                        .strikethrough(done, color: S.ink3)
                    Text(subtitle)
                        .font(S.text(14))
                        .foregroundStyle(S.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(onOpen == nil)

            if let points {
                Text(points).silData(10, color: S.ink3)
            }
        }
        .padding(.vertical, 9)
    }
}

/// A settings row: label, optional detail line, and a trailing control.
struct SILListRow<Trailing: View>: View {
    var title: String
    var detail: String?
    var showsDivider: Bool = true
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(S.text(16)).foregroundStyle(S.ink)
                if let detail {
                    Text(detail).font(S.text(13)).foregroundStyle(S.ink2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .frame(minHeight: detail == nil ? 58 : 66)
        .overlay(alignment: .top) {
            if showsDivider {
                Rectangle().fill(S.line).frame(height: 1)
            }
        }
    }
}

/// Groups `SILListRow`s into the bordered card the prototype's settings use.
struct SILListCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: S.R.small + 2, style: .continuous)
                    .fill(S.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: S.R.small + 2, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Tab bar

/// The floating shell: a blurred pill holding four tabs, plus a round compose
/// button beside it. The selected tab grows and reveals its label.
struct SILTabBar: View {
    @Binding var selection: SILTab
    var onCompose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(SILTab.allCases) { tab in
                    let on = tab == selection
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selection = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 20, weight: .regular))
                            if on {
                                Text(tab.title)
                                    .font(S.mono(10, .medium))
                                    .tracking(0.6)
                                    .textCase(.uppercase)
                                    .fixedSize()
                            }
                        }
                        .foregroundStyle(on ? S.onInv : S.ink2)
                        // The selected pill hugs its icon and label; the rest
                        // share what is left evenly.
                        .padding(.horizontal, on ? 18 : 0)
                        .frame(maxWidth: on ? nil : .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(on ? S.inv : .clear))
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: on, vertical: false)
                }
            }
            .padding(6)
            .frame(height: 64)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(S.glass))
                    .overlay(Capsule().strokeBorder(S.line, lineWidth: 1))
            }
            .compositingGroup()
            .shadow(color: S.shadowColor.opacity(0.5), radius: S.shadowRadius, y: S.shadowY)

            SILRoundButton(systemImage: "plus", size: 64, filled: true, action: onCompose)
                .shadow(color: S.shadowColor.opacity(0.5), radius: S.shadowRadius, y: S.shadowY)
        }
        .padding(.horizontal, 14)
    }
}

/// The four destinations of SIL 2.0.
enum SILTab: String, CaseIterable, Identifiable {
    case today, goals, focus, you

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .goals: return "Goals"
        case .focus: return "Focus"
        case .you:   return "You"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "square.grid.2x2"
        case .goals: return "target"
        case .focus: return "timer"
        case .you:   return "person"
        }
    }
}

// MARK: - Toast

/// Inverted capsule that drops in under the status bar.
struct SILToast: View {
    var message: String

    var body: some View {
        Text(message)
            .font(S.text(14, .medium))
            .foregroundStyle(S.onInv)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Capsule().fill(S.inv))
            .shadow(color: S.shadowColor.opacity(0.5), radius: 20, y: 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Previews

#Preview("Components") {
    @Previewable @State var tab: SILTab = .today
    @Previewable @State var on = true

    ZStack(alignment: .bottom) {
        SILScreen {
            SILHeader(eyebrow: "Wed 17 Oct", title: "Today") {
                SILRoundButton(systemImage: "slider.horizontal.3") {}
            }

            SILCard {
                VStack(alignment: .leading, spacing: 16) {
                    SILRing(progress: 0.72, size: 76) {
                        Text("72").silNumeral(26)
                    }
                    Text("Momentum").font(S.text(18, .medium)).foregroundStyle(S.ink)
                    SILBar(progress: 0.46)
                    SILTickBar(progress: 0.62)
                }
            }

            SILStatStrip(cells: [
                .init("Start", "92.4"), .init("Now", "88.1", accented: true),
                .init("Target", "82.0"), .init("Pace/wk", "0.4")
            ])

            SILHabitRow(title: "Read 20 pages", subtitle: "Daily · manual", points: "+12",
                        progress: 0.4, done: false, attribute: .mind, onToggle: {}, onOpen: {})

            HStack(spacing: 6) {
                ForEach(SILAttribute.allCases) { attribute in
                    SILAttributeChip(attribute: attribute, selected: attribute == .mind) {}
                }
            }

            SILListCard {
                SILListRow(title: "Haptics", showsDivider: false) {
                    Toggle("", isOn: $on).labelsHidden().toggleStyle(SILToggleStyle())
                }
            }

            SILPrimaryButton(title: "Start focus", accented: true) {}
        }
        SILTabBar(selection: $tab) {}
            .padding(.bottom, 26)
    }
}
