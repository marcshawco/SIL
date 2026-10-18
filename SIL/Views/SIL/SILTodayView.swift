//
//  SILTodayView.swift
//  SIL
//
//  The Today tab — the "Bento" direction from `SIL Prototype.dc.html`.
//
//  Two square cards at the top (momentum, level), a wide card holding the
//  three-month dot calendar and the day's remaining count, then the next few
//  habits as plain rows. Nothing competes: one number per card, ink on a
//  hairline, no colour except on the ring that is actually moving.
//

import SwiftUI

struct SILTodayView: View {
    @EnvironmentObject private var gameEngine: GameEngine

    var onOpenHabits: () -> Void
    var onOpenYou: () -> Void

    private var activeHabits: [DailyQuest] {
        gameEngine.dailyQuests.filter { $0.status != .expired }
    }

    private var doneCount: Int {
        activeHabits.filter { $0.status == .completed }.count
    }

    private var totalCount: Int { activeHabits.count }
    private var leftCount: Int { max(0, totalCount - doneCount) }

    private var dayShare: Double {
        totalCount == 0 ? 1 : Double(doneCount) / Double(totalCount)
    }

    private var nextUp: [DailyQuest] {
        Array(activeHabits.filter { $0.status != .completed }.prefix(4))
    }

    private var coachLine: String {
        let player = gameEngine.player
        if totalCount == 0 {
            return "Nothing scheduled yet. Add the first habit when you're ready."
        }
        if leftCount == 0 {
            return "Everything's done. Rest is part of it."
        }
        if player.currentStreak >= 3 {
            return "\(player.currentStreak) days running. \(leftCount) left to keep it."
        }
        return "\(leftCount) left today. Start with the one you'll put off."
    }

    var body: some View {
        SILScreen {
            SILHeader(eyebrow: SILFormat.dateShort(), title: "Today") {
                Button(action: onOpenYou) {
                    HStack(spacing: 6) {
                        Text(SILFormat.number(gameEngine.player.credits))
                        Text(SILWord.creditsShort).foregroundStyle(S.ink3)
                    }
                    .font(S.mono(11))
                    .foregroundStyle(S.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(Capsule().fill(S.card2))
                }
                .buttonStyle(.plain)

                SILRoundButton(systemImage: "slider.horizontal.3", action: onOpenHabits)
            }

            Text(coachLine)
                .font(S.text(17))
                .foregroundStyle(S.ink2)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                momentumCard
                levelCard
            }

            habitsCard

            HStack {
                Text("Next up").silEyebrow()
                Spacer()
                Button("See all", action: onOpenHabits)
                    .font(S.text(14))
                    .foregroundStyle(S.ink2)
                    .buttonStyle(.plain)
            }
            .padding(.top, 10)
            .padding(.horizontal, 2)

            if nextUp.isEmpty {
                Text("Nothing left today. Rest is part of it.")
                    .font(S.text(16))
                    .foregroundStyle(S.ink2)
                    .padding(.vertical, 14)
            } else {
                VStack(spacing: 0) {
                    ForEach(nextUp) { habit in
                        SILHabitRow(
                            title: habit.title,
                            subtitle: subtitle(for: habit),
                            points: SILFormat.points(habit.xpReward),
                            progress: habit.currentProgress,
                            done: habit.status == .completed,
                            attribute: attribute(for: habit),
                            onToggle: { complete(habit) },
                            onOpen: onOpenHabits
                        )
                    }
                }
            }
        }
    }

    // MARK: Cards

