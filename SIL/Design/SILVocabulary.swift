//
//  SILVocabulary.swift
//  SIL
//
//  SIL 2.0 renames the product's language away from the RPG framing. The
//  engine keeps its own names — nothing here touches stored data — so this is
//  a presentation layer the new screens read through.
//
//      Quests  -> Habits        XP   -> Progress
//      Bosses  -> Goals         HP   -> Momentum
//      Gold    -> Credits       Shop -> Rewards
//
//  The six stats also collapse into four attributes. That merge is a view
//  concern too: `Player.stats` still holds all six, and the four totals are
//  derived on read.
//

import Foundation
import SwiftUI

// MARK: - Nouns

/// The user-facing word for each engine concept. Keeping these in one place
/// means the vocabulary can be checked at a glance, and that no screen invents
/// its own synonym.
enum SILWord {
    static let habit = "Habit"
    static let habits = "Habits"
    static let goal = "Goal"
    static let goals = "Goals"
    static let credits = "Credits"
    static let creditsShort = "CR"
    static let progress = "Progress"
    static let momentum = "Momentum"
    static let rewards = "Rewards"
    static let focus = "Focus"
    static let moments = "Moments"
    static let milestones = "Milestones"
    /// What the old "death penalty" is called now. SIL resets the meter; it
    /// does not punish.
    static let recalibration = "Recalibration"
}

// MARK: - Attribute merge

extension SILAttribute {
    /// Which of the four attributes an engine stat rolls up into.
    static func containing(_ stat: StatType) -> SILAttribute {
        switch stat {
        case .strength, .agility:  return .body
        case .intelligence:        return .mind
        case .vitality:            return .energy
        case .spirit, .willpower:  return .spirit
        }
    }

    /// The engine stats this attribute is made of.
    var stats: [StatType] {
        StatType.allCases.filter { SILAttribute.containing($0) == self }
    }

    /// Where a habit that builds this attribute should bank its stat XP. Using
    /// the first constituent keeps rewards deterministic.
    var primaryStat: StatType {
        stats.first ?? .vitality
    }
}

extension Player {
    /// Total points in one of the four attributes.
    func attributeValue(_ attribute: SILAttribute) -> Int {
        attribute.stats.reduce(0) { $0 + (stats[$1]?.totalValue ?? 0) }
    }

    /// All four, in display order.
    var silAttributes: [(attribute: SILAttribute, value: Int)] {
        SILAttribute.allCases.map { ($0, attributeValue($0)) }
    }

    /// Each attribute scaled against the largest, for the radar and the bars.
    var silAttributeShares: [(attribute: SILAttribute, value: Int, share: Double)] {
        let pairs = silAttributes
        let peak = max(1, pairs.map(\.value).max() ?? 1)
        return pairs.map { ($0.attribute, $0.value, Double($0.value) / Double(peak)) }
    }

    // MARK: Renamed readings

    /// HP, read as momentum. The meter you keep topped up, not a life bar.
    var momentum: Int { currentHP }
    var momentumCeiling: Int { max(1, maxHP) }
    var momentumShare: Double { Double(momentum) / Double(momentumCeiling) }

    /// Gold, read as credits.
    var credits: Int { gold }

    /// XP toward the next level, read as progress.
    var progressShare: Double { xpProgress }

    var progressToNextLevel: Int {
        max(0, xpRequiredForNextLevel - currentXP)
    }
}

// MARK: - Formatting

enum SILFormat {

    // MARK: Locale

    /// Everything here formats through the in-app language, not the device's.
    /// `Locale.current` would ignore the picker in Settings, which is how the
    /// Today eyebrow ended up in English on a German build.
    private static var locale: Locale { AppLanguage.currentLocale }

    /// Formatters are expensive to build and these are called from view
    /// bodies, so one of each is kept per locale and rebuilt when the
    /// language changes.
    private final class Cache {
        static let shared = Cache()

        private var localeID = ""
        private var number = NumberFormatter()
        private var date = DateFormatter()

        private func sync(_ locale: Locale) {
            guard locale.identifier != localeID else { return }
            localeID = locale.identifier

            let number = NumberFormatter()
            number.locale = locale
            number.numberStyle = .decimal
            number.maximumFractionDigits = 0
            self.number = number

            let date = DateFormatter()
            date.locale = locale
            // A template, not a pattern: the locale decides the order of the
            // day, the date and the month.
            date.setLocalizedDateFormatFromTemplate("EEEdMMM")
            self.date = date
        }

        func number(for locale: Locale) -> NumberFormatter {
            sync(locale)
            return number
        }

        func date(for locale: Locale) -> DateFormatter {
            sync(locale)
            return date
        }
    }

    // MARK: Numbers

    /// `Int(_: Double)` traps on anything outside `Int`'s range, and goal
    /// targets are typed by hand, so they reach here as values like `1e20`.
    /// Clamping keeps a silly number a silly number instead of a crash.
    static func clampedInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        let rounded = value.rounded()
        if rounded >= 9.2e18 { return Int.max }
        if rounded <= -9.2e18 { return Int.min }
        return Int(rounded)
    }

    /// Thousands separators, no decimals. Used for credits and goal values.
    static func number(_ value: Int) -> String {
        Cache.shared.number(for: locale).string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// The same, for a value that may be out of `Int` range.
    static func number(_ value: Double) -> String {
        number(clampedInt(value))
    }

    /// Signed progress, as it appears beside a habit: `+12`.
    static func points(_ value: Int) -> String {
        value >= 0 ? "+\(number(value))" : number(value)
    }

    /// `3 of 7 done`.
    static func ratio(_ done: Int, _ total: Int) -> String {
        "\(done) of \(total) done"
    }

    /// Percentage with no decimals: `62%`.
    static func percent(_ share: Double) -> String {
        guard share.isFinite else { return "—" }
        return "\(clampedInt(max(0, min(1, share)) * 100))%"
    }

    // MARK: Dates and clocks

    /// `Wed 17 Oct`, the eyebrow above the Today title, in the app's language.
    static func dateShort(_ date: Date = Date()) -> String {
        Cache.shared.date(for: locale).string(from: date)
    }

    /// `Oct`, the heading over a column of the dot calendar.
    static func monthShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date)
    }

    /// Mono clock for the focus timer: `24:05`.
    static func clock(_ seconds: Int) -> String {
        let total = max(0, seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
