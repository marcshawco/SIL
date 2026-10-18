//
//  ActivityLogModels.swift
//  SIL
//
//  Tracks recent player actions for the status log.
//

import Foundation
import SwiftUI

enum ActivityLogType: String, Codable {
    case questCompleted
    case bossDefeated
    case rewardConsumed
    case achievementUnlocked

    var icon: String {
        switch self {
        case .questCompleted: return "checkmark.seal.fill"
        case .bossDefeated: return "bolt.shield.fill"
        case .rewardConsumed: return "gift.fill"
        case .achievementUnlocked: return "trophy.fill"
        }
    }

    /// Shared with the widget target, which cannot see `S`. The log reads in
    /// ink either way.
    var color: Color { .primary }
}

struct ActivityLogEntry: Codable, Identifiable {
    let id: UUID
    let type: ActivityLogType
    let title: String
    let detail: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        type: ActivityLogType,
        title: String,
        detail: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
        self.timestamp = timestamp
    }
}
