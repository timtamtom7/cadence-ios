import Foundation

/// R7: Statistics and insights models
struct SessionInsight: Codable, Identifiable {
    let id: UUID
    let date: Date
    let totalMinutes: Int
    let sessionCount: Int
    let averageFocusScore: Double
    let topSound: String?
    let streakDay: Int
    let goalMet: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        totalMinutes: Int,
        sessionCount: Int,
        averageFocusScore: Double,
        topSound: String? = nil,
        streakDay: Int = 0,
        goalMet: Bool = false
    ) {
        self.id = id
        self.date = date
        self.totalMinutes = totalMinutes
        self.sessionCount = sessionCount
        self.averageFocusScore = averageFocusScore
        self.topSound = topSound
        self.streakDay = streakDay
        self.goalMet = goalMet
    }
}

struct WeeklyStats: Codable {
    let weekStartDate: Date
    let totalMinutes: Int
    let totalSessions: Int
    let averageFocusScore: Double
    let dailyMinutes: [Int] // 7 days, index 0 = Sunday
    let topSound: String?
    let sessionsWithPartner: Int
    let longestSession: Int // minutes
    let streakDays: Int

    init(
        weekStartDate: Date,
        totalMinutes: Int = 0,
        totalSessions: Int = 0,
        averageFocusScore: Double = 0,
        dailyMinutes: [Int] = Array(repeating: 0, count: 7),
        topSound: String? = nil,
        sessionsWithPartner: Int = 0,
        longestSession: Int = 0,
        streakDays: Int = 0
    ) {
        self.weekStartDate = weekStartDate
        self.totalMinutes = totalMinutes
        self.totalSessions = totalSessions
        self.averageFocusScore = averageFocusScore
        self.dailyMinutes = dailyMinutes
        self.topSound = topSound
        self.sessionsWithPartner = sessionsWithPartner
        self.longestSession = longestSession
        self.streakDays = streakDays
    }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    var averageSessionLength: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(totalMinutes) / Double(totalSessions)
    }

    var goalProgress: Double {
        // Default weekly goal: 10 hours
        min(1.0, Double(totalMinutes) / 600.0)
    }

    var formattedWeekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: end))"
    }
}

struct MonthlyStats: Codable {
    let month: Date // First day of month
    let totalMinutes: Int
    let totalSessions: Int
    let averageFocusScore: Double
    let weeklyMinutes: [Int] // 4-5 weeks
    let topSound: String?
    let sessionsWithPartner: Int
    let daysActive: Int
    let longestStreak: Int
    let currentStreak: Int

    init(
        month: Date,
        totalMinutes: Int = 0,
        totalSessions: Int = 0,
        averageFocusScore: Double = 0,
        weeklyMinutes: [Int] = [],
        topSound: String? = nil,
        sessionsWithPartner: Int = 0,
        daysActive: Int = 0,
        longestStreak: Int = 0,
        currentStreak: Int = 0
    ) {
        self.month = month
        self.totalMinutes = totalMinutes
        self.totalSessions = totalSessions
        self.averageFocusScore = averageFocusScore
        self.weeklyMinutes = weeklyMinutes
        self.topSound = topSound
        self.sessionsWithPartner = sessionsWithPartner
        self.daysActive = daysActive
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
    }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
}

struct FocusTrend: Codable, Identifiable {
    let id: UUID
    let date: Date
    let focusScore: Int
    let duration: Int // seconds

    init(id: UUID = UUID(), date: Date, focusScore: Int, duration: Int) {
        self.id = id
        self.date = date
        self.focusScore = focusScore
        self.duration = duration
    }
}

struct FocusPattern: Codable {
    let bestTimeOfDay: TimeOfDay
    let bestDayOfWeek: Int // 1 = Sunday
    let preferredSound: String?
    let averageSessionMinutes: Int
    let consistencyScore: Double // 0-1

    enum TimeOfDay: String, Codable {
        case earlyMorning // 5-8am
        case morning // 8-12pm
        case afternoon // 12-5pm
        case evening // 5-8pm
        case night // 8pm+

        var label: String {
            switch self {
            case .earlyMorning: return "Early Morning"
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            case .night: return "Night"
            }
        }

        var icon: String {
            switch self {
            case .earlyMorning: return "sunrise.fill"
            case .morning: return "sun.max.fill"
            case .afternoon: return "sun.min.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }
    }
}
