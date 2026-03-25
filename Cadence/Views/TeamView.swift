import SwiftUI

struct TeamView: View {
    @State private var teamService = TeamService.shared
    @State private var showCreateTeam = false
    @State private var showJoinTeam = false
    @State private var newTeamName = ""
    @State private var joinTeamCode = ""
    @State private var showTeamSession = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let team = teamService.currentTeam {
                teamContent(team)
            } else {
                noTeamView
            }
        }
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamSheet(
                teamName: $newTeamName,
                onCreate: {
                    Task {
                        let team = await teamService.createTeam(name: newTeamName)
                        newTeamName = ""
                        showCreateTeam = false
                    }
                }
            )
        }
        .sheet(isPresented: $showJoinTeam) {
            JoinTeamSheet(
                teamCode: $joinTeamCode,
                onJoin: {
                    Task {
                        let success = await teamService.joinTeam(code: joinTeamCode)
                        if success {
                            joinTeamCode = ""
                            showJoinTeam = false
                        }
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showTeamSession) {
            if let session = teamService.activeTeamSession {
                TeamSessionRoomView(session: session)
            }
        }
    }

    // MARK: - No Team View

    private var noTeamView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appPrimary)
            }

            Text("Join a Focus Team")
                .font(.appDisplay)
                .foregroundStyle(Color.appTextPrimary)

            Text("Focus together with your team. Track collective focus time and motivate each other.")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    showJoinTeam = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Join with Code")
                    }
                    .font(.appHeading2)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    showCreateTeam = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create Team")
                    }
                    .font(.appHeading2)
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Team Content

    private func teamContent(_ team: Team) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Team header
                teamHeader(team)

                // Team stats
                teamStatsSection(team)

                // Members
                membersSection(team)

                // Team session
                teamSessionSection(team)

                // Leave team
                leaveTeamButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 120)
        }
    }

    private func teamHeader(_ team: Team) -> some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.appPrimary)
            }

            Text(team.name)
                .font(.appHeading1)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "link")
                    .font(.caption)
                Text(team.teamCode)
                    .font(.appMono)
            }
            .foregroundStyle(Color.appTextSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.appSurface)
            .clipShape(Capsule())
        }
    }

    private func teamStatsSection(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Team Progress")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            // Weekly goal progress
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Weekly Goal")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Text("\(team.totalFocusMinutes)m / \(team.weeklyGoalMinutes)m")
                        .font(.appCaption)
                        .foregroundStyle(Color.appPrimary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appSurface)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appPrimary)
                            .frame(width: geometry.size.width * team.weeklyProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Stats grid
            HStack(spacing: Spacing.sm) {
                teamStatCard(value: "\(team.memberCount)", label: "Members", icon: "person.2.fill")
                teamStatCard(value: String(format: "%.1fh", team.totalHours), label: "Total Focus", icon: "hourglass.fill")
                teamStatCard(value: "\(team.totalFocusMinutes / max(1, team.memberCount))m", label: "Avg/Member", icon: "chart.bar.fill")
            }
        }
    }

    private func teamStatCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func membersSection(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Members")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            ForEach(team.members) { member in
                TeamMemberRow(member: member)
            }
        }
    }

    private func teamSessionSection(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Team Session")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            VStack(spacing: Spacing.md) {
                Image(systemName: "person.3.wave.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appPrimary)

                Text("Start a team focus session")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Everyone in the team joins the same virtual focus room")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    teamService.startTeamSession(durationMinutes: 25, ambientSound: "rain")
                    showTeamSession = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Team Session")
                    }
                    .font(.appHeading2)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(Spacing.lg)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var leaveTeamButton: some View {
        Button {
            teamService.leaveTeam()
        } label: {
            Text("Leave Team")
                .font(.appCaption)
                .foregroundStyle(Color.appError)
        }
        .padding(.top, Spacing.md)
    }
}

// MARK: - Team Member Row

struct TeamMemberRow: View {
    let member: TeamMember

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(member.isActive ? Color.appPrimary.opacity(0.2) : Color.appSurface)
                    .frame(width: 44, height: 44)
                Text(member.name.prefix(1))
                    .font(.appHeading2)
                    .foregroundStyle(member.isActive ? Color.appPrimary : Color.appTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.name)
                        .font(.appBody)
                        .foregroundStyle(Color.appTextPrimary)
                    if member.role == .admin {
                        Text("Admin")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: Spacing.sm) {
                    if member.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(member.streak) day")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Color.appWarning)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.weeklyMinutes)m")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)
                Text("this week")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Create Team Sheet

struct CreateTeamSheet: View {
    @Binding var teamName: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Create Team")
                .font(.appHeading1)
                .foregroundStyle(Color.appTextPrimary)

            TextField("Team name", text: $teamName)
                .textFieldStyle(.plain)
                .font(.appBody)
                .padding(Spacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                onCreate()
            } label: {
                Text("Create")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(teamName.isEmpty ? Color.appTextTertiary : Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(teamName.isEmpty)

            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color.appBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Join Team Sheet

struct JoinTeamSheet: View {
    @Binding var teamCode: String
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Join Team")
                .font(.appHeading1)
                .foregroundStyle(Color.appTextPrimary)

            TextField("Enter team code", text: $teamCode)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(Spacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                onJoin()
            } label: {
                Text("Join")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(teamCode.isEmpty ? Color.appTextTertiary : Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(teamCode.isEmpty)

            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color.appBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Team Session Room View

struct TeamSessionRoomView: View {
    let session: TeamSession
    @State private var teamService = TeamService.shared
    @State private var remainingSeconds: Int
    @Environment(\.dismiss) private var dismiss

    init(session: TeamSession) {
        self.session = session
        _remainingSeconds = State(initialValue: session.durationMinutes * 60)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Header
                HStack {
                    Button {
                        teamService.endTeamSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    Spacer()
                    Text("Team Session")
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.clear)
                }
                .padding(.horizontal, Spacing.md)

                Spacer()

                // Team orb visualization
                teamOrbView

                // Timer
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.appTextPrimary)

                // Participants
                participantsView

                Spacer()

                // Sound indicator
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "waveform")
                    Text("Shared ambient: \(session.ambientSound.capitalized)")
                }
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

                Text("End Session")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        teamService.endTeamSession()
                        dismiss()
                    }
            }
            .padding(Spacing.lg)
        }
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var teamOrbView: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.appPrimary.opacity(0.1 + Double(index) * 0.05), lineWidth: 1)
                    .frame(width: 160 + CGFloat(index) * 40, height: 160 + CGFloat(index) * 40)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent, Color.appPrimary, Color.appPrimary.opacity(0.5)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 140, height: 140)

            Image(systemName: "person.3.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.appBackground)
        }
    }

    private var participantsView: some View {
        HStack(spacing: -8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill([Color.appPrimary, Color.appAccent, Color.appWarning][i].opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.appBackground, lineWidth: 2)
                    )
            }
            Text("+\(max(0, (teamService.currentTeam?.members.count ?? 3) - 3))")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
                .padding(.leading, Spacing.sm)
        }
    }
}

#Preview {
    TeamView()
        .preferredColorScheme(.dark)
}
