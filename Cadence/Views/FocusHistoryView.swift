import SwiftUI
import Charts

struct DayTotal: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

struct FocusHistoryView: View {
    @State private var sessions: [Session] = []
    @State private var selectedPeriod: TimePeriod = .week
    @State private var isLoading = true

    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(Color.appPrimary)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        periodPicker
                        summaryCards
                        weeklyChart
                        sessionList
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .navigationTitle("Focus History")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSessions()
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            summaryCard(
                title: "Total Hours",
                value: String(format: "%.1f", totalHours),
                icon: "clock.fill",
                color: Color.appPrimary
            )
            summaryCard(
                title: "Sessions",
                value: "\(filteredSessions.count)",
                icon: "flame.fill",
                color: Color.appAccent
            )
            summaryCard(
                title: "Avg Duration",
                value: "\(Int(averageDuration))m",
                icon: "chart.bar.fill",
                color: Color.appSuccess
            )
            summaryCard(
                title: "Best Day",
                value: bestDay,
                icon: "star.fill",
                color: Color.appWarning
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.appDisplay)
                .foregroundStyle(Color.appTextPrimary)

            Text(title)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Daily Focus")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            if #available(iOS 26.0, *) {
                Chart {
                    ForEach(dailyTotals, id: \.date) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Minutes", day.minutes)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.appTextTertiary.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            } else {
                // Fallback
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(dailyTotals.prefix(7)) { day in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appPrimary)
                                .frame(width: 30, height: CGFloat(day.minutes) / 2)
                            Text(dayLabel(day.date))
                                .font(.system(size: 8))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Sessions")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            if filteredSessions.isEmpty {
                emptyState
            } else {
                ForEach(filteredSessions.prefix(10)) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: Session) -> some View {
        HStack(spacing: Spacing.md) {
            // Duration indicator
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "timer")
                    .font(.body)
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Session")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)

                Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.durationMinutes)m")
                    .font(.appBody)
                    .foregroundStyle(Color.appPrimary)

                if session.partnerId != nil {
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 8))
                        Text("Partner")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(Color.appTextTertiary)
            Text("No sessions in this period")
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
    }

    // MARK: - Computed

    private var filteredSessions: [Session] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return sessions.filter { $0.completedAt >= cutoff }
    }

    private var totalHours: Double {
        let totalSeconds: Int = filteredSessions.reduce(0) { $0 + $1.duration }
        return Double(totalSeconds) / 3600.0
    }

    private var averageDuration: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        let totalSeconds: Int = filteredSessions.reduce(0) { $0 + $1.duration }
        return Double(totalSeconds) / Double(filteredSessions.count) / 60.0
    }

    private var bestDay: String {
        let dayTotals = Dictionary(grouping: filteredSessions) {
            Calendar.current.component(.weekday, from: $0.completedAt)
        }
        let best = dayTotals.max { $0.value.count < $1.value.count }
        if let best = best, let day = Weekday(rawValue: best.key) {
            return day.shortName
        }
        return "-"
    }

    private var dailyTotals: [DayTotal] {
        let calendar = Calendar.current
        var result: [DayTotal] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let daySessions = filteredSessions.filter {
                calendar.isDate($0.completedAt, inSameDayAs: startOfDay)
            }
            let totalSeconds: Int = daySessions.reduce(0) { $0 + $1.duration }
            let totalMinutes = totalSeconds / 60
            result.append(DayTotal(date: startOfDay, minutes: totalMinutes))
        }
        return result.reversed()
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func loadSessions() async {
        // Load from FocusService
        try? await Task.sleep(nanoseconds: 300_000_000)
        await MainActor.run {
            sessions = []
            isLoading = false
        }
    }
}

enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

#Preview {
    NavigationStack {
        FocusHistoryView()
    }
    .preferredColorScheme(.dark)
}
