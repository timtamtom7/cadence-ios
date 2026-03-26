import Foundation

// R12: Social Features — Focus Challenges, Leaderboards, Community, Focus Content
@MainActor
final class CadenceR12Service: ObservableObject {
    static let shared = CadenceR12Service()

    @Published var challenges: [FocusChallenge] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var focusTips: [FocusTip] = []
    @Published var accountabilityMatches: [AccountabilityMatch] = []
    @Published var isAnonymousMode = false

    private let storageKey = "cadenceSocialData"

    private init() {
        loadData()
    }

    // MARK: - Focus Challenges

    struct FocusChallenge: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var description: String
        var type: ChallengeType
        var durationDays: Int
        var targetMinutes: Int
        var participantIds: [String]
        var startDate: Date
        var status: ChallengeStatus
        var milestones: [Milestone]

        enum ChallengeType: String, Codable, CaseIterable {
            case monthly = "Monthly"
            case friend = "Friend"
            case team = "Team"
            case streak = "Streak"
        }

        enum ChallengeStatus: String, Codable {
            case upcoming, active, completed, failed
        }

        struct Milestone: Identifiable, Codable, Equatable {
            let id: UUID
            var minutes: Int
            var achievedAt: Date?
            var isAchieved: Bool

            init(id: UUID = UUID(), minutes: Int, achievedAt: Date? = nil, isAchieved: Bool = false) {
                self.id = id
                self.minutes = minutes
                self.achievedAt = achievedAt
                self.isAchieved = isAchieved
            }
        }

        init(
            id: UUID = UUID(),
            name: String,
            description: String = "",
            type: ChallengeType,
            durationDays: Int = 30,
            targetMinutes: Int,
            participantIds: [String] = ["local"],
            startDate: Date = Date(),
            status: ChallengeStatus = .active,
            milestones: [Milestone] = []
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.type = type
            self.durationDays = durationDays
            self.targetMinutes = targetMinutes
            self.participantIds = participantIds
            self.startDate = startDate
            self.status = status
            self.milestones = milestones
        }

        var endDate: Date {
            Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        }

        var daysRemaining: Int {
            let components = Calendar.current.dateComponents([.day], from: Date(), to: endDate)
            return max(0, components.day ?? 0)
        }

        var daysElapsed: Int {
            let components = Calendar.current.dateComponents([.day], from: startDate, to: Date())
            return max(0, components.day ?? 0)
        }

