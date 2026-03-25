import Foundation

@MainActor
@Observable
class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = LeaderboardEntry.mockLeaderboard
    var isLoading: Bool = false

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
        // R1: Static mock data, no network
        try? await Task.sleep(nanoseconds: 500_000_000)
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
