//
//  MainTabView.swift
//  SIL
//
//  The SIL 2.0 shell: four destinations — Today, Goals, Focus, You — behind a
//  floating tab bar, with a compose button beside it.
//
//  The old five-tab RPG layout (Status / Quests / Training / Bosses / Shop)
//  collapses into this. Habits and Rewards are no longer tabs; they are opened
//  from Today and You, which is what the prototype does.
//

import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {

    // MARK: - Properties

    @EnvironmentObject var gameEngine: GameEngine
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @AppStorage("defaultTab") private var defaultTab: Int = 0

    @State private var selectedTab: SILTab
    @State private var pushedScreen: SILPushedScreen?
    @State private var currentSystemMessage: SystemMessage?

    // MARK: - Initialization

    init() {
        let saved = SettingsManager.shared.defaultTab
        _selectedTab = State(initialValue: SILTab.from(tabIndex: saved))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            S.bg.ignoresSafeArea()

            tabContent
                .transition(.opacity)

            SILTabBar(selection: $selectedTab) {
                pushedScreen = .compose
            }
            .padding(.bottom, 10)

            if let completion = gameEngine.lastCompletion {
                SILCompletionOverlay(
                    title: completion.title,
                    headline: completion.headline,
                    progress: completion.progress,
                    credits: completion.credits,
                    attribute: completion.attribute,
                    attributeGain: completion.attributeGain,
                    goalNote: completion.goalName,
                    note: completion.note,
                    canUndo: gameEngine.canUndoLatestQuestCompletion,
                    onUndo: {
                        _ = gameEngine.undoLastQuestCompletion()
                        gameEngine.lastCompletion = nil
                    },
                    onContinue: { gameEngine.lastCompletion = nil }
                )
                .zIndex(60)
            }

            if let message = currentSystemMessage {
                VStack {
                    SystemMessageBanner(message: message) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            currentSystemMessage = nil
                        }
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .sheet(item: $pushedScreen) { screen in
            pushedView(for: screen)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSystemMessage)) { notification in
            if let message = notification.object as? SystemMessage {
                withAnimation(.easeOut(duration: 0.22)) {
                    currentSystemMessage = message
                }
            }
        }
        .onAppear {
            track(selectedTab)
        }
        .onChange(of: defaultTab) { _, newValue in
            selectedTab = SILTab.from(tabIndex: newValue)
        }
        .onChange(of: selectedTab) { _, newValue in
            HapticManager.shared.selection()
            track(newValue)
        }
        .onChange(of: deepLinkManager.pendingLink) { _, link in
            guard let link else { return }
            apply(link.route)
        }
        .fullScreenCover(item: $gameEngine.deathPenaltySummary) { summary in
            SILRecalibrationOverlay(
                summary: summary,
                momentum: gameEngine.player.momentum,
                level: gameEngine.player.level,
                credits: gameEngine.player.credits
            ) {
                gameEngine.deathPenaltySummary = nil
            }
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $gameEngine.showLevelUpAlert) {
            if let data = gameEngine.lastLevelUpData {
                SILLevelUpOverlay(
                    data: data,
                    totalHabits: gameEngine.player.completedQuestCount
                ) {
                    gameEngine.showLevelUpAlert = false
                }
            }
        }
    }

    // MARK: - Tabs

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case .today:
            SILTodayView(
                onOpenHabits: { pushedScreen = .habits },
                onOpenYou: { selectedTab = .you }
            )
        case .goals:
            SILGoalsView()
        case .focus:
            SILFocusView()
        case .you:
            SILYouView()
        }
    }

    @ViewBuilder private func pushedView(for screen: SILPushedScreen) -> some View {
        switch screen {
        case .habits:
            SILHabitsView()
        case .rewards:
            GlassworkShopView()
        case .compose:
            // The compose button creates a habit; goals are created from the
            // Goals tab, which has its own flow.
            QuestFormSheet(mode: .add)
        }
    }

    // MARK: - Routing

    private func apply(_ route: AppDeepLinkRoute) {
        switch route {
        case .status:   selectedTab = .you
        case .training: selectedTab = .focus
        case .bosses:   selectedTab = .goals
        case .quests:   selectedTab = .today; pushedScreen = .habits
        case .shop:     selectedTab = .you;   pushedScreen = .rewards
        }
    }

    private func track(_ tab: SILTab) {
        AnalyticsManager.shared.trackScreenView(tab.title)
        AnalyticsManager.shared.trackFeature("tab_selected_\(tab.title)")
    }
}

// MARK: - Pushed screens

/// Screens reachable from a tab rather than being tabs themselves.
enum SILPushedScreen: String, Identifiable {
    case habits, rewards, compose

    var id: String { rawValue }
}

// MARK: - Tab storage

extension SILTab {
    /// `defaultTab` and the deep-link routes still store the old five-tab
    /// indices. Map them onto the four destinations so saved preferences and
    /// existing links keep working.
    static func from(tabIndex index: Int) -> SILTab {
        switch index {
        case 1: return .today   // Quests -> Today, which opens Habits
        case 2: return .focus   // Training
        case 3: return .goals   // Bosses
        case 4: return .you     // Shop -> You, which holds Rewards
        default: return .today  // Status
        }
    }

