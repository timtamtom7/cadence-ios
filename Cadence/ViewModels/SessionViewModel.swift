import Foundation

enum FocusMode: String, CaseIterable, Identifiable {
    case deepWork = "Deep Work"
    case creative = "Creative"
    case study = "Study"
    case custom = "Custom"

    var id: String { rawValue }

    var defaultDuration: Int {
        switch self {
        case .deepWork: return 50
        case .creative: return 25
        case .study: return 90
        case .custom: return 25
        }
    }

    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .creative: return "paintbrush.fill"
        case .study: return "book.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var description: String {
        switch self {
        case .deepWork: return "50 min — intense focus"
        case .creative: return "25 min — creative flow"
        case .study: return "90 min — marathon session"
        case .custom: return "Set your own duration"
        }
    }

    var defaultSound: String {
        switch self {
        case .deepWork: return "whitenoise"
        case .creative: return "cafe"
        case .study: return "rain"
        case .custom: return "rain"
        }
    }
}

@MainActor
@Observable
class SessionViewModel {
    // MARK: - State

    var selectedDuration: Int = 25
    var todayMinutes: Int = 0
    var weeklyMinutes: Int = 0
    var totalHours: Double = 0
    var totalSessions: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var achievements: [Achievement] = []
    var selectedSounds: Set<String> = []
    var selectedPartner: Partner?
    var showSessionComplete: Bool = false
    var showCancelConfirmation: Bool = false
    var partnerRadar: [Partner] = Partner.mockPartners
    var selectedFocusMode: FocusMode = .custom

    // MARK: - Matching

    var matchingService = MatchingService()
    var showPartnerDisconnected: Bool = false

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

        let stats = await DatabaseService.shared.loadStats()
        todayMinutes = stats.todayMinutes
        weeklyMinutes = stats.weeklyMinutes
        totalHours = stats.totalHours
        totalSessions = stats.totalSessions
        currentStreak = streak.currentStreak
        longestStreak = streak.longestStreak
    }

    // MARK: - Session Control

    func startSession() {
        let soundIds = Array(selectedSounds)
        let partnerId = selectedPartner?.id
        focusService.start(durationMinutes: selectedDuration, soundIds: soundIds, partnerId: partnerId)
    }

    func startMatchingSession() async {
        matchingService.stopSearching()
        matchingService.isSearching = true
        showPartnerDisconnected = false

        await matchingService.startSearching(
            focusMode: selectedFocusMode.rawValue,
            durationMinutes: selectedDuration
        )

        if let match = matchingService.currentMatch {
            // Partner found
            focusService.start(
                durationMinutes: selectedDuration,
                soundIds: Array(selectedSounds),
                partnerId: match.partnerId
            )
            matchingService.confirmMatch()
        } else {
            // No partner — solo mode
            focusService.start(
                durationMinutes: selectedDuration,
                soundIds: Array(selectedSounds),
                partnerId: nil
            )
        }
    }

    func pauseSession() {
        focusService.pause()
    }

    func resumeSession() {
        focusService.resume()
    }

    func cancelSession() {
        showCancelConfirmation = false
        matchingService.stopSearching()
        focusService.stop()
    }

    func completeSession() {
        showSessionComplete = true
        matchingService.clearMatch()
        Task {
            await loadData()
        }
    }

    // MARK: - Sound Selection

    func toggleSound(_ soundId: String) {
        if selectedSounds.contains(soundId) {
            selectedSounds.remove(soundId)
        } else {
            if selectedSounds.count < 3 {
                selectedSounds.insert(soundId)
            }
        }
    }

    // MARK: - Focus Mode

    func selectFocusMode(_ mode: FocusMode) {
        selectedFocusMode = mode
        if mode != .custom {
            selectedDuration = mode.defaultDuration
            // Auto-select default sound for this mode
            if !selectedSounds.isEmpty {
                selectedSounds.removeAll()
            }
            selectedSounds.insert(mode.defaultSound)
        }
    }

    // MARK: - Partner Selection

    func selectPartner(_ partner: Partner?) {
        selectedPartner = partner
    }

    func handlePartnerDisconnected() {
        matchingService.disconnectPartner()
        showPartnerDisconnected = true
    }

    func reMatchOrContinueSolo(rematch: Bool) {
        showPartnerDisconnected = false
        matchingService.clearMatch()
        if !rematch {
            // Continue solo — session already running
        } else {
            Task {
                await startMatchingSession()
            }
        }
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
