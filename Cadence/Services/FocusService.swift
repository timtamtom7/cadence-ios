import Foundation
import AVFoundation
#if os(macOS)
import AppKit
#else
import UIKit
import AudioToolbox
#endif

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
    private var sessionStartDate: Date?
    private var pausedAtDate: Date?
    private var accumulatedPauseTime: TimeInterval = 0

    // MARK: - Session Data

    private(set) var lastCompletedSession: Session?
    private(set) var sessionStartTime: Date?

    // MARK: - Sound

    private var audioPlayer: AVAudioPlayer?

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
        sessionStartDate = Date()
        accumulatedPauseTime = 0

        timer = Task { [weak self] in
            await self?.runTimer()
        }
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pausedAtDate = Date()
        timer?.cancel()
        timer = nil
    }

    func resume() {
        guard isRunning, isPaused, let pausedAt = pausedAtDate else { return }
        accumulatedPauseTime += Date().timeIntervalSince(pausedAt)
        pausedAtDate = nil
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
        sessionStartDate = nil
        pausedAtDate = nil
        accumulatedPauseTime = 0
    }

    // MARK: - Private

    private func runTimer() async {
        while true {
            // Use Date-based calculation for drift-free timing
            guard let startDate = sessionStartDate else { return }

            let elapsed = Date().timeIntervalSince(startDate) - accumulatedPauseTime
            let newRemaining = max(0, totalSeconds - Int(elapsed))

            if newRemaining != remainingSeconds {
                remainingSeconds = newRemaining
            }

            if remainingSeconds <= 0 {
                await completeSession()
                return
            }

            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s tick for smoother updates
            } catch {
                // Cancelled
                return
            }

            if Task.isCancelled { return }
        }
    }

    private func completeSession() async {
        isRunning = false
        isCompleted = true

        // Play timer bell with fallback
        playTimerBell()

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

    private func playTimerBell() {
        // Try to play bundled bell sound with graceful fallback
        if let bellURL = Bundle.main.url(forResource: "bell", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bellURL)
                audioPlayer?.volume = 0.7
                audioPlayer?.play()
            } catch {
                // Fallback to system sound
                playSystemBell()
            }
        } else {
            // No bell file bundled — use system sound
            playSystemBell()
        }

        // Haptic feedback
        #if !os(macOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func playSystemBell() {
        #if os(macOS)
        NSSound.beep()
        #else
        AudioServicesPlaySystemSound(1007)
        #endif
    }

    private func calculateFocusScore() -> Int {
        // Base score improved by uninterrupted time, penalized for pauses
        let baseScore = 70
        let pausePenalty = isPaused ? 15 : 0
        // Bonus for longer sessions
        let durationBonus = min(15, (totalSeconds / 60) / 5)
        return min(100, baseScore + durationBonus - pausePenalty + Int.random(in: 0...10))
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

        // Social Butterfly — count unique partners
        if let idx = achievements.firstIndex(where: { $0.id == "social_butterfly" && !$0.isEarned }) {
            let sessions = await DatabaseService.shared.loadSessions()
            let uniquePartners = Set(sessions.compactMap { $0.partnerId })
            if uniquePartners.count >= 5 {
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
