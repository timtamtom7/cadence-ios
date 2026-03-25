import SwiftUI

struct SessionCompleteView: View {
    let session: Session
    let streak: Int
    let totalHours: Double
    let totalSessions: Int
    let onDismiss: () -> Void

    @State private var animateSuccess = false
    @State private var animateStreak = false
    @State private var animateStats = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Success Icon with celebration
                successIcon

                // Title with glow
                Text("Session Complete!")
                    .font(.appDisplay)
                    .foregroundStyle(Color.appTextPrimary)
                    .shadow(color: Color.appPrimary.opacity(0.5), radius: 10)

                // Focus Score Badge
                focusScoreBadge

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
                        // Share functionality placeholder
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
            animateSuccess = true
            animateStreak = true
            animateStats = true
            // Small delay before confetti for dramatic effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var successIcon: some View {
        ZStack {
            // Outer pulsing rings
            Circle()
                .fill(Color.appPrimary.opacity(0.1))
                .frame(width: 140, height: 140)
                .scaleEffect(animateSuccess ? 1.1 : 0.8)
                .opacity(animateSuccess ? 1 : 0)

            Circle()
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(animateSuccess ? 1 : 0.5)

            Circle()
                .fill(Color.appPrimary.opacity(0.3))
                .frame(width: 90, height: 90)
                .scaleEffect(animateSuccess ? 1 : 0.5)

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.appPrimary)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateSuccess)
    }

    private var focusScoreBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: scoreIcon)
                .font(.caption)
            Text(scoreMessage)
                .font(.appCaption)
        }
        .foregroundStyle(scoreColor)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(scoreColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var scoreIcon: String {
        switch session.focusScore {
        case 90...100: return "star.fill"
        case 75..<90: return "hand.thumbsup.fill"
        case 50..<75: return "leaf.fill"
        default: return "bolt.fill"
        }
    }

    private var scoreMessage: String {
        switch session.focusScore {
        case 90...100: return "Incredible focus! 🌟"
        case 75..<90: return "Great session! 💪"
        case 50..<75: return "Good work! Keep it up!"
        default: return "Every session counts!"
        }
    }

    private var scoreColor: Color {
        switch session.focusScore {
        case 90...100: return Color.appAccent
        case 75..<90: return Color.appPrimary
        case 50..<75: return Color.appWarning
        default: return Color.appTextSecondary
        }
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

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .position(particle.position)
                        .offset(particle.offset)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.appPrimary, .appAccent, .appWarning, .appSuccess]
        let centerX = size.width / 2
        let centerY = size.height / 2

        particles = (0..<30).map { _ in
            ConfettiParticle(
                position: CGPoint(x: centerX, y: centerY),
                offset: .zero,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                opacity: 1.0,
                angle: Double.random(in: 0...360),
                distance: CGFloat.random(in: 50...200)
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                let angle = particles[i].angle
                let distance = particles[i].distance
                let radians = angle * .pi / 180
                particles[i].offset = CGSize(
                    width: cos(radians) * distance,
                    height: sin(radians) * distance - 100 // slight upward bias
                )
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var offset: CGSize
    var color: Color
    var size: CGFloat
    var opacity: Double
    var angle: Double
    var distance: CGFloat
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
