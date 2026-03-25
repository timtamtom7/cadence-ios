import Foundation

@MainActor
@Observable
class TeamService {
    static let shared = TeamService()

    var currentTeam: Team?
    var activeTeamSession: TeamSession?
    var availableTeams: [Team] = []
    var isLoading: Bool = false

    init() {
        loadMockData()
    }

    func loadMockData() {
        currentTeam = Team.mockTeam
        availableTeams = [
            Team.mockTeam,
            Team(name: "Night Owls", members: [], totalFocusMinutes: 890, teamCode: "OWLS99"),
            Team(name: "Morning Crew", members: [], totalFocusMinutes: 1200, teamCode: "AMCREW"),
        ]
    }

    func createTeam(name: String) async -> Team {
        isLoading = true
        let team = Team(name: name, members: [
            TeamMember(name: "You", role: .admin, weeklyMinutes: 0, streak: 0, isActive: true)
        ])
        try? await Task.sleep(nanoseconds: 500_000_000)
        currentTeam = team
        isLoading = false
        return team
    }

    func joinTeam(code: String) async -> Bool {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        // Find team by code
        if let team = availableTeams.first(where: { $0.teamCode == code }) {
            currentTeam = team
            isLoading = false
            return true
        }
        isLoading = false
        return false
    }

    func leaveTeam() {
        currentTeam = nil
        activeTeamSession = nil
    }

    func startTeamSession(durationMinutes: Int, ambientSound: String) {
        guard let team = currentTeam else { return }
        activeTeamSession = TeamSession(
            teamId: team.id,
            durationMinutes: durationMinutes,
            participantIds: team.members.filter { $0.isActive }.map { $0.id },
            ambientSound: ambientSound,
            status: .active
        )
    }

    func endTeamSession() {
        guard var session = activeTeamSession else { return }
        session.status = .completed
        activeTeamSession = nil

        // Update team stats
        if var team = currentTeam {
            team.totalFocusMinutes += session.durationMinutes
            currentTeam = team
        }
    }
}
