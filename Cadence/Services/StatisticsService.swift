import Foundation

/// R7: Statistics and analytics service
@MainActor
@Observable
class StatisticsService {
    static let shared = StatisticsService()

    private(set) var weeklyStats: WeeklyStats?
    private(set) var monthlyStats: MonthlyStats?
    private(set) var focusPattern: FocusPattern?
    private(set) var recentTrends: [FocusTrend] = []

    private let calendar = Calendar.current

    private init() {}

    // MARK: - Weekly Stats

    func computeWeeklyStats(sessions: [Session], streak: StreakData, soundCounts: [String: Double]) -> WeeklyStats {
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return WeeklyStats(weekStartDate: today)
        }

        let weekSessions = sessions.filter { session in
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return false }
            return session.completedAt >= weekStart && session.completedAt <= today
        }

        let totalMinutes = weekSessions.reduce(0) { $0 + ($1.duration / 60) }
        let totalSessions = weekSessions.count
        let avgScore = weekSessions.isEmpty ? 0 : Double(weekSessions.reduce(0) { $0 + $1.focusScore }) / Double(weekSessions.count)

        var dailyMinutes = Array(repeating: 0, count: 7)
        var longestSession = 0
        var sessionsWithPartner = 0
        var soundCounts: [String: Double] = [:]

        for session in weekSessions {
            let dayIndex = calendar.component(.weekday, from: session.completedAt) - 1
            dailyMinutes[dayIndex] += session.duration / 60
            longestSession = max(longestSession, session.duration / 60)
            if session.partnerId != nil {
                sessionsWithPartner += 1
            }
            for soundId in session.soundIds {
                soundCounts[soundId, default: 0] += 1
            }
        }

        let topSound = soundCounts.max(by: { $0.value < $1.value })?.key

        return WeeklyStats(
            weekStartDate: weekStart,
            totalMinutes: totalMinutes,
            totalSessions: totalSessions,
            averageFocusScore: avgScore,
            dailyMinutes: dailyMinutes,
            topSound: topSound,
            sessionsWithPartner: sessionsWithPartner,
            longestSession: longestSession,
            streakDays: streak.currentStreak
        )
    }

    func computeMonthlyStats(sessions: [Session], streak: StreakData, soundCounts: [String: Double]) -> MonthlyStats {
        let today = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        let monthSessions = sessions.filter { $0.completedAt >= monthStart && $0.completedAt <= today }

        let totalMinutes = monthSessions.reduce(0) { $0 + ($1.duration / 60) }
        let totalSessions = monthSessions.count
        let avgScore = monthSessions.isEmpty ? 0 : Double(monthSessions.reduce(0) { $0 + $1.focusScore }) / Double(monthSessions.count)

        // Weekly breakdown
        var weeklyMinutes: [Int] = [0, 0, 0, 0, 0]
        for session in monthSessions {
            let weekOfMonth = (calendar.component(.weekOfMonth, from: session.completedAt)) - 1
            if weekOfMonth >= 0 && weekOfMonth < 5 {
                weeklyMinutes[weekOfMonth] += session.duration / 60
            }
        }

        // Count unique active days
        let uniqueDays = Set(monthSessions.map { calendar.startOfDay(for: $0.completedAt) }).count

        var soundCounts: [String: Double] = [:]
        for session in monthSessions {
            for soundId in session.soundIds {
                soundCounts[soundId, default: 0] += 1
            }
        }
        let topSound = soundCounts.max(by: { $0.value < $1.value })?.key

        return MonthlyStats(
            month: monthStart,
            totalMinutes: totalMinutes,
            totalSessions: totalSessions,
            averageFocusScore: avgScore,
            weeklyMinutes: weeklyMinutes,
            topSound: topSound,
            sessionsWithPartner: monthSessions.filter { $0.partnerId != nil }.count,
            daysActive: uniqueDays,
            longestStreak: streak.longestStreak,
            currentStreak: streak.currentStreak
        )
    }

    func computeFocusPattern(sessions: [Session]) -> FocusPattern? {
        guard sessions.count >= 5 else { return nil }

        // Best time of day
        var hourCounts: [Int: Int] = [:]
        var dayCounts: [Int: Int] = [:]
        var totalMinutes = 0
        var totalSessions = 0

        for session in sessions {
            let hour = calendar.component(.hour, from: session.completedAt)
            let day = calendar.component(.weekday, from: session.completedAt)
            hourCounts[hour, default: 0] += 1
            dayCounts[day, default: 0] += 1
            totalMinutes += session.duration
            totalSessions += 1
        }

        let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 12
        let bestDay = dayCounts.max(by: { $0.value < $1.value })?.key ?? 1

        let timeOfDay: FocusPattern.TimeOfDay
        switch bestHour {
        case 5..<8: timeOfDay = .earlyMorning
        case 8..<12: timeOfDay = .morning
        case 12..<17: timeOfDay = .afternoon
        case 17..<20: timeOfDay = .evening
        default: timeOfDay = .night
        }

        // Sound preference
        var soundCounts: [String: Double] = [:]
        for session in sessions {
            for soundId in session.soundIds {
                soundCounts[soundId, default: 0] += 1
            }
        }
        let preferredSound = soundCounts.max(by: { $0.value < $1.value })?.key

        // Consistency: how regular are sessions (simple variance-based)
        let avgSessionLength = totalSessions > 0 ? Double(totalMinutes) / Double(totalSessions) : 0
        let consistencyScore = min(1.0, avgSessionLength / 45.0) // normalize to ~45min ideal

        return FocusPattern(
            bestTimeOfDay: timeOfDay,
            bestDayOfWeek: bestDay,
            preferredSound: preferredSound,
            averageSessionMinutes: Int(avgSessionLength),
            consistencyScore: consistencyScore
        )
    }

    func computeTrends(sessions: [Session], days: Int = 14) -> [FocusTrend] {
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        return sessions
            .filter { $0.completedAt >= startDate && $0.completedAt <= Date() }
            .map { FocusTrend(date: $0.completedAt, focusScore: $0.focusScore, duration: $0.duration) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Refresh

    func refresh(sessions: [Session], streak: StreakData, soundCounts: [String: Double]) {
        weeklyStats = computeWeeklyStats(sessions: sessions, streak: streak, soundCounts: soundCounts)
        monthlyStats = computeMonthlyStats(sessions: sessions, streak: streak, soundCounts: soundCounts)
        focusPattern = computeFocusPattern(sessions: sessions)
        recentTrends = computeTrends(sessions: sessions)
    }
}
