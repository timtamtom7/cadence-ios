import Foundation

@MainActor
@Observable
class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = LeaderboardEntry.mockLeaderboard
    var isLoading: Bool = false
    var currentStreak: Int = 0

    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }

    var currentUserEntry: LeaderboardEntry? {
        entries.first { $0.isCurrentUser }
    }

    var currentUserRank: Int {
        currentUserEntry?.rank ?? 0
    }

    func refresh() async {
        isLoading = true
        // Load real stats
        let streak = await DatabaseService.shared.loadStreak()
        currentStreak = streak.currentStreak

        let stats = await DatabaseService.shared.loadStats()

        // Update current user entry with real stats
        if let idx = entries.firstIndex(where: { $0.isCurrentUser }) {
            let updatedEntry = LeaderboardEntry(
                id: entries[idx].id,
                rank: entries[idx].rank,
                name: entries[idx].name,
                weeklyMinutes: stats.weeklyMinutes,
                streak: streak.currentStreak,
                totalHours: stats.totalHours,
                totalSessions: stats.totalSessions,
                isCurrentUser: true
            )
            entries[idx] = updatedEntry
            entries.sort { $0.rank < $1.rank }
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        isLoading = false
    }

    func rankIcon(for rank: Int) -> String {
        switch rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    func rankColor(for rank: Int) -> String {
        switch rank {
        case 1: return "FFD700" // Gold
        case 2: return "C0C0C0" // Silver
        case 3: return "CD7F32" // Bronze
        default: return "7AAEAA"
        }
    }
}
