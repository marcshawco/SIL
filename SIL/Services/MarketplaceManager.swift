//
//  MarketplaceManager.swift
//  SIL
//
//  [SYSTEM]: Marketplace terminal initialized.
//  Exchange your gold for real-world rewards.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Marketplace Manager

/// Manages the reward marketplace where players spend gold on real-life rewards
@MainActor
class MarketplaceManager: ObservableObject {

    static let shared = MarketplaceManager()

    // MARK: - Published Properties

    @Published var availableRewards: [MarketplaceReward] = []
    @Published var purchaseHistory: [RewardPurchase] = []
    @Published var unredeemedRewards: [RewardPurchase] = []

    // MARK: - Initialization

    private init() {
        loadDefaultRewards()
        loadCustomRewards()
        loadPurchaseHistory()
    }

    // MARK: - Reward Management

    /// Load default marketplace rewards
    private func loadDefaultRewards() {
        availableRewards = [
            // Small Rewards (10-50 Gold)
            MarketplaceReward(
                name: "Extra Snack",
                description: "Treat yourself to a snack of your choice.",
                cost: 10,
                category: .treat,
                icon: "takeoutbag.and.cup.and.straw"
            ),
            MarketplaceReward(
                name: "15-Min Break",
                description: "Take a guilt-free 15-minute break to do whatever.",
                cost: 15,
                category: .time,
                icon: "timer"
            ),
            MarketplaceReward(
                name: "Episode Pass",
                description: "Watch one episode of your favorite show.",
                cost: 25,
                category: .entertainment,
                icon: "tv"
            ),

            // Medium Rewards (50-200 Gold)
            MarketplaceReward(
                name: "Cheat Meal",
                description: "Order your favorite food guilt-free.",
                cost: 100,
                category: .treat,
                icon: "fork.knife"
            ),
            MarketplaceReward(
                name: "Game Time",
                description: "1 hour of uninterrupted gaming.",
                cost: 75,
                category: .entertainment,
                icon: "gamecontroller"
            ),
            MarketplaceReward(
                name: "Sleep In",
                description: "Sleep in tomorrow without the guilt.",
                cost: 80,
                category: .time,
                icon: "bed.double"
            ),
            MarketplaceReward(
                name: "Coffee Upgrade",
                description: "Get your favorite fancy coffee drink.",
                cost: 50,
                category: .treat,
                icon: "cup.and.saucer"
            ),
            MarketplaceReward(
                name: "Health Potion",
                description: "Restore +25 HP instantly.",
                cost: 35,
                category: .item,
                icon: "cross.case.fill",
                healthRestore: 25
            ),
            MarketplaceReward(
                name: "Streak Shield",
                description: "Protect your streak from one missed day.",
                cost: 120,
                category: .item,
                icon: "shield.fill",
                streakShieldCharges: 1
            ),
            MarketplaceReward(
                name: "Movie Night",
                description: "Watch a full movie of your choice.",
                cost: 150,
                category: .entertainment,
                icon: "popcorn"
            ),
            MarketplaceReward(
                name: "Skip-the-Chores Evening",
                description: "One evening completely free of chores.",
                cost: 120,
                category: .experience,
                icon: "sofa.fill"
            ),

            // Large Rewards (200-500 Gold)
            MarketplaceReward(
                name: "Self-Care Day",
                description: "Take a full day off for self-care.",
                cost: 300,
                category: .time,
                icon: "sparkles"
            ),
            MarketplaceReward(
                name: "New Book",
                description: "Buy yourself a new book.",
                cost: 200,
                category: .item,
                icon: "book"
            ),
            MarketplaceReward(
                name: "Nice Dinner",
                description: "Treat yourself to a nice restaurant dinner.",
                cost: 400,
                category: .treat,
                icon: "wineglass"
            ),
            MarketplaceReward(
                name: "Subscription Month",
                description: "One month of a streaming service of your choice.",
                cost: 350,
                category: .entertainment,
                icon: "play.circle"
            ),
            MarketplaceReward(
                name: "Rest Day Pass",
                description: "A planned day off. Missed quests cost no HP and your streak stays safe.",
                cost: 250,
                category: .item,
                icon: "moon.zzz.fill",
                restDayPassCharges: 1
            ),
            MarketplaceReward(
                name: "New Hobby Supplies",
                description: "Stock up on supplies for a hobby you love.",
                cost: 250,
                category: .experience,
                icon: "paintpalette"
            ),
            MarketplaceReward(
                name: "Concert or Event Ticket",
                description: "Buy a ticket to a concert, game, or live event.",
                cost: 500,
                category: .experience,
                icon: "ticket"
            ),

            // Premium Rewards (500+ Gold)
            MarketplaceReward(
                name: "Day Trip",
                description: "Take a day trip somewhere fun.",
                cost: 750,
                category: .experience,
                icon: "car"
            ),
            MarketplaceReward(
                name: "New Gear",
                description: "Buy yourself a piece of equipment/gear you've been wanting.",
                cost: 1000,
                category: .item,
                icon: "bag"
            ),
            MarketplaceReward(
                name: "Weekend Getaway",
                description: "Plan a weekend getaway for yourself.",
                cost: 2000,
                category: .experience,
                icon: "airplane"
            ),
            MarketplaceReward(
                name: "Major Purchase",
                description: "That thing you've been saving for? You've earned it.",
                cost: 5000,
                category: .item,
                icon: "star.fill"
            ),
            MarketplaceReward(
                name: "Power Nap",
                description: "20 guilt-free minutes face-down. Restores +20 HP and clears the head for the next quest.",
                cost: 60,
                category: .time,
                icon: "moon.zzz",
                healthRestore: 20
            )
        ]
    }

