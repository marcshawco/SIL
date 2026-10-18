//
//  PenaltyManager.swift
//  SIL
//
//  [SYSTEM]: Penalty enforcement module activated.
//  Failure has consequences, Hunter.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - Penalty Manager

/// Manages the penalty system - consequences for missed quests and failures
/// Inspired by Solo Leveling's "Catch-up"
@MainActor
class PenaltyManager: ObservableObject {

    static let shared = PenaltyManager()

    // MARK: - Published Properties

    @Published var activePenalties: [PenaltyQuest] = []
    @Published var isInPenaltyZone = false
    @Published var penaltyZoneEndTime: Date?
    @Published var showPenaltyWarning = false
    @Published var currentPenaltyMessage: String = ""

    // MARK: - Constants

    private let penaltyZoneDurationHours = 24
    private let maxActivePenalties = 3

    // MARK: - Initialization

    private init() {
        loadPenalties()
        checkPenaltyStatus()
    }

    // MARK: - Penalty Application

    /// Apply a penalty based on the reason
    func applyPenalty(reason: PenaltyReason, to player: inout Player) {
        // Increment penalty count
        player.penaltyCount += 1

        // Generate appropriate penalty quest
        let penalty = generatePenalty(for: reason)
        activePenalties.append(penalty)

        // Enter penalty zone if too many penalties
        if activePenalties.count >= maxActivePenalties {
            enterPenaltyZone(player: &player)
        }

        // Send notification
        sendPenaltyNotification(penalty: penalty, reason: reason)

        // Save
        savePenalties()
    }

    /// Generate a penalty quest based on the reason
    private func generatePenalty(for reason: PenaltyReason) -> PenaltyQuest {
        let penalties = DefaultQuests.penaltyQuests
        guard !penalties.isEmpty else {
            return PenaltyQuest(
                title: "Get back on",
                description: "One short task puts momentum back.",
                penaltyType: .physical
            )
        }

        // Select based on reason severity
        switch reason {
        case .missedDailyQuests(let count):
            if count >= 3 {
                // Severe - physical penalty
                return penalties.first { $0.penaltyType == .physical } ?? penalties[0]
            } else {
                // Moderate - any penalty
                return penalties.randomElement() ?? penalties[0]
            }

        case .dungeonFailed:
            // Physical punishment for abandoning
            return penalties.first { $0.penaltyType == .physical } ?? penalties[0]

        case .streakBroken:
            // Social accountability
            return penalties.first { $0.penaltyType == .social } ?? penalties[0]

        case .custom:
            return penalties.randomElement() ?? penalties[0]
        }
    }

    // MARK: - Penalty Zone

    /// Enter the penalty zone - severe consequences
    private func enterPenaltyZone(player: inout Player) {
        isInPenaltyZone = true
        player.inPenaltyZone = true
        penaltyZoneEndTime = Date().addingTimeInterval(TimeInterval(penaltyZoneDurationHours * 3600))

        // Send urgent notification
        sendPenaltyZoneNotification()

        // Schedule penalty zone reminders
        schedulePenaltyZoneReminders()
    }

    /// Exit the penalty zone after completing penalties
    func exitPenaltyZone(player: inout Player) {
        isInPenaltyZone = false
        player.inPenaltyZone = false
        penaltyZoneEndTime = nil

        // Cancel reminders
        cancelPenaltyZoneReminders()

        // Reward for completing penalties
        player.currentXP += 50 // Redemption XP
    }

    // MARK: - Penalty Completion

    /// Complete a penalty quest
    func completePenalty(_ penalty: PenaltyQuest, player: inout Player) {
        guard let index = activePenalties.firstIndex(where: { $0.id == penalty.id }) else { return }

        activePenalties[index].isCompleted = true
        activePenalties.remove(at: index)

        // Check if can exit penalty zone
        if isInPenaltyZone && activePenalties.isEmpty {
            exitPenaltyZone(player: &player)
        }

        // Award small redemption bonus
        player.currentXP += 25
        player.gold += 5

        savePenalties()
    }

    /// Check if a penalty has expired
    func checkExpiredPenalties(player: inout Player) {
        var expiredCount = 0

        for penalty in activePenalties {
            if penalty.isExpired && !penalty.isCompleted {
                expiredCount += 1
            }
        }

        // Remove expired penalties but add new ones
        activePenalties.removeAll { $0.isExpired }

        // Double the penalties for not completing them
        for _ in 0..<expiredCount {
            applyPenalty(reason: .custom("The catch-up task ran out of time"), to: &player)
        }
    }

    // MARK: - Notifications

