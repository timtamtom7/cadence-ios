import Foundation
import UserNotifications
import os.log

/// Service for managing local notifications on macOS
/// Handles focus session reminders, streak alerts, and weekly digests
/// with smart throttling to avoid notification fatigue
@MainActor
@Observable
final class MacNotificationService: NSObject {
    static let shared = MacNotificationService()

    private let logger = Logger(subsystem: "com.cadence.macos", category: "Notifications")
    private let notificationCenter = UNUserNotificationCenter.current()

    var isAuthorized: Bool = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Track last notification times to prevent spam
    private var lastSessionReminder: Date?
    private var lastStreakReminder: Date?
    private var sessionReminderCount: Int = 0
    private var lastResetDate: Date = Date()

    /// Minimum interval between session reminders (30 minutes)
    private let sessionReminderCooldown: TimeInterval = 30 * 60

    /// Minimum interval between streak reminders (24 hours)
    private let streakReminderCooldown: TimeInterval = 24 * 60 * 60

    private override init() {
        super.init()
        notificationCenter.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification authorization — call on first launch
    /// Returns true if authorization was granted
    func requestAuthorization() async -> Bool {
        // Reset daily counts if it's a new day
        resetDailyCountsIfNeeded()

        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await updateAuthorizationStatus()
            logger.info("Notification authorization: \(granted ? "granted" : "denied")")

            if granted {
                await registerCategories()
                await scheduleWeeklyDigestIfEnabled()
            }

            return granted
        } catch {
            logger.error("Notification authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status without requesting
    func checkAuthorizationStatus() async {
        await updateAuthorizationStatus()
    }

    private func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Session Reminders

    /// Schedule a focus session reminder
    /// Uses smart throttling to avoid too many notifications
    func scheduleSessionReminder(at date: Date, durationMinutes: Int) async {
        guard isAuthorized else {
            logger.warning("Not authorized, skipping session reminder")
            return
        }

        // Smart throttling: don't send if we've sent one recently
        if let lastReminder = lastSessionReminder,
           Date().timeIntervalSince(lastReminder) < sessionReminderCooldown {
            logger.info("Session reminder suppressed (cooldown active)")
            return
        }

        // Daily limit: max 5 session reminders per day
        if sessionReminderCount >= 5 {
            logger.info("Session reminder suppressed (daily limit reached)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Focus!"
        content.body = "Ready for another \(durationMinutes)-minute session?"
        content.sound = .default
        content.categoryIdentifier = "SESSION_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "cadence.sessionReminder.\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            lastSessionReminder = Date()
            sessionReminderCount += 1
            logger.info("Session reminder scheduled for \(date.formatted(), privacy: .public)")
        } catch {
            logger.error("Failed to schedule session reminder: \(error.localizedDescription)")
        }
    }

    /// Cancel all pending session reminders
    func cancelAllSessionReminders() {
        notificationCenter.getPendingNotificationRequests { requests in
            let reminderIds = requests
                .filter { $0.identifier.hasPrefix("cadence.sessionReminder.") }
                .map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: reminderIds)
        }
        logger.info("All session reminders cancelled")
    }

    // MARK: - Streak Reminders

    /// Schedule a streak reminder if user hasn't focused today
    /// Only schedules if no session has been completed yet today
    func scheduleStreakReminderIfNeeded(username: String) async {
        guard isAuthorized else {
            logger.warning("Not authorized, skipping streak reminder")
            return
        }

        // Reset daily counts if needed
        resetDailyCountsIfNeeded()

        // Check if we've already reminded today
        if let lastReminder = lastStreakReminder,
           Calendar.current.isDateInToday(lastReminder) {
            logger.info("Streak reminder already sent today")
            return
        }

        // Check if user already focused today
        let todayMinutes = await DatabaseService.shared.loadStats().todayMinutes
        guard todayMinutes == 0 else {
            logger.info("User already focused today, skipping streak reminder")
            return
        }

        // Cancel any existing streak reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["cadence.streakReminder"])

        // Schedule for 7pm local time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19
        components.minute = 0

        guard let reminderDate = calendar.date(from: components) else { return }

        // If 7pm has passed, skip for today
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        let displayName = username.isEmpty ? "there" : username
        content.body = "You haven't focused today. Spend just 25 minutes to keep your \(displayName)'s streak alive."
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
            try await notificationCenter.add(request)
            lastStreakReminder = Date()
            logger.info("Streak reminder scheduled for \(reminderDate.formatted(), privacy: .public)")
        } catch {
            logger.error("Failed to schedule streak reminder: \(error.localizedDescription)")
        }
    }

    /// Cancel pending streak reminder
    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["cadence.streakReminder"])
    }