    // MARK: - Purchase Flow

    /// Purchase a reward
    func purchaseReward(_ reward: MarketplaceReward, player: inout Player) -> PurchaseResult {
        // Check if player has enough gold
        guard player.gold >= reward.cost else {
            AnalyticsManager.shared.trackFeature("shop_purchase_failed_insufficient_gold")
            HapticManager.shared.purchaseFailed()
            return PurchaseResult(
                success: false,
                message: "Insufficient gold. You need \(reward.cost - player.gold) more."
            )
        }

        if let healthRestore = reward.healthRestore, healthRestore > 0, player.currentHP >= player.maxHP {
            AnalyticsManager.shared.trackFeature("shop_purchase_blocked_full_health")
            HapticManager.shared.warning()
            return PurchaseResult(
                success: false,
                message: "HP is already full. Use this when you need healing."
            )
        }

        // Deduct gold
        player.gold -= reward.cost
        AnalyticsManager.shared.trackFeature("shop_purchase_completed")
        AnalyticsManager.shared.trackFeature("shop_category_\(reward.category.rawValue)")

        // Create purchase record
        var purchase = RewardPurchase(
            reward: reward,
            purchaseDate: Date()
        )

        purchaseHistory.append(purchase)

        if let healthRestore = reward.healthRestore, healthRestore > 0 {
            let hpBefore = player.currentHP
            player.currentHP = min(player.maxHP, player.currentHP + healthRestore)
            let restoredAmount = max(0, player.currentHP - hpBefore)

            purchase.isRedeemed = true
            purchase.redeemedDate = Date()
            if let historyIndex = purchaseHistory.firstIndex(where: { $0.id == purchase.id }) {
                purchaseHistory[historyIndex] = purchase
            }

            savePurchaseHistory()

            GameEngine.shared.recordExternalActivity(
                type: .rewardConsumed,
                title: reward.name,
                detail: restoredAmount > 0
                    ? "+\(restoredAmount) HP restored"
                    : "HP already full"
            )
            GameEngine.shared.evaluateAchievementsIfNeeded()
            HapticManager.shared.purchaseSucceeded()

            return PurchaseResult(
                success: true,
                message: restoredAmount > 0
                    ? "Health restored by \(restoredAmount) HP."
                    : "HP is already full.",
                purchase: purchase
            )
        }

        if let shieldCharges = reward.streakShieldCharges, shieldCharges > 0 {
            player.streakShieldCharges += shieldCharges
            purchase.isRedeemed = true
            purchase.redeemedDate = Date()
            if let historyIndex = purchaseHistory.firstIndex(where: { $0.id == purchase.id }) {
                purchaseHistory[historyIndex] = purchase
            }

            savePurchaseHistory()

            GameEngine.shared.recordExternalActivity(
                type: .rewardConsumed,
                title: reward.name,
                detail: "+\(shieldCharges) streak protection charge"
            )
            GameEngine.shared.evaluateAchievementsIfNeeded()
            HapticManager.shared.purchaseSucceeded()

            return PurchaseResult(
                success: true,
                message: "Streak shield ready. Charges: \(player.streakShieldCharges).",
                purchase: purchase
            )
        }

        if let restPassCharges = reward.restDayPassCharges, restPassCharges > 0 {
            player.restDayPassCharges += restPassCharges
            purchase.isRedeemed = true
            purchase.redeemedDate = Date()
            if let historyIndex = purchaseHistory.firstIndex(where: { $0.id == purchase.id }) {
                purchaseHistory[historyIndex] = purchase
            }

            savePurchaseHistory()

            GameEngine.shared.recordExternalActivity(
                type: .rewardConsumed,
                title: reward.name,
                detail: "+\(restPassCharges) rest day pass"
            )
            GameEngine.shared.evaluateAchievementsIfNeeded()
            HapticManager.shared.purchaseSucceeded()

            return PurchaseResult(
                success: true,
                message: "Rest day pass ready. Passes: \(player.restDayPassCharges).",
                purchase: purchase
            )
        }

        unredeemedRewards.append(purchase)

        // Save
        savePurchaseHistory()
        GameEngine.shared.save()
        GameEngine.shared.evaluateAchievementsIfNeeded()
        HapticManager.shared.purchaseSucceeded()

        return PurchaseResult(
            success: true,
            message: "Reward purchased! Remember to redeem it.",
            purchase: purchase
        )
    }