    /// Send a notification about a new penalty
    private func sendPenaltyNotification(penalty: PenaltyQuest, reason: PenaltyReason) {
        let content = UNMutableNotificationContent()
        content.title = "Catch-up task"
        content.body = "\(reason.description) Try: \(penalty.title)"
        content.sound = .default
        content.categoryIdentifier = "PENALTY"

        // Add custom sound for dramatic effect
        // content.sound = UNNotificationSound(named: UNNotificationSoundName("penalty_alert.wav"))

        let request = UNNotificationRequest(
            identifier: "penalty_\(penalty.id.uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send penalty zone warning notification
    private func sendPenaltyZoneNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Catch-up started"
        content.body = "A few things slipped. Clear the catch-up tasks within 24 hours and nothing else changes."
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .critical
        content.categoryIdentifier = "PENALTY_ZONE"

        let request = UNNotificationRequest(
            identifier: "penalty_zone_start",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule reminders while in penalty zone
    private func schedulePenaltyZoneReminders() {
        let reminderIntervals = [6, 12, 18, 23] // Hours

        for hours in reminderIntervals {
            let content = UNMutableNotificationContent()
            content.title = "Catch-up ending soon"

            let remainingHours = penaltyZoneDurationHours - hours
            content.body = "\(remainingHours) hours left to clear your catch-up tasks."
            content.sound = .default
            content.categoryIdentifier = "PENALTY_REMINDER"

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(hours * 3600),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "penalty_reminder_\(hours)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Cancel penalty zone reminders
    private func cancelPenaltyZoneReminders() {
        let identifiers = [6, 12, 18, 23].map { "penalty_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Status Checking

    /// Check current penalty status
    private func checkPenaltyStatus() {
        // Check if penalty zone has expired
        if isInPenaltyZone, let endTime = penaltyZoneEndTime, Date() > endTime {
            // Penalty zone expired without completion - severe consequences
            handlePenaltyZoneFailure()
        }
    }

    /// Handle failure to complete penalty zone in time
    private func handlePenaltyZoneFailure() {
        // This is the ultimate failure state
        // Reset streak, deduct XP/gold, etc.
        currentPenaltyMessage = "Catch-up window closed. Momentum took the hit."
        showPenaltyWarning = true

        // The actual stat modifications would happen in GameEngine
        // Post notification for GameEngine to handle
        NotificationCenter.default.post(
            name: .penaltyZoneFailed,
            object: nil
        )
    }

    // MARK: - Persistence

    private func savePenalties() {
        if let data = try? JSONEncoder().encode(activePenalties) {
            UserDefaults.standard.set(data, forKey: "activePenalties")
        }
        UserDefaults.standard.set(isInPenaltyZone, forKey: "isInPenaltyZone")
        UserDefaults.standard.set(penaltyZoneEndTime, forKey: "penaltyZoneEndTime")
    }

    private func loadPenalties() {
        if let data = UserDefaults.standard.data(forKey: "activePenalties"),
           let penalties = try? JSONDecoder().decode([PenaltyQuest].self, from: data) {
            activePenalties = penalties
        }
        isInPenaltyZone = UserDefaults.standard.bool(forKey: "isInPenaltyZone")
        penaltyZoneEndTime = UserDefaults.standard.object(forKey: "penaltyZoneEndTime") as? Date
    }
}

// MARK: - Penalty Zone View

/// Visual representation of penalty zone state
struct PenaltyZoneView: View {
    @ObservedObject var penaltyManager = PenaltyManager.shared
    @State private var pulseAnimation = false

    var body: some View {
        if penaltyManager.isInPenaltyZone {
            VStack(spacing: 20) {
                // Warning header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(S.warn)
                        .opacity(pulseAnimation ? 1.0 : 0.5)

                    Text("CATCH-UP")
                        .font(SystemTypography.titleMedium)
                        .foregroundStyle(S.warn)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(S.warn)
                        .opacity(pulseAnimation ? 1.0 : 0.5)
                }

                // Time remaining
                if let endTime = penaltyManager.penaltyZoneEndTime {
                    TimeRemainingView(endTime: endTime)
                }

                // Active penalties
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMPLETE THESE PENALTIES:")
                        .font(SystemTypography.systemMessage)
                        .foregroundStyle(S.ink2)

                    ForEach(penaltyManager.activePenalties) { penalty in
                        PenaltyRowView(penalty: penalty)
                    }
                }

                // Warning text
                Text("Failure to complete penalties will result in severe stat reductions.")
                    .font(SystemTypography.caption)
                    .foregroundStyle(S.warn.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(S.warn.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SystemRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: SystemRadius.large)
                    .stroke(S.warn, lineWidth: 2)
            )
            .glow(color: S.warn.opacity(pulseAnimation ? 0.5 : 0.2), radius: 15)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
    }
}

// MARK: - Time Remaining View

struct TimeRemainingView: View {
    let endTime: Date
    @State private var timeRemaining: String = ""
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 4) {
            Text("TIME REMAINING")
                .font(SystemTypography.captionSmall)
                .foregroundStyle(S.ink3)

            Text(timeRemaining)
                .font(SystemTypography.timerSmall)
                .foregroundStyle(S.warn)
        }
        .onAppear {
            updateTimeRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func updateTimeRemaining() {
        let remaining = endTime.timeIntervalSince(Date())

        if remaining <= 0 {
            timeRemaining = "EXPIRED"
            return
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Penalty Row View

struct PenaltyRowView: View {
    let penalty: PenaltyQuest

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: penalty.penaltyType.icon)
                .font(.system(size: 20))
                .foregroundStyle(S.warn)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(penalty.title)
                    .font(SystemTypography.headline)
                    .foregroundStyle(penalty.isCompleted ? S.ink3 : S.ink)
                    .strikethrough(penalty.isCompleted)

                Text(penalty.description)
                    .font(SystemTypography.caption)
                    .foregroundStyle(S.ink2)
                    .lineLimit(2)
            }

            Spacer()

            if penalty.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(S.ink)
            } else {
                Button("COMPLETE") {
                    // Handle completion
                }
                .font(SystemTypography.captionSmall)
                .foregroundStyle(S.bg)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(S.warn)
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(S.card)
        .clipShape(RoundedRectangle(cornerRadius: SystemRadius.medium))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let penaltyZoneFailed = Notification.Name("penaltyZoneFailed")
    static let penaltyApplied = Notification.Name("penaltyApplied")
}

// MARK: - GameEngine Extension

extension GameEngine {
    /// Apply penalty (implementation)
    func applyPenalty(reason: PenaltyReason) {
        PenaltyManager.shared.applyPenalty(reason: reason, to: &player)
        save()
    }
}
