//
//  SILApp.swift
//  SIL
//
//  [SYSTEM]: Application core initialized.
//  Welcome to the Game of Life.
//
//  Created by Marcus Shaw II on 2/5/26.
//

import SwiftUI

@main
struct SILApp: App {

    // MARK: - State Objects

    @StateObject private var gameEngine = GameEngine.shared
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var preferredLanguageCode = AppLanguage.system.rawValue

    // MARK: - Environment

    init() {
        // [SYSTEM]: Configure app defaults
        SettingsManager.shared.setDefaults()
        AppearancePreference.migrateLegacyKeysIfNeeded()
        _ = CloudKitSyncManager.shared
        AnalyticsManager.shared.trackAppLaunch()

        // [SYSTEM]: Configure appearance
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(gameEngine)
                .environmentObject(deepLinkManager)
                .preferredColorScheme(resolvedColorScheme)
                .environment(\.locale, resolvedLocale)
                .id(preferredLanguageCode)
                .onOpenURL { url in
                    deepLinkManager.handle(url)
                }
                .onAppear {
                    configureAppearance()
                }
            // [SYSTEM]: NO permission bombing - permissions are requested
            // via "Neural Link" setup quests in onboarding or settings
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        (AppearancePreference(rawValue: appearanceRaw) ?? .system).colorScheme
    }

    private var resolvedLocale: Locale {
        AppLanguage(rawValue: preferredLanguageCode)?.locale ?? .autoupdatingCurrent
    }

    // MARK: - Configuration

    private func configureAppearance() {
        // Navigation and tab bars still show through on the few pushed
        // screens. `UIColor(SwiftUIColor)` keeps the trait closure that `S`
        // builds its tokens from, so these follow light and dark too.
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(S.bg)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(S.ink),
            .font: S.uiSans(17, .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(S.ink),
            .font: S.uiSans(34, .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // The raised surface, so a system tab dock matches the cards.
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(S.bg2)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Every UITableView (which backs SwiftUI Form and List) goes clear so
        // the page ground reads through instead of a stark white card.
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }
}

// MARK: - Root View

/// The root view that handles onboarding vs main app flow
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var gameEngine: GameEngine

    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                SILOnboardingView {
                    hasCompletedOnboarding = true
                }
                    .transition(.opacity)
            } else {
                MainTabView()
                    .environmentObject(gameEngine)
                    .transition(.opacity)
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackScreenView("splash")
            // Show splash for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: showSplash) { _, isShowingSplash in
            guard !isShowingSplash else { return }
            AnalyticsManager.shared.trackScreenView(hasCompletedOnboarding ? "main_tabs" : "onboarding")
        }
    }
}

// MARK: - Splash View

/// The initial splash screen with system initialization effect
struct SplashView: View {
    @State private var showBrand = false
    @State private var showStatus = false

    var body: some View {
        ZStack {
            S.bg
                .ignoresSafeArea()

            VStack(spacing: 20) {
                SILMarkTile(size: 96)
                    .scaleEffect(showBrand ? 1 : 0.92)
                    .opacity(showBrand ? 1 : 0)

                if showStatus {
                    Text("SIL · Systematically Improving Lifestyle")
                        .silEyebrow(10)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 32)
            .offset(y: -8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
                showBrand = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showStatus = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView(hasCompletedOnboarding: .constant(true))
        .environmentObject(GameEngine.shared)
}
