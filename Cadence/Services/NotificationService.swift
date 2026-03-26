import Foundation
import UserNotifications
import os.log

/// Service for managing local notifications including weekly focus digest
@MainActor
@Observable
class NotificationService {
    static let shared = NotificationService()

    private let logger = Logger(subsystem: "com.cadence.app", category: "NotificationService")

    var isAuthorized: Bool = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    // MARK: - Authorization

    /// Request notification authorization from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await updateAuthorizationStatus()
            logger.info("Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Notification authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        await updateAuthorizationStatus()
    }

    private func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Weekly Digest

    /// Schedule the weekly focus digest notification based on user preferences
    func scheduleWeeklyDigest(profile: UserProfile, stats: DatabaseService.Stats) async {
        // Remove any existing weekly digest
        await cancelWeeklyDigest()

        guard profile.weeklyDigestEnabled else {
            logger.info("Weekly digest disabled, not scheduling")
            return
        }

        guard isAuthorized else {
            logger.warning("Notifications not authorized, skipping weekly digest scheduling")
            return
        }

        // Calculate the next occurrence of the target weekday and hour
        let nextDigestDate = calculateNextDigestDate(
            weekday: profile.weeklyDigestWeekday,
            hour: profile.weeklyDigestHour
        )

        let content = await buildDigestContent(profile: profile, stats: stats)

        do {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: nextDigestDate
                ),
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "cadence.weeklyDigest",
                content: content,
                trigger: trigger
            )

            try await UNUserNotificationCenter.current().add(request)
            logger.info("Weekly digest scheduled for \(nextDigestDate.formatted(), privacy: .public)")
        } catch {
            logger.error("Failed to schedule weekly digest: \(error.localizedDescription)")
        }
    }

    /// Cancel the weekly digest notification
    func cancelWeeklyDigest() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["cadence.weeklyDigest"]
        )
        logger.info("Weekly digest cancelled")
    }

    /// Update all notifications based on current user profile and stats
    func updateNotifications(profile: UserProfile, stats: DatabaseService.Stats) async {
        if profile.weeklyDigestEnabled && isAuthorized {
            await scheduleWeeklyDigest(profile: profile, stats: stats)
        } else {
            await cancelWeeklyDigest()
        }
    }

    // MARK: - Session Reminder

    /// Schedule a one-time reminder notification
    func scheduleSessionReminder(at date: Date, durationMinutes: Int) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Focus!"
        content.body = "Ready for another \(durationMinutes)-minute focus session?"
        content.sound = .default
        content.categoryIdentifier = "SESSION_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "cadence.sessionReminder.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Session reminder scheduled for \(date.formatted(), privacy: .public)")
        } catch {
            logger.error("Failed to schedule session reminder: \(error.localizedDescription)")
        }
    }

    /// Cancel all pending session reminders
    func cancelAllSessionReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let reminderIds = requests
                .filter { $0.identifier.hasPrefix("cadence.sessionReminder.") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIds)
        }
    }

    // MARK: - Streak Reminder

    /// Schedule a streak reminder if user hasn't focused today
    func scheduleStreakReminderIfNeeded(profile: UserProfile) async {
        guard isAuthorized else { return }

        // Check if user already had a session today
        let todayMinutes = await DatabaseService.shared.loadStats().todayMinutes
        guard todayMinutes == 0 else {
            logger.info("User already focused today, skipping streak reminder")
            return
        }

        // Cancel any existing streak reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["cadence.streakReminder"]
        )

        // Schedule reminder for 7pm local time if no session today
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19
        components.minute = 0

        guard let reminderDate = calendar.date(from: components) else { return }

        // If 7pm has passed, skip for today
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        content.body = "You haven't focused today. Spend just 25 minutes to keep your \(profile.username)'s streak alive."
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "cadence.streakReminder",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Streak reminder scheduled for \(reminderDate.formatted(), privacy: .public)")
        } catch {
            logger.error("Failed to schedule streak reminder: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Calculate the next occurrence of a weekday at a given hour
    private func calculateNextDigestDate(weekday: Int, hour: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        components.hour = hour
        components.minute = 0
        components.second = 0

        // Find the target weekday
        let currentWeekday = calendar.component(.weekday, from: now)
        var daysUntilTarget = weekday - currentWeekday
        if daysUntilTarget < 0 { daysUntilTarget += 7 }
        if daysUntilTarget == 0 {
            // Same day — check if the time has already passed
            if let todayTarget = calendar.date(from: components), todayTarget <= now {
                daysUntilTarget = 7
            }
        }

        guard let targetDate = calendar.date(byAdding: .day, value: daysUntilTarget, to: now) else {
            return now
        }

        var finalComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        finalComponents.hour = hour
        finalComponents.minute = 0
        finalComponents.second = 0

        return calendar.date(from: finalComponents) ?? now
    }

    /// Build the notification content for the weekly digest
    private func buildDigestContent(profile: UserProfile, stats: DatabaseService.Stats) async -> UNNotificationContent {
        let content = UNMutableNotificationContent()

        let streak = await DatabaseService.shared.loadStreak()
        let sessions = await DatabaseService.shared.loadSessions()
        let calendar = Calendar.current

        // This week's sessions
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekSessions = sessions.filter { $0.completedAt >= weekStart }
        let weekMinutes = weekSessions.reduce(0) { $0 + $1.duration } / 60
        let weekSessionsCount = weekSessions.count

        // Build message
        let name = profile.username.isEmpty ? "you" : profile.username
        let hoursStr = weekMinutes >= 60
            ? String(format: "%.0fh %dm", floor(Double(weekMinutes) / 60), weekMinutes % 60)
            : "\(weekMinutes)m"

        content.title = "Your Weekly Focus Report"

        if weekSessionsCount == 0 {
            content.body = "Hey \(name), you didn't focus this week. Start fresh next week!"
        } else if streak.currentStreak > 0 {
            content.body = "Hey \(name)! \(hoursStr) focused across \(weekSessionsCount) sessions. \(streak.currentStreak)-day streak 🔥"
        } else {
            content.body = "Hey \(name)! \(hoursStr) focused across \(weekSessionsCount) sessions this week. Keep it up!"
        }

        // Weekly goal progress
        let weeklyGoal = profile.dailyGoalMinutes * 5
        let progress = min(1.0, Double(weekMinutes) / Double(weeklyGoal))
        if progress >= 1.0 {
            content.subtitle = "🎉 Weekly goal crushed! \(Int(progress * 100))% complete"
        } else {
            content.subtitle = "\(Int(progress * 100))% of weekly goal (\(weeklyGoal)m)"
        }

        content.sound = .default
        content.categoryIdentifier = "WEEKLY_DIGEST"
        content.interruptionLevel = .timeSensitive

        return content
    }

    // MARK: - Notification Categories

    /// Register notification categories and actions
    func registerCategories() {
        let startSessionAction = UNNotificationAction(
            identifier: "START_SESSION",
            title: "Start Session",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )

        let weeklyDigestCategory = UNNotificationCategory(
            identifier: "WEEKLY_DIGEST",
            actions: [startSessionAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let sessionReminderCategory = UNNotificationCategory(
            identifier: "SESSION_REMINDER",
            actions: [startSessionAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let streakReminderCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [startSessionAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            weeklyDigestCategory,
            sessionReminderCategory,
            streakReminderCategory
        ])

        logger.info("Notification categories registered")
    }

    // MARK: - Pending Notifications

    /// Get all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Cancel all notifications
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("All notifications cancelled")
    }
}
