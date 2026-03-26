import Foundation
import EventKit

/// R8: Calendar integration for scheduling focus sessions
@MainActor
@Observable
class CalendarExportService {
    static let shared = CalendarExportService()

    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var hasCalendarAccess: Bool = false

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                hasCalendarAccess = granted
                authorizationStatus = granted ? .fullAccess : .denied
            }
            return granted
        } catch {
            authorizationStatus = .denied
            hasCalendarAccess = false
            return false
        }
    }

    // MARK: - Schedule Focus Block

    func scheduleFocusBlock(
        date: Date,
        durationMinutes: Int,
        title: String = "Focus Time",
        notes: String? = nil,
        calendarTitle: String? = nil
    ) -> Bool {
        guard hasCalendarAccess else { return false }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: date) ?? date
        event.notes = notes ?? "Scheduled via Cadence"
        event.calendar = findCalendar(named: calendarTitle) ?? eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Schedule Recurring Focus Blocks

    func scheduleWeeklyFocusBlocks(
        startTime: DateComponents,
        durationMinutes: Int,
        weekdays: [Int],
        title: String = "Weekly Focus",
        weeks: Int = 4
    ) -> Int {
        guard hasCalendarAccess else { return 0 }

        var successCount = 0
        let calendar = Calendar.current

        for weekOffset in 0..<weeks {
            for weekday in weekdays {
                guard let weekdayDate = nextDate(for: weekday, hour: startTime.hour ?? 9, minute: startTime.minute ?? 0, weeksFromNow: weekOffset, calendar: calendar) else { continue }

                if scheduleFocusBlock(date: weekdayDate, durationMinutes: durationMinutes, title: title) {
                    successCount += 1
                }
            }
        }

        return successCount
    }

    private func nextDate(for weekday: Int, hour: Int, minute: Int, weeksFromNow: Int, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekOfYear = (components.weekOfYear ?? 1) + weeksFromNow
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    // MARK: - Sync Session to Calendar

    func syncSessionToCalendar(_ session: Session, calendarTitle: String? = nil) -> Bool {
        guard hasCalendarAccess else { return false }

        let durationMinutes = session.duration / 60
        let startTime = session.completedAt
        let title = "Focus Session (\(durationMinutes)m)"

        var notes = "Focus Score: \(session.focusScore)/100\n"
        if !session.soundIds.isEmpty {
            notes += "Sounds: \(session.soundIds.joined(separator: ", "))\n"
        }
        if session.partnerId != nil {
            notes += "Had a focus partner"
        }

        return scheduleFocusBlock(
            date: startTime,
            durationMinutes: durationMinutes,
            title: title,
            notes: notes,
            calendarTitle: calendarTitle
        )
    }

    // MARK: - Export Week to Calendar

    func exportWeekSchedule(
        sessions: [Session],
        weekday: Int,
        startHour: Int,
        durationMinutes: Int
    ) -> Int {
        guard hasCalendarAccess else { return 0 }

        guard let startDate = nextDate(for: weekday, hour: startHour, minute: 0, weeksFromNow: 0, calendar: Calendar.current) else { return 0 }

        var count = 0
        for session in sessions {
            if Calendar.current.component(.weekday, from: session.completedAt) == weekday {
                if scheduleFocusBlock(
                    date: startDate,
                    durationMinutes: durationMinutes,
                    title: "Focus Session"
                ) {
                    count += 1
                }
            }
        }

        return count
    }

    // MARK: - Helpers

    private func findCalendar(named name: String?) -> EKCalendar? {
        guard let name = name else { return nil }
        return eventStore.calendars(for: .event).first { $0.title == name }
    }

    // MARK: - Data Export

    func exportSessionsToJSON(sessions: [Session]) -> Data? {
        let export = sessions.map { session in
            [
                "id": session.id.uuidString,
                "duration_minutes": session.duration / 60,
                "completed_at": ISO8601DateFormatter().string(from: session.completedAt),
                "focus_score": session.focusScore,
                "sounds": session.soundIds.joined(separator: ","),
                "had_partner": session.partnerId != nil
            ] as [String: Any]
        }
        return try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
    }

    func exportSessionsToCSV(sessions: [Session]) -> String {
        var csv = "ID,Duration (min),Completed At,Focus Score,Sounds,Had Partner\n"
        for session in sessions {
            let row = [
                session.id.uuidString,
                "\(session.duration / 60)",
                ISO8601DateFormatter().string(from: session.completedAt),
                "\(session.focusScore)",
                session.soundIds.joined(separator: "|"),
                session.partnerId != nil ? "Yes" : "No"
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }
}
