import Foundation

enum PartnerStatus: String, Codable {
    case searching
    case matched
    case inSession
    case idle
    case available

    var displayText: String {
        switch self {
        case .searching: return "Searching..."
        case .matched: return "Matched"
        case .inSession: return "In Session"
        case .idle: return "Idle"
        case .available: return "Available"
        }
    }

    var color: String {
        switch self {
        case .searching: return "FFD93D"
        case .matched: return "00D4AA"
        case .inSession: return "7AAEAA"
        case .idle: return "7AAEAA"
        case .available: return "00F5CC"
        }
    }

    var icon: String {
        switch self {
        case .searching: return "antenna.radiowaves.left.and.right"
        case .matched: return "checkmark.circle.fill"
        case .inSession: return "person.2.fill"
        case .idle: return "moon.fill"
        case .available: return "person.crop.circle.badge.checkmark"
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
    let focusMode: String?
    let joinedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        status: PartnerStatus,
        currentSession: String? = nil,
        streak: Int,
        weeklyMinutes: Int,
        focusMode: String? = nil,
        joinedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.currentSession = currentSession
        self.streak = streak
        self.weeklyMinutes = weeklyMinutes
        self.focusMode = focusMode
        self.joinedAt = joinedAt
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

    static let mockPartners: [Partner] = [
        Partner(name: "Alex Chen", status: .inSession, currentSession: "Deep Work", streak: 14, weeklyMinutes: 320, focusMode: "Deep Work"),
        Partner(name: "Maya Patel", status: .available, currentSession: nil, streak: 7, weeklyMinutes: 245, focusMode: nil),
        Partner(name: "Jordan Lee", status: .idle, currentSession: nil, streak: 21, weeklyMinutes: 480, focusMode: nil),
        Partner(name: "Sam Rivera", status: .inSession, currentSession: "Writing", streak: 3, weeklyMinutes: 180, focusMode: "Creative"),
        Partner(name: "Taylor Kim", status: .available, currentSession: nil, streak: 10, weeklyMinutes: 290, focusMode: nil)
    ]
}

struct MatchingSession: Identifiable, Codable {
    let id: UUID
    let partnerId: UUID
    let partnerName: String
    let startedAt: Date
    let durationMinutes: Int
    let focusMode: String
    var status: MatchingSessionStatus

    init(
        id: UUID = UUID(),
        partnerId: UUID,
        partnerName: String,
        startedAt: Date = Date(),
        durationMinutes: Int,
        focusMode: String,
        status: MatchingSessionStatus = .matched
    ) {
        self.id = id
        self.partnerId = partnerId
        self.partnerName = partnerName
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.focusMode = focusMode
        self.status = status
    }
}

enum MatchingSessionStatus: String, Codable {
    case searching
    case matched
    case inSession
    case completed
    case disconnected
}

struct LeaderboardEntry: Identifiable, Equatable {
    let id: UUID
    let rank: Int
    let name: String
    let weeklyMinutes: Int
    let streak: Int
    let totalHours: Double
    let totalSessions: Int
    let isCurrentUser: Bool

    init(
        id: UUID = UUID(),
        rank: Int,
        name: String,
        weeklyMinutes: Int,
        streak: Int,
        totalHours: Double = 0,
        totalSessions: Int = 0,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.rank = rank
        self.name = name
        self.weeklyMinutes = weeklyMinutes
        self.streak = streak
        self.totalHours = totalHours
        self.totalSessions = totalSessions
        self.isCurrentUser = isCurrentUser
    }

    static let mockLeaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, name: "Jordan Lee", weeklyMinutes: 480, streak: 21, totalHours: 156, totalSessions: 312),
        LeaderboardEntry(rank: 2, name: "Alex Chen", weeklyMinutes: 320, streak: 14, totalHours: 98, totalSessions: 196),
        LeaderboardEntry(rank: 3, name: "Taylor Kim", weeklyMinutes: 290, streak: 10, totalHours: 87, totalSessions: 174),
        LeaderboardEntry(rank: 4, name: "Maya Patel", weeklyMinutes: 245, streak: 7, totalHours: 72, totalSessions: 144),
        LeaderboardEntry(rank: 5, name: "You", weeklyMinutes: 180, streak: 5, totalHours: 45, totalSessions: 90, isCurrentUser: true),
        LeaderboardEntry(rank: 6, name: "Sam Rivera", weeklyMinutes: 180, streak: 3, totalHours: 38, totalSessions: 76),
        LeaderboardEntry(rank: 7, name: "Casey Morgan", weeklyMinutes: 150, streak: 2, totalHours: 29, totalSessions: 58),
        LeaderboardEntry(rank: 8, name: "Riley Johnson", weeklyMinutes: 120, streak: 4, totalHours: 22, totalSessions: 44)
    ]
}
