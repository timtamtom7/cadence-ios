import Foundation

struct WeeklyChallenge: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let unit: String
    let icon: String
    var rewardXP: Int
    var isCompleted: Bool

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, Double(currentValue) / Double(targetValue))
    }

    var progressText: String {
        "\(currentValue)/\(targetValue) \(unit)"
    }

    static let mockChallenges: [WeeklyChallenge] = [
        WeeklyChallenge(
            id: "sessions_10",
            title: "Marathon Week",
            description: "Complete 10 focus sessions",
            targetValue: 10,
            currentValue: 7,
            unit: "sessions",
            icon: "flame.fill",
            rewardXP: 100,
            isCompleted: false
        ),
        WeeklyChallenge(
            id: "minutes_300",
            title: "Time Investment",
            description: "Focus for 300 minutes total",
            targetValue: 300,
            currentValue: 180,
            unit: "min",
            icon: "clock.fill",
            rewardXP: 150,
            isCompleted: false
        ),
        WeeklyChallenge(
            id: "streak_7",
            title: "Week Warrior",
            description: "Maintain a 7-day streak",
            targetValue: 7,
            currentValue: 5,
            unit: "days",
            icon: "flame",
            rewardXP: 200,
            isCompleted: false
        ),
        WeeklyChallenge(
            id: "team_hours",
            title: "Team Player",
            description: "Complete 5 team sessions",
            targetValue: 5,
            currentValue: 5,
            unit: "sessions",
            icon: "person.3.fill",
            rewardXP: 175,
            isCompleted: true
        )
    ]
}