    // MARK: - Weekly Digest

    /// Schedule weekly digest based on user profile
    func scheduleWeeklyDigest(weekday: Int = 1, // Sunday
                              hour: Int = 10) async {
        guard isAuthorized else { return }

        // Remove existing
        await cancelWeeklyDigest()

        let nextDigestDate = calculateNextDigestDate(weekday: weekday, hour: hour)

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Focus Report"

        let stats = await DatabaseService.shared.loadStats()
        let streak = await DatabaseService.shared.loadStreak()
        let sessions = await DatabaseService.shared.loadSessions()

        // Calculate this week's stats
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekSessions = sessions.filter { $0.completedAt >= weekStart }
        let weekMinutes = weekSessions.reduce(0) { $0 + $1.duration } / 60
        let weekSessionsCount = weekSessions.count

        let hoursStr = weekMinutes >= 60
            ? String(format: "%.0fh %dm", floor(Double(weekMinutes) / 60), weekMinutes % 60)
            : "\(weekMinutes)m"

        if weekSessionsCount == 0 {
            content.body = "You didn't focus this week. Start fresh next week!"
        } else if streak.currentStreak > 0 {
            content.body = "\(hoursStr) focused across \(weekSessionsCount) sessions. \(streak.currentStreak)-day streak 🔥"
        } else {
            content.body = "\(hoursStr) focused across \(weekSessionsCount) sessions this week. Keep it up!"
        }

        content.sound = .default
        content.categoryIdentifier = "WEEKLY_DIGEST"

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

        do {
            try await notificationCenter.add(request)
            logger.info("Weekly digest scheduled for \(nextDigestDate.formatted(), privacy: .public)")
        } catch {
            logger.error("Failed to schedule weekly digest: \(error.localizedDescription)")
        }
    }

    /// Cancel weekly digest notification
    func cancelWeeklyDigest() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["cadence.weeklyDigest"])
    }

    // MARK: - Categories

    /// Register notification categories and actions
    func registerCategories() async {
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

        notificationCenter.setNotificationCategories([
            weeklyDigestCategory,
            sessionReminderCategory,
            streakReminderCategory
        ])

        logger.info("Notification categories registered")
    }

    // MARK: - Helpers

    /// Calculate next occurrence of weekday at given hour
    private func calculateNextDigestDate(weekday: Int, hour: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        components.hour = hour
        components.minute = 0
        components.second = 0

        let currentWeekday = calendar.component(.weekday, from: now)
        var daysUntilTarget = weekday - currentWeekday
        if daysUntilTarget < 0 { daysUntilTarget += 7 }
        if daysUntilTarget == 0 {
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

    /// Reset daily counters if it's a new day
    private func resetDailyCountsIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            sessionReminderCount = 0
            lastSessionReminder = nil
            lastStreakReminder = nil
            lastResetDate = Date()
        }
    }

    /// Schedule weekly digest if user has it enabled in profile
    private func scheduleWeeklyDigestIfEnabled() async {
        let profile = await DatabaseService.shared.loadUserProfile()
        // Weekly digest could be an opt-in setting in the future
        // For now, schedule it (user can disable via settings)
        await scheduleWeeklyDigest()
    }

    // MARK: - Debug

    /// Get all pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    /// Cancel all notifications
    func cancelAll() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("All notifications cancelled")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension MacNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            switch actionIdentifier {
            case "START_SESSION":
                logger.info("User tapped 'Start Session' from notification")
                // Post notification to start a session
                NotificationCenter.default.post(name: .startFocusSession, object: nil)
            case "DISMISS":
                logger.info("User dismissed notification")
            default:
                break
            }
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let startFocusSession = Notification.Name("com.cadence.startFocusSession")
}
