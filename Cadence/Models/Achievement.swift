import Foundation

struct Achievement: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isEarned: Bool
    var earnedAt: Date?

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        isEarned: Bool = false,
        earnedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isEarned = isEarned
        self.earnedAt = earnedAt
    }

    static let allAchievements: [Achievement] = [
        Achievement(
            id: "first_focus",
            title: "First Focus",
            description: "Complete your first focus session",
            icon: "star.fill"
        ),
        Achievement(
            id: "week_warrior",
            title: "Week Warrior",
            description: "Maintain a 7-day focus streak",
            icon: "flame.fill"
        ),
        Achievement(
            id: "night_owl",
            title: "Night Owl",
            description: "Complete a session after 10pm",
            icon: "moon.stars.fill"
        ),
        Achievement(
            id: "marathoner",
            title: "Marathoner",
            description: "Complete a 60-minute focus session",
            icon: "timer"
        ),
        Achievement(
            id: "social_butterfly",
            title: "Social Butterfly",
            description: "Focus with 5 different partners",
            icon: "person.2.fill"
        )
    ]
}
