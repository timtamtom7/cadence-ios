import SwiftUI

struct BreathingOrb: View {
    let progress: Double
    let timeString: String
    let isPaused: Bool

    @State private var breathePhase: Bool = false
    @State private var pulsePhase: Double = 0

    private let breatheAnimation = Animation
        .easeInOut(duration: 4.0)
        .repeatForever(autoreverses: true)

    private let pulseAnimation = Animation
        .easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true)

    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color.appPrimary.opacity(0.1 + Double(index) * 0.05),
                        lineWidth: 1
                    )
                    .frame(width: 180 + CGFloat(index) * 30, height: 180 + CGFloat(index) * 30)
                    .scaleEffect(breathePhase ? 1.05 : 0.95)
            }

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.appPrimary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Main orb
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appPrimary.opacity(0.4),
                                Color.appPrimary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(breathePhase ? 1.1 : 0.9)

                // Core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appAccent,
                                Color.appPrimary,
                                Color.appPrimary.opacity(0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                // Timer text
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.appBackground)
                        .opacity(isPaused ? 0.6 : 1.0)

                    if isPaused {
                        Text("PAUSED")
                            .font(.appCaption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appBackground.opacity(0.7))
                    }
                }
            }
            .scaleEffect(breathePhase ? 1.0 : 0.85)
            .opacity(isPaused ? 0.7 : 1.0)
        }
        .onAppear {
            guard !isPaused else { return }
            withAnimation(breatheAnimation) {
                breathePhase = true
            }
            withAnimation(pulseAnimation) {
                pulsePhase = 1.0
            }
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                // Stop animations when paused
                withAnimation(.easeOut(duration: 0.3)) {
                    breathePhase = false
                }
            } else {
                withAnimation(breatheAnimation) {
                    breathePhase = true
                }
            }
        }
        .onChange(of: progress) { _, _ in
            // Haptic feedback at milestones
        }
        .accessibilityLabel("Focus timer: \(timeString)")
        .accessibilityHint(isPaused ? "Session paused" : "Session in progress")
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        BreathingOrb(
            progress: 0.4,
            timeString: "18:32",
            isPaused: false
        )
    }
    .preferredColorScheme(.dark)
}
