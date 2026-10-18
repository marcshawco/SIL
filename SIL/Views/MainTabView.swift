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
        case .compose:
            SILComposeSheet(initialKind: selectedTab == .goals ? .goal : .habit)
        }
    }

    // MARK: - Routing

    private func apply(_ route: AppDeepLinkRoute) {
        switch route {
        case .status:   selectedTab = .you
        case .training: selectedTab = .focus
        case .bosses:   selectedTab = .goals
        case .quests:   selectedTab = .today; pushedScreen = .habits
        // Rewards are a section of You rather than a screen of their own.
        case .shop:     selectedTab = .you
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
    case habits, compose

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


#Preview {
    MainTabView()
        .environmentObject(GameEngine.shared)
}
