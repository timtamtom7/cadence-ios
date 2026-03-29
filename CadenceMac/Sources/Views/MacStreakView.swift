import SwiftUI

struct MacStreakView: View {
    @State private var streak: StreakData = StreakData()
    @State private var weeklySessions: [Session] = []
    @State private var weeklyMinutes: Int = 0

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Your Progress")
                                .font(.appHeading1)
                                .foregroundStyle(Color.appTextPrimary)
                            Text("Keep the streak alive")
                                .font(.appBody)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        Spacer()
                    }

                    // Streak cards
                    HStack(spacing: Spacing.md) {
                        StreakCard(
                            icon: "flame.fill",
                            iconColor: .orange,
                            value: "\(streak.currentStreak)",
                            label: "Current Streak",
                            subtitle: "days"
                        )

                        StreakCard(
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            value: "\(streak.longestStreak)",
                            label: "Best Streak",
                            subtitle: "days"
                        )

                        StreakCard(
                            icon: "clock.fill",
                            iconColor: .appPrimary,
                            value: "\(weeklyMinutes)",
                            label: "This Week",
                            subtitle: "minutes"
                        )
                    }

                    // Weekly heatmap
                    WeeklyHeatmap(sessions: weeklySessions)

                    // Recent sessions
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Recent Sessions")
                            .font(.appHeading2)
                            .foregroundStyle(Color.appTextPrimary)

                        if weeklySessions.isEmpty {
                            EmptyStateView(
                                icon: "moon.zzz.fill",
                                title: "No sessions yet",
                                message: "Start your first focus session to begin tracking"
                            )
                            .frame(height: 200)
                        } else {
                            ForEach(weeklySessions.prefix(10)) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        streak = await DatabaseService.shared.loadStreak()
        let sessions = await DatabaseService.shared.loadSessions()
        let calendar = Calendar.current
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) {
            weeklySessions = sessions.filter { $0.completedAt >= weekAgo }
        }
        weeklyMinutes = sessions
            .filter { weeklySessions.contains($0) }
            .reduce(0) { $0 + $1.duration } / 60
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)

            VStack(spacing: 0) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.appSurfaceElevated)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Heatmap

struct WeeklyHeatmap: View {
    let sessions: [Session]

    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let today = Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    private var sessionCountByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.completedAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("This Week")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.sm) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: Spacing.xs) {
                        Text(dayFormatter.string(from: day))
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextTertiary)

                        let count = sessionCountByDay[calendar.startOfDay(for: day)] ?? 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: count))
                            .frame(width: 40, height: 40)
                            .overlay {
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.appCaption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.appBackground)
                                }
                            }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.appSurfaceElevated)
            .cornerRadius(12)
        }
    }

    private func heatmapColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.appSurface
        case 1: return Color.appPrimary.opacity(0.4)
        case 2: return Color.appPrimary.opacity(0.6)
        case 3: return Color.appPrimary.opacity(0.8)
        default: return Color.appPrimary
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: Session

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(session.durationMinutes) min focus session")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)
                Text(timeFormatter.string(from: session.completedAt))
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            Spacer()

            HStack(spacing: Spacing.xxs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appAccent)
                Text("\(session.focusScore)")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(8)
    }
}

#Preview {
    MacStreakView()
        .frame(width: 700, height: 600)
}
