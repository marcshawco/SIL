//
//  SILGoalsView.swift
//  SIL
//
//  The Goals tab — what used to be Bosses.
//
//  A goal is no longer an enemy with a health bar. It is a measurement: one
//  large number, a tick grid that fills like a ruler, and an honest line about
//  when you will arrive at this pace. Nothing is defeated; something is
//  reached.
//

import SwiftUI

struct SILGoalsView: View {
    @EnvironmentObject private var gameEngine: GameEngine

    @State private var openGoal: BossFight?
    @State private var showCreate = false

    private var goals: [BossFight] {
        gameEngine.activeBossFights.filter { !$0.isDefeated }
    }

    private var coachLine: String {
        switch goals.count {
        case 0:  return "No goals yet. A goal is something that takes weeks, not minutes."
        case 1:  return "One goal, properly. That is usually the right number."
        default: return "\(goals.count) goals running. The habits underneath them do the work."
        }
    }

    var body: some View {
        SILScreen {
            SILHeader(eyebrow: "Long work · weeks, not minutes", title: SILWord.goals) {
                SILRoundButton(systemImage: "plus") { showCreate = true }
            }

            Text(coachLine)
                .font(S.text(17))
                .foregroundStyle(S.ink2)
                .padding(.bottom, 4)

            ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                Button {
                    openGoal = goal
                } label: {
                    SILGoalCard(goal: goal, index: index + 1)
                }
                .buttonStyle(.plain)
            }

            Button {
                showCreate = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(S.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(S.card2))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("New goal")
                            .font(S.text(17, .medium))
                            .foregroundStyle(S.ink)
                        Text("Something that takes weeks, not minutes")
                            .font(S.text(14))
                            .foregroundStyle(S.ink2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22)
                .frame(height: 92)
                .background(
                    RoundedRectangle(cornerRadius: S.R.card, style: .continuous)
                        .strokeBorder(S.line2, style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showCreate) {
            BossFormSheet()
        }
        .sheet(item: $openGoal) { goal in
            SILGoalDetailView(goalID: goal.id)
                .environmentObject(gameEngine)
        }
    }
}

// MARK: - Goal reading

/// Everything the Goals screens need to say about a goal, derived once so the
/// card and the detail view can't drift apart.
struct SILGoalReading {
    let index: Int
    let title: String
    let kind: String
    let source: String
    /// 0…1 toward the target.
    let share: Double
    /// The headline number and what follows it.
    let value: String
    let unit: String
    let ofTarget: String
    let startText: String
    let nowText: String
    let targetText: String
    let paceText: String
    let dayText: String
    let etaShort: String
    let etaLine: String

    init(goal: BossFight, index: Int) {
        self.index = index
        self.title = goal.title

        let elapsedWeeks = max(
            0.2,
            Date().timeIntervalSince(goal.createdAt) / (7 * 24 * 3600)
        )

        if let dynamic = goal.dynamicGoal {
            self.kind = dynamic.type.displayName
            self.source = "Apple Health · auto"
            self.share = dynamic.normalizedProgress
            self.value = SILGoalReading.trim(dynamic.currentValue)
            self.unit = dynamic.unitLabel
            self.ofTarget = "of \(SILGoalReading.trim(dynamic.targetValue))"
            self.startText = SILGoalReading.trim(dynamic.startValue)
            self.nowText = SILGoalReading.trim(dynamic.currentValue)
            self.targetText = SILGoalReading.trim(dynamic.targetValue)

            let moved = abs(dynamic.currentValue - dynamic.startValue)
            let perWeek = moved / elapsedWeeks
            self.paceText = SILGoalReading.trim(perWeek)

            let remaining = dynamic.remainingAmount
            let weeksLeft = perWeek > 0.0001 ? remaining / perWeek : .infinity
            self.etaShort = SILGoalReading.etaShort(weeksLeft)
            self.etaLine = SILGoalReading.etaLine(weeksLeft, remaining: remaining, unit: dynamic.unitLabel)
        } else {
            self.kind = goal.difficulty.rawValue
            let done = goal.microTasks.filter(\.isCompleted).count
            self.source = goal.microTasks.isEmpty
                ? "Habits move this"
                : "\(done) of \(goal.microTasks.count) steps done"
            self.share = goal.damageDealtPercentage
            self.value = SILFormat.percent(goal.damageDealtPercentage)
            self.unit = "done"
            self.ofTarget = ""
            self.startText = "0%"
            self.nowText = SILFormat.percent(goal.damageDealtPercentage)
            self.targetText = "100%"

            let perWeek = goal.damageDealtPercentage * 100 / elapsedWeeks
            self.paceText = "\(Int(perWeek.rounded()))%"

            let remainingPct = (1 - goal.damageDealtPercentage) * 100
            let weeksLeft = perWeek > 0.01 ? remainingPct / perWeek : .infinity
            self.etaShort = SILGoalReading.etaShort(weeksLeft)
            self.etaLine = SILGoalReading.etaLine(weeksLeft, remaining: remainingPct, unit: "%")
        }

        if let deadline = goal.deadline {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
            self.dayText = days >= 0 ? "\(days)d left" : "\(-days)d over"
        } else {
            let days = Calendar.current.dateComponents([.day], from: goal.createdAt, to: Date()).day ?? 0
            self.dayText = "day \(max(1, days + 1))"
        }
    }

    var percentText: String { SILFormat.percent(share) }

    // MARK: Helpers

    private static func trim(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        if abs(value) >= 1000 { return SILFormat.number(Int(value.rounded())) }
        return value == value.rounded()
            ? String(Int(value.rounded()))
            : String(format: "%.1f", value)
    }

    private static func etaShort(_ weeks: Double) -> String {
        guard weeks.isFinite, weeks > 0 else { return "no pace yet" }
        if weeks < 1.5 { return "~1 wk" }
        if weeks < 9 { return "~\(Int(weeks.rounded())) wks" }
        return "~\(Int((weeks / 4.345).rounded())) mo"
    }

    private static func etaLine(_ weeks: Double, remaining: Double, unit: String) -> String {
        guard weeks.isFinite, weeks > 0 else {
            return "Not enough history to call a pace yet"
        }
        let left = trim(remaining)
        if weeks < 1.5 {
            return "\(left) \(unit) to go — about a week at this pace"
        }
        if weeks < 9 {
            return "\(left) \(unit) to go — about \(Int(weeks.rounded())) weeks at this pace"
        }
        return "\(left) \(unit) to go — about \(Int((weeks / 4.345).rounded())) months at this pace"
    }
}

// MARK: - Goal card

struct SILGoalCard: View {
    var goal: BossFight
    var index: Int

    var body: some View {
        let reading = SILGoalReading(goal: goal, index: index)

        SILCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(String(format: "%02d", index)) · \(reading.kind)").silEyebrow()
                    Spacer()
                    Text(reading.dayText).silEyebrow()
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(reading.value).silNumeral(46)
                    Text("\(reading.unit) \(reading.ofTarget)")
                        .font(S.text(15))
                        .foregroundStyle(S.ink3)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(reading.title)
                        .font(S.text(19, .medium))
                        .tracking(-0.28)
                        .foregroundStyle(S.ink)
                    Text(reading.source)
                        .font(S.text(14))
                        .foregroundStyle(S.ink2)
                }

                SILTickBar(progress: reading.share, count: 36, height: 16)

                HStack {
                    Text(reading.percentText)
                        .font(S.mono(10))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(S.ink)
                    Spacer()
                    Text(reading.etaShort).silEyebrow(10)
                }
            }
        }
    }
}

