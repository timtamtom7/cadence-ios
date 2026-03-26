import Foundation

/// R9: Freemium subscription management
@Observable
final class FreemiumService: @unchecked Sendable {
    static let shared: FreemiumService = {
        MainActor.assumeIsolated { FreemiumService() }
    }()

    var currentTier: SubscriptionTier = .free

    enum SubscriptionTier: String, Codable, CaseIterable {
        case free = "Free"
        case pro = "Pro"
        case team = "Team"

        var price: String {
            switch self {
            case .free: return "Free"
            case .pro: return "$4.99/mo"
            case .team: return "$9.99/mo"
            }
        }

        var features: [String] {
            switch self {
            case .free:
                return [
                    "2 focus sessions per day",
                    "5 ambient sounds",
                    "Basic statistics",
                    "Daily streak tracking"
                ]
            case .pro:
                return [
                    "Unlimited focus sessions",
                    "All 15+ ambient sounds",
                    "Advanced AI insights",
                    "Calendar integration",
                    "Data export (JSON/CSV)",
                    "Custom goals",
                    "Priority support"
                ]
            case .team:
                return [
                    "Everything in Pro",
                    "Team focus sessions",
                    "Shared team goals",
                    "Team leaderboards",
                    "Admin dashboard",
                    "API access",
                    "Dedicated support"
                ]
            }
        }

        var sessionLimit: Int? {
            switch self {
            case .free: return 2
            case .pro: return nil
            case .team: return nil
            }
        }

        var soundLimit: Int {
            switch self {
            case .free: return 5
            case .pro: return Int.max
            case .team: return Int.max
            }
        }
    }

    private let defaults = UserDefaults.standard
    private let tierKey = "cadence.subscriptionTier"
    private let dailySessionKey = "cadence.dailySessionCount"
    private let lastSessionDateKey = "cadence.lastSessionDate"

    private init() {
        loadTier()
    }

    private func loadTier() {
        if let tierString = defaults.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        }
    }

    func upgrade(to tier: SubscriptionTier) {
        currentTier = tier
        defaults.set(tier.rawValue, forKey: tierKey)
    }

    func cancelSubscription() {
        currentTier = .free
        defaults.removeObject(forKey: tierKey)
    }

    // MARK: - Feature Gating

    func canStartSession() -> Bool {
        if currentTier != .free { return true }
        resetDailyCountIfNeeded()
        let count = defaults.integer(forKey: dailySessionKey)
        return count < 2
    }

    func recordSession() {
        if currentTier != .free { return }
        resetDailyCountIfNeeded()
        let count = defaults.integer(forKey: dailySessionKey)
        defaults.set(count + 1, forKey: dailySessionKey)
    }

    func remainingSessionsToday() -> Int {
        if currentTier != .free { return Int.max }
        resetDailyCountIfNeeded()
        let count = defaults.integer(forKey: dailySessionKey)
        return max(0, 2 - count)
    }

    private func resetDailyCountIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = defaults.object(forKey: lastSessionDateKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if lastDay < today {
                defaults.set(0, forKey: dailySessionKey)
            }
        }
        defaults.set(today, forKey: lastSessionDateKey)
    }

    // MARK: - Feature Checks

    var canUseAdvancedInsights: Bool { currentTier != .free }
    var canUseCalendarIntegration: Bool { currentTier != .free }
    var canUseDataExport: Bool { currentTier != .free }
    var canUseAICoaching: Bool { currentTier != .free }
    var canUseTeamFeatures: Bool { currentTier == .team }
    var canUseUnlimitedSessions: Bool { currentTier != .free }
    var canUseCustomGoals: Bool { currentTier != .free }
    var canUseAllSounds: Bool { currentTier != .free }
}
