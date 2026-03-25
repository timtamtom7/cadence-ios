import Foundation

/// R8: AI-powered focus coach service
@MainActor
final class AICoachService: ObservableObject {
    static let shared = AICoachService()

    @Published private(set) var isAnalyzing = false
    @Published private(set) var lastInsight: CoachInsight?

    private init() {}

    // MARK: - Insights

    struct CoachInsight: Identifiable {
        let id = UUID()
        let type: InsightType
        let title: String
        let message: String
        let actionLabel: String?
        let action: (() -> Void)?

        enum InsightType {
            case streak
            case duration
            case partner
            case habit
            case reminder

            var icon: String {
                switch self {
                case .streak: return "flame.fill"
                case .duration: return "clock.fill"
                case .partner: return "person.2.fill"
                case .habit: return "leaf.fill"
                case .reminder: return "bell.fill"
                }
            }

            var color: String {
                switch self {
                case .streak: return "#FF6B6B"
                case .duration: return "#00D4AA"
                case .partner: return "#00F5CC"
                case .habit: return "#4ECDC4"
                case .reminder: return "#FFD93D"
                }
            }
        }
    }

    // MARK: - Analyze Session

    func analyzeSession(_ session: Session, allSessions: [Session]) async -> CoachInsight? {
        isAnalyzing = true
        defer { isAnalyzing = false }

        // Simple analysis based on session data
        // In production, this would call an AI model

        try? await Task.sleep(nanoseconds: 500_000_000)

        var insights: [CoachInsight] = []

        // Duration insight
        if session.duration >= 3600 {
            insights.append(CoachInsight(
                type: .duration,
                title: "Deep Focus!",
                message: "You focused for \(session.duration / 60) minutes straight. That's impressive concentration.",
                actionLabel: "Try 90 minutes",
                action: nil
            ))
        }

        // Streak insight
        let streak = calculateStreak(sessions: allSessions)
        if streak >= 7 {
            insights.append(CoachInsight(
                type: .streak,
                title: "Week Warrior!",
                message: "\(streak) days and counting. You're building a real habit.",
                actionLabel: nil,
                action: nil
            ))
        }

        // Partner insight
        if session.partnerId != nil {
            insights.append(CoachInsight(
                type: .partner,
                title: "Stronger Together",
                message: "Partner sessions boost accountability by 40%. Great choice!",
                actionLabel: nil,
                action: nil
            ))
        }

        // Pick the most relevant insight
        let insight = insights.randomElement()
        lastInsight = insight
        return insight
    }

    // MARK: - Daily Tip

    func dailyTip() async -> CoachInsight {
        let tips: [CoachInsight] = [
            CoachInsight(
                type: .habit,
                title: "Morning Momentum",
                message: "Start your day with a 25-minute focus session to build momentum.",
                actionLabel: "Start Now",
                action: nil
            ),
            CoachInsight(
                type: .duration,
                title: "Ultradian Rhythm",
                message: "Your brain focuses best in 90-minute cycles. Try timing your sessions around this.",
                actionLabel: nil,
                action: nil
            ),
            CoachInsight(
                type: .habit,
                title: "Environment Matters",
                message: "A dedicated focus space can improve your concentration by up to 35%.",
                actionLabel: nil,
                action: nil
            ),
            CoachInsight(
                type: .partner,
                title: "Accountability Partner",
                message: "Sessions with a partner have 40% higher completion rates.",
                actionLabel: "Find a Partner",
                action: nil
            )
        ]
        return tips.randomElement() ?? tips[0]
    }

    // MARK: - Weekly Summary

    func weeklySummary(sessions: [Session]) async -> WeeklySummary {
        let weekSessions = sessions.filter {
            Calendar.current.isDate($0.completedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }

        let totalMinutes = weekSessions.reduce(0) { $0 + $1.duration / 60 }
        let partnerSessions = weekSessions.filter { $0.partnerId != nil }.count
        let avgFocusScore = weekSessions.isEmpty ? 0 : weekSessions.reduce(0) { $0 + $1.focusScore } / weekSessions.count

        return WeeklySummary(
            totalMinutes: totalMinutes,
            sessionCount: weekSessions.count,
            partnerSessionCount: partnerSessions,
            averageFocusScore: avgFocusScore,
            streak: calculateStreak(sessions: sessions)
        )
    }

    // MARK: - Helpers

    private func calculateStreak(sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let sortedDates = sessions
            .map { calendar.startOfDay(for: $0.completedAt) }
            .sorted(by: >)

        guard !sortedDates.isEmpty else { return 0 }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if date < currentDate {
                break
            }
        }

        return streak
    }
}

struct WeeklySummary {
    let totalMinutes: Int
    let sessionCount: Int
    let partnerSessionCount: Int
    let averageFocusScore: Int
    let streak: Int

    var formattedHours: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