        var progress: Double {
            guard durationDays > 0 else { return 0 }
            return min(1.0, Double(daysElapsed) / Double(durationDays))
        }
    }

    func createChallenge(name: String, description: String, type: FocusChallenge.ChallengeType, durationDays: Int, targetMinutes: Int) -> FocusChallenge {
        // Create milestones at 25%, 50%, 75%, 100%
        let milestones = [
            FocusChallenge.Milestone(minutes: targetMinutes / 4),
            FocusChallenge.Milestone(minutes: targetMinutes / 2),
            FocusChallenge.Milestone(minutes: (targetMinutes * 3) / 4),
            FocusChallenge.Milestone(minutes: targetMinutes)
        ]
        let challenge = FocusChallenge(name: name, description: description, type: type, durationDays: durationDays, targetMinutes: targetMinutes, milestones: milestones)
        challenges.insert(challenge, at: 0)
        saveData()
        return challenge
    }

    func updateChallengeProgress(_ challengeId: UUID, minutesCompleted: Int) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeId }) else { return }
        for i in 0..<challenges[index].milestones.count {
            if minutesCompleted >= challenges[index].milestones[i].minutes && !challenges[index].milestones[i].isAchieved {
                challenges[index].milestones[i].isAchieved = true
                challenges[index].milestones[i].achievedAt = Date()
            }
        }
        saveData()
    }

    func deleteChallenge(_ challengeId: UUID) {
        challenges.removeAll { $0.id == challengeId }
        saveData()
    }

    // MARK: - Leaderboard

    struct LeaderboardEntry: Identifiable, Codable, Equatable {
        let id: UUID
        var userId: String
        var displayName: String
        var isAnonymous: Bool
        var focusMinutes: Int
        var streak: Int
        var rank: Int

        init(
            id: UUID = UUID(),
            userId: String,
            displayName: String,
            isAnonymous: Bool = false,
            focusMinutes: Int,
            streak: Int = 0,
            rank: Int = 0
        ) {
            self.id = id
            self.userId = userId
            self.displayName = isAnonymous ? "Focuser #\(userId.prefix(4))" : displayName
            self.isAnonymous = isAnonymous
            self.focusMinutes = focusMinutes
            self.streak = streak
            self.rank = rank
        }
    }

    func loadLeaderboard() {
        // Demo leaderboard data
        leaderboard = [
            LeaderboardEntry(userId: "u1", displayName: "Sarah K", focusMinutes: 1840, streak: 14, rank: 1),
            LeaderboardEntry(userId: "u2", displayName: "Mike R", focusMinutes: 1620, streak: 7, rank: 2),
            LeaderboardEntry(userId: "u3", displayName: "Alex T", focusMinutes: 1480, streak: 21, rank: 3),
            LeaderboardEntry(userId: "local", displayName: "You", focusMinutes: 950, streak: 5, rank: 4),
            LeaderboardEntry(userId: "u5", displayName: "Jordan L", focusMinutes: 720, streak: 3, rank: 5)
        ].sorted { $0.focusMinutes > $1.focusMinutes }
        .enumerated()
        .map { index, entry in
            var e = entry
            e.rank = index + 1
            return e
        }
    }

    // MARK: - Focus Tips

    struct FocusTip: Identifiable, Codable, Equatable {
        let id: UUID
        var title: String
        var content: String
        var category: TipCategory
        var authorName: String
        var isExpert: Bool
        var upvotes: Int
        var createdAt: Date

        enum TipCategory: String, Codable, CaseIterable {
            case technique = "Technique"
            case environment = "Environment"
            case mindset = "Mindset"
            case productivity = "Productivity"
            case recovery = "Recovery"
        }

        init(
            id: UUID = UUID(),
            title: String,
            content: String,
            category: TipCategory,
            authorName: String = "Community",
            isExpert: Bool = false,
            upvotes: Int = 0,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.content = content
            self.category = category
            self.authorName = authorName
            self.isExpert = isExpert
            self.upvotes = upvotes
            self.createdAt = createdAt
        }
    }

    func addTip(title: String, content: String, category: FocusTip.TipCategory) -> FocusTip {
        let tip = FocusTip(title: title, content: content, category: category)
        focusTips.insert(tip, at: 0)
        saveData()
        return tip
    }

    func upvoteTip(_ tipId: UUID) {
        guard let index = focusTips.firstIndex(where: { $0.id == tipId }) else { return }
        focusTips[index].upvotes += 1
        saveData()
    }

    // MARK: - Accountability Matching

    struct AccountabilityMatch: Identifiable, Codable, Equatable {
        let id: UUID
        var matchedUserId: String
        var matchedUserName: String
        var matchedAt: Date
        var status: MatchStatus

        enum MatchStatus: String, Codable {
            case pending, connected, ended
        }

        init(
            id: UUID = UUID(),
            matchedUserId: String,
            matchedUserName: String,
            matchedAt: Date = Date(),
            status: MatchStatus = .pending
        ) {
            self.id = id
            self.matchedUserId = matchedUserId
            self.matchedUserName = matchedUserName
            self.matchedAt = matchedAt
            self.status = status
        }
    }

    func requestMatch(goalMinutes: Int) -> AccountabilityMatch {
        // Demo match
        let match = AccountabilityMatch(matchedUserId: "match1", matchedUserName: "Taylor S")
        accountabilityMatches.append(match)
        saveData()
        return match
    }

    // MARK: - Persistence

    private struct SocialData: Codable {
        var challenges: [FocusChallenge]
        var focusTips: [FocusTip]
        var accountabilityMatches: [AccountabilityMatch]
        var isAnonymousMode: Bool
    }

    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let socialData = try? JSONDecoder().decode(SocialData.self, from: data) else {
            return
        }
        challenges = socialData.challenges
        focusTips = socialData.focusTips
        accountabilityMatches = socialData.accountabilityMatches
        isAnonymousMode = socialData.isAnonymousMode
    }

    private func saveData() {
        let socialData = SocialData(
            challenges: challenges,
            focusTips: focusTips,
            accountabilityMatches: accountabilityMatches,
            isAnonymousMode: isAnonymousMode
        )
        if let data = try? JSONEncoder().encode(socialData) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Demo Data

    func loadDemoData() {
        guard challenges.isEmpty && leaderboard.isEmpty && focusTips.isEmpty else { return }

        // Demo challenges
        let monthlyChallenge = FocusChallenge(
            name: "30-Day Focus Marathon",
            description: "Complete 30 hours of deep focus this month",
            type: .monthly,
            durationDays: 30,
            targetMinutes: 1800
        )
        let friendChallenge = FocusChallenge(
            name: "Friend Focus Duel",
            description: "Out-focus your friends this week",
            type: .friend,
            durationDays: 7,
            targetMinutes: 300
        )
        challenges = [monthlyChallenge, friendChallenge]

        // Demo leaderboard
        loadLeaderboard()

        // Demo tips
        let tips = [
            FocusTip(title: "The 90-Minute Rule", content: "Work in 90-minute focused blocks aligned with your ultradian rhythm. Take a 15-20 minute break between blocks.", category: .technique, isExpert: true, upvotes: 234),
            FocusTip(title: "Create a Focus Shrine", content: "Dedicate one physical space purely for deep work. Train your brain to enter focus mode when you enter that space.", category: .environment, upvotes: 189),
            FocusTip(title: "Embrace Boredom", content: "The ability to be bored is the ability to focus. Stop filling every gap with your phone.", category: .mindset, authorName: "Cal Newport", isExpert: true, upvotes: 412)
        ]
        focusTips = tips

        saveData()
    }
}
