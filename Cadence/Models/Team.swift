import Foundation

struct Team: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var members: [TeamMember]
    var totalFocusMinutes: Int
    var weeklyGoalMinutes: Int
    var createdAt: Date
    var teamCode: String

    init(
        id: UUID = UUID(),
        name: String,
        members: [TeamMember] = [],
        totalFocusMinutes: Int = 0,
        weeklyGoalMinutes: Int = 600,
        createdAt: Date = Date(),
        teamCode: String = ""
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.totalFocusMinutes = totalFocusMinutes
        self.weeklyGoalMinutes = weeklyGoalMinutes
        self.createdAt = createdAt
        self.teamCode = teamCode.isEmpty ? String(UUID().uuidString.prefix(6)).uppercased() : teamCode
    }

    var memberCount: Int { members.count }

    var weeklyProgress: Double {
        min(1.0, Double(totalFocusMinutes) / Double(weeklyGoalMinutes))
    }

    var totalHours: Double {
        Double(totalFocusMinutes) / 60.0
    }

    static let mockTeam = Team(
        name: "Focus Squad",
        members: [
            TeamMember(id: UUID(), name: "Alex Chen", role: .admin, weeklyMinutes: 320, streak: 14, isActive: true),
            TeamMember(id: UUID(), name: "Maya Patel", role: .member, weeklyMinutes: 245, streak: 7, isActive: true),
            TeamMember(id: UUID(), name: "Jordan Lee", role: .member, weeklyMinutes: 480, streak: 21, isActive: false),
        ],
        totalFocusMinutes: 1045,
        weeklyGoalMinutes: 900,
        teamCode: "FOCUS42"
    )
}

struct TeamMember: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let role: TeamRole
    var weeklyMinutes: Int
    var streak: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        role: TeamRole = .member,
        weeklyMinutes: Int = 0,
        streak: Int = 0,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.weeklyMinutes = weeklyMinutes
        self.streak = streak
        self.isActive = isActive
    }

    var weeklyHours: Double {
        Double(weeklyMinutes) / 60.0
    }
}

enum TeamRole: String, Codable {
    case admin
    case member
}

struct TeamSession: Identifiable, Codable {
    let id: UUID
    let teamId: UUID
    let startedAt: Date
    let durationMinutes: Int
    let participantIds: [UUID]
    var ambientSound: String
    var status: TeamSessionStatus

    init(
        id: UUID = UUID(),
        teamId: UUID,
        startedAt: Date = Date(),
        durationMinutes: Int,
        participantIds: [UUID] = [],
        ambientSound: String = "rain",
        status: TeamSessionStatus = .active
    ) {
        self.id = id
        self.teamId = teamId
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.participantIds = participantIds
        self.ambientSound = ambientSound
        self.status = status
    }
}

enum TeamSessionStatus: String, Codable {
    case active
    case completed
    case cancelled
}
