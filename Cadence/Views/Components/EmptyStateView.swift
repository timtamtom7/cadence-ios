import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.appPrimary.opacity(0.05))
                    .frame(width: 130, height: 130)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appPrimary.opacity(0.8))
            }

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)

                Text(message)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.appHeading2)
                        .foregroundStyle(Color.appBackground)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.appPrimary)
                        .clipShape(Capsule())
                }
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Pre-built Empty States

extension EmptyStateView {
    static var noSessions: EmptyStateView {
        EmptyStateView(
            icon: "timer",
            title: "No Sessions Yet",
            message: "Start your first focus session to begin building your streak."
        )
    }

    static var noPartners: EmptyStateView {
        EmptyStateView(
            icon: "person.2.wave.2",
            title: "No Partners Yet",
            message: "Find someone to focus with and stay accountable together."
        )
    }

    static var noTeam: EmptyStateView {
        EmptyStateView(
            icon: "person.3.fill",
            title: "Not on a Team",
            message: "Join or create a focus team to track collective progress."
        )
    }

    static var noAchievements: EmptyStateView {
        EmptyStateView(
            icon: "medal.fill",
            title: "No Badges Yet",
            message: "Complete focus sessions to unlock achievement badges."
        )
    }

    static var leaderboardLoading: EmptyStateView {
        EmptyStateView(
            icon: "chart.bar.fill",
            title: "Loading Leaderboard",
            message: "Fetching the latest focus stats..."
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        EmptyStateView(
            icon: "timer",
            title: "No Sessions Yet",
            message: "Start your first focus session to begin building your streak.",
            actionTitle: "Start Focusing"
        ) {
            print("Action tapped")
        }
    }
    .preferredColorScheme(.dark)
}