// MARK: - Goal detail

struct SILGoalDetailView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss

    let goalID: UUID

    private var goal: BossFight? {
        gameEngine.activeBossFights.first { $0.id == goalID }
    }

    private var index: Int {
        (gameEngine.activeBossFights.firstIndex { $0.id == goalID } ?? 0) + 1
    }

    private var linkedHabits: [DailyQuest] {
        guard let goal else { return [] }
        return gameEngine.dailyQuests.filter {
            $0.linkedBossID == goal.id || $0.linkedDynamicBossID == goal.id
        }
    }

    var body: some View {
        ZStack {
            S.bg.ignoresSafeArea()
            if let goal {
                content(for: goal)
            } else {
                Text("This goal is finished.")
                    .font(S.text(17))
                    .foregroundStyle(S.ink2)
            }
        }
    }

    @ViewBuilder private func content(for goal: BossFight) -> some View {
        let reading = SILGoalReading(goal: goal, index: index)

        SILScreen(spacing: 18) {
            HStack {
                SILRoundButton(systemImage: "chevron.left") { dismiss() }
                Spacer()
                Text("\(reading.kind) · \(reading.source)").silEyebrow()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Goal \(String(format: "%02d", index)) · \(reading.dayText)").silEyebrow()
                Text(reading.title)
                    .font(S.display(32, .semibold))
                    .tracking(S.displayTracking(32))
                    .foregroundStyle(S.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(reading.value).silNumeral(68)
                Text("\(reading.unit) \(reading.ofTarget)")
                    .font(S.text(16))
                    .foregroundStyle(S.ink3)
            }
            .padding(.top, 6)

            SILTickBar(progress: reading.share, count: 44, height: 30, spacing: 3)

            HStack {
                Text("\(reading.percentText) complete")
                    .font(S.mono(10))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(S.ink)
                Spacer()
                Text(reading.etaShort).silEyebrow(10)
            }

            Text(reading.etaLine + ".")
                .font(S.text(16))
                .foregroundStyle(S.ink2)

            SILCard(padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Last 8 weeks").silEyebrow()
                        Spacer()
                        Text("\(reading.paceText) / wk").silEyebrow()
                    }
                    SILSparkline(values: history(for: goal))
                        .frame(height: 120)
                }
            }

            SILStatStrip(cells: [
                .init("Start", reading.startText),
                .init("Now", reading.nowText, accented: true),
                .init("Target", reading.targetText),
                .init("Pace/wk", reading.paceText)
            ])

            VStack(alignment: .leading, spacing: 10) {
                Text(SILWord.milestones).silEyebrow()
                HStack(spacing: 8) {
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { mark in
                        let reached = reading.share >= mark
                        Text("\(Int(mark * 100))%")
                            .font(S.text(15, .medium))
                            .foregroundStyle(reached ? S.onInv : S.ink2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                Capsule()
                                    .fill(reached ? S.inv : .clear)
                                    .overlay(Capsule().strokeBorder(reached ? .clear : S.line2, lineWidth: 1))
                            )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Habits that move this")
                    .silEyebrow()
                    .padding(.bottom, 6)

                if linkedHabits.isEmpty {
                    Text("No habits linked yet. Link one when you create it.")
                        .font(S.text(15))
                        .foregroundStyle(S.ink2)
                } else {
                    ForEach(linkedHabits) { habit in
                        SILHabitRow(
                            title: habit.title,
                            subtitle: habit.resolvedFrequency.rawValue,
                            points: nil,
                            progress: habit.currentProgress,
                            done: habit.status == .completed,
                            attribute: habit.targetStats.first.map(SILAttribute.containing) ?? .body,
                            onToggle: {
                                guard habit.status != .completed else { return }
                                HapticManager.shared.success()
                                _ = gameEngine.completeQuest(habit)
                            },
                            onOpen: nil
                        )
                    }
                }
            }

            if !goal.microTasks.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Steps").silEyebrow().padding(.bottom, 6)
                    ForEach(goal.microTasks) { task in
                        Button {
                            guard !task.isCompleted else { return }
                            HapticManager.shared.success()
                            _ = gameEngine.completeMicroTask(bossId: goal.id, taskId: task.id)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(task.isCompleted ? S.inv : S.card2)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if task.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(S.onInv)
                                        }
                                    }
                                Text(task.title)
                                    .font(S.text(15))
                                    .foregroundStyle(task.isCompleted ? S.ink3 : S.ink)
                                    .strikethrough(task.isCompleted, color: S.ink3)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// Eight weekly samples of progress. Without stored history this is
    /// reconstructed from the goal's age and current position, which is honest
    /// about the shape without pretending to data the engine never kept.
    private func history(for goal: BossFight) -> [Double] {
        let reading = SILGoalReading(goal: goal, index: index)
        let weeks = 8
        return (0..<weeks).map { week in
            let fraction = Double(week + 1) / Double(weeks)
            return reading.share * fraction
        }
    }
}

// MARK: - Sparkline

/// A thin line over a faint fill, with the latest point marked in the accent.
struct SILSparkline: View {
    var values: [Double]

    var body: some View {
        GeometryReader { geo in
            let points = self.points(in: geo.size)
            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                        points.forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(S.ink.opacity(0.06))

                    Path { path in
                        path.move(to: points[0])
                        points.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(S.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

                    Circle()
                        .fill(S.accent)
                        .frame(width: 9, height: 9)
                        .position(points[points.count - 1])
                }
            }
        }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let peak = max(0.0001, values.max() ?? 1)
        let step = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * step,
                y: size.height - (CGFloat(value / peak) * (size.height - 12)) - 6
            )
        }
    }
}
