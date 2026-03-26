import Foundation

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    let duration: Int // seconds
    let completedAt: Date
    let soundIds: [String]
    let partnerId: UUID?
    let focusScore: Int // 0-100
    let platform: Platform

    init(
        id: UUID = UUID(),
        duration: Int,
        completedAt: Date = Date(),
        soundIds: [String] = [],
        partnerId: UUID? = nil,
        focusScore: Int,
        platform: Platform = .ios
    ) {
        self.id = id
        self.duration = duration
        self.completedAt = completedAt
        self.soundIds = soundIds
        self.partnerId = partnerId
        self.focusScore = focusScore
        self.platform = platform
    }

    var durationMinutes: Int {
        duration / 60
    }

    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Optional metadata saved after a session completes
struct SessionNote: Codable, Equatable {
    let sessionId: UUID
    var notes: String
    var tags: [String]

    init(sessionId: UUID, notes: String = "", tags: [String] = []) {
        self.sessionId = sessionId
        self.notes = notes
        self.tags = tags
    }
}

/// Predefined tags users can apply to sessions
enum SessionTag: String, CaseIterable, Identifiable {
    case deepWork = "Deep Work"
    case creative = "Creative"
    case study = "Study"
    case planning = "Planning"
    case review = "Review"
    case writing = "Writing"
    case coding = "Coding"
    case reading = "Reading"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .creative: return "paintbrush.fill"
        case .study: return "book.fill"
        case .planning: return "map.fill"
        case .review: return "checkmark.seal.fill"
        case .writing: return "pencil.line"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .reading: return "eyeglasses"
        }
    }
}

struct UserProfile: Codable {
    var username: String
    var dailyGoalMinutes: Int
    var notificationsEnabled: Bool
    var createdAt: Date
    /// Hour of day (0-23) to send weekly digest notification
    var weeklyDigestHour: Int
    /// Weekday (1=Sun, 7=Sat) to send weekly digest
    var weeklyDigestWeekday: Int
    /// Whether weekly digest notifications are enabled
    var weeklyDigestEnabled: Bool

    init(
        username: String = "Focus User",
        dailyGoalMinutes: Int = 120,
        notificationsEnabled: Bool = true,
        createdAt: Date = Date(),
        weeklyDigestHour: Int = 9,
        weeklyDigestWeekday: Int = 7,
        weeklyDigestEnabled: Bool = false
    ) {
        self.username = username
        self.dailyGoalMinutes = dailyGoalMinutes
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.weeklyDigestHour = weeklyDigestHour
        self.weeklyDigestWeekday = weeklyDigestWeekday
        self.weeklyDigestEnabled = weeklyDigestEnabled
    }

    /// Weekday name for weekly digest
    var weeklyDigestWeekdayName: String {
        let weekdays = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekdays[weeklyDigestWeekday]
    }

    /// Formatted digest time string
    var weeklyDigestTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = weeklyDigestHour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(weeklyDigestHour):00"
    }
}

struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastSessionDate: Date?

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastSessionDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastSessionDate = lastSessionDate
    }

    mutating func recordSession(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastDate = lastSessionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysDiff == 0 means same day, don't increment
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastSessionDate = date
    }
}
