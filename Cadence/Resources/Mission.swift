import Foundation

// MARK: - 10-Year Mission Statement
struct MissionStatement {
    static let headline = "Help 1 million people achieve flow state"
    
    static let body = """
    In 10 years, Cadence will be the definitive focus intelligence platform. \
    We will have helped 1 million people — from students to CEOs — achieve \
    deep focus and flow state. We will generate $3M ARR and employ a team of \
    25 focused, mission-driven individuals.
    
    Our core thesis: in an age of distraction, deep focus is a superpower. \
    Cadence makes that superpower accessible to everyone.
    """
    
    static let values = [
        "Deep work over shallow busywork",
        "Quality over quantity, always",
        "Focus is a skill, not a天赋 (talent)",
        "Flow state is the ultimate productivity",
        "Make it beautiful, make it simple"
    ]
}

// MARK: - Long-Term Roadmap
struct LongTermRoadmap {
    static let milestones: [RoadmapMilestone] = [
        RoadmapMilestone(year: 2024, quarter: "Q3", goal: "Launch Android + Web", arr: "$50K"),
        RoadmapMilestone(year: 2024, quarter: "Q4", goal: "1,000 paying users", arr: "$100K"),
        RoadmapMilestone(year: 2025, quarter: "Q2", goal: "Cadence 2.0 launch", arr: "$200K"),
        RoadmapMilestone(year: 2025, quarter: "Q4", goal: "First enterprise customer", arr: "$350K"),
        RoadmapMilestone(year: 2026, quarter: "Q2", goal: "$500K ARR milestone", arr: "$500K"),
        RoadmapMilestone(year: 2027, quarter: "Q1", goal: "Seed round close", arr: "$750K"),
        RoadmapMilestone(year: 2027, quarter: "Q4", goal: "Cadence 3.0 with flow AI", arr: "$1M"),
        RoadmapMilestone(year: 2028, quarter: "Q4", goal: "10,000 paying users", arr: "$1.5M"),
        RoadmapMilestone(year: 2029, quarter: "Q4", goal: "$3M ARR achieved", arr: "$3M")
    ]
}

struct RoadmapMilestone {
    let year: Int
    let quarter: String
    let goal: String
    let arr: String
}

// MARK: - Legacy Impact Tracker
struct LegacyImpactTracker {
    nonisolated(unsafe) static var totalUsersHelped: Int = 0
    nonisolated(unsafe) static var totalFlowStatesAchieved: Int = 0
    nonisolated(unsafe) static var totalFocusHours: Int = 0
    
    static let targetUsers = 1_000_000
    static let targetFlowStates = 10_000_000
    static let targetFocusHours = 100_000_000
    
    static var userProgress: Double {
        Double(totalUsersHelped) / Double(targetUsers)
    }
    
    static var flowStateProgress: Double {
        Double(totalFlowStatesAchieved) / Double(targetFlowStates)
    }
    
    static var focusHoursProgress: Double {
        Double(totalFocusHours) / Double(targetFocusHours)
    }
}

// MARK: - Cadence 3.0 Release Plan
struct Cadence3ReleasePlan {
    static let codename = "Flow"
    static let targetLaunch = "Q1 2027"
    
    static let features: [ReleaseFeature] = [
        ReleaseFeature(name: "Flow State Detection", priority: .critical, status: .inProgress),
        ReleaseFeature(name: "Biometric Feedback", priority: .high, status: .planned),
        ReleaseFeature(name: "AI Focus Coach", priority: .high, status: .planned),
        ReleaseFeature(name: "Corporate Dashboard", priority: .medium, status: .backlog),
        ReleaseFeature(name: "Vision Pro Spatial App", priority: .low, status: .backlog)
    ]
}

struct ReleaseFeature {
    let name: String
    let priority: Priority
    let status: Status
    
    enum Priority: String {
        case critical, high, medium, low
    }
    
    enum Status: String {
        case shipped, inProgress, planned, backlog
    }
}
