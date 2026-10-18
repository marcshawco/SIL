//
//  SILHabitsView.swift
//  SIL
//
//  The Habits screen — what used to be Quests. Opened from Today rather than
//  being a tab of its own.
//
//  Habits are grouped by the part of the day they belong to, filtered by a
//  row of pills, and expand in place to show their tags, subtasks and
//  actions. A done habit does not disappear; it greys out and keeps its slot,
//  so the day stays legible.
//

import SwiftUI

struct SILHabitsView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss

    @State private var filter: SILHabitFilter = .all
    @State private var expanded: UUID?
    @State private var showCreate = false

    private var habits: [DailyQuest] {
        gameEngine.dailyQuests.filter { $0.status != .expired }
    }

    private var visible: [DailyQuest] {
        habits.filter { filter.accepts($0) }
    }

    private var doneCount: Int { habits.filter { $0.status == .completed }.count }

    private var groups: [(slot: SILDaySlot, items: [DailyQuest])] {
        SILDaySlot.allCases.compactMap { slot in
            let items = visible.filter { SILDaySlot.of($0) == slot }
            return items.isEmpty ? nil : (slot, items)
        }
    }

    var body: some View {
        SILScreen(spacing: 18) {
            HStack {
                SILRoundButton(systemImage: "chevron.left") { dismiss() }
                Spacer()
                SILRoundButton(systemImage: "plus") { showCreate = true }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(SILWord.habits).silTitle()
                Text("\(habits.count) today · \(doneCount) done")
                    .font(S.text(16))
                    .foregroundStyle(S.ink2)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(SILHabitFilter.allCases) { option in
                        SILPill(label: option.label, selected: option == filter) {
                            withAnimation(.easeOut(duration: 0.18)) { filter = option }
                        }
                    }
                }
                .padding(.horizontal, S.Space.screenH)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -S.Space.screenH)

            if groups.isEmpty {
                Text(filter == .all
                     ? "No habits yet. Add the first one."
                     : "Nothing matches that filter.")
                    .font(S.text(16))
                    .foregroundStyle(S.ink2)
                    .padding(.vertical, 20)
            }

            ForEach(groups, id: \.slot) { group in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(group.slot.label).silEyebrow()
                        Spacer()
                        Text("\(group.items.count)").silEyebrow()
                    }
                    .padding(.vertical, 6)

                    ForEach(group.items) { habit in
                        SILHabitCell(
                            habit: habit,
                            isExpanded: expanded == habit.id,
                            onToggleExpand: {
                                withAnimation(.easeOut(duration: 0.22)) {
                                    expanded = expanded == habit.id ? nil : habit.id
                                }
                            }
                        )
                    }
                }
            }

            Button {
                showCreate = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundStyle(S.ink)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(S.card2))
                    Text("Add habit")
                        .font(S.text(17, .medium))
                        .foregroundStyle(S.ink)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showCreate) {
            QuestFormSheet(mode: .add)
        }
    }
}

// MARK: - Filters

enum SILHabitFilter: String, CaseIterable, Identifiable {
    case all, left, done, auto, optional

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:      return "All"
        case .left:     return "Left"
        case .done:     return "Done"
        case .auto:     return "Automatic"
        case .optional: return "Optional"
        }
    }

    func accepts(_ habit: DailyQuest) -> Bool {
        switch self {
        case .all:      return true
        case .left:     return habit.status != .completed
        case .done:     return habit.status == .completed
        case .auto:     return habit.trackingType != .manual
        case .optional: return habit.isOptional
        }
    }
}

// MARK: - Day slots

/// Habits are grouped by when they are usually done. Without a stored time of
/// day this is read from the reminder, which is the closest honest signal.
enum SILDaySlot: String, CaseIterable {
    case morning, afternoon, evening, anytime

    var label: String {
        switch self {
        case .morning:   return "Morning"
        case .afternoon: return "Afternoon"
        case .evening:   return "Evening"
        case .anytime:   return "Any time"
        }
    }

