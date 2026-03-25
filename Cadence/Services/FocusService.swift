import Foundation
import Combine

@MainActor
@Observable
class FocusService {
    // MARK: - Published State

    var remainingSeconds: Int = 0
    var totalSeconds: Int = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isCompleted: Bool = false
    var activeSoundIds: [String] = []
    var selectedPartnerId: UUID?

    // MARK: - Private

    private var timer: Task<Void, Never>?
    private var backgroundDate: Date?

    // MARK: - Session Data

    private(set) var lastCompletedSession: Session?
    private(set) var sessionStartTime: Date?

    // MARK: - Timer Control

    func start(durationMinutes: Int, soundIds: [String] = [], partnerId: UUID? = nil) {
        stop()

        totalSeconds = durationMinutes * 60
        remainingSeconds = totalSeconds
        isRunning = true
        isPaused = false
        isCompleted = false
        activeSoundIds = soundIds
        selectedPartnerId = partnerId
        sessionStartTime = Date()

        timer = Task { [weak self] in
            await self?.runTimer()
        }
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timer?.cancel()
        timer = nil
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        timer = Task { [weak self] in
            await self?.runTimer()
        }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
        isCompleted = false
        sessionStartTime = nil
    }

    // MARK: - Private

    private func runTimer() async {
        while remainingSeconds > 0 {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                // Cancelled
                return
            }
            if Task.isCancelled { return }
            remainingSeconds -= 1
        }
        await completeSession()
    }

    private func completeSession() async {
        isRunning = false
        isCompleted = true

        let duration = totalSeconds
        let focusScore = calculateFocusScore()

        let session = Session(
            duration: duration,
            completedAt: Date(),
            soundIds: activeSoundIds,
            partnerId: selectedPartnerId,
            focusScore: focusScore
        )

        lastCompletedSession = session

        // Persist
        await DatabaseService.shared.saveSession(session)
        await DatabaseService.shared.recordSessionForStreak()

        // Check achievements
        await checkAchievements(for: session)
    }

    private func calculateFocusScore() -> Int {
        // Simple algorithm: base score + bonus for uninterrupted time
        // In R1, this is a placeholder
        let baseScore = 70
        let pausePenalty = isPaused ? 10 : 0
        return min(100, baseScore + Int.random(in: 0...20) - pausePenalty)
    }

    private func checkAchievements(for session: Session) async {
        var achievements = await DatabaseService.shared.loadAchievements()
        var updated = false

        // First Focus
        if let idx = achievements.firstIndex(where: { $0.id == "first_focus" && !$0.isEarned }) {
            achievements[idx].isEarned = true
            achievements[idx].earnedAt = Date()
            updated = true
        }

        // Marathoner (60 min)
        if let idx = achievements.firstIndex(where: { $0.id == "marathoner" && !$0.isEarned }) {
            if session.durationMinutes >= 60 {
                achievements[idx].isEarned = true
                achievements[idx].earnedAt = Date()
                updated = true
            }
        }

        // Night Owl (after 10pm)
        if let idx = achievements.firstIndex(where: { $0.id == "night_owl" && !$0.isEarned }) {
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 22 || hour < 4 {
                achievements[idx].isEarned = true
                achievements[idx].earnedAt = Date()
                updated = true
            }
        }

        // Week Warrior
        let streak = await DatabaseService.shared.loadStreak()
        if let idx = achievements.firstIndex(where: { $0.id == "week_warrior" && !$0.isEarned }) {
            if streak.currentStreak >= 7 {
                achievements[idx].isEarned = true
                achievements[idx].earnedAt = Date()
                updated = true
            }
        }

        if updated {
            await DatabaseService.shared.saveAchievements(achievements)
        }
    }

    // MARK: - Helpers

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedDuration: String {
        let minutes = totalSeconds / 60
        return "\(minutes) min"
    }
}
