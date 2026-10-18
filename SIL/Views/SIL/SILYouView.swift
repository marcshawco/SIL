//
//  SILYouView.swift
//  SIL
//
//  The You tab — what used to be Status plus Shop.
//
//  Who you are and what you've accumulated: level and momentum as paired
//  cards, the four attributes as a radar or a list, half a year of
//  consistency, then rewards, moments and milestones. No rank badges, no
//  "S-Rank Hunter" — a name, a title, and the numbers behind them.
//

import SwiftUI

struct SILYouView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @ObservedObject private var marketplace = MarketplaceManager.shared

    @AppStorage("sil.you.attributeShape") private var showsRadar: Bool = true
    @State private var showSettings = false

    private var player: Player { gameEngine.player }

    var body: some View {
        SILScreen {
            profileHeader

            HStack(spacing: 12) {
                levelCard
                momentumCard
            }

            attributesCard
            consistencyCard
            rewardsSection
            momentsSection
            milestonesSection
        }
        .sheet(isPresented: $showSettings) {
            SILSettingsView()
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(spacing: 14) {
            SILRing(progress: player.progressShare, size: 64, lineWidth: 2, tint: S.accent) {
                Circle()
                    .fill(S.card2)
                    .overlay(
                        Text(String(player.name.prefix(1)).uppercased())
                            .font(S.display(22, .semibold))
                            .foregroundStyle(S.ink)
                    )
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(S.display(28, .semibold))
                    .tracking(S.displayTracking(28))
                    .foregroundStyle(S.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(player.title)
                    .font(S.text(14))
                    .foregroundStyle(S.ink2)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            SILRoundButton(systemImage: "slider.horizontal.3") { showSettings = true }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Cards

    private var levelCard: some View {
        SILCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(player.level)").silNumeral(66)
                    Text("lvl").font(S.text(20)).foregroundStyle(S.ink3)
                }
                Spacer(minLength: 12)
                VStack(alignment: .leading, spacing: 8) {
                    SILBar(progress: player.progressShare)
                    Text("\(SILFormat.percent(player.progressShare)) \(SILWord.progress.lowercased())")
                        .font(S.text(14))
                        .foregroundStyle(S.ink2)
                }
            }
            .frame(height: 140, alignment: .top)
        }
    }

    private var momentumCard: some View {
        SILCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                SILMeterBars(values: momentumHistory, height: 40)
                Spacer(minLength: 12)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(player.momentum)").silNumeral(34)
                    Text("\(SILWord.momentum) · \(player.currentStreak) days")
                        .font(S.text(14))
                        .foregroundStyle(S.ink2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .frame(height: 140, alignment: .top)
        }
    }

    /// Twenty bars of daily completion volume, newest on the right.
    private var momentumHistory: [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var counts: [Date: Int] = [:]
        for entry in gameEngine.recentActivity where entry.type == .questCompleted {
            counts[calendar.startOfDay(for: entry.timestamp), default: 0] += 1
        }
        let peak = Double(max(1, counts.values.max() ?? 1))
        return (0..<20).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return Double(counts[day] ?? 0) / peak
        }
    }

    private var attributesCard: some View {
        SILCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Attributes")
                        .font(S.text(18, .medium))
                        .foregroundStyle(S.ink)
                    Spacer()
                    SILSegmented(
                        options: [(true, "Shape"), (false, "List")],
                        selection: $showsRadar,
                        height: 30
                    )
                    .frame(width: 128)
                }

                if showsRadar {
                    SILAttributeRadar(values: player.silAttributeShares)
                        .frame(height: 230)
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(player.silAttributeShares, id: \.attribute) { row in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    row.attribute.glyph
                                        .frame(width: 11, height: 11)
                                        .foregroundStyle(S.ink)
                                    Text(row.attribute.name)
                                        .font(S.text(16))
                                        .foregroundStyle(S.ink)
                                    Spacer()
                                    Text("\(row.value)").silData(12)
                                }
                                SILBar(progress: row.share)
                            }
                        }
                    }
                }
            }
        }
    }

    private var consistencyCard: some View {
        SILCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Consistency")
                        .font(S.text(18, .medium))
                        .foregroundStyle(S.ink)
                    Spacer()
                    Text("26 weeks").silEyebrow()
                }
                SILConsistencyGrid(completionsByDay: completionsByDay)
                Text("\(SILFormat.number(player.completedQuestCount)) habits completed in total.")
                    .font(S.text(14))
                    .foregroundStyle(S.ink2)
            }
        }
    }

    private var completionsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        for entry in gameEngine.recentActivity where entry.type == .questCompleted {
            counts[calendar.startOfDay(for: entry.timestamp), default: 0] += 1
        }
        return counts
    }

    // MARK: - Rewards

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(SILWord.rewards)
                    .font(S.display(24, .semibold))
                    .tracking(S.displayTracking(24))
                    .foregroundStyle(S.ink)
                Spacer()
                HStack(spacing: 4) {
                    Text(SILFormat.number(player.credits))
                    Text(SILWord.creditsShort).foregroundStyle(S.ink3)
                }
                .font(S.mono(11))
                .foregroundStyle(S.ink)
            }
            .padding(.top, 14)
            .padding(.horizontal, 2)

            Text("Your rules. Credits come from required habits and focus.")
                .font(S.text(14))
                .foregroundStyle(S.ink2)
                .padding(.horizontal, 2)
                .padding(.top, 6)
                .padding(.bottom, 12)

            SILCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(marketplace.availableRewards.prefix(5).enumerated()), id: \.element.id) { index, reward in
                        rewardRow(reward, showsDivider: index > 0)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
            }
        }
    }

    private func rewardRow(_ reward: MarketplaceReward, showsDivider: Bool) -> some View {
        let affordable = player.credits >= reward.cost
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(reward.name)
                    .font(S.text(17, .medium))
                    .foregroundStyle(S.ink)
                Text(reward.description)
                    .font(S.text(13))
                    .foregroundStyle(S.ink2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                buy(reward)
            } label: {
                Text("\(SILFormat.number(reward.cost)) \(SILWord.creditsShort)")
                    .font(S.mono(11))
                    .foregroundStyle(affordable ? S.ink : S.ink3)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(
                        Capsule()
                            .fill(affordable ? S.card2 : .clear)
                            .overlay(Capsule().strokeBorder(affordable ? .clear : S.line2, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            if showsDivider {
                Rectangle().fill(S.line).frame(height: 1)
            }
        }
    }

    private func buy(_ reward: MarketplaceReward) {
        let result = marketplace.purchaseReward(reward, player: &gameEngine.player)
        if result.success {
            HapticManager.shared.success()
            gameEngine.save()
        }
    }

    // MARK: - Moments

    private var momentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(SILWord.moments)
                .font(S.display(24, .semibold))
                .tracking(S.displayTracking(24))
                .foregroundStyle(S.ink)
                .padding(.horizontal, 2)
                .padding(.top, 14)
                .padding(.bottom, 8)

            if gameEngine.recentActivity.isEmpty {
                Text("Nothing logged yet.")
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
                    .padding(.horizontal, 2)
            } else {
                ForEach(gameEngine.recentActivity.prefix(8)) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(entry.timestamp, format: .dateTime.hour().minute())
                            .silData(10, color: S.ink3)
                            .frame(width: 46, alignment: .leading)
                        Text(entry.title)
                            .font(S.text(15))
                            .foregroundStyle(S.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(entry.detail)
                            .silData(10)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 2)
                    .overlay(alignment: .top) {
                        Rectangle().fill(S.line).frame(height: 1)
                    }
                }
            }
        }
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SILWord.milestones)
                .font(S.display(24, .semibold))
                .tracking(S.displayTracking(24))
                .foregroundStyle(S.ink)
                .padding(.horizontal, 2)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(milestones, id: \.name) { milestone in
                    VStack(alignment: .leading, spacing: 14) {
                        Circle()
                            .fill(milestone.reached ? S.ink : S.line2)
                            .frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(milestone.name)
                                .font(S.text(16, .medium))
                                .foregroundStyle(S.ink)
                            Text(milestone.note)
                                .font(S.text(13))
                                .foregroundStyle(S.ink2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: S.R.small, style: .continuous)
                            .fill(S.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: S.R.small, style: .continuous)
                                    .strokeBorder(S.line, lineWidth: 1)
                            )
                    )
                    .opacity(milestone.reached ? 1 : 0.45)
                }
            }
        }
        .padding(.top, 14)
    }

    private var milestones: [(name: String, note: String, reached: Bool)] {
        [
            ("First week", "7 days in a row", player.longestStreak >= 7),
            ("First month", "30 days in a row", player.longestStreak >= 30),
            ("Hundred", "100 habits closed", player.completedQuestCount >= 100),
            ("Level ten", "Reach level 10", player.level >= 10)
        ]
    }
}

