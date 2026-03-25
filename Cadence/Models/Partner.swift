import Foundation

enum PartnerStatus: String, Codable {
    case focusing
    case idle
    case available

    var displayText: String {
        switch self {
        case .focusing: return "Focusing"
        case .idle: return "Idle"
        case .available: return "Available"
        }
    }

    var color: String {
        switch self {
        case .focusing: return "00D4AA"
        case .idle: return "7AAEAA"
        case .available: return "00F5CC"
        }
    }
}

struct Partner: Identifiable, Equatable {
    let id: UUID
    let name: String
    let status: PartnerStatus
    let currentSession: String?
    let streak: Int
    let weeklyMinutes: Int

    init(
        id: UUID = UUID(),
        name: String,
        status: PartnerStatus,
        currentSession: String? = nil,
        streak: Int,
        weeklyMinutes: Int
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.currentSession = currentSession
        self.streak = streak
        self.weeklyMinutes = weeklyMinutes
    }
    
    var avatarInitials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var currentStreak: Int { streak }
    
    var totalSessions: Int { weeklyMinutes / 30 }

    // Mock data for R1
    static let mockPartners: [Partner] = [
        Partner(name: "Alex Chen", status: .focusing, currentSession: "Deep Work", streak: 14, weeklyMinutes: 320),
        Partner(name: "Maya Patel", status: .available, currentSession: nil, streak: 7, weeklyMinutes: 245),
        Partner(name: "Jordan Lee", status: .idle, currentSession: nil, streak: 21, weeklyMinutes: 480),
        Partner(name: "Sam Rivera", status: .focusing, currentSession: "Writing", streak: 3, weeklyMinutes: 180),
        Partner(name: "Taylor Kim", status: .available, currentSession: nil, streak: 10, weeklyMinutes: 290)
    ]
}

struct LeaderboardEntry: Identifiable, Equatable {
    let id: UUID
    let rank: Int
    let name: String
    let weeklyMinutes: Int
    let streak: Int
    let isCurrentUser: Bool

    init(
        id: UUID = UUID(),
        rank: Int,
        name: String,
        weeklyMinutes: Int,
        streak: Int,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.rank = rank
        self.name = name
        self.weeklyMinutes = weeklyMinutes
        self.streak = streak
        self.isCurrentUser = isCurrentUser
    }

    static let mockLeaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, name: "Jordan Lee", weeklyMinutes: 480, streak: 21),
        LeaderboardEntry(rank: 2, name: "Alex Chen", weeklyMinutes: 320, streak: 14),
        LeaderboardEntry(rank: 3, name: "Taylor Kim", weeklyMinutes: 290, streak: 10),
        LeaderboardEntry(rank: 4, name: "Maya Patel", weeklyMinutes: 245, streak: 7),
        LeaderboardEntry(rank: 5, name: "You", weeklyMinutes: 180, streak: 5, isCurrentUser: true),
        LeaderboardEntry(rank: 6, name: "Sam Rivera", weeklyMinutes: 180, streak: 3),
        LeaderboardEntry(rank: 7, name: "Casey Morgan", weeklyMinutes: 150, streak: 2),
        LeaderboardEntry(rank: 8, name: "Riley Johnson", weeklyMinutes: 120, streak: 4)
    ]
}
