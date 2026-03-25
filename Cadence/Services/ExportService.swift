import Foundation

/// R8: Export service for sessions, statistics, and sharing
final class ExportService: @unchecked Sendable {
    static let shared = ExportService()

    private init() {}

    // MARK: - JSON Export

    func exportSessionsToJSON(sessions: [Session]) -> Data? {
        let export = SessionExport(
            sessions: sessions,
            exportedAt: Date()
        )
        return try? JSONEncoder().encode(export)
    }

    // MARK: - Share Text

    func shareText(session: Session, streak: Int) -> String {
        let minutes = session.duration / 60
        var text = "Focus: \(minutes) minutes"
        if session.partnerId != nil {
            text += " | 👥 Partner Session"
        }
        text += " | 🔥 \(streak) day streak"
        text += "\nMade with Cadence"
        return text
    }

    func shareText(weeklySummary: WeeklySummary) -> String {
        var text = "This week with Cadence:"
        text += "\n📊 \(weeklySummary.formattedHours) of focus"
        text += "\n🔥 \(weeklySummary.streak) day streak"
        text += "\n🎯 Avg focus score: \(weeklySummary.averageFocusScore)%"
        text += "\nMade with Cadence"
        return text
    }
}

struct SessionExport: Codable {
    let sessions: [Session]
    let exportedAt: Date
}