// MARK: - Attribute radar

/// Four axes, four rings, one filled quad. The old six-point chart read as a
/// character sheet; four points read as a shape you can hold in your head.
struct SILAttributeRadar: View {
    var values: [(attribute: SILAttribute, value: Int, share: Double)]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) - 36
            let mid = CGPoint(x: geo.size.width / 2, y: side / 2 + 18)
            let radius = side / 2 - 8

            ZStack {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { ring in
                    quad(center: mid, radius: radius * ring)
                        .stroke(S.line2, lineWidth: 1)
                }

                Path { path in
                    path.move(to: CGPoint(x: mid.x, y: mid.y - radius))
                    path.addLine(to: CGPoint(x: mid.x, y: mid.y + radius))
                    path.move(to: CGPoint(x: mid.x - radius, y: mid.y))
                    path.addLine(to: CGPoint(x: mid.x + radius, y: mid.y))
                }
                .stroke(S.line, lineWidth: 1)

                let shape = quad(
                    center: mid,
                    radii: SILAttribute.allCases.map { attribute in
                        radius * max(0.12, share(of: attribute))
                    }
                )
                shape.fill(S.accent.opacity(0.22))
                shape.stroke(S.accentInk, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))

                label(.body)
                    .position(x: mid.x, y: mid.y - radius - 14)
                label(.energy)
                    .position(x: mid.x, y: mid.y + radius + 14)
                label(.mind)
                    .position(x: mid.x + radius + 22, y: mid.y)
                label(.spirit)
                    .position(x: mid.x - radius - 22, y: mid.y)
            }
            .animation(.easeOut(duration: 0.45), value: values.map(\.share))
        }
    }

    private func share(of attribute: SILAttribute) -> Double {
        values.first { $0.attribute == attribute }?.share ?? 0
    }

    private func value(of attribute: SILAttribute) -> Int {
        values.first { $0.attribute == attribute }?.value ?? 0
    }

    private func label(_ attribute: SILAttribute) -> some View {
        Text("\(attribute.name) \(value(of: attribute))")
            .font(S.mono(9))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(S.ink2)
            .fixedSize()
    }

    /// Order is clockwise from the top: Body, Mind, Energy, Spirit.
    private func quad(center: CGPoint, radius: CGFloat) -> Path {
        quad(center: center, radii: [radius, radius, radius, radius])
    }

    private func quad(center: CGPoint, radii: [CGFloat]) -> Path {
        var path = Path()
        let points = [
            CGPoint(x: center.x, y: center.y - radii[0]),              // Body — top
            CGPoint(x: center.x + radii[1], y: center.y),              // Mind — right
            CGPoint(x: center.x, y: center.y + radii[2]),              // Energy — bottom
            CGPoint(x: center.x - radii[3], y: center.y)               // Spirit — left
        ]
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }
}

// MARK: - Consistency grid

/// Twenty-six weeks as columns of seven dots. Same data as the old heatmap,
/// drawn in ink opacity rather than a green ramp.
struct SILConsistencyGrid: View {
    var completionsByDay: [Date: Int]
    var weeks: Int = 26

    private var columns: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<weeks).reversed().map { weekOffset in
            (0..<7).compactMap { dayOffset in
                calendar.date(byAdding: .day, value: -(weekOffset * 7 + (6 - dayOffset)), to: today)
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                VStack(spacing: 4) {
                    ForEach(week, id: \.self) { day in
                        Circle()
                            .fill(S.ink)
                            .opacity(opacity(for: day))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func opacity(for day: Date) -> Double {
        let count = completionsByDay[Calendar.current.startOfDay(for: day)] ?? 0
        if day > Date() { return 0.06 }
        switch count {
        case 0:     return 0.13
        case 1:     return 0.35
        case 2...3: return 0.6
        default:    return 1
        }
    }
}
