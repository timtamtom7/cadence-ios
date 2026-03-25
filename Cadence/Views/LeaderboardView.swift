import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var selectedTab: LeaderboardTab = .weekly

    enum LeaderboardTab: String, CaseIterable {
        case weekly = "Weekly"
        case global = "Global"
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.appPrimary)
                    Spacer()
                } else {
                    leaderboardContent
                }
            }
            .padding(.bottom, 100)
        }
        .task {
            await viewModel.refresh()
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Leaderboard")
                    .font(.appDisplay)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
            }

            // Tab selector
            HStack(spacing: 0) {
                ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.appCaption)
                            .foregroundStyle(selectedTab == tab ? Color.appPrimary : Color.appTextSecondary)
                            .padding(.vertical, Spacing.xs)
                            .padding(.horizontal, Spacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.appSurface)
            .clipShape(Capsule())
        }
    }

    private var leaderboardContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Personal Stats Card
                personalStatsCard
                    .padding(.horizontal, Spacing.md)

                // Top 3 Podium
                if !viewModel.topThree.isEmpty {
                    topThreePodium
                        .padding(.horizontal, Spacing.md)
                }

                // Rest of leaderboard
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.entries.dropFirst(3)) { entry in
                        LeaderboardRow(entry: entry, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.top, Spacing.md)
        }
    }

    private var personalStatsCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Your Stats")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.appPrimary)
            }

            if let userEntry = viewModel.currentUserEntry {
                HStack(spacing: Spacing.xl) {
                    personalStatItem(value: "#\(userEntry.rank)", label: "Rank", icon: "medal.fill")
                    personalStatItem(value: "\(userEntry.weeklyMinutes)m", label: "This Week", icon: "clock.fill")
                    personalStatItem(value: String(format: "%.1fh", userEntry.totalHours), label: "Total", icon: "hourglass")
                    personalStatItem(value: "\(userEntry.totalSessions)", label: "Sessions", icon: "checkmark.circle.fill")
                }
            } else {
                Text("Complete your first session to appear on the leaderboard")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Streak bar
            HStack(spacing: Spacing.sm) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.appWarning)
                Text("\(viewModel.currentUserEntry?.streak ?? 0) day streak")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
        )
    }

    private func personalStatItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var topThreePodium: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if viewModel.topThree.count > 1 {
                podiumPlace(entry: viewModel.topThree[1], height: 80, place: 2)
            }
            if !viewModel.topThree.isEmpty {
                podiumPlace(entry: viewModel.topThree[0], height: 100, place: 1)
            }
            if viewModel.topThree.count > 2 {
                podiumPlace(entry: viewModel.topThree[2], height: 60, place: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
    }

    private func podiumPlace(entry: LeaderboardEntry, height: CGFloat, place: Int) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(Color(hex: viewModel.rankColor(for: place)).opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(entry.name.prefix(1))
                    .font(.appHeading2)
                    .foregroundStyle(Color(hex: viewModel.rankColor(for: place)))
            }

            Text(entry.name.components(separatedBy: " ").first ?? "")
                .font(.appCaption)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)

            Text("\(entry.weeklyMinutes)m")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: viewModel.rankColor(for: place)))
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let viewModel: LeaderboardViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Image(systemName: "medal.fill")
                        .foregroundStyle(Color(hex: viewModel.rankColor(for: entry.rank)))
                } else {
                    Text("\(entry.rank)")
                        .font(.appMono)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .frame(width: 32)

            // Avatar
            ZStack {
                Circle()
                    .fill(entry.isCurrentUser ? Color.appPrimary.opacity(0.2) : Color.appSurface)
                    .frame(width: 44, height: 44)
                Text(entry.name.prefix(1))
                    .font(.appHeading2)
                    .foregroundStyle(entry.isCurrentUser ? Color.appPrimary : Color.appTextPrimary)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.appBody)
                    .foregroundStyle(entry.isCurrentUser ? Color.appAccent : Color.appTextPrimary)
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(entry.streak)")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.appWarning)
                }
            }

            Spacer()

            // Minutes
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.weeklyMinutes)")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)
                Text("min")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(Spacing.sm)
        .background(entry.isCurrentUser ? Color.appPrimary.opacity(0.08) : Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isCurrentUser ? Color.appPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    LeaderboardView()
        .preferredColorScheme(.dark)
}
