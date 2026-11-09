//
//  TrainingManager.swift
//  SIL
//
//  Focus sessions: a countdown, a held state, and a settlement that pays for
//  the time actually spent. There is no failure state — see `finish(share:)`.
//

import SwiftUI
import Combine

// MARK: - Training Manager

/// Drives a focus session: the timer, the held state, and the rewards.
@MainActor
class TrainingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TrainingManager()

    // MARK: - Published Properties

    @Published var isActive: Bool = false
    @Published var focusModeEnabled: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var sessionTitle: String = "Focus"
    /// Whether a running session is currently held. The Focus screen reads
    /// this to label its pause control and dim the dial.
    @Published private(set) var isPaused: Bool = false
    /// Which of the four SIL attributes this session builds. Stored as the
    /// engine stat so rewards stay compatible.
    @Published var focusStat: StatType = .intelligence

    // MARK: - Private Properties

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var remainingSeconds: Int {
        max(0, totalSeconds - elapsedSeconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(totalSeconds)
    }

    var isComplete: Bool {
        elapsedSeconds >= totalSeconds && totalSeconds > 0
    }

    var formattedTimeRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var durationMinutes: Int {
        totalSeconds / 60
    }

    // XP reward based on duration
    var xpReward: Int {
        // Base: 10 XP per 15 minutes
        let baseXP = (durationMinutes / 15) * 10
        return max(10, baseXP)
    }

    var goldReward: Int {
        // Base: 5 gold per 15 minutes
        let baseGold = (durationMinutes / 15) * 5
        return max(5, baseGold)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Session Control

    /// Start a new training session
    /// - Parameters:
    ///   - minutes: Duration in minutes
    ///   - title: Optional custom session title
    func startSession(minutes: Int, title: String = "Focus") {
        guard !isActive else { return }

        sessionTitle = title
        totalSeconds = minutes * 60
        elapsedSeconds = 0
        isActive = true
        isPaused = false
        focusModeEnabled = true
        AnalyticsManager.shared.trackFeature("training_session_started")
        AnalyticsManager.shared.trackFeature("training_duration_\(minutes)")
        HapticManager.shared.trainingStarted()

        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SystemMessageHelper.showInfo(
                "Focus running",
                "Turn on Do Not Disturb and put the phone face down."
            )
        }
    }

    /// Tick the timer forward by one second
    private func tick() {
        guard isActive else { return }

        elapsedSeconds += 1

        if isComplete {
            complete()
        }
    }

    /// Complete the session in full. Called by the timer when it runs out.
    func complete() {
        finish(share: 1, fullRun: true)
    }

    /// End a running session before the timer is up. The reward is the share
    /// of the session actually spent, so stopping is never a punishment — it
    /// just pays less. This is what the Focus screen's "End early" does.
    func endEarly() {
        finish(share: progress, fullRun: false)
    }

    /// Settle a session and award `share` of its rewards.
    ///
    /// `share` is clamped to 0...1. A part-run still banks stat progress in
    /// proportion, and still logs, so the day's history stays honest.
    private func finish(share: Double, fullRun: Bool) {
        guard isActive else { return }

        // Stop timer
        timer?.invalidate()
        timer = nil

        let earnedShare = max(0, min(1, share))
        let xp = Int((Double(xpReward) * earnedShare).rounded())
        let gold = Int((Double(goldReward) * earnedShare).rounded())
        let statXP = Int((20 * earnedShare).rounded())
        let minutesSpent = max(0, elapsedSeconds / 60)

        // Update game state
        let engine = GameEngine.shared
        if xp > 0 { _ = engine.awardXP(xp) }
        engine.player.gold += gold
        if fullRun { engine.player.dungeonsClearedCount += 1 }
        if statXP > 0 { engine.awardStatXP(focusStat, amount: statXP) }
        engine.recordExternalActivity(
            type: .questCompleted,
            title: sessionTitle,
            detail: "+\(xp) progress · +\(gold) CR"
        )
        engine.save()

        // Show completion message
        if fullRun {
            SystemMessageHelper.showInfo(
                "Focus done",
                "+\(xp) progress, +\(gold) CR."
            )
            AnalyticsManager.shared.trackFeature("training_session_completed")
            HapticManager.shared.trainingCompleted()
        } else {
            SystemMessageHelper.showInfo(
                "Focus ended early",
                "\(minutesSpent) min in. +\(xp) progress, +\(gold) CR."
            )
            AnalyticsManager.shared.trackFeature("training_session_ended_early")
            HapticManager.shared.success()
        }

        // Reset state
        isActive = false
        isPaused = false
        focusModeEnabled = false
        elapsedSeconds = 0
        totalSeconds = 0
    }

    /// Hold the session when the app is backgrounded.
    ///
    /// Leaving the app is not a failure here: the clock stops so the time is
    /// not credited, and the session is waiting when you come back. Nothing is
    /// taken away — the only way to lose a session is to end it, and ending it
    /// still pays for the part you did.
    func holdForAppExit() {
        guard isActive, !isPaused else { return }
        pause()
        SystemMessageHelper.showInfo(
            "Focus held",
            "The clock stopped when you left. Pick it up when you're back."
        )
    }

    /// Toggle focus mode (screen dimming)
    func toggleFocusMode() {
        focusModeEnabled.toggle()
        AnalyticsManager.shared.trackFeature(focusModeEnabled ? "focus_mode_enabled" : "focus_mode_disabled")
        HapticManager.shared.selection()
    }

    /// Pause the session (for emergencies)
    func pause() {
        guard isActive else { return }
        timer?.invalidate()
        timer = nil
        isPaused = true
    }

    /// Resume a paused session
    func resume() {
        guard isActive && timer == nil else { return }
        isPaused = false

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        focusModeEnabled = false
    }
}

// MARK: - Training Difficulty

/// Training session difficulty levels
enum TrainingDifficulty: String, CaseIterable {
    case quick = "Quick"       // 15 min
    case standard = "Standard" // 30 min
    case intense = "Intense"   // 45 min
    case marathon = "Marathon" // 60 min

    var minutes: Int {
        switch self {
        case .quick: return 15
        case .standard: return 30
        case .intense: return 45
        case .marathon: return 60
        }
    }

    var xpMultiplier: Double {
        switch self {
        case .quick: return 1.0
        case .standard: return 1.2
        case .intense: return 1.5
        case .marathon: return 2.0
        }
    }

    var color: Color {
        switch self {
        case .quick: return S.ink
        case .standard: return S.accent
        case .intense: return S.accentInk
        case .marathon: return S.ink
        }
    }
}
