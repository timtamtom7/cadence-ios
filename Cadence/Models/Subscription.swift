import Foundation

// MARK: - Platform
enum Platform: String, Codable, CaseIterable {
    case ios = "iOS"
    case android = "Android"
    case web = "Web"
    
    var displayName: String { rawValue }
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "Free"
    case pro = "Pro"
    case teams = "Teams"
    
    var displayName: String { rawValue }
    
    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$9.99/mo"
        case .teams: return "$14.99/user/mo"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["25 focus sessions/mo", "Basic sounds", "Leaderboards"]
        case .pro:
            return ["Unlimited sessions", "All sounds", "AI insights", "Challenges", "Advanced analytics"]
        case .teams:
            return ["Everything in Pro", "Team sessions", "Admin dashboard", "SSO", "Priority support"]
        }
    }
}

// MARK: - Subscription Status
struct SubscriptionStatus: Codable {
    var tier: SubscriptionTier
    var expiresAt: Date?
    var isActive: Bool
    
    init(tier: SubscriptionTier = .free, expiresAt: Date? = nil) {
        self.tier = tier
        self.expiresAt = expiresAt
        self.isActive = tier == .free || (expiresAt ?? .distantPast) > Date()
    }
}

// MARK: - Retention Tracker
struct RetentionMilestone: Identifiable {
    let id = UUID()
    let day: Int // day 1, 3, 7, 14, 30
    let title: String
    let description: String
    let isCompleted: Bool
    
    static let milestones: [RetentionMilestone] = [
        RetentionMilestone(day: 1, title: "First Focus", description: "Complete your first focus session", isCompleted: false),
        RetentionMilestone(day: 3, title: "AI Insight", description: "Receive your first AI insight", isCompleted: false),
        RetentionMilestone(day: 7, title: "Challenge Accepted", description: "Complete your first challenge", isCompleted: false)
    ]
}
