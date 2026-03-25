import SwiftUI

struct ChallengesView: View {
    @State private var challenges: [WeeklyChallenge] = WeeklyChallenge.mockChallenges
    @State private var daysRemaining: Int = 3

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Progress summary
                    progressSummary

                    // Active challenges
                    activeChallengesSection

                    // Completed challenges
                    completedChallengesSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 120)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Weekly Challenges")
                    .font(.appDisplay)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
            }

            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("\(daysRemaining) days left")
                    .font(.appCaption)
            }
            .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var progressSummary: some View {
        let completedCount = challenges.filter { $0.isCompleted }.count
        let totalXP = challenges.reduce(0) { $0 + $1.rewardXP }
        let earnedXP = challenges.filter { $0.isCompleted }.reduce(0) { $0 + $1.rewardXP }

        return HStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Text("\(completedCount)/\(challenges.count)")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appPrimary)
                Text("Completed")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .background(Color.appSurfaceElevated)
                .frame(height: 40)

            VStack(spacing: Spacing.xs) {
                Text("\(earnedXP)/\(totalXP)")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appAccent)
                Text("XP Earned")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var activeChallengesSection: some View {
        let active = challenges.filter { !$0.isCompleted }
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if !active.isEmpty {
                sectionHeader("Active", color: Color.appPrimary)

                ForEach(active) { challenge in
                    ChallengeCard(challenge: challenge)
                }
            }
        }
    }

    private var completedChallengesSection: some View {
        let completed = challenges.filter { $0.isCompleted }
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if !completed.isEmpty {
                sectionHeader("Completed", color: Color.appSuccess)

                ForEach(completed) { challenge in
                    ChallengeCard(challenge: challenge)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.appHeading2)
            .foregroundStyle(Color.appTextPrimary)
    }
}

struct ChallengeCard: View {
    let challenge: WeeklyChallenge

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(challenge.isCompleted ? Color.appSuccess.opacity(0.15) : Color.appPrimary.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: challenge.icon)
                        .font(.title2)
                        .foregroundStyle(challenge.isCompleted ? Color.appSuccess : Color.appPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(challenge.title)
                            .font(.appBody)
                            .foregroundStyle(Color.appTextPrimary)

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("\(challenge.rewardXP) XP")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Color.appAccent)
                    }

                    Text(challenge.description)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appSurfaceElevated)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(challenge.isCompleted ? Color.appSuccess : Color.appPrimary)
                            .frame(width: geo.size.width * challenge.progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(challenge.progressText)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextSecondary)

                    Spacer()

                    if challenge.isCompleted {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Completed")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Color.appSuccess)
                    } else {
                        Text("\(Int(challenge.progress * 100))%")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(challenge.isCompleted ? Color.appSuccess.opacity(0.05) : Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(challenge.isCompleted ? Color.appSuccess.opacity(0.2) : Color.appPrimary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ChallengesView()
        .preferredColorScheme(.dark)
}