    /// Redeem a purchased reward
    func redeemReward(_ purchase: RewardPurchase) {
        guard let index = unredeemedRewards.firstIndex(where: { $0.id == purchase.id }) else { return }

        unredeemedRewards[index].isRedeemed = true
        unredeemedRewards[index].redeemedDate = Date()

        // Update in history too
        if let historyIndex = purchaseHistory.firstIndex(where: { $0.id == purchase.id }) {
            purchaseHistory[historyIndex] = unredeemedRewards[index]
        }

        unredeemedRewards.remove(at: index)

        GameEngine.shared.recordExternalActivity(
            type: .rewardConsumed,
            title: purchase.reward.name,
            detail: "Shop reward redeemed"
        )
        AnalyticsManager.shared.trackFeature("shop_reward_redeemed")
        HapticManager.shared.rewardRedeemed()

        savePurchaseHistory()
    }

    // MARK: - Custom Rewards

    /// Add a custom reward
    func addCustomReward(
        name: String,
        description: String,
        cost: Int,
        category: RewardCategory
    ) {
        let reward = MarketplaceReward(
            name: name,
            description: description,
            cost: cost,
            category: category,
            icon: category.defaultIcon,
            isCustom: true
        )

        availableRewards.append(reward)
        saveCustomRewards()
        AnalyticsManager.shared.trackFeature("custom_reward_created")
    }

    /// Remove a custom reward
    func removeCustomReward(_ reward: MarketplaceReward) {
        guard reward.isCustom else { return }
        availableRewards.removeAll { $0.id == reward.id }
        saveCustomRewards()
        AnalyticsManager.shared.trackFeature("custom_reward_deleted")
    }

