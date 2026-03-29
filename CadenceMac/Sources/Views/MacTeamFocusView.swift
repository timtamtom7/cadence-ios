import SwiftUI

struct TeamFocusView: View {
    @State private var r12Service = CadenceR12Service.shared
    @State private var selectedChallenge: CadenceR12Service.FocusChallenge?
    @State private var showCreateSheet = false
    @State private var isLoadingLeaderboard = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Active team challenge
                    if let active = r12Service.challenges.first(where: { $0.status == .active }) {
                        activeChallengeCard(active)
                    }

                    // This week's team stats
                    teamStatsCard

                    // Team leaderboard
                    leaderboardSection

                    // Join or create challenge
                    joinChallengeSection
                }
                .padding(Spacing.lg)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateChallengeSheet { challenge in
                r12Service.createChallenge(
                    name: challenge.name,
                    description: challenge.description,
                    type: challenge.type,
                    durationDays: challenge.durationDays,
                    targetMinutes: challenge.targetMinutes
                )
            }
        }
        .onAppear {
            r12Service.loadLeaderboard()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Focus Together")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Team challenges & leaderboard")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Button {
                showCreateSheet = true
            } label: {
                Label("New Challenge", systemImage: "plus.circle.fill")
                    .font(.appCaption)
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.appPrimary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Active Challenge Card

    private func activeChallengeCard(_ challenge: CadenceR12Service.FocusChallenge) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(challenge.type.rawValue)
                            .font(.appCaption2)
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.15))
                            .cornerRadius(4)

                        Text("\(challenge.daysRemaining) days left")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextTertiary)
                    }

                    Text(challenge.name)
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)
                }

                Spacer()

                Text("\(challenge.participantIds.count)")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appPrimary)
                Text("members")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appSurfaceElevated)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appPrimary)
                            .frame(width: geometry.size.width * challenge.progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(Int(challenge.progress * 100))% complete · \(challenge.targetMinutes / 60)h target")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            // Milestones
            HStack(spacing: Spacing.sm) {
                ForEach(challenge.milestones) { milestone in
                    MilestonePip(milestone: milestone)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }

    // MARK: - Team Stats

    private var teamStatsCard: some View {
        HStack(spacing: Spacing.lg) {
            teamStatItem(value: "10h", label: "This week", sublabel: "team focus")
            Divider().frame(height: 40).background(Color.appSurfaceElevated)
            teamStatItem(value: "\(r12Service.leaderboard.count)", label: "Active", sublabel: "challengers")
            Divider().frame(height: 40).background(Color.appSurfaceElevated)
            teamStatItem(value: "3", label: "Milestones", sublabel: "this week")
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }

    private func teamStatItem(value: String, label: String, sublabel: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appHeading1)
                .foregroundStyle(Color.appPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextPrimary)
            Text(sublabel)
                .font(.appCaption2)
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Team Leaderboard")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                Text("This Week")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            VStack(spacing: 1) {
                ForEach(r12Service.leaderboard) { entry in
                    LeaderboardRow(entry: entry)
                }
            }
            .background(Color.appSurface)
            .cornerRadius(12)
        }
    }

    // MARK: - Join Challenge

    private var joinChallengeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Join a Team Challenge")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.sm) {
                challengeTypeCard(type: .team, icon: "person.3.fill", title: "Team", subtitle: "2-10 members")
                challengeTypeCard(type: .friend, icon: "person.2.fill", title: "Friends", subtitle: "Up to 5")
                challengeTypeCard(type: .monthly, icon: "calendar", title: "Monthly", subtitle: "All users")
            }
        }
    }

    private func challengeTypeCard(type: CadenceR12Service.FocusChallenge.ChallengeType, icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.appPrimary)

            Text(title)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)

            Text(subtitle)
                .font(.appCaption)
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }
}

// MARK: - Milestone Pip

struct MilestonePip: View {
    let milestone: CadenceR12Service.FocusChallenge.Milestone

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(milestone.isAchieved ? Color.appPrimary : Color.appSurfaceElevated)
                .frame(width: 12, height: 12)
                .overlay {
                    if milestone.isAchieved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color.appBackground)
                    }
                }

            Text("\(milestone.minutes / 60)h")
                .font(.appCaption2)
                .foregroundStyle(milestone.isAchieved ? Color.appPrimary : Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: CadenceR12Service.LeaderboardEntry

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return Color.appTextTertiary
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Rank
            Text("#\(entry.rank)")
                .font(.appMono)
                .foregroundStyle(entry.rank <= 3 ? rankColor : Color.appTextTertiary)
                .frame(width: 32, alignment: .leading)

            // Avatar
            Circle()
                .fill(Color.appPrimary.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(entry.displayName.prefix(1)))
                        .font(.appCaption)
                        .foregroundStyle(Color.appPrimary)
                }

            // Name
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.displayName)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(entry.streak) day streak")
                            .font(.appCaption2)
                    }
                    .foregroundStyle(Color.appWarning)
                }
            }

            Spacer()

            // Minutes
            Text("\(entry.focusMinutes / 60)h \(entry.focusMinutes % 60)m")
                .font(.appMono)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(entry.userId == "local" ? Color.appPrimary.opacity(0.08) : Color.clear)
    }
}

// MARK: - Create Challenge Sheet

struct CreateChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType: CadenceR12Service.FocusChallenge.ChallengeType = .team
    @State private var durationDays = 7
    @State private var targetHours = 5

    let onCreate: (NewChallenge) -> Void

    struct NewChallenge {
        let name: String
        let description: String
        let type: CadenceR12Service.FocusChallenge.ChallengeType
        let durationDays: Int
        let targetMinutes: Int
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Create Challenge")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appTextSecondary)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                TextField("Challenge name", text: $name)
                    .font(.appBody)
                    .padding(Spacing.sm)
                    .background(Color.appSurfaceElevated)
                    .cornerRadius(8)
                    .foregroundStyle(Color.appTextPrimary)

                TextField("Description (optional)", text: $description)
                    .font(.appBody)
                    .padding(Spacing.sm)
                    .background(Color.appSurfaceElevated)
                    .cornerRadius(8)
                    .foregroundStyle(Color.appTextPrimary)

                HStack {
                    Text("Type:")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                    Picker("", selection: $selectedType) {
                        ForEach(CadenceR12Service.FocusChallenge.ChallengeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Text("Duration:")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                    Stepper("\(durationDays) days", value: $durationDays, in: 1...90)
                        .foregroundStyle(Color.appTextPrimary)
                }

                HStack {
                    Text("Target:")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                    Stepper("\(targetHours) hours", value: $targetHours, in: 1...100)
                        .foregroundStyle(Color.appTextPrimary)
                }
            }

            Button {
                let challenge = NewChallenge(
                    name: name,
                    description: description,
                    type: selectedType,
                    durationDays: durationDays,
                    targetMinutes: targetHours * 60
                )
                onCreate(challenge)
                dismiss()
            } label: {
                Text("Create Challenge")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(name.isEmpty ? Color.appSurfaceElevated : Color.appPrimary)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(name.isEmpty)
        }
        .padding(Spacing.xl)
        .frame(width: 480)
        .background(Color.appSurface)
    }
}

#Preview {
    TeamFocusView()
        .frame(width: 700, height: 700)
}
