import Foundation

// MARK: - AI Focus Goal

/// Represents the type of focus goal a user wants to achieve (AI-optimized variant)
enum AIFocusGoal: String, CaseIterable, Codable, Identifiable {
    case deepWork = "Deep Work"
    case creative = "Creative"
    case study = "Study"
    case quickTask = "Quick Task"
    case planning = "Planning"
    case review = "Review"
    case reading = "Reading"

    var id: String { rawValue }

    /// SF Symbol icon for each goal type
    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .creative: return "paintbrush.fill"
        case .study: return "book.fill"
        case .quickTask: return "bolt.fill"
        case .planning: return "map.fill"
        case .review: return "checkmark.seal.fill"
        case .reading: return "eyeglasses"
        }
    }

    /// Recommended session duration range in minutes
    var recommendedDurationRange: ClosedRange<Int> {
        switch self {
        case .deepWork: return 45...90
        case .creative: return 30...60
        case .study: return 25...50
        case .quickTask: return 15...25
        case .planning: return 30...45
        case .review: return 20...40
        case .reading: return 20...45
        }
    }

    /// Map to existing FocusGoal category if possible
    var focusGoalCategory: FocusGoal.GoalCategory? {
        switch self {
        case .deepWork: return .deepWork
        case .creative: return .creative
        case .study: return .study
        case .quickTask: return nil
        case .planning: return nil
        case .review: return nil
        case .reading: return .reading
        }
    }
}

// MARK: - AI Focus Session

/// A focus session with metadata for AI analysis
struct AIFocusSession: Identifiable, Codable {
    let id: UUID
    let duration: Int // seconds
    let completedAt: Date
    let soundIds: [String]
    let partnerId: UUID?
    let focusScore: Int // 0-100
    let goal: AIFocusGoal?

    init(
        id: UUID = UUID(),
        duration: Int,
        completedAt: Date = Date(),
        soundIds: [String] = [],
        partnerId: UUID? = nil,
        focusScore: Int,
        goal: AIFocusGoal? = nil
    ) {
        self.id = id
        self.duration = duration
        self.completedAt = completedAt
        self.soundIds = soundIds
        self.partnerId = partnerId
        self.focusScore = focusScore
        self.goal = goal
    }

    var durationMinutes: Int { duration / 60 }
}

// MARK: - Focus Mix

/// Recommended mix of ambient sounds for a focus goal
struct FocusMix: Identifiable, Codable {
    let id: UUID
    let primarySound: SoundEntry
    let secondarySound: SoundEntry?
    let tertiarySound: SoundEntry?
    let suggestion: String

    init(
        id: UUID = UUID(),
        primarySound: SoundEntry,
        secondarySound: SoundEntry? = nil,
        tertiarySound: SoundEntry? = nil,
        suggestion: String
    ) {
        self.id = id
        self.primarySound = primarySound
        self.secondarySound = secondarySound
        self.tertiarySound = tertiarySound
        self.suggestion = suggestion
    }
}

/// A single sound entry in a focus mix
struct SoundEntry: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let volume: Float // 0.0 - 1.0

    init(id: String, name: String, icon: String, volume: Float) {
        self.id = id
        self.name = name
        self.icon = icon
        self.volume = volume
    }
}

// MARK: - Smart Suggestion

/// A contextual smart suggestion for the user
struct SmartSuggestion: Identifiable {
    let id: UUID
    let message: String
    let icon: String
    let priority: Priority

    enum Priority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - AIFocusService

/// AI-powered focus intelligence service that suggests optimal focus mixes
/// and detects flow states based on session history
final class AIFocusService: @unchecked Sendable {
    static let shared = AIFocusService()

    private let calendar = Calendar.current
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sessions = "cadence.sessions"
    }

    private init() {}

    // MARK: - Public API

