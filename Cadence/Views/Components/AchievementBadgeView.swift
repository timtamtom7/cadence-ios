import SwiftUI

struct AchievementBadgeView: View {
    let achievement: Achievement
    var size: CGFloat = 80
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            // Outer glow for earned badges
            if achievement.isEarned {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: size + 16, height: size + 16)
                    .scaleEffect(animateGlow ? 1.1 : 0.9)
                    .opacity(animateGlow ? 0.8 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animateGlow
                    )

                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: size + 8, height: size + 8)
            }

            // Badge circle
            Circle()
                .fill(
                    achievement.isEarned
                        ? LinearGradient(
                            colors: [Color.appPrimary.opacity(0.3), Color.appPrimary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.appSurface, Color.appSurfaceElevated],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: size, height: size)

            // Badge icon
            Image(systemName: achievement.icon)
                .font(.system(size: size * 0.35))
                .foregroundStyle(
                    achievement.isEarned
                        ? Color.appPrimary
                        : Color.appTextTertiary.opacity(0.4)
                )

            // Lock overlay for unearned
            if !achievement.isEarned {
                Circle()
                    .fill(Color.appBackground.opacity(0.5))
                    .frame(width: size, height: size)

                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.2))
                    .foregroundStyle(Color.appTextTertiary)
            }

            // Achievement badge ring
            Circle()
                .stroke(
                    achievement.isEarned ? Color.appPrimary : Color.appTextTertiary.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
        }
        .onAppear {
            if achievement.isEarned {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
        .accessibilityLabel("\(achievement.title): \(achievement.isEarned ? "Earned" : "Locked")")
        .accessibilityHint(achievement.description)
    }
}

// MARK: - Achievement Detail Card

struct AchievementDetailCard: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: Spacing.md) {
            AchievementBadgeView(achievement: achievement, size: 60)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(achievement.title)
                    .font(.appBody)
                    .foregroundStyle(achievement.isEarned ? Color.appTextPrimary : Color.appTextTertiary)

                Text(achievement.description)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                if let earnedAt = achievement.earnedAt, achievement.isEarned {
                    Text("Earned \(earnedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appPrimary)
                }
            }

            Spacer()

            if achievement.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            HStack(spacing: 20) {
                AchievementBadgeView(achievement: Achievement.allAchievements[0], size: 80)
                AchievementBadgeView(achievement: Achievement.allAchievements[1], size: 80)
                AchievementBadgeView(achievement: Achievement.allAchievements[2], size: 80)
            }

            AchievementDetailCard(achievement: Achievement.allAchievements[0])

            AchievementDetailCard(achievement: Achievement(
                id: "locked",
                title: "Marathoner",
                description: "Complete a 60-minute session",
                icon: "timer",
                isEarned: false
            ))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
