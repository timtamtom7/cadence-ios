import SwiftUI

struct MatchFoundSheet: View {
    let match: MatchingSession
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIn ? 1 : 0.5)

                Circle()
                    .fill(Color.appPrimary.opacity(0.3))
                    .frame(width: 90, height: 90)
                    .scaleEffect(animateIn ? 1 : 0.5)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appPrimary)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateIn)

            // Match details
            VStack(spacing: Spacing.sm) {
                Text("Match Found!")
                    .font(.appDisplay)
                    .foregroundStyle(Color.appTextPrimary)

                Text("You're matched with \(match.partnerName)")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }

            // Session info
            HStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xxs) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.appPrimary)
                    Text("\(match.durationMinutes) min")
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Duration")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                VStack(spacing: Spacing.xxs) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(Color.appPrimary)
                    Text(match.focusMode)
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Focus Mode")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(Spacing.lg)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            // Actions
            VStack(spacing: Spacing.sm) {
                Button {
                    Theme.hapticMedium()
                    onConfirm()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Together")
                    }
                }
                .buttonStyle(AxiomPrimaryButtonStyle())

                Button {
                    Theme.haptic(.light)
                    onCancel()
                } label: {
                    Text("Find Someone Else")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.appBackground)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Match Queue View

struct MatchQueueView: View {
    let queueCount: Int
    let focusMode: String
    let onCancel: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                // Pulsing background
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.8)

                Circle()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(spacing: Spacing.xs) {
                Text("Searching...")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Matching by \(focusMode) mode")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                if queueCount > 0 {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(queueCount) in queue")
                            .font(.appCaption)
                    }
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.appPrimary.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            Button {
                Theme.haptic(.light)
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.appBody)
                    .foregroundStyle(Color.appError)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        MatchQueueView(
            queueCount: 3,
            focusMode: "Deep Work",
            onCancel: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