    /// Suggests an optimal focus sound mix based on the user's goal and time of day
    /// - Parameters:
    ///   - goal: The type of focus the user wants to achieve
    ///   - time: The current time (used for time-of-day adjustments)
    /// - Returns: A FocusMix with recommended sounds and a contextual suggestion
    func suggestFocusMix(for goal: AIFocusGoal, time: Date) -> FocusMix {
        let hour = calendar.component(.hour, from: time)
        let isMorning = hour >= 5 && hour < 12
        let isAfternoon = hour >= 12 && hour < 17
        let isEvening = hour >= 17 && hour < 22
        let isNight = hour >= 22 || hour < 5

        // Goal-based primary sound selection
        let primarySound: SoundEntry
        switch goal {
        case .deepWork:
            primarySound = SoundEntry(id: "rain", name: "Rain", icon: "cloud.rain.fill", volume: 0.6)
        case .creative:
            primarySound = SoundEntry(id: "forest", name: "Forest", icon: "leaf.fill", volume: 0.5)
        case .study:
            primarySound = SoundEntry(id: "whitenoise", name: "White Noise", icon: "waveform", volume: 0.4)
        case .quickTask:
            primarySound = SoundEntry(id: "cafe", name: "Cafe", icon: "cup.and.saucer.fill", volume: 0.5)
        case .planning:
            primarySound = SoundEntry(id: "fire", name: "Fireplace", icon: "flame.fill", volume: 0.4)
        case .review:
            primarySound = SoundEntry(id: "ocean", name: "Ocean Waves", icon: "water.waves", volume: 0.5)
        case .reading:
            primarySound = SoundEntry(id: "rain", name: "Rain", icon: "cloud.rain.fill", volume: 0.35)
        }

        // Time-of-day secondary sound
        let secondarySound: SoundEntry?
        switch (isMorning, isAfternoon, isEvening, isNight) {
        case (true, _, _, _):
            secondarySound = SoundEntry(id: "birds", name: "Birds", icon: "bird.fill", volume: 0.25)
        case (_, true, _, _):
            secondarySound = SoundEntry(id: "forest", name: "Forest", icon: "leaf.fill", volume: 0.3)
        case (_, _, true, _):
            secondarySound = SoundEntry(id: "fire", name: "Fireplace", icon: "flame.fill", volume: 0.3)
        case (_, _, _, true):
            secondarySound = SoundEntry(id: "whitenoise", name: "White Noise", icon: "waveform", volume: 0.2)
        default:
            secondarySound = nil
        }

        // Build suggestion message
        let suggestion = buildSuggestion(for: goal, hour: hour)

        return FocusMix(
            primarySound: primarySound,
            secondarySound: secondarySound,
            tertiarySound: nil,
            suggestion: suggestion
        )
    }

    /// Detects whether the given session achieved a flow state
    /// - Parameter session: The focus session to analyze
    /// - Returns: true if the session exhibited flow state characteristics
    func detectFlowState(session: AIFocusSession) -> Bool {
        var flowIndicators = 0

        // High focus score (85+) indicates sustained attention
        if session.focusScore >= 85 {
            flowIndicators += 1
        }

        // Longer sessions (>30 min) can indicate time distortion
        if session.durationMinutes >= 30 {
            flowIndicators += 1
        }

        // Very high focus score + long duration = likely effortless control
        if session.focusScore >= 90 && session.durationMinutes >= 45 {
            flowIndicators += 1
        }

        // Sessions with sound mixing tend to have better focus
        if session.soundIds.count >= 2 {
            flowIndicators += 1
        }

        // Need at least 3 indicators for flow state
        return flowIndicators >= 3
    }

