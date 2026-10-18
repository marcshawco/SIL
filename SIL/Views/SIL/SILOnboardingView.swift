//
//  SILOnboardingView.swift
//  SIL
//
//  Four steps, from the prototype. A progress rule across the top, one large
//  statement per screen, and a single action at the bottom.
//
//  The old first-launch flow sold the fantasy — ranks, the System, awakening.
//  This one asks three questions and gets out of the way: what are you
//  building, which three habits, and what may SIL read on its own.
//

import SwiftUI

struct SILOnboardingView: View {
    @EnvironmentObject private var gameEngine: GameEngine

    /// Called once the picked habits have been written.
    var onFinish: () -> Void

    @State private var step = 0
    @State private var attributes: Set<SILAttribute> = [.mind, .body]
    @State private var picks: Set<String> = ["starter-read", "starter-water", "starter-meditate"]
    @State private var allowHealth = true
    @State private var allowLocation = false
    @State private var allowNotifications = true

    private let stepCount = 4

    var body: some View {
        ZStack {
            S.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    Group {
                        switch step {
                        case 0:  welcomeStep
                        case 1:  attributesStep
                        case 2:  habitsStep
                        default: permissionsStep
                        }
                    }
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)

                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 64)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? S.ink : S.line2)
                        .frame(height: 2)
                }
            }
            Button("Skip") { finish() }
                .font(S.text(15))
                .foregroundStyle(S.ink2)
                .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if step > 0 {
                SILRoundButton(systemImage: "arrow.left", size: 58) {
                    withAnimation(.easeOut(duration: 0.2)) { step -= 1 }
                }
                .overlay(Circle().strokeBorder(S.line2, lineWidth: 1))
            }
            SILPrimaryButton(title: callToAction, enabled: canAdvance) {
                advance()
            }
        }
    }

    private var callToAction: String {
        switch step {
        case 0:  return "Start"
        case 1:  return attributes.isEmpty ? "Pick at least one" : "Next"
        case 2:  return picks.isEmpty ? "Pick at least one" : "Next"
        default: return "Finish"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1:  return !attributes.isEmpty
        case 2:  return !picks.isEmpty
        default: return true
        }
    }

    private func advance() {
        HapticManager.shared.selection()
        if step == stepCount - 1 {
            finish()
        } else {
            withAnimation(.easeOut(duration: 0.2)) { step += 1 }
        }
    }

    private func stepNumber(_ value: Int) -> some View {
        Text("\(value)")
            .font(S.display(20, .semibold))
            .foregroundStyle(S.onInv)
            .frame(width: 52, height: 38)
            .background(Capsule().fill(S.inv))
    }

    private func statement(_ text: String) -> some View {
        Text(text)
            .font(S.display(42, .semibold))
            .tracking(S.displayTracking(42))
            .foregroundStyle(S.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func lead(_ text: String) -> some View {
        Text(text)
            .font(S.text(17))
            .foregroundStyle(S.ink2)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            SILMarkTile(size: 96)
            Spacer(minLength: 40)
            Text("SIL · Systematically Improving Lifestyle").silEyebrow(10)
            Text("Small things, done daily, measured honestly.")
                .font(S.display(46, .semibold))
                .tracking(S.displayTracking(46))
                .foregroundStyle(S.ink)
                .fixedSize(horizontal: false, vertical: true)
            lead("Habits, goals and focus in one quiet system. The progress compounds, and you'll see it.")
        }
    }

    private var attributesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepNumber(1)
            statement("What are you building?")
            lead("Pick the areas you want to grow. You can change this later.")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(SILAttribute.allCases) { attribute in
                    let on = attributes.contains(attribute)
                    Button {
                        HapticManager.shared.selection()
                        if on { attributes.remove(attribute) } else { attributes.insert(attribute) }
                    } label: {
                        VStack(alignment: .leading) {
                            attribute.glyph
                                .frame(width: 14, height: 14)
                                .foregroundStyle(on ? S.onInv : S.ink)
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(attribute.name)
                                    .font(S.display(20, .semibold))
                                    .tracking(-0.4)
                                Text(note(for: attribute))
                                    .font(S.text(13))
                                    .foregroundStyle(on ? S.onInv.opacity(0.7) : S.ink2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .foregroundStyle(on ? S.onInv : S.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 150)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(on ? S.inv : S.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .strokeBorder(on ? .clear : S.line, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
    }

    private func note(for attribute: SILAttribute) -> String {
        switch attribute {
        case .body:   return "Moving, lifting, walking"
        case .mind:   return "Reading, studying, making"
        case .energy: return "Sleep, water, food"
        case .spirit: return "Stillness, patience, care"
        }
    }

    private var habitsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepNumber(2)
            statement("Start with three.")
            lead("Three habits you keep beat ten you drop. Add more once these feel easy.")

            VStack(spacing: 0) {
                ForEach(starters) { starter in
                    let on = picks.contains(starter.id)
                    Button {
                        HapticManager.shared.selection()
                        if on { picks.remove(starter.id) } else { picks.insert(starter.id) }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(on ? S.inv : S.card2)
                                if on {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(S.onInv)
                                } else {
                                    starter.attribute.glyph
                                        .frame(width: 11, height: 11)
                                        .foregroundStyle(S.ink)
                                }
                            }
                            .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(starter.title)
                                    .font(S.text(17, .medium))
                                    .foregroundStyle(S.ink)
                                Text(starter.note)
                                    .font(S.text(14))
                                    .foregroundStyle(S.ink2)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepNumber(3)
            statement("Let it track itself.")
            lead("The less you log by hand, the longer you'll stay with it. Your data stays on your devices.")

            SILListCard {
                SILListRow(
                    title: "Apple Health",
                    detail: "Steps, sleep, water, workouts, weight",
                    showsDivider: false
                ) {
                    Toggle("", isOn: $allowHealth).labelsHidden().toggleStyle(SILToggleStyle())
                }
                SILListRow(title: "Location", detail: "Check in at the gym or the library") {
                    Toggle("", isOn: $allowLocation).labelsHidden().toggleStyle(SILToggleStyle())
                }
                SILListRow(title: "Notifications", detail: "Reminders at the times you choose") {
                    Toggle("", isOn: $allowNotifications).labelsHidden().toggleStyle(SILToggleStyle())
                }
            }
        }
    }

    // MARK: - Starters

    private struct Starter: Identifiable {
        let id: String
        let title: String
        let note: String
        let attribute: SILAttribute
        let tracking: QuestTrackingType
    }

    /// Starters for the attributes the user picked, so step two follows from
    /// step one rather than offering the same seven regardless.
    private var starters: [Starter] {
        let all: [Starter] = [
            .init(id: "starter-walk", title: "Walk 8,000 steps", note: "Apple Health · automatic", attribute: .body, tracking: .healthKit),
            .init(id: "starter-lift", title: "Strength session", note: "Three times a week", attribute: .body, tracking: .manual),
            .init(id: "starter-read", title: "Read 20 pages", note: "Daily · by hand", attribute: .mind, tracking: .manual),
            .init(id: "starter-write", title: "Write for 30 minutes", note: "Daily · timer", attribute: .mind, tracking: .timer),
            .init(id: "starter-water", title: "Drink 2 L of water", note: "Apple Health · automatic", attribute: .energy, tracking: .healthKit),
            .init(id: "starter-sleep", title: "In bed by 23:00", note: "Apple Health · automatic", attribute: .energy, tracking: .healthKit),
            .init(id: "starter-meditate", title: "Meditate 10 min", note: "Daily · timer", attribute: .spirit, tracking: .timer),
            .init(id: "starter-journal", title: "Journal, five minutes", note: "Daily · by hand", attribute: .spirit, tracking: .manual)
        ]
        let chosen = attributes.isEmpty ? Set(SILAttribute.allCases) : attributes
        return all.filter { chosen.contains($0.attribute) }
    }

    // MARK: - Finish

    private func finish() {
        let selected = starters.filter { picks.contains($0.id) }
        for starter in selected {
            let habit = DailyQuest(
                title: starter.title,
                description: starter.note,
                difficulty: .easy,
                targetStats: [starter.attribute.primaryStat],
                frequency: .daily,
                trackingType: starter.tracking == .healthKit ? .manual : starter.tracking,
                unit: "times"
            )
            gameEngine.saveQuest(habit)
        }

        SettingsManager.shared.autoTrackHealthKit = allowHealth
        SettingsManager.shared.autoTrackLocation = allowLocation
        SettingsManager.shared.eveningReminderEnabled = allowNotifications

        if allowNotifications {
            Task { try? await NotificationManager.shared.requestAuthorization() }
        }

        gameEngine.save()
        AnalyticsManager.shared.trackFeature("onboarding_completed")
        onFinish()
    }
}
