import SwiftUI
import Charts

struct DayTotal: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

/// Focus history view with real session data and filtering
struct FocusHistoryView: View {
    @State private var sessions: [Session] = []
    @State private var sessionNotes: [UUID: SessionNote] = [:]
    @State private var selectedPeriod: TimePeriod = .week
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showFilters = false
    @State private var filterMinScore: Int = 0
    @State private var filterSoundId: String? = nil
    @State private var filterHasPartner: Bool? = nil
    @State private var searchText: String = ""

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
            } else if let error = errorMessage {
                errorView(error)
            } else {
                historyContent
            }
        }
        .navigationTitle("Focus History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptic(.light)
                    showFilters.toggle()
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(hasActiveFilters ? Color.appPrimary : Color.appTextSecondary)
                }
                .accessibilityLabel("Filter sessions")
            }
        }
        .sheet(isPresented: $showFilters) {
            filterSheet
        }
        .task {
            await loadSessions()
        }
    }

    // MARK: - Main Content

    private var historyContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                periodPicker
                    .padding(.horizontal, Spacing.md)

                if filteredSessions.isEmpty {
                    emptyHistoryView
                } else {
                    summaryCards
                        .padding(.horizontal, Spacing.md)

                    weeklyChart
                        .padding(.horizontal, Spacing.md)

                    if hasActiveFilters {
                        activeFiltersBar
                            .padding(.horizontal, Spacing.md)
                    }

                    sessionList
                        .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards

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
                title: "Avg Score",
                value: String(format: "%.0f", averageFocusScore),
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
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Daily Focus")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            if #available(iOS 26.0, *) {
                Chart {
                    ForEach(dailyTotals) { day in
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
                // Fallback for older iOS
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
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Active Filters Bar

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                if filterMinScore > 0 {
                    filterChip(label: "Score ≥ \(filterMinScore)", active: true) {
                        filterMinScore = 0
                    }
                }
                if let sound = filterSoundId {
                    if let s = Sound.allSounds.first(where: { $0.id == sound }) {
                        filterChip(label: s.name, active: true) {
                            filterSoundId = nil
                        }
                    }
                }
                if filterHasPartner != nil {
                    filterChip(label: "Partner", active: true) {
                        filterHasPartner = nil
                    }
                }
                Button {
                    Theme.haptic(.light)
                    filterMinScore = 0
                    filterSoundId = nil
                    filterHasPartner = nil
                    searchText = ""
                } label: {
                    Text("Clear All")
                        .font(.appCaption)
                        .foregroundStyle(Color.appError)
                }
            }
        }
    }

    private func filterChip(label: String, active: Bool, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.appCaption)
            Button {
                Theme.haptic(.light)
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
            }
        }
        .foregroundStyle(Color.appPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.appPrimary.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Session List

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Recent Sessions")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text("\(filteredSessions.count) sessions")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            ForEach(filteredSessions.prefix(20)) { session in
                sessionRow(session)
            }

            if filteredSessions.count > 20 {
                Text("Showing 20 of \(filteredSessions.count) sessions")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.sm)
            }
        }
    }

    private func sessionRow(_ session: Session) -> some View {
        let note = sessionNotes[session.id]

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Duration indicator
                ZStack {
                    Circle()
                        .fill(scoreColor(for: session.focusScore).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "timer")
                        .font(.body)
                        .foregroundStyle(scoreColor(for: session.focusScore))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.appBody)
                        .foregroundStyle(Color.appTextPrimary)

                    HStack(spacing: Spacing.xs) {
                        // Duration
                        Text("\(session.durationMinutes)m")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)

                        // Sound
                        if !session.soundIds.isEmpty {
                            if let firstSound = session.soundIds.first,
                               let sound = Sound.allSounds.first(where: { $0.id == firstSound }) {
                                HStack(spacing: 2) {
                                    Image(systemName: sound.icon)
                                        .font(.appCaption2)
                                    Text(sound.name)
                                        .font(.appCaption2)
                                }
                                .foregroundStyle(Color.appTextTertiary)
                            }
                        }

                        // Partner indicator
                        if session.partnerId != nil {
                            HStack(spacing: 2) {
                                Image(systemName: "person.2.fill")
                                    .font(.appCaption2)
                                Text("Partner")
                                    .font(.appCaption2)
                            }
                            .foregroundStyle(Color.appAccent)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text("\(session.focusScore)")
                            .font(.appCaption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(scoreColor(for: session.focusScore))

                    if note != nil || !session.soundIds.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 9))
                            if let text = noteText(note) {
                                Text(text)
                                    .font(.system(size: 9))
                            }
                        }
                        .foregroundStyle(Color.appTextTertiary)
                        .lineLimit(1)
                    }
                }
            }

            // Tags row
            if let note = note, !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(note.tags, id: \.self) { tag in
                            if let sessionTag = SessionTag(rawValue: tag) {
                                HStack(spacing: 2) {
                                    Image(systemName: sessionTag.icon)
                                        .font(.system(size: 8))
                                    Text(tag)
                                        .font(.system(size: 9))
                                }
                                .foregroundStyle(Color.appPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appPrimary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Note preview
            if let note = note, !note.notes.isEmpty {
                Text(note.notes)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: session, note: note))
    }

    private func noteText(_ note: SessionNote?) -> String? {
        guard let note = note else { return nil }
        if !note.notes.isEmpty { return "Note" }
        if !note.tags.isEmpty { return "\(note.tags.count) tags" }
        return nil
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return Color.appAccent
        case 60..<80: return Color.appPrimary
        case 40..<60: return Color.appWarning
        default: return Color.appError
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func accessibilityLabel(for session: Session, note: SessionNote?) -> String {
        var label = "\(session.durationMinutes) minute focus session, \(session.completedAt.formatted(date: .abbreviated, time: .shortened)), focus score \(session.focusScore)"
        if session.partnerId != nil { label += ", with partner" }
        if let note = note {
            if !note.tags.isEmpty { label += ", tags: \(note.tags.joined(separator: ", "))" }
            if !note.notes.isEmpty { label += ", notes: \(note.notes)" }
        }
        return label
    }

    // MARK: - Empty View

    private var emptyHistoryView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appPrimary.opacity(0.8))
            }

            VStack(spacing: Spacing.xs) {
                Text("No Sessions Found")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)

                if hasActiveFilters {
                    Text("Try adjusting your filters to see more sessions.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Theme.hapticMedium()
                        clearFilters()
                    } label: {
                        Text("Clear Filters")
                    }
                    .buttonStyle(AxiomPrimaryButtonStyle())
                } else {
                    Text("Complete your first focus session to see your history here.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.appError)
            Text("Failed to Load History")
                .font(.appHeading1)
                .foregroundStyle(Color.appTextPrimary)
            Text(message)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
            Button {
                Theme.hapticMedium()
                Task { await loadSessions() }
            } label: {
                Text("Try Again")
            }
            .buttonStyle(AxiomPrimaryButtonStyle())
            Spacer()
        }
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Minimum score filter
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Minimum Focus Score")
                                .font(.appHeading2)
                                .foregroundStyle(Color.appTextPrimary)

                            HStack(spacing: Spacing.sm) {
                                ForEach([0, 50, 70, 85], id: \.self) { score in
                                    Button {
                                        filterMinScore = score
                                    } label: {
                                        Text(score == 0 ? "Any" : "\(score)+")
                                            .font(.appCaption)
                                            .foregroundStyle(filterMinScore == score ? Color.appBackground : Color.appTextSecondary)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, Spacing.xs)
                                            .background(filterMinScore == score ? Color.appPrimary : Color.appSurface)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

                        // Sound filter
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Sound")
                                .font(.appHeading2)
                                .foregroundStyle(Color.appTextPrimary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    soundFilterChip(sound: nil, label: "Any")
                                    ForEach(Sound.allSounds) { sound in
                                        soundFilterChip(sound: sound, label: sound.name)
                                    }
                                }
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

                        // Partner filter
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Partner Session")
                                .font(.appHeading2)
                                .foregroundStyle(Color.appTextPrimary)

                            HStack(spacing: Spacing.sm) {
                                partnerFilterChip(value: nil, label: "Any")
                                partnerFilterChip(value: true, label: "Partner Only")
                                partnerFilterChip(value: false, label: "Solo Only")
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

                        // Clear filters
                        if hasActiveFilters {
                            Button {
                                Theme.hapticNotification(.warning)
                                clearFilters()
                            } label: {
                                Text("Clear All Filters")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appError)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Filter Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Theme.haptic(.light)
                        showFilters = false
                    } label: {
                        Text("Done")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func soundFilterChip(sound: Sound?, label: String) -> some View {
        Button {
            Theme.hapticSelection()
            filterSoundId = sound?.id
        } label: {
            HStack(spacing: 4) {
                if let sound = sound {
                    Image(systemName: sound.icon)
                        .font(.appCaption)
                }
                Text(label)
                    .font(.appCaption)
            }
            .foregroundStyle(filterSoundId == sound?.id ? Color.appBackground : Color.appTextSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(filterSoundId == sound?.id ? Color.appPrimary : Color.backgroundElevated2)
            .clipShape(Capsule())
        }
    }

    private func partnerFilterChip(value: Bool?, label: String) -> some View {
        Button {
            Theme.hapticSelection()
            filterHasPartner = value
        } label: {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(filterHasPartner == value ? Color.appBackground : Color.appTextSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(filterHasPartner == value ? Color.appPrimary : Color.backgroundElevated2)
                .clipShape(Capsule())
        }
    }

    // MARK: - Computed

    private var hasActiveFilters: Bool {
        filterMinScore > 0 || filterSoundId != nil || filterHasPartner != nil
    }

    private func clearFilters() {
        filterMinScore = 0
        filterSoundId = nil
        filterHasPartner = nil
        searchText = ""
    }

    private var filteredSessions: [Session] {
        sessions.filter { session in
            // Score filter
            if session.focusScore < filterMinScore { return false }
            // Sound filter
            if let soundId = filterSoundId, !session.soundIds.contains(soundId) { return false }
            // Partner filter
            if let hasPartner = filterHasPartner {
                if hasPartner && session.partnerId == nil { return false }
                if !hasPartner && session.partnerId != nil { return false }
            }
            return true
        }
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

    private var averageFocusScore: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        let total: Int = filteredSessions.reduce(0) { $0 + $1.focusScore }
        return Double(total) / Double(filteredSessions.count)
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

    // MARK: - Data Loading

    private func loadSessions() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let allSessions = await DatabaseService.shared.loadSessions()
            let allNotes = await DatabaseService.shared.loadAllSessionNotes()
            let notesMap = Dictionary(uniqueKeysWithValues: allNotes.map { ($0.sessionId, $0) })

            await MainActor.run {
                sessions = allSessions
                sessionNotes = notesMap
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        FocusHistoryView()
    }
    .preferredColorScheme(.dark)
}
