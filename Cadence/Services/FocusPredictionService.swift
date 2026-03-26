import Foundation

// MARK: - Focus Prediction Engine
struct FocusPrediction: Codable {
    let suggestedTime: Date
    let suggestedDuration: Int // minutes
    let confidence: Double // 0-1
    let reason: String
}

@MainActor
class FocusPredictionService: ObservableObject {
    @Published var currentPrediction: FocusPrediction?
    @Published var isLoading = false
    
    private let calendar = Calendar.current
    
    /// Predict optimal focus time based on historical session data
    func predictOptimalFocusTime(sessions: [Session]) -> FocusPrediction? {
        guard sessions.count >= 5 else {
            return defaultPrediction()
        }
        
        // Analyze best performing times
        let hourFrequency = analyzeBestHours(sessions: sessions)
        let bestHour = hourFrequency.max(by: { $0.value < $1.value })?.key ?? 9
        
        let avgDuration = sessions.map(\.duration).reduce(0, +) / sessions.count
        let suggestedDuration = max(25, min(120, avgDuration / 60))
        
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = bestHour
        components.minute = 0
        let suggestedTime = calendar.date(from: components) ?? now
        
        let confidence = min(0.9, Double(sessions.count) / 50.0)
        
        return FocusPrediction(
            suggestedTime: suggestedTime > now ? suggestedTime : calendar.date(byAdding: .day, value: 1, to: suggestedTime)!,
            suggestedDuration: suggestedDuration,
            confidence: confidence,
            reason: "Based on your \(sessions.count) past sessions"
        )
    }
    
    private func analyzeBestHours(sessions: [Session]) -> [Int: Double] {
        var hourScores: [Int: Double] = [:]
        
        for session in sessions {
            let hour = calendar.component(.hour, from: session.completedAt)
            let score = Double(session.focusScore)
            let currentAvg = hourScores[hour] ?? 0
            let count = sessions.filter { calendar.component(.hour, from: $0.completedAt) == hour }.count
            hourScores[hour] = (currentAvg * Double(count - 1) + score) / Double(count)
        }
        
        return hourScores
    }
    
    private func defaultPrediction() -> FocusPrediction {
        let now = Date()
        let suggestedTime = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        return FocusPrediction(
            suggestedTime: suggestedTime,
            suggestedDuration: 50,
            confidence: 0.3,
            reason: "Start with 50 minutes — adjust based on how you feel"
        )
    }
}

// MARK: - Siri Shortcuts Integration
struct SiriShortcutService {
    
    /// Donate shortcut for completing a focus session
    static func donateFocusCompleted(duration: Int) {
        // Siri Shortcuts donation placeholder
        // In production: use AppIntents framework
    }
    
    /// Donate shortcut for starting a focus session
    static func donateFocusStarted() {
        // Siri Shortcuts donation placeholder
    }
    
    /// Suggest a focus session via Siri
    static func suggestFocusSession(at time: Date, duration: Int) {
        // Siri Suggestion API placeholder
    }
}
