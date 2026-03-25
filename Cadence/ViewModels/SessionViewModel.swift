import Foundation

@MainActor
@Observable
class SessionViewModel {
    // MARK: - State

    var selectedDuration: Int = 25
    var todayMinutes: Int = 0
    var weeklyMinutes: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var achievements: [Achievement] = []
    var selectedSounds: Set<String> = []
    var selectedPartner: Partner?
    var showSessionComplete: Bool = false
    var showCancelConfirmation: Bool = false
    var partnerRadar: [Partner] = Partner.mockPartners

    // MARK: - Presets

    let durationPresets = [15, 25, 45, 60]

    // MARK: - Focus Service

    let focusService = FocusService()

    // MARK: - Initialization

    init() {
        Task {
            await loadData()
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        let profile = await DatabaseService.shared.loadUserProfile()
        let streak = await DatabaseService.shared.loadStreak()
        achievements = await DatabaseService.shared.loadAchievements()

        todayMinutes = await DatabaseService.shared.todayMinutes()
        weeklyMinutes = await DatabaseService.shared.weeklyMinutes()
        currentStreak = streak.currentStreak
        longestStreak = streak.longestStreak
    }

    // MARK: - Session Control

    func startSession() {
        let soundIds = Array(selectedSounds)
        let partnerId = selectedPartner?.id
        focusService.start(durationMinutes: selectedDuration, soundIds: soundIds, partnerId: partnerId)
    }

    func pauseSession() {
        focusService.pause()
    }

    func resumeSession() {
        focusService.resume()
    }

    func cancelSession() {
        showCancelConfirmation = false
        focusService.stop()
    }

    func completeSession() {
        showSessionComplete = true
        Task {
            await loadData()
        }
    }

    // MARK: - Sound Selection

    func toggleSound(_ soundId: String) {
        if selectedSounds.contains(soundId) {
            selectedSounds.remove(soundId)
        } else {
            selectedSounds.insert(soundId)
        }
    }

    // MARK: - Partner Selection

    func selectPartner(_ partner: Partner?) {
        selectedPartner = partner
    }

    // MARK: - Achievements

    var earnedAchievements: [Achievement] {
        achievements.filter { $0.isEarned }
    }

    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isEarned }
    }

    // MARK: - Helpers

    var dailyGoalMinutes: Int {
        120
    }

    var dailyProgress: Double {
        min(1.0, Double(todayMinutes) / Double(dailyGoalMinutes))
    }

    var streakText: String {
        if currentStreak == 0 {
            return "Start your streak!"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }
}