    static func of(_ habit: DailyQuest) -> SILDaySlot {
        guard habit.reminderEnabled, let time = habit.reminderTime else { return .anytime }
        switch Calendar.current.component(.hour, from: time) {
        case 0..<12:  return .morning
        case 12..<17: return .afternoon
        default:      return .evening
        }
    }
}

// MARK: - Habit cell

/// One habit in the list. Collapsed it is a tick, a title and a chevron;
/// expanded it reveals its tags, subtasks and the actions that close it.
struct SILHabitCell: View {
    @EnvironmentObject private var gameEngine: GameEngine

    let habit: DailyQuest
    var isExpanded: Bool
    var onToggleExpand: () -> Void

    private var done: Bool { habit.status == .completed }

    private var attribute: SILAttribute {
        habit.targetStats.first.map(SILAttribute.containing) ?? .energy
    }

    private var linkedGoal: BossFight? {
        guard let id = habit.linkedBossID ?? habit.linkedDynamicBossID else { return nil }
        return gameEngine.activeBossFights.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                SILHabitTick(
                    progress: habit.currentProgress,
                    done: done,
                    attribute: attribute,
                    action: complete
                )

                Button(action: onToggleExpand) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title)
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

                Button(action: onToggleExpand) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(S.ink3)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

            if isExpanded {
                expandedBody
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isExpanded ? S.card : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(isExpanded ? S.line : .clear, lineWidth: 1)
                )
        )
        .padding(.horizontal, -12)
    }

    // MARK: Expanded

    @ViewBuilder private var expandedBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            FlowRow(spacing: 6) {
                tag(tagLine)
                tag("\(SILFormat.points(habit.xpReward)) \(SILWord.progress.lowercased())")
                if !habit.isOptional {
                    tag("\(SILFormat.points(habit.goldReward)) \(SILWord.creditsShort)")
                }
                if let goal = linkedGoal {
                    tag("→ \(goal.title)", accented: true)
                }
            }

            if habit.hasSubtasks {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(habit.subtasks) { subtask in
                        Button {
                            guard !subtask.isCompleted else { return }
                            HapticManager.shared.success()
                            _ = gameEngine.completeQuestSubtask(questID: habit.id, subtaskID: subtask.id)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(subtask.isCompleted ? S.inv : S.card2)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if subtask.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(S.onInv)
                                        }
                                    }
                                Text(subtask.title)
                                    .font(S.text(15))
                                    .foregroundStyle(subtask.isCompleted ? S.ink3 : S.ink)
                                    .strikethrough(subtask.isCompleted, color: S.ink3)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if habit.trackingType == .healthKit {
                HStack(spacing: 8) {
                    Circle().fill(S.accent).frame(width: 6, height: 6)
                    Text("Syncing from Apple Health")
                        .font(S.mono(9.5))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(S.ink2)
                }
            }

            if !done {
                SILPrimaryButton(title: "Mark done") { complete() }
                    .frame(height: 46)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tag(_ text: String, accented: Bool = false) -> some View {
        Text(text)
            .font(S.mono(9.5))
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundStyle(accented ? S.accentInk : S.ink2)
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background(Capsule().fill(S.card2))
    }

    private var tagLine: String {
        switch habit.trackingType {
        case .healthKit: return "Apple Health"
        case .location:  return "Location"
        case .timer:     return "Timer"
        case .manual:    return habit.resolvedFrequency.rawValue
        }
    }

    private var subtitle: String {
        var parts = [tagLine]
        if habit.hasSubtasks {
            let done = habit.subtasks.filter(\.isCompleted).count
            parts.append("\(done)/\(habit.subtasks.count) steps")
        }
        if habit.isOptional { parts.append("optional") }
        return parts.joined(separator: " · ")
    }

    private func complete() {
        guard !done else { return }
        HapticManager.shared.success()
        _ = gameEngine.completeQuest(habit)
    }
}

// MARK: - Flow layout

/// Wraps its children onto as many lines as they need. Used for the tag row,
/// where the number of tags varies per habit.
struct FlowRow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
