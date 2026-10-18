//
//  SILComposeSheet.swift
//  SIL
//
//  One sheet makes both things. The segmented control at the top switches
//  between a habit and a goal; the title field is the same large, unadorned
//  input either way; the footer previews what you are about to create and
//  saves it.
//
//  This replaces two separate multi-hundred-line forms (QuestFormSheet and
//  BossFormSheet) for the create case. Editing an existing habit still goes
//  through QuestFormSheet, which knows how to round-trip every field.
//

import SwiftUI

struct SILComposeSheet: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss

    enum Kind: Hashable { case habit, goal }

    /// Which tab the sheet opens on.
    var initialKind: Kind = .habit

    @State private var kind: Kind = .habit
    @State private var title = ""

    // Habit
    @State private var attribute: SILAttribute = .body
    @State private var effort: QuestDifficulty = .easy
    @State private var frequency: QuestFrequency = .daily
    @State private var tracking: QuestTrackingType = .manual
    @State private var linkedGoalID: UUID?
    @State private var isOptional = false
    @State private var remind = false
    @State private var reminderTime = SILComposeSheet.defaultReminder

    // Goal
    @State private var goalType: DynamicBossGoalType = .stepCount
    @State private var goalTarget = ""
    @State private var timeframe: SILTimeframe = .threeMonths
    @State private var goalAuto = true

    private static var defaultReminder: Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private var canSave: Bool {
        let named = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard kind == .goal else { return named }
        return named && (Double(goalTarget.replacingOccurrences(of: ",", with: "")) ?? 0) > 0
    }

    var body: some View {
        ZStack {
            S.bg2.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        TextField("Name it", text: $title)
                            .font(S.display(30, .semibold))
                            .tracking(S.displayTracking(30))
                            .foregroundStyle(S.ink)
                            .padding(.vertical, 4)

                        if kind == .habit { habitForm } else { goalForm }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)

                footer
            }
        }
        .onAppear { kind = initialKind }
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(S.line2)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            HStack {
                Button("Cancel") { dismiss() }
                    .font(S.text(16))
                    .foregroundStyle(S.ink2)
                    .buttonStyle(.plain)
                    .frame(width: 64, height: 44, alignment: .leading)

                Spacer()

                SILSegmented(
                    options: [(Kind.habit, SILWord.habit), (Kind.goal, SILWord.goal)],
                    selection: $kind,
                    height: 34,
                    fills: false
                )

                Spacer()

                Color.clear.frame(width: 64, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text(previewLine)
                .silEyebrow(9.5)
                .multilineTextAlignment(.center)

            SILPrimaryButton(
                title: kind == .habit ? "Add habit" : "Add goal",
                accented: true,
                enabled: canSave
            ) {
                save()
            }
            .frame(height: 56)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 34)
        .overlay(alignment: .top) {
            Rectangle().fill(S.line).frame(height: 1)
        }
    }

    private var previewLine: String {
        if kind == .habit {
            let xp = GameFormulas.questXP(difficulty: effort)
            let credits = isOptional ? 0 : GameFormulas.questGold(difficulty: effort)
            let creditPart = isOptional ? "no credits" : "\(SILFormat.points(credits)) \(SILWord.creditsShort)"
            return "\(frequency.rawValue) · \(SILFormat.points(xp)) \(SILWord.progress) · \(creditPart) · \(attribute.name)"
        }
        let target = goalTarget.isEmpty ? "—" : goalTarget
        return "\(target) \(goalType.unitLabel) · \(timeframe.label) · \(goalAuto ? "automatic" : "logged by hand")"
    }

    // MARK: - Habit form

    @ViewBuilder private var habitForm: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(starters, id: \.title) { starter in
                    SILPill(label: starter.label, selected: title == starter.title, height: 38) {
                        title = starter.title
                        attribute = starter.attribute
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -20)

        field("Builds") {
            HStack(spacing: 6) {
                ForEach(SILAttribute.allCases) { option in
                    SILAttributeChip(attribute: option, selected: option == attribute) {
                        attribute = option
                    }
                }
            }
        }

        field("Effort") {
            SILSegmented(
                options: [
                    (QuestDifficulty.easy, "Light"),
                    (QuestDifficulty.normal, "Steady"),
                    (QuestDifficulty.hard, "Hard")
                ],
                selection: $effort,
                height: 44
            )
        }

        field("Repeats") {
            FlowRow(spacing: 6) {
                ForEach(QuestFrequency.allCases) { option in
                    SILPill(label: option.rawValue, selected: option == frequency, height: 38) {
                        frequency = option
                    }
                }
            }
        }

        field("Tracking") {
            FlowRow(spacing: 6) {
                ForEach([QuestTrackingType.manual, .healthKit, .location, .timer], id: \.self) { option in
                    SILPill(label: trackingLabel(option), selected: option == tracking, height: 38) {
                        tracking = option
                    }
                }
            }
        }

        if !gameEngine.activeBossFights.isEmpty {
            field("Moves a goal") {
                FlowRow(spacing: 6) {
                    SILPill(label: "None", selected: linkedGoalID == nil, height: 38) {
                        linkedGoalID = nil
                    }
                    ForEach(gameEngine.activeBossFights.filter { !$0.isDefeated }) { goal in
                        SILPill(label: goal.title, selected: linkedGoalID == goal.id, height: 38) {
                            linkedGoalID = goal.id
                        }
                    }
                }
            }
        }

        SILListCard {
            SILListRow(title: "Remind me", showsDivider: false) {
                Toggle("", isOn: $remind).labelsHidden().toggleStyle(SILToggleStyle())
            }
            if remind {
                SILListRow(title: "At") {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }

        SILListCard {
            SILListRow(
                title: "Optional",
                detail: "Counts toward your level. No credits, and missing it never costs momentum.",
                showsDivider: false
            ) {
                Toggle("", isOn: $isOptional).labelsHidden().toggleStyle(SILToggleStyle())
            }
        }
    }

    private func trackingLabel(_ type: QuestTrackingType) -> String {
        switch type {
        case .manual:    return "By hand"
        case .healthKit: return "Apple Health"
        case .location:  return "Location"
        case .timer:     return "Timer"
        }
    }

    private struct Starter {
        let label: String
        let title: String
        let attribute: SILAttribute
    }

    private var starters: [Starter] {
        [
            .init(label: "Water", title: "Drink 2 L of water", attribute: .energy),
            .init(label: "Read", title: "Read 20 pages", attribute: .mind),
            .init(label: "Walk", title: "Walk 8,000 steps", attribute: .body),
            .init(label: "Meditate", title: "Meditate 10 min", attribute: .spirit),
            .init(label: "Lift", title: "Strength session", attribute: .body),
            .init(label: "Screens off", title: "No phone after 22:00", attribute: .spirit)
        ]
    }

    // MARK: - Goal form

    @ViewBuilder private var goalForm: some View {
        field("Type") {
            FlowRow(spacing: 6) {
                ForEach(DynamicBossGoalType.allCases) { option in
                    SILPill(label: option.displayName, selected: option == goalType, height: 38) {
                        goalType = option
                    }
                }
            }
        }

        field("Target") {
            HStack(spacing: 12) {
                TextField("0", text: $goalTarget)
                    .keyboardType(.decimalPad)
                    .font(S.display(28, .medium))
                    .tracking(S.displayTracking(28))
                    .foregroundStyle(S.ink)
                Text(goalType.unitLabel)
                    .font(S.text(16))
                    .foregroundStyle(S.ink3)
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: S.R.small, style: .continuous)
                    .fill(S.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: S.R.small, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
            )
        }

        field("Timeframe") {
            HStack(spacing: 6) {
                ForEach(SILTimeframe.allCases) { option in
                    Button {
                        timeframe = option
                    } label: {
                        Text(option.label)
                            .font(S.text(14, .medium))
                            .foregroundStyle(option == timeframe ? S.onInv : S.ink2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(option == timeframe ? S.inv : S.card2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        SILListCard {
            SILListRow(
                title: "Track from Apple Health",
                detail: "Weight, steps, sleep and workouts update on their own.",
                showsDivider: false
            ) {
                Toggle("", isOn: $goalAuto).labelsHidden().toggleStyle(SILToggleStyle())
            }
        }
    }

    // MARK: - Layout helper

    @ViewBuilder private func field<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).silEyebrow()
            content()
        }
    }

    // MARK: - Save

    private func save() {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        HapticManager.shared.success()

        if kind == .habit {
            let habit = DailyQuest(
                title: name,
                description: "",
                difficulty: effort,
                targetStats: [attribute.primaryStat],
                frequency: frequency,
                isOptional: isOptional,
                trackingType: tracking,
                linkedBossID: linkedGoalID,
                reminderEnabled: remind,
                reminderTime: remind ? reminderTime : nil
            )
            gameEngine.saveQuest(habit)
            if remind {
                NotificationManager.shared.scheduleQuestReminder(for: habit)
            }
        } else {
            let target = Double(goalTarget.replacingOccurrences(of: ",", with: "")) ?? 0
            let goal = DynamicBossGoal(
                type: goalType,
                startValue: 0,
                targetValue: target,
                currentValue: 0,
                cadence: .weekly,
                perCadenceTarget: target / Double(max(1, timeframe.weeks))
            )
            _ = gameEngine.createBossFight(
                title: name,
                description: "",
                difficulty: .hard,
                targetStats: [attribute.primaryStat],
                maxHP: 10_000,
                dynamicGoal: goal,
                autoGenerateGoalQuest: goalAuto,
                deadline: timeframe.deadline
            )
        }

        gameEngine.save()
        dismiss()
    }
}

// MARK: - Timeframe

enum SILTimeframe: String, CaseIterable, Identifiable {
    case oneMonth, threeMonths, sixMonths

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneMonth:    return "1 month"
        case .threeMonths: return "3 months"
        case .sixMonths:   return "6 months"
        }
    }

    var weeks: Int {
        switch self {
        case .oneMonth:    return 4
        case .threeMonths: return 13
        case .sixMonths:   return 26
        }
    }

    var deadline: Date? {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: Date())
    }
}