    private var momentumCard: some View {
        Button(action: onOpenYou) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    SILRing(progress: gameEngine.player.momentumShare, size: 76) {
                        Text("\(gameEngine.player.momentum)").silNumeral(26)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(S.ink3)
                }
                Spacer(minLength: 12)
                VStack(alignment: .leading, spacing: 3) {
                    Text(SILWord.momentum)
                        .font(S.text(18, .medium))
                        .foregroundStyle(S.ink)
                    Text("\(gameEngine.player.currentStreak)-day streak")
                        .font(S.text(14))
                        .foregroundStyle(S.ink2)
                }
            }
            .frame(height: 140, alignment: .top)
        }
        .buttonStyle(.plain)
        .modifier(SILCardBackground())
    }

    private var levelCard: some View {
        Button(action: onOpenYou) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(gameEngine.player.level)").silNumeral(66)
                    Text("lvl")
                        .font(S.text(20))
                        .foregroundStyle(S.ink3)
                }
                Spacer(minLength: 12)
                VStack(alignment: .leading, spacing: 8) {
                    SILBar(progress: gameEngine.player.progressShare)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Level")
                            .font(S.text(18, .medium))
                            .foregroundStyle(S.ink)
                        Text("\(SILFormat.number(gameEngine.player.progressToNextLevel)) to level \(gameEngine.player.level + 1)")
                            .font(S.text(14))
                            .foregroundStyle(S.ink2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }
            .frame(height: 140, alignment: .top)
        }
        .buttonStyle(.plain)
        .modifier(SILCardBackground())
    }

    private var habitsCard: some View {
        Button(action: onOpenHabits) {
            VStack(spacing: 22) {
                SILDotCalendar(completionsByDay: completionsByDay)

                HStack(spacing: 14) {
                    SILRing(progress: dayShare, size: 56) {
                        Text("\(leftCount)").silNumeral(20)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Habits left today")
                            .font(S.text(18, .medium))
                            .foregroundStyle(S.ink)
                        Text(SILFormat.ratio(doneCount, totalCount))
                            .font(S.text(14))
                            .foregroundStyle(S.ink2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(S.ink3)
                }
            }
        }
        .buttonStyle(.plain)
        .modifier(SILCardBackground(padding: EdgeInsets(top: 22, leading: 20, bottom: 18, trailing: 20)))
    }

    // MARK: Data

    /// Completion counts keyed by day, read from the activity log so the dot
    /// calendar shows real history rather than a placeholder.
    private var completionsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        for entry in gameEngine.recentActivity where entry.type == .questCompleted {
            let day = calendar.startOfDay(for: entry.timestamp)
            counts[day, default: 0] += 1
        }
        return counts
    }

    private func attribute(for habit: DailyQuest) -> SILAttribute {
        guard let stat = habit.targetStats.first else { return .energy }
        return SILAttribute.containing(stat)
    }

    private func subtitle(for habit: DailyQuest) -> String {
        var parts: [String] = []
        switch habit.trackingType {
        case .healthKit: parts.append("Apple Health · auto")
        case .location:  parts.append("Location")
        case .timer:     parts.append("Timer")
        case .manual:    parts.append(habit.resolvedFrequency.rawValue)
        }
        if habit.isOptional { parts.append("optional") }
        return parts.joined(separator: " · ")
    }

    private func complete(_ habit: DailyQuest) {
        guard habit.status != .completed else { return }
        HapticManager.shared.success()
        _ = gameEngine.completeQuest(habit)
    }
}

// MARK: - Card background

/// Cards on Today are buttons, so the card chrome is applied as a modifier
/// rather than by wrapping them in `SILCard`.
private struct SILCardBackground: ViewModifier {
    var padding = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: S.R.card, style: .continuous)
                ZStack {
                    shape.fill(S.cardGrad)
                    shape.strokeBorder(S.line, lineWidth: 1)
                }
                .compositingGroup()
                .shadow(color: S.shadowColor.opacity(0.3), radius: S.shadowRadius, y: S.shadowY)
            }
    }
}

// MARK: - Dot calendar

/// Three months of days as 5pt dots, brightest where the most habits closed.
/// The old heatmap read as a contribution graph; this reads as a calendar.
struct SILDotCalendar: View {
    var completionsByDay: [Date: Int]
    var monthCount: Int = 3

    private var months: [(name: String, days: [Date])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<monthCount).reversed().compactMap { offset in
            guard
                let monthStart = calendar.date(byAdding: .month, value: -offset, to: today),
                let interval = calendar.dateInterval(of: .month, for: monthStart),
                let range = calendar.range(of: .day, in: .month, for: monthStart)
            else { return nil }

            let days = range.compactMap {
                calendar.date(byAdding: .day, value: $0 - 1, to: interval.start)
            }
            return (formatter.string(from: monthStart), days)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(months, id: \.name) { month in
                VStack(spacing: 12) {
                    Text(month.name)
                        .font(S.text(12, .medium))
                        .foregroundStyle(S.ink2)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(5), spacing: 6), count: 7), spacing: 6) {
                        ForEach(month.days, id: \.self) { day in
                            Circle()
                                .fill(S.ink)
                                .opacity(opacity(for: day))
                                .frame(width: 5, height: 5)
                        }
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
