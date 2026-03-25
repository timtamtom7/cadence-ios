import Foundation

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    let duration: Int // seconds
    let completedAt: Date
    let soundIds: [String]
    let partnerId: UUID?
    let focusScore: Int // 0-100

    init(
        id: UUID = UUID(),
        duration: Int,
        completedAt: Date = Date(),
        soundIds: [String] = [],
        partnerId: UUID? = nil,
        focusScore: Int
    ) {
        self.id = id
        self.duration = duration
        self.completedAt = completedAt
        self.soundIds = soundIds
        self.partnerId = partnerId
        self.focusScore = focusScore
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

struct UserProfile: Codable {
    var username: String
    var dailyGoalMinutes: Int
    var notificationsEnabled: Bool
    var createdAt: Date

    init(
        username: String = "Focus User",
        dailyGoalMinutes: Int = 120,
        notificationsEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.username = username
        self.dailyGoalMinutes = dailyGoalMinutes
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
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
