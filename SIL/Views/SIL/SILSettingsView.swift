//
//  SILSettingsView.swift
//  SIL
//
//  Settings, rebuilt from the prototype: mono section labels over grouped
//  cards of plain rows. Appearance first (mode, accent, app icon), then what
//  a recalibration costs, reminders, connections and the general shelf.
//
//  Nothing here is styled as a console. A settings row is a label, maybe a
//  line of explanation, and one control.
//

import SwiftUI

struct SILSettingsView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var appearance = SILAppearance.shared
    @ObservedObject private var iconModel = AppIconManager.shared

    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw: String = AppearancePreference.system.rawValue
    @AppStorage("defaultTab") private var defaultTab: Int = 0

    @State private var haptics = SettingsManager.shared.hapticEnabled
    @State private var reminders = SettingsManager.shared.eveningReminderEnabled
    @State private var streakAlerts = SettingsManager.shared.streakAlertsEnabled
    @State private var health = SettingsManager.shared.autoTrackHealthKit
    @State private var location = SettingsManager.shared.autoTrackLocation
    @State private var dropsLevel = SettingsManager.shared.recalibrationDropsLevel
    @State private var easesAttributes = SettingsManager.shared.recalibrationEasesAttributes
    @State private var costsCredits = SettingsManager.shared.recalibrationCostsCredits

    @State private var showWidgets = false
    @State private var showPermissions = false
    @State private var showFAQ = false

    private var appearancePreference: Binding<AppearancePreference> {
        Binding(
            get: { AppearancePreference(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        SILScreen(spacing: 12) {
            HStack {
                SILRoundButton(systemImage: "chevron.left") { dismiss() }
                Spacer(minLength: 0)
            }

            Text("Settings")
                .silTitle()
                .padding(.vertical, 6)

            appearanceSection
            momentumSection
            remindersSection
            connectionsSection
            generalSection

            Text("SIL \(appVersion) · Systematically Improving Lifestyle")
                .silEyebrow(9)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 18)
        }
        .sheet(isPresented: $showWidgets) { SILWidgetGalleryView() }
        .sheet(isPresented: $showPermissions) { PermissionManagerView() }
        .sheet(isPresented: $showFAQ) {
            NavigationStack {
                ScrollView { FAQSection() }
                    .background(S.bg)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0"
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance").silEyebrow().padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 18) {
                SILSegmented(
                    options: [
                        (AppearancePreference.system, "System"),
                        (AppearancePreference.light, "Light"),
                        (AppearancePreference.dark, "Dark")
                    ],
                    selection: appearancePreference
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Accent").font(S.text(16)).foregroundStyle(S.ink)
                    HStack(spacing: 10) {
                        ForEach(SILAccent.allCases) { option in
                            accentSwatch(option)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("App icon").font(S.text(16)).foregroundStyle(S.ink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(AppIconOption.allCases) { option in
                            iconSwatch(option)
                        }
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(S.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
            )
        }
    }

    private func accentSwatch(_ option: SILAccent) -> some View {
        let selected = appearance.accent == option
        return Button {
            appearance.accent = option
            HapticManager.shared.selection()
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(swatchColor(option))
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(S.line2, lineWidth: 1))
                    .padding(3)
                    .overlay(
                        Circle().strokeBorder(selected ? S.ink : .clear, lineWidth: 1.5)
                    )
                Text(option.label)
                    .font(S.text(12))
                    .foregroundStyle(selected ? S.ink : S.ink2)
            }
        }
        .buttonStyle(.plain)
    }

    private func swatchColor(_ option: SILAccent) -> Color {
        switch option {
        case .violet: return S.hex("5B3CFF")
        case .orange: return S.hex("FF6A2B")
        case .mono:   return S.ink
        }
    }

    private func iconSwatch(_ option: AppIconOption) -> some View {
        let selected = iconModel.currentOption == option
        return Button {
            iconModel.setIcon(option)
        } label: {
            VStack(spacing: 8) {
                Image(option.previewAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? S.ink : .clear, lineWidth: 1.5)
                    )
                Text(option.displayName)
                    .font(S.text(12))
                    .foregroundStyle(selected ? S.ink : S.ink2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Momentum

    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SILWord.momentum).silEyebrow().padding(.horizontal, 4).padding(.top, 14)

            Text("Missed required habits drain momentum. If it reaches zero, SIL recalibrates: the meter refills and the costs below apply.")
                .font(S.text(14))
                .foregroundStyle(S.ink2)
                .padding(.horizontal, 4)

            SILListCard {
                SILListRow(title: "Drop one level") {
                    toggle($dropsLevel) { SettingsManager.shared.recalibrationDropsLevel = $0 }
                }
                SILListRow(title: "Ease attributes back") {
                    toggle($easesAttributes) { SettingsManager.shared.recalibrationEasesAttributes = $0 }
                }
                SILListRow(title: "Give up 20% of credits") {
                    toggle($costsCredits) { SettingsManager.shared.recalibrationCostsCredits = $0 }
                }
            }
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders").silEyebrow().padding(.horizontal, 4).padding(.top, 14)

            SILListCard {
                SILListRow(title: "Habit reminders") {
                    toggle($reminders) { SettingsManager.shared.eveningReminderEnabled = $0 }
                }
                SILListRow(title: "Streak alerts", detail: "A nudge when a run is about to break") {
                    toggle($streakAlerts) { SettingsManager.shared.streakAlertsEnabled = $0 }
                }
            }
        }
    }

    // MARK: - Connections

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connections").silEyebrow().padding(.horizontal, 4).padding(.top, 14)

            SILListCard {
                SILListRow(title: "Apple Health", detail: "Steps, sleep, water, workouts, weight") {
                    toggle($health) { SettingsManager.shared.autoTrackHealthKit = $0 }
                }
                SILListRow(title: "Location", detail: "Check in at the gym or the library") {
                    toggle($location) { SettingsManager.shared.autoTrackLocation = $0 }
                }
                SILListRow(title: "Permissions") {
                    chevronButton { showPermissions = true }
                }
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General").silEyebrow().padding(.horizontal, 4).padding(.top, 14)

            SILListCard {
                SILListRow(title: "Haptics") {
                    toggle($haptics) { SettingsManager.shared.hapticEnabled = $0 }
                }
                SILListRow(title: "Open on") {
                    Picker("", selection: $defaultTab) {
                        ForEach(GameTab.allCases) { tab in
                            Text(tab.localizedTitle).tag(tab.rawValue)
                        }
                    }
                    .labelsHidden()
                    .tint(S.ink2)
                }
                SILListRow(title: "Widgets") {
                    chevronButton { showWidgets = true }
                }
                SILListRow(title: "Questions") {
                    chevronButton { showFAQ = true }
                }
            }
        }
    }

    // MARK: - Controls

    private func toggle(_ binding: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        Toggle("", isOn: Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                onChange(newValue)
                HapticManager.shared.selection()
            }
        ))
        .labelsHidden()
        .toggleStyle(SILToggleStyle())
    }

    private func chevronButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(S.ink3)
                .frame(width: 32, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget gallery

/// What the widgets look like and how to add them. A preview, not a control
/// panel — the Home Screen is where they are actually placed.
struct SILWidgetGalleryView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss

    private var player: Player { gameEngine.player }

    private var leftCount: Int {
        gameEngine.dailyQuests.filter { $0.status != .completed && $0.status != .expired }.count
    }

    var body: some View {
        SILScreen(spacing: 14) {
            HStack {
                SILRoundButton(systemImage: "chevron.left") { dismiss() }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Widgets").silTitle()
                Text("Long-press your wallpaper to add one.")
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
            }
            .padding(.vertical, 6)

            Text("Home Screen").silEyebrow().padding(.horizontal, 4).padding(.top, 6)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                widgetTile {
                    VStack(alignment: .leading) {
                        SILRing(progress: player.momentumShare, size: 58, lineWidth: 3.5) {
                            Text("\(player.momentum)").silNumeral(20)
                        }
                        Spacer()
                        Text(SILWord.momentum).font(S.text(15, .medium)).foregroundStyle(S.ink)
                        Text("\(player.currentStreak)-day streak")
                            .font(S.text(12))
                            .foregroundStyle(S.ink2)
                    }
                }
                widgetTile {
                    VStack(alignment: .leading) {
                        Text("Left today").silEyebrow(8.5)
                        Spacer()
                        Text("\(leftCount)").silNumeral(40)
                        Text("level \(player.level)")
                            .font(S.text(12))
                            .foregroundStyle(S.ink2)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(S.bg2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
            )
        }
    }

    private func widgetTile<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(S.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
            )
    }
}