    // MARK: - Persistence

    private func savePurchaseHistory() {
        if let data = try? JSONEncoder().encode(purchaseHistory) {
            UserDefaults.standard.set(data, forKey: "rewardPurchaseHistory")
        }
        if let data = try? JSONEncoder().encode(unredeemedRewards) {
            UserDefaults.standard.set(data, forKey: "unredeemedRewards")
        }
    }

    private func loadPurchaseHistory() {
        if let data = UserDefaults.standard.data(forKey: "rewardPurchaseHistory"),
           let history = try? JSONDecoder().decode([RewardPurchase].self, from: data) {
            purchaseHistory = history
        }
        if let data = UserDefaults.standard.data(forKey: "unredeemedRewards"),
           let unredeemed = try? JSONDecoder().decode([RewardPurchase].self, from: data) {
            unredeemedRewards = unredeemed
        }
    }

    private func saveCustomRewards() {
        let customRewards = availableRewards.filter { $0.isCustom }
        if let data = try? JSONEncoder().encode(customRewards) {
            UserDefaults.standard.set(data, forKey: "customRewards")
        }
    }

    private func loadCustomRewards() {
        guard let data = UserDefaults.standard.data(forKey: "customRewards"),
              let customRewards = try? JSONDecoder().decode([MarketplaceReward].self, from: data) else {
            return
        }

        let existingIDs = Set(availableRewards.map(\.id))
        let uniqueCustomRewards = customRewards.filter { !existingIDs.contains($0.id) }
        availableRewards.append(contentsOf: uniqueCustomRewards)
    }

    func resetForFreshStart() {
        loadDefaultRewards()
        purchaseHistory = []
        unredeemedRewards = []
    }
}

// MARK: - Marketplace Reward

struct MarketplaceReward: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let cost: Int
    let category: RewardCategory
    let icon: String
    var isCustom: Bool
    var healthRestore: Int?
    var streakShieldCharges: Int?
    var restDayPassCharges: Int?

    init(
        name: String,
        description: String,
        cost: Int,
        category: RewardCategory,
        icon: String,
        isCustom: Bool = false,
        healthRestore: Int? = nil,
        streakShieldCharges: Int? = nil,
        restDayPassCharges: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.cost = cost
        self.category = category
        self.icon = icon
        self.isCustom = isCustom
        self.healthRestore = healthRestore
        self.streakShieldCharges = streakShieldCharges
        self.restDayPassCharges = restDayPassCharges
    }
}

// MARK: - Reward Category

enum RewardCategory: String, Codable, CaseIterable {
    case treat = "Treats"
    case entertainment = "Entertainment"
    case time = "Time Off"
    case item = "Items"
    case experience = "Experiences"

    var color: Color {
        switch self {
        case .treat: return S.ink2
        case .entertainment: return S.accentInk
        case .time: return S.accent
        case .item: return S.ink
        case .experience: return S.ink
        }
    }

    var defaultIcon: String {
        switch self {
        case .treat: return "gift"
        case .entertainment: return "play.circle"
        case .time: return "clock"
        case .item: return "bag"
        case .experience: return "star"
        }
    }
}

// MARK: - Reward Purchase

struct RewardPurchase: Codable, Identifiable {
    let id: UUID
    let reward: MarketplaceReward
    let purchaseDate: Date
    var isRedeemed: Bool
    var redeemedDate: Date?

    init(reward: MarketplaceReward, purchaseDate: Date) {
        self.id = UUID()
        self.reward = reward
        self.purchaseDate = purchaseDate
        self.isRedeemed = false
        self.redeemedDate = nil
    }
}

// MARK: - Purchase Result

struct PurchaseResult {
    let success: Bool
    let message: String
    var purchase: RewardPurchase?
}
