import SwiftUI

struct SessionCompleteView: View {
    let session: Session
    let streak: Int
    let totalHours: Double
    let totalSessions: Int
    let onDismiss: () -> Void

    @State private var animateScore = false
    @State private var animateStreak = false
    @State private var animateStats = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateScore ? 1 : 0.5)

                    Circle()
                        .fill(Color.appPrimary.opacity(0.3))
                        .frame(width: 90, height: 90)
                        .scaleEffect(animateScore ? 1 : 0.5)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateScore)

                // Title
                Text("Session Complete!")
                    .font(.appDisplay)
                    .foregroundStyle(Color.appTextPrimary)

                // Stats Grid
                VStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xl) {
                        statItem(value: "\(session.durationMinutes)", label: "Minutes", icon: "clock.fill")
                        statItem(value: "\(session.focusScore)", label: "Focus Score", icon: "brain.head.profile")
                    }

                    if streak > 0 {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.appWarning)
                            Text("\(streak) day streak")
                                .font(.appHeading2)
                                .foregroundStyle(Color.appTextPrimary)
                        }
                        .opacity(animateStreak ? 1 : 0)
                        .offset(y: animateStreak ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateStreak)
                    }

                    // Personal stats
                    HStack(spacing: Spacing.xl) {
                        statItem(value: String(format: "%.1f", totalHours), label: "Total Hours", icon: "hourglass")
                        statItem(value: "\(totalSessions)", label: "Sessions", icon: "checkmark.circle.fill")
                    }
                    .opacity(animateStats ? 1 : 0)
                    .offset(y: animateStats ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: animateStats)
                }
                .padding(Spacing.lg)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                // Actions
                VStack(spacing: Spacing.sm) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Done")
                            .font(.appHeading2)
                            .foregroundStyle(Color.appBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        onDismiss()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Achievement")
                        }
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .padding(Spacing.md)
        }
        .onAppear {
            animateScore = true
            animateStreak = true
            animateStats = true
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.appHeading1)
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

#Preview {
    SessionCompleteView(
        session: Session(duration: 25 * 60, focusScore: 85),
        streak: 5,
        totalHours: 45.5,
        totalSessions: 90,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
