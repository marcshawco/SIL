//
//  PlayerTitleSystem.swift
//  SIL
//
//  A short description of how someone has actually been spending their
//  effort, derived from their strongest attributes and their level.
//
//  These used to be RPG class names — Battlemage, Shadowblade, Grand Wizard.
//  SIL describes the behaviour instead: what the record says you keep doing.
//

import Foundation

enum PlayerClassTitle {

    /// Player level → mastery tier (0 = novice, 1 = adept, 2 = master).
    static func tier(forLevel level: Int) -> Int {
        switch level {
        case ..<10: return 0
        case 10..<40: return 1
        default: return 2
        }
    }

    /// Resolve the class title from the current stat spread and level.
    /// - A clear single specialty → a tiered single-stat title.
    /// - Two comparably-strong stats (once past novice) → a hybrid title.
    private struct RankedStat {
        let type: StatType
        let value: Int
        let xp: Int
    }

    static func resolve(stats: [StatType: Stat], level: Int) -> String {
        // Rank stats by strength (totalValue, tie-broken by raw experience).
        var ranked: [RankedStat] = []
        for type in StatType.allCases {
            let stat = stats[type]
            ranked.append(RankedStat(type: type, value: stat?.totalValue ?? 0, xp: stat?.experience ?? 0))
        }
        ranked.sort { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.xp > rhs.xp
        }

        let t = tier(forLevel: level)

        guard let top = ranked.first, top.value > 0 else {
            return "Just getting started" // nothing recorded yet
        }

        let second: RankedStat? = ranked.count > 1 ? ranked[1] : nil
        let third: RankedStat? = ranked.count > 2 ? ranked[2] : nil

        // Balanced build: the top three stats are tied, so there's no real
        // specialization to name — call them a generalist.
        if let second, let third,
           top.value == second.value, second.value == third.value {
            let balanced = ["A bit of everything", "Well rounded", "Balanced"]
            return balanced[min(max(t, 0), balanced.count - 1)]
        }

        // A genuine secondary strength (at least 60% of the top one), which
        // only shows up once there is enough history to mean something.
        if let second, second.value > 0, t >= 1,
           Double(second.value) >= Double(top.value) * 0.6 {
            let combo = comboTitle(top.type, second.type)
            return t >= 2 ? "Deeply \(combo.lowercased())" : combo
        }

        return singleTitle(top.type, tier: t)
    }

    private static func singleTitle(_ stat: StatType, tier: Int) -> String {
        let ladders: [StatType: [String]] = [
            .strength:     ["Lifting", "Trained", "Strong"],
            .intelligence: ["Reading", "Studied", "Deep in it"],
            .agility:      ["Moving", "Quick", "Fluid"],
            .vitality:     ["Resting well", "Recovered", "Durable"],
            .willpower:    ["Showing up", "Disciplined", "Unmoved"],
            .spirit:       ["Noticing", "Steady", "Settled"]
        ]
        let ladder = ladders[stat] ?? ["Getting going", "Keeping on", "Established"]
        return ladder[min(max(tier, 0), ladder.count - 1)]
    }

    private static func comboTitle(_ a: StatType, _ b: StatType) -> String {
        let combos: [Set<StatType>: String] = [
            [.strength, .intelligence]:  "Body and mind",
            [.strength, .agility]:       "Athletic",
            [.strength, .vitality]:      "Conditioned",
            [.strength, .willpower]:     "Relentless",
            [.strength, .spirit]:        "Grounded",
            [.intelligence, .agility]:   "Sharp",
            [.intelligence, .vitality]:  "Sustainable",
            [.intelligence, .willpower]: "Focused",
            [.intelligence, .spirit]:    "Reflective",
            [.agility, .vitality]:       "Resilient",
            [.agility, .willpower]:      "Consistent",
            [.agility, .spirit]:         "Light on your feet",
            [.vitality, .willpower]:     "Steady",
            [.vitality, .spirit]:        "Balanced",
            [.willpower, .spirit]:       "Composed"
        ]
        return combos[Set([a, b])] ?? "Well rounded"
    }
}

extension Player {
    /// A short description of how this person has been spending their effort,
    /// from their strongest attributes and their level.
    var classTitle: String {
        PlayerClassTitle.resolve(stats: stats, level: level)
    }
}
