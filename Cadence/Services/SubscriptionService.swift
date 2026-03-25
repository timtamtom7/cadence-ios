import Foundation

/// R9: Subscription tier management for Cadence
@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var currentTier: SubscriptionTier = .free

    private let tierKey = "cadence_subscription_tier"

    private init() {
        loadTier()
    }

    enum SubscriptionTier: String, Codable, CaseIterable {
        case free = "Free"
        case premium = "Premium"
        case team = "Team"

        var maxDailySessions: Int {
            switch self {
            case .free: return 3
            case .premium: return Int.max
            case .team: return Int.max
            }
        }

        var maxDurationMinutes: Int {
            switch self {
            case .free: return 30
            case .premium: return Int.max
            case .team: return Int.max
            }
        }

        var partnerMatchingEnabled: Bool {
            self != .free
        }

        var advancedAnalyticsEnabled: Bool {
            self != .free
        }

        var exportEnabled: Bool {
            self != .free
        }

        var customSoundsEnabled: Bool {
            self != .free
        }

        var teamManagementEnabled: Bool {
            self == .team
        }

        var adminControlsEnabled: Bool {
            self == .team
        }

        var priceDisplay: String {
            switch self {
            case .free: return "Free"
            case .premium: return "$4.99/mo"
            case .team: return "$9.99/mo"
            }
        }

        var description: String {
            switch self {
            case .free: return "3 sessions/day, 30min max"
            case .premium: return "Unlimited sessions, partner matching, analytics"
            case .team: return "Everything + team management"
            }
        }
    }

    // MARK: - Feature Gating

    func canStartSession(todaySessionCount: Int) -> Bool {
        currentTier != .free || todaySessionCount < SubscriptionTier.free.maxDailySessions
    }

    func canUseDuration(_ minutes: Int) -> Bool {
        currentTier != .free || minutes <= SubscriptionTier.free.maxDurationMinutes
    }

    func canUsePartnerMatching() -> Bool {
        currentTier.partnerMatchingEnabled
    }

    func canUseAdvancedAnalytics() -> Bool {
        currentTier.advancedAnalyticsEnabled
    }

    func canExport() -> Bool {
        currentTier.exportEnabled
    }

    func canUseCustomSounds() -> Bool {
        currentTier.customSoundsEnabled
    }

    // MARK: - Tier Management

    func setTier(_ tier: SubscriptionTier) {
        currentTier = tier
        UserDefaults.standard.set(tier.rawValue, forKey: tierKey)
    }

    private func loadTier() {
        if let saved = UserDefaults.standard.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: saved) {
            currentTier = tier
        } else {
            currentTier = .free
        }
    }

    // MARK: - Usage Stats

    func usageStats(todaySessions: Int) -> SubscriptionUsageStats {
        SubscriptionUsageStats(
            todaySessions: todaySessions,
            maxSessions: currentTier.maxDailySessions,
            isAtLimit: currentTier == .free && todaySessions >= SubscriptionTier.free.maxDailySessions
        )
    }
}

struct SubscriptionUsageStats {
    let todaySessions: Int
    let maxSessions: Int
    let isAtLimit: Bool

    var remaining: Int {
        max(0, maxSessions - todaySessions)
    }

    var usagePercent: Double {
        guard maxSessions > 0 && maxSessions != Int.max else { return 0 }
        return min(1.0, Double(todaySessions) / Double(maxSessions))
    }
}
