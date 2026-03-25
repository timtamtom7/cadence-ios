import SwiftUI

struct AchievementsView: View {
    @State private var achievements: [Achievement] = Achievement.allAchievements
    @State private var totalHours: Double = 0
    @State private var totalSessions: Int = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Summary
                    summaryCard

                    // Earned achievements
                    if !earnedAchievements.isEmpty {
                        earnedSection
                    }

                    // Locked achievements
                    if !lockedAchievements.isEmpty {
                        lockedSection
                    }

                    // Achievement tiers
                    tiersSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 120)
            }
        }
        .task {
            await loadData()
        }
    }

    private var earnedAchievements: [Achievement] {
        achievements.filter { $0.isEarned }
    }

    private var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isEarned }
    }

    private var summaryCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text("\(earnedAchievements.count)/\(achievements.count)")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appPrimary)
            }

            HStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.xs) {
                    Text("\(Int(totalHours))")
                        .font(.appHeading1)
                        .foregroundStyle(Color.appPrimary)
                    Text("Hours Focused")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Divider()
                    .background(Color.appSurfaceElevated)
                    .frame(height: 40)

                VStack(spacing: Spacing.xs) {
                    Text("\(totalSessions)")
                        .font(.appHeading1)
                        .foregroundStyle(Color.appPrimary)
                    Text("Sessions")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Divider()
                    .background(Color.appSurfaceElevated)
                    .frame(height: 40)

                VStack(spacing: Spacing.xs) {
                    Text("\(earnedAchievements.count)")
                        .font(.appHeading1)
                        .foregroundStyle(Color.appPrimary)
                    Text("Badges")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var earnedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Earned", count: earnedAchievements.count, color: Color.appPrimary)

            ForEach(earnedAchievements) { achievement in
                AchievementCard(achievement: achievement, isEarned: true)
            }
        }
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Locked", count: lockedAchievements.count, color: Color.appTextTertiary)

            ForEach(lockedAchievements) { achievement in
                AchievementCard(achievement: achievement, isEarned: false)
            }
        }
    }

    private var tiersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Achievement Tiers")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            VStack(spacing: Spacing.sm) {
                achievementTier(
                    name: "Bronze Focuser",
                    requirement: "Complete 10 sessions",
                    progress: min(1.0, Double(totalSessions) / 10.0),
                    isEarned: totalSessions >= 10,
                    color: "CD7F32"
                )

                achievementTier(
                    name: "Silver Focuser",
                    requirement: "Reach 50 hours total",
                    progress: min(1.0, totalHours / 50.0),
                    isEarned: totalHours >= 50,
                    color: "C0C0C0"
                )

                achievementTier(
                    name: "Gold Focuser",
                    requirement: "Reach 100 hours total",
                    progress: min(1.0, totalHours / 100.0),
                    isEarned: totalHours >= 100,
                    color: "FFD700"
                )
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)
            Text("\(count)")
                .font(.appCaption)
                .foregroundStyle(color)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
            Spacer()
        }
    }

    private func achievementTier(name: String, requirement: String, progress: Double, isEarned: Bool, color: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: color).opacity(isEarned ? 0.2 : 0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: isEarned ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(isEarned ? Color(hex: color) : Color.appTextTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.appBody)
                    .foregroundStyle(isEarned ? Color.appTextPrimary : Color.appTextTertiary)

                Text(requirement)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.appSurface)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: color))
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            if isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: color))
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadData() async {
        let sessions = await DatabaseService.shared.loadSessions()
        totalSessions = sessions.count
        totalHours = Double(sessions.reduce(0) { $0 + $1.duration }) / 3600.0
        achievements = await DatabaseService.shared.loadAchievements()
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isEarned: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color.appPrimary.opacity(0.15) : Color.appSurface)
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(isEarned ? Color.appPrimary : Color.appTextTertiary)
                    .opacity(isEarned ? 1 : 0.4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.appBody)
                    .foregroundStyle(isEarned ? Color.appTextPrimary : Color.appTextTertiary)

                Text(achievement.description)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                if let earnedAt = achievement.earnedAt, isEarned {
                    Text("Earned \(earnedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appPrimary)
                }
            }

            Spacer()

            if isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)
            } else {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
        .padding(Spacing.md)
        .background(isEarned ? Color.appPrimary.opacity(0.05) : Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEarned ? Color.appPrimary.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    AchievementsView()
        .preferredColorScheme(.dark)
}