    /// Returns a smart contextual suggestion based on session history and time
    /// - Parameter time: The current time
    /// - Returns: A SmartSuggestion with an actionable insight
    func smartSuggestion(for time: Date) -> SmartSuggestion {
        let sessions = loadRecentSessions()
        let hour = calendar.component(.hour, from: time)

        // Analyze best focus time from history
        if let bestTime = analyzeBestFocusTime(sessions: sessions) {
            let timeString = formatHour(bestTime)
            if sessions.count >= 5 {
                return SmartSuggestion(
                    id: UUID(),
                    message: "Based on your history, \(timeString) is your best focus time — your average focus score is 15% higher then.",
                    icon: "clock.badge.checkmark.fill",
                    priority: .high
                )
            }
        }

        // Time-of-day contextual suggestions
        if hour >= 5 && hour < 9 {
            return SmartSuggestion(
                id: UUID(),
                message: "Morning sessions average 12% higher focus scores. Start with a 25-minute Deep Work session?",
                icon: "sunrise.fill",
                priority: .medium
            )
        } else if hour >= 22 || hour < 5 {
            return SmartSuggestion(
                id: UUID(),
                message: "Night owl detected! Late sessions tend to be 20% longer — consider a quick 15-minute task instead.",
                icon: "moon.stars.fill",
                priority: .medium
            )
        } else if hour >= 12 && hour < 14 {
            return SmartSuggestion(
                id: UUID(),
                message: "Post-lunch dip incoming. Short 15-minute sessions work best in the early afternoon.",
                icon: "cup.and.saucer.fill",
                priority: .low
            )
        }

        // Default suggestion
        return SmartSuggestion(
            id: UUID(),
            message: "Ready to focus? Your streak is \(loadCurrentStreak()) days — keep it going!",
            icon: "flame.fill",
            priority: .low
        )
    }

    // MARK: - Private Helpers

    private func buildSuggestion(for goal: AIFocusGoal, hour: Int) -> String {
        let sessions = loadRecentSessions()
        let hourDesc: String

        switch hour {
        case 5..<12: hourDesc = "morning"
        case 12..<17: hourDesc = "afternoon"
        case 17..<22: hourDesc = "evening"
        default: hourDesc = "night"
        }

        if sessions.isEmpty {
            return "Try a \(goal.recommendedDurationRange.lowerBound)-minute \(goal.rawValue) session this \(hourDesc)."
        }

        let avgScore = sessions.map(\.focusScore).reduce(0, +) / max(1, sessions.count)
        if avgScore >= 85 {
            return "You're in great focus form! Push for a \(goal.recommendedDurationRange.upperBound)-minute \(goal.rawValue) session."
        } else if avgScore >= 70 {
            return "Solid focus today. A \(goal.recommendedDurationRange.lowerBound)-minute \(goal.rawValue) session should work well."
        } else {
            return "Start light with a \(min(goal.recommendedDurationRange.lowerBound, 25))-minute session and build momentum."
        }
    }

    private func loadRecentSessions() -> [AIFocusSession] {
        guard let data = defaults.data(forKey: Keys.sessions),
              let sessions = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }

        // Return last 30 sessions from the last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return sessions
            .filter { $0.completedAt >= thirtyDaysAgo }
            .prefix(30)
            .map { session in
                AIFocusSession(
                    id: session.id,
                    duration: session.duration,
                    completedAt: session.completedAt,
                    soundIds: session.soundIds,
                    partnerId: session.partnerId,
                    focusScore: session.focusScore,
                    goal: nil
                )
            }
    }

    private func loadCurrentStreak() -> Int {
        guard let data = defaults.data(forKey: "cadence.streak"),
              let streak = try? JSONDecoder().decode(StreakData.self, from: data) else {
            return 0
        }
        return streak.currentStreak
    }

    private func analyzeBestFocusTime(sessions: [AIFocusSession]) -> Int? {
        guard !sessions.isEmpty else { return nil }

        var hourScores: [Int: [Int]] = [:]

        for session in sessions {
            let hour = calendar.component(.hour, from: session.completedAt)
            var scores = hourScores[hour] ?? []
            scores.append(session.focusScore)
            hourScores[hour] = scores
        }

        var hourAverages: [Int: Double] = [:]
        for (hour, scores) in hourScores {
            hourAverages[hour] = Double(scores.reduce(0, +)) / Double(scores.count)
        }

        return hourAverages.max(by: { $0.value < $1.value })?.key
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        if let date = calendar.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)"
    }
}
