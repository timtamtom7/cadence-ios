import SwiftUI

struct WeeklyGoalRing: View {
    let progress: Double // 0.0 to 1.0+
    let currentMinutes: Int
    let goalMinutes: Int
    var ringSize: CGFloat = 120
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.appSurface, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

            // Center content
            VStack(spacing: 2) {
                if progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: ringSize * 0.2))
                        .foregroundStyle(Color.appPrimary)
                }

                Text("\(currentMinutes)m")
                    .font(.system(size: ringSize * 0.18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)

                Text("of \(goalMinutes)m")
                    .font(.system(size: ringSize * 0.1))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary, Color.appAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Daily Goal Ring (smaller, for stats cards)

struct DailyGoalRing: View {
    let progress: Double
    let currentMinutes: Int
    let goalMinutes: Int

    var body: some View {
        WeeklyGoalRing(
            progress: progress,
            currentMinutes: currentMinutes,
            goalMinutes: goalMinutes,
            ringSize: 80,
            lineWidth: 6
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            WeeklyGoalRing(
                progress: 0.75,
                currentMinutes: 90,
                goalMinutes: 120
            )

            WeeklyGoalRing(
                progress: 1.0,
                currentMinutes: 120,
                goalMinutes: 120
            )

            HStack(spacing: 20) {
                DailyGoalRing(
                    progress: 0.5,
                    currentMinutes: 30,
                    goalMinutes: 60
                )

                DailyGoalRing(
                    progress: 1.0,
                    currentMinutes: 60,
                    goalMinutes: 60
                )
            }
        }
    }
    .preferredColorScheme(.dark)
}
