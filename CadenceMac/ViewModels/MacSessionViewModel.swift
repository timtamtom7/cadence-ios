import Foundation
import Combine
import SwiftUI

enum PauseState {
    case running
    case paused
}

@Observable
final class MacSessionViewModel {
    // MARK: - Published State

    var isRunning: Bool = false
    var isCompleted: Bool = false
    var pauseState: PauseState = .running
    var remainingSeconds: Int = 0
    var selectedDuration: Int = 25
    var currentStreak: Int = 0
    var totalHours: Double = 0.0
    var totalSessions: Int = 0
    var breathingScale: CGFloat = 1.0
    var breathingOpacity: Double = 1.0

    // MARK: - Private

    private var timer: Timer?
    private var breathingTimer: Timer?
    private var sessionStartTime: Date?
    private var sessionDuration: Int = 0

    var timeDisplay: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Session Control

    func startSession(duration: Int) {
        guard !isRunning else { return }

        sessionDuration = duration * 60
        remainingSeconds = sessionDuration
        isRunning = true
        isCompleted = false
        pauseState = .running
        sessionStartTime = Date()

        startTimer()
        startBreathingAnimation()
        saveSessionStart()
    }

    func stopSession() {
        timer?.invalidate()
        timer = nil
        breathingTimer?.invalidate()
        breathingTimer = nil
        isRunning = false
        pauseState = .running
        breathingScale = 1.0
        breathingOpacity = 1.0
        remainingSeconds = 0
    }

    func togglePause() {
        if pauseState == .running {
            pauseState = .paused
            timer?.invalidate()
            timer = nil
        } else {
            pauseState = .running
            startTimer()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard pauseState == .running else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if remainingSeconds <= 0 {
            completeSession()
        }
    }

    private func completeSession() {
        timer?.invalidate()
        timer = nil
        breathingTimer?.invalidate()
        breathingTimer = nil
        isRunning = false
        isCompleted = true
        saveSessionComplete()
        loadStats()
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        var growing = true
        var opacityValue: Double = 0.5

        breathingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, self.pauseState == .running else { return }

            if growing {
                self.breathingScale += 0.008
                opacityValue += 0.008
                if self.breathingScale >= 1.15 {
                    growing = false
                }
            } else {
                self.breathingScale -= 0.008
                opacityValue -= 0.008
                if self.breathingScale <= 0.85 {
                    growing = true
                }
            }

            self.breathingOpacity = min(max(opacityValue, 0.3), 1.0)
        }
    }

    // MARK: - Stats

    func loadStats() {
        currentStreak = UserDefaults.standard.integer(forKey: "cadence_streak")
        totalHours = UserDefaults.standard.double(forKey: "cadence_total_hours")
        totalSessions = UserDefaults.standard.integer(forKey: "cadence_total_sessions")

        if totalHours == 0 && totalSessions == 0 {
            totalHours = 12.5
            totalSessions = 8
            currentStreak = 3
        }
    }

    // MARK: - Persistence

    private func saveSessionStart() {
        let sessionData: [String: Any] = [
            "startTime": Date(),
            "duration": sessionDuration,
            "status": "started"
        ]
        UserDefaults.standard.set(sessionData, forKey: "cadence_last_session")
    }

    private func saveSessionComplete() {
        let completedDuration = sessionDuration / 60
        let focusScore = calculateFocusScore()

        totalSessions += 1
        totalHours += Double(completedDuration) / 60.0

        UserDefaults.standard.set(totalSessions, forKey: "cadence_total_sessions")
        UserDefaults.standard.set(totalHours, forKey: "cadence_total_hours")
        UserDefaults.standard.set(true, forKey: "cadence_session_completed_\(Date().timeIntervalSince1970)")
    }

    private func calculateFocusScore() -> Int {
        return Int.random(in: 75...100)
    }
}