    var tabIndex: Int {
        switch self {
        case .today: return 1
        case .focus: return 2
        case .goals: return 3
        case .you:   return 0
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let showSystemMessage = Notification.Name("showSystemMessage")
}

// MARK: - Launch tab

/// Backs the "Open App To" picker in Settings. Its raw values are the old
/// five-tab indices, which `defaultTab` already stores on disk, so existing
/// preferences survive the move to four destinations.
enum GameTab: Int, CaseIterable, Identifiable {
    case today = 1
    case goals = 3
    case focus = 2
    case you = 0

    var id: Int { rawValue }

    var tab: SILTab {
        SILTab.from(tabIndex: rawValue)
    }

    var title: String { tab.title }

    var icon: String { tab.symbol }
}


struct DeathPenaltySummaryView: View {
    let summary: DeathPenaltySummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GW.bg.ignoresSafeArea()
                Canvas { ctx, size in
                    let w = size.width, h = size.height
                    func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
                        let rect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
                        let g = Gradient(colors: [color, color.opacity(0)])
                        ctx.fill(Path(ellipseIn: rect),
                                 with: .radialGradient(g, center: c,
                                                       startRadius: 0,
                                                       endRadius: max(rx, ry)))
                    }
                    ellipse(CGPoint(x: w * 0.5, y: h * 0.0), w * 0.9, h * 0.5, GW.danger.opacity(0.35))
                    ellipse(CGPoint(x: w * 0.5, y: h * 1.0), w * 0.7, h * 0.5, GW.danger.opacity(0.15))
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("[ SYSTEM · DEFEAT ]")
                            .font(GW.mono(10, weight: .medium))
                            .tracking(3)
                            .foregroundStyle(GW.danger)
                        Text("You were defeated.")
                            .font(GW.display(28, weight: .bold))
                            .tracking(-0.5)
                            .foregroundStyle(GW.ink)
                        Text("You missed \(summary.missedQuestCount) required quest\(summary.missedQuestCount == 1 ? "" : "s"). Health was restored, and penalties were applied.")
                            .font(GW.sans(13))
                            .foregroundStyle(GW.mute)
                            .lineSpacing(3)

                        GWCard(paddingX: 14, paddingY: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("RANK")
                                    .font(GW.mono(9, weight: .medium))
                                    .tracking(2)
                                    .foregroundStyle(GW.mute)
                                Text(summary.wasDemoted ? "\(summary.previousRank.rawValue) → \(summary.newRank.rawValue)" : "\(summary.previousRank.rawValue) · NO DEMOTION")
                                    .font(GW.display(18, weight: .bold))
                                    .foregroundStyle(summary.wasDemoted ? GW.amber : GW.ink)
                            }
                        }

                        GWCard(paddingX: 14, paddingY: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CURRENCY")
                                    .font(GW.mono(9, weight: .medium))
                                    .tracking(2)
                                    .foregroundStyle(GW.mute)
                                HStack(alignment: .firstTextBaseline) {
                                    Text("−\(summary.goldLost.formatted()) g")
                                        .font(GW.display(20, weight: .bold))
                                        .foregroundStyle(GW.danger)
                                    Spacer()
                                    Text("\(summary.goldRemaining.formatted()) remaining")
                                        .font(GW.mono(10))
                                        .foregroundStyle(GW.mute)
                                }
                            }
                        }

                        GWCard(paddingX: 14, paddingY: 12) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("STAT LOSS")
                                        .font(GW.mono(9, weight: .medium))
                                        .tracking(2)
                                        .foregroundStyle(GW.mute)
                                    Spacer()
                                    Text("−\(summary.statLossPercent)%")
                                        .font(GW.mono(9, weight: .bold))
                                        .tracking(2)
                                        .foregroundStyle(GW.danger)
                                }
                                ForEach(summary.statLosses) { loss in
                                    HStack {
                                        Text(loss.stat.rawValue)
                                            .font(GW.mono(11, weight: .bold))
                                            .tracking(1.2)
                                            .foregroundStyle(loss.stat.color)
                                        Text(loss.stat.rawValue == "STR" ? "Strength"
                                             : loss.stat.rawValue == "INT" ? "Intelligence"
                                             : loss.stat.rawValue == "AGI" ? "Agility"
                                             : loss.stat.rawValue == "VIT" ? "Vitality"
                                             : loss.stat.rawValue == "WIL" ? "Willpower"
                                             : loss.stat.rawValue == "SPI" ? "Spirit"
                                             : "")
                                            .font(GW.sans(12))
                                            .foregroundStyle(GW.inkSoft)
                                        Spacer()
                                        Text("−\(loss.lost)")
                                            .font(GW.mono(12, weight: .bold))
                                            .foregroundStyle(GW.danger)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Continue") { dismiss() }
                        .font(GW.sans(14, weight: .semibold))
                        .foregroundStyle(GW.cyan)
                }
            }
            .toolbarBackground(GW.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Death Report")
            .navigationBarTitleDisplayMode(.inline)
        }
        .foregroundStyle(GW.ink)
        
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(GameEngine.shared)
}
