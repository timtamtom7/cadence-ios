import SwiftUI

struct MacFocusSessionView: View {
    @State private var focusService = FocusService()
    @State private var selectedDuration: Int = 25
    @State private var selectedSoundId: String? = nil
    @State private var showSessionComplete = false

    private let durations = [15, 25, 45, 60, 90]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if focusService.isRunning || focusService.isPaused {
                activeSessionView
            } else {
                setupView
            }
        }
        .sheet(isPresented: $showSessionComplete) {
            MacSessionCompleteView(session: focusService.lastCompletedSession) {
                showSessionComplete = false
                focusService.stop()
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Breathing orb preview
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appAccent, Color.appPrimary, Color.appPrimary.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 160, height: 160)
                    .opacity(0.4)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appAccent, Color.appPrimary],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Text("00:00")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.appBackground)
            }

            VStack(spacing: Spacing.md) {
                Text("Ready to focus?")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Choose your session length")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }

            // Duration picker
            HStack(spacing: Spacing.sm) {
                ForEach(durations, id: \.self) { duration in
                    DurationButton(
                        minutes: duration,
                        isSelected: selectedDuration == duration
                    ) {
                        selectedDuration = duration
                    }
                }
            }

            // Sound selector
            HStack(spacing: Spacing.sm) {
                Text("Sound:")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)

                Picker("", selection: $selectedSoundId) {
                    Text("None").tag(nil as String?)
                    ForEach(Sound.allSounds) { sound in
                        Label(sound.name, systemImage: sound.icon)
                            .tag(sound.id as String?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }

            // Start button
            Button {
                focusService.start(durationMinutes: selectedDuration, soundIds: selectedSoundId.map { [$0] } ?? [])
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "play.fill")
                    Text("Start Focus Session")
                }
                .font(.appHeading2)
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.appPrimary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start Focus Session")
            .accessibilityHint("Begin a \(selectedDuration) minute focus session")

            Spacer()
        }
        .padding(Spacing.lg)
    }

    // MARK: - Active Session View

    private var activeSessionView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Breathing orb with timer
            MacBreathingOrb(
                progress: focusService.progress,
                timeString: focusService.formattedTime,
                isPaused: focusService.isPaused
            )

            // Breathing prompt
            if !focusService.isPaused {
                Text("Breathe in... breathe out...")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextTertiary)
                    .italic()
                    .transition(.opacity)
            }

            // Session info
            HStack(spacing: Spacing.lg) {
                VStack {
                    Text(focusService.formattedDuration)
                        .font(.appHeading2)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Duration")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextTertiary)
                }

                if let session = focusService.lastCompletedSession {
                    VStack {
                        Text("\(session.focusScore)")
                            .font(.appHeading2)
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Focus Score")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }
            }

            Spacer()

            // Controls
            HStack(spacing: Spacing.md) {
                if focusService.isPaused {
                    Button {
                        focusService.resume()
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(.appBody)
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.appPrimary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Resume session")
                    .accessibilityHint("Continue your focus session")
                } else {
                    Button {
                        focusService.pause()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.appBody)
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.appSurfaceElevated)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pause session")
                    .accessibilityHint("Pause your focus session")
                }

                Button {
                    focusService.stop()
                } label: {
                    Label("End Session", systemImage: "stop.fill")
                        .font(.appBody)
                        .foregroundStyle(Color.appError)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.appError.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("End session")
                .accessibilityHint("Stop and end your focus session")
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .onChange(of: focusService.isCompleted) { _, completed in
            if completed {
                showSessionComplete = true
                // Cancel streak reminder since user completed a session
                MacNotificationService.shared.cancelStreakReminder()
                // Schedule next streak reminder for tomorrow if needed
                Task {
                    let profile = await DatabaseService.shared.loadUserProfile()
                    await MacNotificationService.shared.scheduleStreakReminderIfNeeded(username: profile.username)
                }
            }
        }
    }
}

// MARK: - Duration Button

struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.appHeading2)
                Text("min")
                    .font(.appCaption)
            }
            .foregroundStyle(isSelected ? Color.appBackground : Color.appTextSecondary)
            .frame(width: 56, height: 56)
            .background(isSelected ? Color.appPrimary : Color.appSurfaceElevated)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes")
        .accessibilityHint("Select \(minutes) minute session duration")
    }
}

// MARK: - Breathing Orb

struct MacBreathingOrb: View {
    let progress: Double
    let timeString: String
    let isPaused: Bool

    @State private var breathePhase = false

    private let breatheAnimation = Animation
        .easeInOut(duration: 4.0)
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
                    .frame(width: 220 + CGFloat(index) * 30, height: 220 + CGFloat(index) * 30)
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

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appAccent, Color.appPrimary, Color.appPrimary.opacity(0.8)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.appBackground)
                        .opacity(isPaused ? 0.6 : 1.0)

                    if isPaused {
                        Text("PAUSED")
                            .font(.system(size: 10, weight: .semibold))
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
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                withAnimation(.easeOut(duration: 0.3)) {
                    breathePhase = false
                }
            } else {
                withAnimation(breatheAnimation) {
                    breathePhase = true
                }
            }
        }
    }
}

// MARK: - Session Complete Sheet

struct MacSessionCompleteView: View {
    let session: Session?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(spacing: Spacing.xs) {
                Text("Session Complete!")
                    .font(.appHeading1)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Great work staying focused")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }

            if let session = session {
                HStack(spacing: Spacing.xl) {
                    StatPill(label: "Duration", value: "\(session.durationMinutes) min")
                    StatPill(label: "Focus Score", value: "\(session.focusScore)")
                }
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appPrimary)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done")
            .accessibilityHint("Close the session complete view")
        }
        .padding(Spacing.xl)
        .frame(width: 360, height: 400)
        .background(Color.appSurface)
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appHeading2)
                .foregroundStyle(Color.appPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextTertiary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurfaceElevated)
        .cornerRadius(8)
    }
}

#Preview {
    MacFocusSessionView()
        .frame(width: 700, height: 600)
}
