import SwiftUI

struct ContentView: View {
    @State private var viewModel = MacSessionViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                headerView

                Spacer()

                focusOrbView

                Spacer()

                timerDisplayView

                actionButton

                statsRow
            }
            .padding(Spacing.lg)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startFocusSession)) { _ in
            viewModel.startSession(duration: viewModel.selectedDuration)
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopFocusSession)) { _ in
            viewModel.stopSession()
        }
        .onAppear {
            viewModel.loadStats()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Cadence")
                    .font(.appHeading1)
                    .foregroundColor(.appTextPrimary)

                Text(viewModel.isRunning ? "Focusing..." : "Ready to focus")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 3)
                )
        }
    }

    private var statusColor: Color {
        viewModel.isRunning ? .appPrimary : .appTextTertiary
    }

    // MARK: - Focus Orb

    private var focusOrbView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: Color.appPrimary.opacity(0.5), radius: 20, x: 0, y: 0)

            if viewModel.isRunning {
                Circle()
                    .stroke(Color.appPrimary.opacity(0.5), lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(viewModel.breathingScale)
                    .opacity(viewModel.breathingOpacity)
            }
        }
        .onTapGesture {
            if viewModel.isRunning {
                viewModel.togglePause()
            }
        }
    }

    // MARK: - Timer Display

    private var timerDisplayView: some View {
        VStack(spacing: Spacing.xs) {
            Text(viewModel.timeDisplay)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.appTextPrimary)

            if viewModel.isRunning {
                Text(viewModel.pauseState == .paused ? "Paused" : "Stay focused")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            } else {
                Text("Tap orb to start \(viewModel.selectedDuration)min session")
                    .font(.appCaption)
                    .foregroundColor(.appTextTertiary)
            }
        }
    }

    // MARK: - Duration Picker

    @ViewBuilder
    private var durationPickerView: some View {
        HStack(spacing: Spacing.sm) {
            ForEach([15, 25, 45, 60], id: \.self) { minutes in
                Button {
                    viewModel.selectedDuration = minutes
                } label: {
                    Text("\(minutes)m")
                        .font(.appCaption)
                        .foregroundColor(viewModel.selectedDuration == minutes ? .appBackground : .appTextSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedDuration == minutes ? Color.appPrimary : Color.appSurface)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRunning)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            if viewModel.isRunning {
                viewModel.stopSession()
            } else {
                viewModel.startSession(duration: viewModel.selectedDuration)
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                Text(viewModel.isRunning ? "End Session" : "Start Focus")
            }
            .font(.appBody)
            .foregroundColor(viewModel.isRunning ? .appBackground : .appTextPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isRunning ? Color.appError : Color.appPrimary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Spacing.xl) {
            statItem(value: "\(viewModel.currentStreak)", label: "Day Streak", icon: "flame.fill")
            statItem(value: String(format: "%.1f", viewModel.totalHours), label: "Total Hours", icon: "clock.fill")
            statItem(value: "\(viewModel.totalSessions)", label: "Sessions", icon: "checkmark.circle.fill")
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
        )
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)

            Text(value)
                .font(.appHeading2)
                .foregroundColor(.appTextPrimary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .frame(width: 400, height: 500)
        .preferredColorScheme(.dark)
}
