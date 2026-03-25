import SwiftUI

/// R7: Detailed analytics and insights dashboard
struct InsightsView: View {
    @State private var statisticsService = StatisticsService.shared
    @State private var sessions: [Session] = []
    @State private var streak: StreakData = StreakData()
    @State private var selectedPeriod: StatsPeriod = .week

    enum StatsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedPeriod == .week {
                        weeklyStatsSection
                    } else {
                        monthlyStatsSection
                    }

                    focusPatternSection
                    trendsSection
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadData()
            }
        }
    }

    // MARK: - Weekly Stats Section

    private var weeklyStatsSection: some View {
        VStack(spacing: 16) {
            if let stats = statisticsService.weeklyStats {
                // Summary cards
                HStack(spacing: 12) {
                    StatCard(
                        title: "Total Time",
                        value: String(format: "%.1fh", stats.totalHours),
                        icon: "clock.fill",
                        color: .appPrimary
                    )
                    StatCard(
                        title: "Sessions",
                        value: "\(stats.totalSessions)",
                        icon: "timer",
                        color: .appAccent
                    )
                }
                .padding(.horizontal)

                // Daily breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Breakdown")
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(stats.dailyMinutes.enumerated()), id: \.offset) { index, minutes in
                            DailyBar(
                                day: dayName(for: index),
                                minutes: minutes,
                                maxMinutes: max(stats.dailyMinutes.max() ?? 1, 1)
                            )
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
                .background(Color.appSurface)
                .cornerRadius(16)
                .padding(.horizontal)

                // Goal progress
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Weekly Goal")
                            .font(.appHeading2)
                            .foregroundStyle(Color.appTextPrimary)
                        Spacer()
                        Text("\(Int(stats.goalProgress * 100))%")
                            .font(.appBody)
                            .foregroundStyle(Color.appPrimary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appSurfaceElevated)
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appPrimary)
                                .frame(width: geometry.size.width * stats.goalProgress, height: 12)
                        }
                    }
                    .frame(height: 12)

                    Text("\(stats.totalMinutes)/600 minutes")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextTertiary)
                }
                .padding()
                .background(Color.appSurface)
                .cornerRadius(16)
                .padding(.horizontal)

                // Other stats
                HStack(spacing: 12) {
                    SmallStatCard(
                        title: "Avg Score",
                        value: String(format: "%.0f", stats.averageFocusScore),
                        icon: "star.fill"
                    )
                    SmallStatCard(
                        title: "Best Session",
                        value: "\(stats.longestSession)m",
                        icon: "trophy.fill"
                    )
                    SmallStatCard(
                        title: "Social",
                        value: "\(stats.sessionsWithPartner)",
                        icon: "person.2.fill"
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Monthly Stats Section

    private var monthlyStatsSection: some View {
        VStack(spacing: 16) {
            if let stats = statisticsService.monthlyStats {
                HStack(spacing: 12) {
                    StatCard(
                        title: "This Month",
                        value: String(format: "%.1fh", stats.totalHours),
                        icon: "calendar",
                        color: .appPrimary
                    )
                    StatCard(
                        title: "Active Days",
                        value: "\(stats.daysActive)",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Weekly breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Progress")
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)

                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Array(stats.weeklyMinutes.enumerated()), id: \.offset) { index, minutes in
                            WeeklyBar(
                                week: "W\(index + 1)",
                                minutes: minutes,
                                maxMinutes: max(stats.weeklyMinutes.max() ?? 1, 1)
                            )
                        }
                    }
                    .frame(height: 100)
                }
                .padding()
                .background(Color.appSurface)
                .cornerRadius(16)
                .padding(.horizontal)

                // Streak info
                HStack(spacing: 12) {
                    SmallStatCard(
                        title: "Current",
                        value: "\(stats.currentStreak)d",
                        icon: "flame.fill"
                    )
                    SmallStatCard(
                        title: "Longest",
                        value: "\(stats.longestStreak)d",
                        icon: "crown.fill"
                    )
                    SmallStatCard(
                        title: "Avg Score",
                        value: String(format: "%.0f", stats.averageFocusScore),
                        icon: "star.fill"
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Focus Pattern Section

    private var focusPatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Focus Pattern")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            if let pattern = statisticsService.focusPattern {
                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: pattern.bestTimeOfDay.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(Color.appPrimary)
                        Text(pattern.bestTimeOfDay.label)
                            .font(.appBody)
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Best Time")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appSurfaceElevated)
                    .cornerRadius(12)

                    VStack(spacing: 8) {
                        Image(systemName: "repeat")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.appAccent)
                        Text("\(Int(pattern.consistencyScore * 100))%")
                            .font(.appBody)
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Consistency")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appSurfaceElevated)
                    .cornerRadius(12)
                }
            } else {
                Text("Complete 5+ sessions to discover your pattern")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextTertiary)
                    .padding()
            }
        }
        .padding()
        .background(Color.appSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Trends Section

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Score Trend")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            if !statisticsService.recentTrends.isEmpty {
                FocusTrendChart(trends: statisticsService.recentTrends)
                    .frame(height: 150)
            } else {
                Text("No trend data yet")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.appSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func loadData() {
        Task {
            let db = DatabaseService.shared
            sessions = await db.loadSessions()
            streak = await db.loadStreak()
            let soundCounts = await db.loadActiveSounds()
            let soundCountsDouble = await db.loadActiveSounds()
            let soundCounts = soundCountsDouble.mapValues { Int($0) }
            statisticsService.refresh(sessions: sessions, streak: streak, soundCounts: soundCounts)
        }
    }

    private func dayName(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[index % 7]
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.appDisplay)
                .foregroundStyle(Color.appTextPrimary)
            Text(title)
                .font(.appCaption)
                .foregroundStyle(Color.appTextTertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .cornerRadius(16)
    }
}

struct SmallStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .cornerRadius(12)
    }
}

struct DailyBar: View {
    let day: String
    let minutes: Int
    let maxMinutes: Int

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appPrimary)
                .frame(width: 32, height: max(4, CGFloat(minutes) / CGFloat(maxMinutes) * 80))
            Text(day)
                .font(.caption2)
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyBar: View {
    let week: String
    let minutes: Int
    let maxMinutes: Int

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appPrimary)
                .frame(width: 40, height: max(4, CGFloat(minutes) / CGFloat(maxMinutes) * 70))
            Text(week)
                .font(.caption2)
                .foregroundStyle(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FocusTrendChart: View {
    let trends: [FocusTrend]

    var body: some View {
        GeometryReader { geometry in
            let maxScore: Int = 100
            let points = trends.enumerated().map { index, trend -> CGPoint in
                let x = geometry.size.width * CGFloat(index) / CGFloat(max(trends.count - 1, 1))
                let y = geometry.size.height * (1 - CGFloat(trend.focusScore) / CGFloat(maxScore))
                return CGPoint(x: x, y: y)
            }

            ZStack {
                // Grid lines
                ForEach([25, 50, 75, 100], id: \.self) { score in
                    Path { path in
                        let y = geometry.size.height * (1 - CGFloat(score) / CGFloat(maxScore))
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.appTextTertiary.opacity(0.2), lineWidth: 1)
                }

                // Line chart
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.appPrimary, lineWidth: 2)
                }

                // Dots
                ForEach(Array(trends.enumerated()), id: \.element.id) { index, trend in
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 8, height: 8)
                        .position(points[index])
                }
            }
        }
    }
}

#Preview {
    InsightsView()
}
