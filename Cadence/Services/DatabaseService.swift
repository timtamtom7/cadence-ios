import Foundation

actor DatabaseService {
    static let shared = DatabaseService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sessions = "cadence.sessions"
        static let userProfile = "cadence.userProfile"
        static let streak = "cadence.streak"
        static let achievements = "cadence.achievements"
        static let activeSounds = "cadence.activeSounds"
    }

    // MARK: - Sessions

    func saveSession(_ session: Session) {
        var sessions = loadSessions()
        sessions.append(session)
        if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: Keys.sessions)
        }
    }

    func loadSessions() -> [Session] {
        guard let data = defaults.data(forKey: Keys.sessions),
              let sessions = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.completedAt > $1.completedAt }
    }

    func todayMinutes() -> Int {
        let sessions = loadSessions()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions
            .filter { calendar.startOfDay(for: $0.completedAt) == today }
            .reduce(0) { $0 + $1.duration } / 60
    }

    func weeklyMinutes() -> Int {
        let sessions = loadSessions()
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return sessions
            .filter { $0.completedAt >= weekAgo }
            .reduce(0) { $0 + $1.duration } / 60
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: Keys.userProfile)
        }
    }

    func loadUserProfile() -> UserProfile {
        guard let data = defaults.data(forKey: Keys.userProfile),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    // MARK: - Streak

    func saveStreak(_ streak: StreakData) {
        if let data = try? JSONEncoder().encode(streak) {
            defaults.set(data, forKey: Keys.streak)
        }
    }

    func loadStreak() -> StreakData {
        guard let data = defaults.data(forKey: Keys.streak),
              let streak = try? JSONDecoder().decode(StreakData.self, from: data) else {
            return StreakData()
        }
        return streak
    }

    func recordSessionForStreak() {
        var streak = loadStreak()
        streak.recordSession()
        saveStreak(streak)
    }

    // MARK: - Achievements

    func saveAchievements(_ achievements: [Achievement]) {
        if let data = try? JSONEncoder().encode(achievements) {
            defaults.set(data, forKey: Keys.achievements)
        }
    }

    func loadAchievements() -> [Achievement] {
        guard let data = defaults.data(forKey: Keys.achievements),
              let achievements = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return Achievement.allAchievements
        }
        return achievements
    }

    // MARK: - Sound Preferences

    func saveActiveSounds(_ sounds: [String: Double]) {
        if let data = try? JSONEncoder().encode(sounds) {
            defaults.set(data, forKey: Keys.activeSounds)
        }
    }

    struct Stats {
        var todayMinutes: Int = 0
        var weeklyMinutes: Int = 0
        var totalHours: Double = 0
        var totalSessions: Int = 0
    }

    func loadStats() -> Stats {
        var stats = Stats()
        let sessions = loadSessions()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        stats.todayMinutes = sessions
            .filter { calendar.startOfDay(for: $0.completedAt) == today }
            .reduce(0) { $0 + $1.duration } / 60

        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) {
            stats.weeklyMinutes = sessions
                .filter { $0.completedAt >= weekAgo }
                .reduce(0) { $0 + $1.duration } / 60
        }

        stats.totalSessions = sessions.count
        stats.totalHours = Double(sessions.reduce(0) { $0 + $1.duration }) / 3600.0

        return stats
    }

    func loadActiveSounds() -> [String: Double] {
        guard let data = defaults.data(forKey: Keys.activeSounds),
              let sounds = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return [:]
        }
        return sounds
    }

    // MARK: - Reset

    func resetAllData() {
        defaults.removeObject(forKey: Keys.sessions)
        defaults.removeObject(forKey: Keys.userProfile)
        defaults.removeObject(forKey: Keys.streak)
        defaults.removeObject(forKey: Keys.achievements)
        defaults.removeObject(forKey: Keys.activeSounds)
    }
}
