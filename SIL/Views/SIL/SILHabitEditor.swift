//
//  SILHabitEditor.swift
//  SIL
//
//  The full habit editor. `SILComposeSheet` makes a habit in a few taps; this
//  is where every field lives — steps, tracking, the goal it moves, the
//  schedule — and it is the screen the Habits list opens for editing.
//
//  It replaces `QuestFormSheet`, which was the last pre-SIL screen: 2,260
//  lines, two parallel forms behind a page control, a readiness card scoring
//  the user's progress through the form, and Glasswork chrome throughout.
//  What follows is one column of plain labelled fields on SIL surfaces. Every
//  field the old form round-tripped is still here; the ceremony is not.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Mode

enum SILHabitEditorMode: Identifiable {
    case add
    case edit(DailyQuest)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let habit): return habit.id.uuidString
        }
    }

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existing: DailyQuest? {
        if case .edit(let habit) = self { return habit }
        return nil
    }
}

// MARK: - Editor

struct SILHabitEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameEngine: GameEngine

    let mode: SILHabitEditorMode

    // Core
    @State private var title = ""
    @State private var notes = ""
    @State private var attributes: Set<SILAttribute> = [.spirit]
    @State private var effort: QuestDifficulty = .easy
    @State private var frequency: QuestFrequency = .daily
    @State private var isOptional = false

    // Steps
    @State private var steps: [Step] = []
    @State private var newStep = ""

    // Tracking
    @State private var tracking: QuestTrackingType = .manual
    @State private var targetValue: Double = 1
    @State private var unit = "times"
    @State private var healthMetric: HealthKitQuestType = .steps
    @State private var address = ""
    @State private var coordinate: LocationCoordinate?
    @State private var radiusMeters: Double = 804.67
    @StateObject private var autocomplete = AddressAutocompleteProvider()
    @State private var isResolvingAddress = false
    @State private var addressNote: String?
    @State private var addressNoteIsProblem = false

    // Links and reminders
    @State private var linkedGoalID: UUID?
    @State private var showGoalComposer = false
    @State private var remind = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()

    // Sheets and chrome
    @State private var wheel: Wheel?
    @State private var showMetricPicker = false
    @State private var isSaving = false
    @State private var failure: String?
    @FocusState private var titleFocused: Bool

    // MARK: Derived

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What is still missing, in the user's words. Empty means saveable.
    private var missing: [String] {
        var list: [String] = []
        if trimmedTitle.isEmpty { list.append("a name") }
        if attributes.isEmpty { list.append("something it builds") }
        if tracking == .location {
            if trimmedAddress.isEmpty {
                list.append("an address")
            } else if coordinate == nil {
                list.append("a checked address")
            }
        }
        return list
    }

    private var canSave: Bool { missing.isEmpty }

    private var progressReward: Int { GameFormulas.questXP(difficulty: effort) }

    private var creditReward: Int {
        isOptional ? 0 : GameFormulas.questGold(difficulty: effort)
    }

    private var linkableGoals: [BossFight] {
        gameEngine.activeBossFights
            .filter { !$0.isDefeated }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var namedSteps: [Step] {
        steps.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            S.bg2.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleField
                        buildsField
                        effortField
                        stepsField
                        trackingField
                        goalField
                        scheduleField
                        optionalRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)

                footer
            }
        }
        .keyboardDismissToolbar()
        .onAppear(perform: load)
        .onChange(of: tracking) { _, new in
            if new == .location && targetValue < 5 { targetValue = 45 }
            if new != .location {
                addressNote = nil
                autocomplete.clear()
            }
            if new == .manual && unit.isEmpty { unit = "times" }
        }
        .onChange(of: address) { _, _ in
            guard tracking == .location else { return }
            coordinate = nil
            addressNote = nil
            autocomplete.updateQuery(address)
        }
        .onChange(of: radiusMeters) { _, new in
            guard let existing = coordinate else { return }
            coordinate = LocationCoordinate(
                latitude: existing.latitude,
                longitude: existing.longitude,
                radius: new,
                locationName: existing.locationName
            )
        }
        .sheet(isPresented: $showGoalComposer) {
            SILComposeSheet(initialKind: .goal)
        }
        .sheet(isPresented: $showMetricPicker) {
            SILHealthMetricSheet(selection: $healthMetric)
        }
        .sheet(item: $wheel) { input in
            BottomWheelValuePickerSheet(
                title: input.title,
                subtitle: input.subtitle,
                accentColor: S.accent,
                options: options(for: input),
                selection: binding(for: input),
                confirmTitle: "Apply"
            )
        }
        .alert("Couldn't save", isPresented: Binding(
            get: { failure != nil },
            set: { if !$0 { failure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(failure ?? "")
        }
    }

    // MARK: Chrome

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

                Spacer()

                Text(mode.isEditing ? "Edit habit" : "New habit")
                    .font(S.text(16, .medium))
                    .foregroundStyle(S.ink)

                Spacer()

                // Balances the Cancel button so the title sits centred.
                Text("Cancel")
                    .font(S.text(16))
                    .hidden()
            }
            .padding(.horizontal, 20)
            .frame(height: 50)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text(previewLine)
                .silEyebrow(9.5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            SILPrimaryButton(
                title: mode.isEditing ? "Save habit" : "Add habit",
                accented: true,
                enabled: canSave && !isSaving
            ) {
                Task { await save() }
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

    /// One line under the save button: what you are about to keep, or what is
    /// still needed. The old form scored readiness in a card of its own.
    private var previewLine: String {
        guard canSave else {
            return "Needs \(SILHabitEditor.list(missing))"
        }
        let credits = isOptional ? "no credits" : "\(SILFormat.points(creditReward)) \(SILWord.creditsShort)"
        var parts = [
            frequency.rawValue,
            "\(SILFormat.points(progressReward)) \(SILWord.progress)",
            credits
        ]
        if let summary = trackingSummary {
            parts.append(summary)
        }
        if !namedSteps.isEmpty {
            parts.append("\(namedSteps.count) steps")
        }
        return parts.joined(separator: " · ")
    }

    /// `nil` where the tracking adds nothing to the line — a plain one-a-day
    /// habit would otherwise read "1 times".
    private var trackingSummary: String? {
        switch tracking {
        case .manual:
            let count = SILFormat.clampedInt(targetValue)
            guard count > 1 else { return nil }
            return "\(count) \(unit.isEmpty ? "times" : unit)"
        case .healthKit:
            return "\(healthMetric.displayName.lowercased()), automatic"
        case .location:
            return coordinate == nil ? "location" : "\(SILFormat.clampedInt(targetValue)) min on site"
        case .timer:
            return "timed"
        }
    }

    /// `a name and an address`, `a name, something it builds and an address`.
    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 0:  return ""
        case 1:  return items[0]
        default: return items.dropLast().joined(separator: ", ") + " and " + items[items.count - 1]
        }
    }

    // MARK: Fields

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Name it", text: $title)
                .font(S.display(30, .semibold))
                .tracking(S.displayTracking(30))
                .foregroundStyle(S.ink)
                .focused($titleFocused)
                .padding(.vertical, 4)

            TextField("A note to yourself (optional)", text: $notes, axis: .vertical)
                .lineLimit(1...3)
                .font(S.text(16))
                .foregroundStyle(S.ink2)
        }
    }

    private var buildsField: some View {
        field("Builds", note: "Up to three. These grow when you close it.") {
            HStack(spacing: 6) {
                ForEach(SILAttribute.allCases) { option in
                    SILAttributeChip(attribute: option, selected: attributes.contains(option)) {
                        toggle(option)
                    }
                }
            }
        }
    }

    private var effortField: some View {
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
    }

    private var stepsField: some View {
        field("Steps", note: namedSteps.isEmpty
              ? "Optional. Break it up and each step pays its share."
              : "Each step pays about \(SILFormat.points(progressReward / max(1, namedSteps.count))) \(SILWord.progress).") {
            VStack(spacing: 0) {
                ForEach($steps) { $step in
                    HStack(spacing: 12) {
                        Button {
                            step.isDone.toggle()
                            HapticManager.shared.selection()
                        } label: {
                            Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundStyle(step.isDone ? S.ink : S.ink3)
                        }
                        .buttonStyle(.plain)

                        TextField("Step", text: $step.title)
                            .font(S.text(16))
                            .foregroundStyle(S.ink)

                        Button {
                            remove(step.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(S.ink3)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove step")
                    }
                    .frame(height: 54)
                    .overlay(alignment: .top) {
                        Rectangle().fill(S.line).frame(height: 1)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(S.ink3)
                        .frame(width: 19)
                    TextField("Add a step", text: $newStep)
                        .font(S.text(16))
                        .foregroundStyle(S.ink)
                        .submitLabel(.done)
                        .onSubmit(addStep)
                    if !newStep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Add", action: addStep)
                            .font(S.text(15, .medium))
                            .foregroundStyle(S.ink)
                            .buttonStyle(.plain)
                    }
                }
                .frame(height: 54)
                .overlay(alignment: .top) {
                    Rectangle().fill(S.line).frame(height: 1)
                }
            }
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

    private var trackingField: some View {
        field("Tracking", note: trackingNote) {
            VStack(alignment: .leading, spacing: 14) {
                FlowRow(spacing: 6) {
                    ForEach(QuestTrackingType.betaSelectableTypes, id: \.self) { option in
                        SILPill(label: label(for: option), selected: option == tracking, height: 38) {
                            tracking = option
                        }
                    }
                }

                switch tracking {
                case .manual:   manualTracking
                case .healthKit: healthTracking
                case .location: locationTracking
                case .timer:    EmptyView()
                }
            }
        }
    }

    @ViewBuilder private var manualTracking: some View {
        SILListCard {
            SILListRow(title: "How many", showsDivider: false) {
                valueButton("\(SILFormat.clampedInt(targetValue))") { wheel = .manualTarget }
            }
            SILListRow(title: "Called") {
                TextField("times", text: $unit)
                    .font(S.text(16))
                    .foregroundStyle(S.ink)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }

    @ViewBuilder private var healthTracking: some View {
        SILListCard {
            SILListRow(title: "Metric", showsDivider: false) {
                valueButton(healthMetric.displayName) { showMetricPicker = true }
            }
            SILListRow(title: "Target", detail: "In \(healthMetric.unit)") {
                valueButton(SILFormat.number(targetValue)) { wheel = .healthTarget }
            }
        }
    }

    @ViewBuilder private var locationTracking: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Street, city", text: $address, axis: .vertical)
                .lineLimit(1...2)
                .font(S.text(16))
                .foregroundStyle(S.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(S.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(S.line, lineWidth: 1)
                        )
                )

            if autocomplete.isSearching {
                Text("Looking it up…")
                    .font(S.text(14))
                    .foregroundStyle(S.ink2)
            }

            if !autocomplete.suggestions.isEmpty {
                SILListCard {
                    ForEach(Array(autocomplete.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        SILListRow(
                            title: suggestion.primaryText,
                            detail: suggestion.secondaryText,
                            showsDivider: index > 0
                        ) {
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(S.ink3)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            address = suggestion.fullText
                            Task { await resolveAddress() }
                        }
                    }
                }
            }

            if coordinate == nil {
                SILGhostButton(
                    title: isResolvingAddress ? "Checking…" : "Check this address",
                    height: 48
                ) {
                    Task { await resolveAddress() }
                }
                .disabled(isResolvingAddress || trimmedAddress.isEmpty)
                .opacity(trimmedAddress.isEmpty ? 0.5 : 1)
            }

            if let note = addressNote {
                Text(note)
                    .font(S.text(14))
                    .foregroundStyle(addressNoteIsProblem ? S.warn : S.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                    latitudinalMeters: max(400, radiusMeters * 2.5),
                    longitudinalMeters: max(400, radiusMeters * 2.5)
                ))) {
                    Marker(
                        coordinate.locationName,
                        coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    )
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(S.line, lineWidth: 1)
                )
                .allowsHitTesting(false)
            }

            SILListCard {
                SILListRow(title: "Stay for", showsDivider: false) {
                    valueButton("\(SILFormat.clampedInt(targetValue)) min") { wheel = .stay }
                }
                SILListRow(title: "Within") {
                    valueButton(radiusLabel) { wheel = .radius }
                }
            }
        }
    }

    private var goalField: some View {
        field("Moves a goal") {
            if linkableGoals.isEmpty {
                SILGhostButton(title: "Set a goal first", height: 48) {
                    showGoalComposer = true
                }
            } else {
                FlowRow(spacing: 6) {
                    SILPill(label: "None", selected: linkedGoalID == nil, height: 38) {
                        linkedGoalID = nil
                    }
                    ForEach(linkableGoals) { goal in
                        SILPill(label: goal.title, selected: linkedGoalID == goal.id, height: 38) {
                            linkedGoalID = goal.id
                        }
                    }
                }
            }
        }
    }

    private var scheduleField: some View {
        field("Repeats") {
            VStack(alignment: .leading, spacing: 14) {
                FlowRow(spacing: 6) {
                    ForEach(QuestFrequency.allCases) { option in
                        SILPill(label: option.rawValue, selected: option == frequency, height: 38) {
                            frequency = option
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
            }
        }
    }

    private var optionalRow: some View {
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

    // MARK: Small pieces

    @ViewBuilder private func field<Content: View>(
        _ label: String,
        note: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).silEyebrow()
            content()
            if let note {
                Text(note)
                    .font(S.text(13))
                    .foregroundStyle(S.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func valueButton(_ value: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(value)
                    .font(S.mono(13))
                    .foregroundStyle(S.ink)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(S.ink3)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Capsule().fill(S.card2))
        }
        .buttonStyle(.plain)
    }

    private func label(for type: QuestTrackingType) -> String {
        switch type {
        case .manual:    return "By hand"
        case .healthKit: return "Apple Health"
        case .location:  return "Location"
        case .timer:     return "Timer"
        }
    }

    private var trackingNote: String {
        switch tracking {
        case .manual:
            return "You mark this one done yourself."
        case .healthKit:
            return healthMetric == .workoutCount
                ? "Closes itself when Apple Health records a workout — from Fitness, the Watch, or anything that syncs in."
                : "Closes itself from Apple Health, including data synced from other apps."
        case .location:
            return "Closes itself once you've stayed within \(radiusLabel) for the time you set."
        case .timer:
            return "Closes when you run a focus session against it."
        }
    }

    private var radiusLabel: String {
        let miles = radiusMeters / 1609.34
        return String(format: "%.2f mi", miles)
    }

    private func toggle(_ attribute: SILAttribute) {
        if attributes.contains(attribute) {
            // Never leave it with nothing selected — something has to grow.
            guard attributes.count > 1 else {
                HapticManager.shared.warning()
                return
            }
            attributes.remove(attribute)
        } else if attributes.count < 3 {
            attributes.insert(attribute)
        } else {
            HapticManager.shared.warning()
            return
        }
        HapticManager.shared.selection()
    }

    private func addStep() {
        let trimmed = newStep.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        steps.append(Step(title: trimmed))
        newStep = ""
        HapticManager.shared.selection()
    }

    private func remove(_ id: UUID) {
        steps.removeAll { $0.id == id }
        HapticManager.shared.selection()
    }

    // MARK: Load

    private func load() {
        guard let habit = mode.existing else {
            if !mode.isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { titleFocused = true }
            }
            return
        }

        title = habit.title
        notes = habit.description
        effort = habit.difficulty
        attributes = Set(habit.targetStats.map(SILAttribute.containing))
        if attributes.isEmpty { attributes = [.spirit] }
        tracking = habit.trackingType
        frequency = habit.resolvedFrequency
        targetValue = habit.targetValue
        unit = habit.unit
        isOptional = habit.isOptional
        remind = habit.reminderEnabled
        reminderTime = habit.reminderTime ?? reminderTime
        steps = habit.subtasks.map(Step.init)

        address = habit.locationAddress ?? ""
        coordinate = habit.locationCoordinate
            ?? QuestDataManager.shared.cachedValidatedLocation(forQuestID: habit.id)
            ?? QuestDataManager.shared.cachedValidatedLocation(for: address)
        radiusMeters = coordinate?.radius ?? radiusMeters
        if let coordinate {
            addressNote = "Checked: \(coordinate.locationName)"
            addressNoteIsProblem = false
        }

        // Old location habits were stored as a single visit; the editor now
        // talks in minutes on site.
        if habit.trackingType == .location, habit.unit == "visits", habit.targetValue <= 1 {
            targetValue = 45
        }

        linkedGoalID = habit.linkedBossID
            ?? gameEngine.activeBossFights.first(where: { $0.linkedQuestIDs.contains(habit.id) })?.id

        if let identifier = habit.healthKitIdentifier {
            healthMetric = HealthKitQuestType.allCases.first { $0.identifier == identifier } ?? .steps
        }
    }

    // MARK: Save

    private func save() async {
        guard canSave else {
            HapticManager.shared.warning()
            failure = "Needs \(SILHabitEditor.list(missing))."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let existing = mode.existing
        let id = existing?.id ?? UUID()
        let stored = namedSteps.map(\.asSubtask)

        var resolvedCoordinate: LocationCoordinate?
        if tracking == .location {
            guard let base = await locationForSaving(existing: existing) else { return }
            resolvedCoordinate = LocationCoordinate(
                latitude: base.latitude,
                longitude: base.longitude,
                radius: radiusMeters,
                locationName: base.locationName
            )
            if let resolvedCoordinate {
                QuestDataManager.shared.cacheValidatedLocation(
                    resolvedCoordinate,
                    forQuestID: id,
                    address: trimmedAddress
                )
            }
        }

        let now = Date()
        let habit = DailyQuest(
            id: id,
            title: trimmedTitle,
            description: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            difficulty: effort,
            status: status(for: stored, existing: existing),
            targetStats: attributes.sorted { $0.rawValue < $1.rawValue }.map(\.primaryStat),
            frequency: frequency,
            isOptional: isOptional,
            trackingType: tracking,
            currentProgress: progress(for: stored, existing: existing),
            targetValue: max(1, targetValue),
            unit: storedUnit,
            createdAt: existing?.createdAt ?? now,
            // Changing how often it repeats restarts the window; keeping the
            // same cadence must not push today's deadline out.
            expiresAt: existing.map { $0.resolvedFrequency == frequency ? $0.expiresAt : frequency.nextResetDate(from: now) }
                ?? frequency.nextResetDate(from: now),
            healthKitIdentifier: tracking == .healthKit ? healthMetric.identifier : nil,
            locationCoordinate: resolvedCoordinate,
            locationAddress: tracking == .location ? trimmedAddress : nil,
            linkedBossID: linkedGoalID,
            reminderEnabled: remind,
            reminderTime: remind ? reminderTime : nil,
            subtasks: stored
        )

        gameEngine.saveQuest(habit, replacing: existing?.id)
        if remind {
            NotificationManager.shared.scheduleQuestReminder(for: habit)
        }
        HapticManager.shared.success()
        dismiss()
    }

    /// The coordinate to store. Reuses what is already known before asking
    /// Apple Maps again, and reports its own failure.
    private func locationForSaving(existing: DailyQuest?) async -> LocationCoordinate? {
        if existing?.locationAddress == trimmedAddress, let known = existing?.locationCoordinate {
            return known
        }
        if let checked = coordinate { return checked }
        if let cached = QuestDataManager.shared.cachedValidatedLocation(for: trimmedAddress) { return cached }
        if let resolved = await SILAddressResolver.resolve(trimmedAddress) { return resolved }
        failure = "Apple Maps couldn't find that address. A street, city and region usually does it."
        return nil
    }

    private var storedUnit: String {
        switch tracking {
        case .healthKit: return healthMetric.unit
        case .location:  return "minutes"
        case .manual:    return unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "times" : unit
        case .timer:     return unit
        }
    }

    private func status(for stored: [QuestSubtask], existing: DailyQuest?) -> QuestStatus {
        guard !stored.isEmpty else { return existing?.status ?? .available }
        if stored.allSatisfy(\.isCompleted) {
            return existing?.status == .completed ? .completed : .inProgress
        }
        return stored.contains(where: \.isCompleted) ? .inProgress : .available
    }

    private func progress(for stored: [QuestSubtask], existing: DailyQuest?) -> Double {
        guard !stored.isEmpty else { return existing?.currentProgress ?? 0 }
        return Double(stored.filter(\.isCompleted).count) / Double(stored.count)
    }

    private func resolveAddress() async {
        guard !trimmedAddress.isEmpty else {
            addressNote = "Type an address first."
            addressNoteIsProblem = true
            return
        }

        isResolvingAddress = true
        defer { isResolvingAddress = false }

        guard let resolved = await SILAddressResolver.resolve(trimmedAddress) else {
            coordinate = nil
            addressNote = "Couldn't find that one. Try adding the city and region."
            addressNoteIsProblem = true
            return
        }

        let found = LocationCoordinate(
            latitude: resolved.latitude,
            longitude: resolved.longitude,
            radius: radiusMeters,
            locationName: resolved.locationName
        )
        coordinate = found
        // Settle on the canonical text so reopening the habit doesn't drift
        // between equivalent spellings of the same place.
        address = resolved.locationName
        addressNote = "Checked: \(resolved.locationName)"
        addressNoteIsProblem = false
        autocomplete.clear()
        QuestDataManager.shared.cacheValidatedLocation(
            found,
            forQuestID: mode.existing?.id,
            address: resolved.locationName
        )
    }

    // MARK: Wheels

    private enum Wheel: String, Identifiable {
        case manualTarget, healthTarget, stay, radius

        var id: String { rawValue }

        var title: String {
            switch self {
            case .manualTarget: return "How many"
            case .healthTarget: return "Target"
            case .stay:         return "Stay for"
            case .radius:       return "Within"
            }
        }

        var subtitle: String {
            switch self {
            case .manualTarget: return "How many times counts as done."
            case .healthTarget: return "What Apple Health has to reach."
            case .stay:         return "How long you have to be there."
            case .radius:       return "How close counts as being there."
            }
        }
    }

    private func options(for wheel: Wheel) -> [WheelValueOption] {
        switch wheel {
        case .manualTarget:
            return (1...100).map { WheelValueOption(value: Double($0), label: "\($0)") }
        case .healthTarget:
            return healthMetric.targetOptions
        case .stay:
            return stride(from: 5, through: 240, by: 5).map {
                WheelValueOption(value: Double($0), label: "\($0) min")
            }
        case .radius:
            return stride(from: 100, through: 1600, by: 50).map { metres in
                WheelValueOption(
                    value: Double(metres),
                    label: String(format: "%.2f mi · %d m", Double(metres) / 1609.34, metres)
                )
            }
        }
    }

    private func binding(for wheel: Wheel) -> Binding<Double> {
        wheel == .radius ? $radiusMeters : $targetValue
    }

    // MARK: Step draft

    /// A subtask being edited. Held separately from `QuestSubtask` so a row
    /// can be blank while it is typed into without reaching the model.
    struct Step: Identifiable {
        let id: UUID
        var title: String
        var isDone: Bool
        let createdAt: Date

        init(id: UUID = UUID(), title: String = "", isDone: Bool = false, createdAt: Date = Date()) {
            self.id = id
            self.title = title
            self.isDone = isDone
            self.createdAt = createdAt
        }

        init(_ subtask: QuestSubtask) {
            self.init(
                id: subtask.id,
                title: subtask.title,
                isDone: subtask.isCompleted,
                createdAt: subtask.createdAt
            )
        }

        var asSubtask: QuestSubtask {
            QuestSubtask(
                id: id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                isCompleted: isDone,
                createdAt: createdAt
            )
        }
    }
}

#Preview {
    SILHabitEditor(mode: .add)
        .environmentObject(GameEngine.shared)
}
