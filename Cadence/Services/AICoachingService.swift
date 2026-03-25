import Foundation

/// R8: AI-powered session coaching and recommendations
@MainActor
@Observable
class AICoachingService {
    static let shared = AICoachingService()

    private(set) var todaysRecommendation: SessionRecommendation?
    private(set) var weeklyInsight: String?

    private let statisticsService = StatisticsService.shared

    private init() {}

    // MARK: - Session Recommendation

    struct SessionRecommendation {
        let suggestedDuration: Int // seconds
        let suggestedSound: String
        let reasoning: String
        let optimalTime: String?
        let expectedFocusScore: Int
    }

    func generateRecommendation(sessions: [Session], streak: StreakData) -> SessionRecommendation {
        // Analyze recent sessions to generate personalized recommendation
        let recentSessions = sessions.suffix(10)
        let avgDuration = recentSessions.isEmpty ? 1500 : recentSessions.reduce(0) { $0 + $1.duration } / recentSessions.count
        let avgScore = recentSessions.isEmpty ? 70 : recentSessions.reduce(0) { $0 + $1.focusScore } / recentSessions.count

        // Determine suggested duration based on streak and recent performance
        let duration: Int
        let reasoning: String
        let expectedScore: Int

        if streak.currentStreak >= 7 {
            // Strong streak - suggest longer sessions
            duration = max(1800, min(3600, Int(Double(avgDuration) * 1.2)))
            reasoning = "Your \(streak.currentStreak)-day streak shows strong commitment. Time to level up with slightly longer sessions."
            expectedScore = min(100, Int(Double(avgScore) * 1.05))
        } else if streak.currentStreak >= 3 {
            duration = avgDuration
            reasoning = "Building momentum with your \(streak.currentStreak)-day streak. Keep it consistent!"
            expectedScore = Int(avgScore)
        } else if recentSessions.isEmpty {
            duration = 1500
            reasoning = "Welcome back! Start with a manageable 25-minute session to ease back in."
            expectedScore = 70
        } else {
            duration = min(avgDuration, 1800)
            reasoning = "Focus on quality over length. Shorter, focused sessions build lasting habits."
            expectedScore = Int(Double(avgScore) * 0.95)
        }

        // Suggest optimal sound based on pattern
        let sound = suggestSound(recentSessions: Array(recentSessions))

        // Suggest optimal time
        let optimalTime = suggestOptimalTime(sessions: Array(recentSessions))

        return SessionRecommendation(
            suggestedDuration: duration,
            suggestedSound: sound,
            reasoning: reasoning,
            optimalTime: optimalTime,
            expectedFocusScore: expectedScore
        )
    }

    private func suggestSound(recentSessions: [Session]) -> String {
        var soundCounts: [String: Int] = [:]
        for session in recentSessions {
            for soundId in session.soundIds {
                soundCounts[soundId, default: 0] += 1
            }
        }

        if let top = soundCounts.max(by: { $0.value < $1.value }) {
            return top.key
        }
        return "rain"
    }

    private func suggestOptimalTime(sessions: [Session]) -> String? {
        guard sessions.count >= 5 else { return nil }

        var hourScores: [Int: [Int]] = [:]
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.completedAt)
            hourScores[hour, default: []].append(session.focusScore)
        }

        let bestHour = hourScores.max { a, b in
            let avgA = Double(a.value.reduce(0, +)) / Double(a.value.count)
            let avgB = Double(b.value.reduce(0, +)) / Double(b.value.count)
            return avgA < avgB
        }?.key

        guard let hour = bestHour else { return nil }

        switch hour {
        case 5..<8: return "Early morning (5-8am) tends to be your peak focus time"
        case 8..<12: return "Mornings (8am-noon) are your strongest focus window"
        case 12..<17: return "Afternoons (noon-5pm) work well for your focus"
        case 17..<20: return "Evenings (5-8pm) can be productive for you"
        default: return "Late nights work for your focus style"
        }
    }

    // MARK: - Weekly Insight

    func generateWeeklyInsight(stats: WeeklyStats?, previousStats: WeeklyStats?) -> String? {
        guard let stats = stats else { return nil }

        var insights: [String] = []

        if let prev = previousStats {
            let minuteChange = stats.totalMinutes - prev.totalMinutes
            if abs(minuteChange) > 30 {
                if minuteChange > 0 {
                    insights.append("You focused \(minuteChange) more minutes than last week!")
                } else {
                    insights.append("Your focus time was \(abs(minuteChange)) minutes less than last week.")
                }
            }
        }

        if stats.averageFocusScore >= 85 {
            insights.append("Outstanding focus quality this week!")
        } else if stats.averageFocusScore < 60 && stats.totalSessions >= 3 {
            insights.append("Consider shorter sessions to maintain better focus quality.")
        }

        if stats.sessionsWithPartner > stats.totalSessions / 2 {
            insights.append("Social sessions seem to boost your focus!")
        }

        if stats.streakDays >= 7 && stats.totalSessions >= 7 {
            insights.append("Incredible consistency - you're building a real habit!")
        }

        weeklyInsight = insights.isEmpty ? nil : insights.joined(separator: " ")
        return weeklyInsight
    }

    // MARK: - Refresh

    func refresh(sessions: [Session], streak: StreakData) {
        todaysRecommendation = generateRecommendation(sessions: sessions, streak: streak)
    }
}
