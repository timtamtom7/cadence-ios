import SwiftUI

struct FocusTimerView: View {
    @State private var viewModel = SessionViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if viewModel.focusService.isRunning || viewModel.focusService.isCompleted {
                activeSessionView
            } else {
                sessionSetupView
            }
        }
        .sheet(isPresented: $viewModel.showSessionComplete) {
            if let session = viewModel.focusService.lastCompletedSession {
                SessionCompleteView(
                    session: session,
                    streak: viewModel.currentStreak,
                    onDismiss: {
                        viewModel.showSessionComplete = false
                        viewModel.focusService.stop()
                    }
                )
            }
        }
        .alert("Cancel Session?", isPresented: $viewModel.showCancelConfirmation) {
            Button("Keep Going", role: .cancel) {}
            Button("Cancel", role: .destructive) {
                viewModel.cancelSession()
            }
        } message: {
            Text("Your progress won't be saved.")
        }
    }

    // MARK: - Session Setup

    private var sessionSetupView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                headerSection

                durationPickerSection

                soundPreviewSection

                partnerRadarSection

                startButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 100)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("Focus")
                .font(.appDisplay)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.lg) {
                statPill(icon: "flame.fill", value: "\(viewModel.currentStreak)", label: "Streak")
                statPill(icon: "clock.fill", value: "\(viewModel.todayMinutes)m", label: "Today")
            }
        }
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
        .clipShape(Capsule())
    }

    private var durationPickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Duration")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.durationPresets, id: \.self) { duration in
                    durationButton(duration)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func durationButton(_ duration: Int) -> some View {
        let isSelected = viewModel.selectedDuration == duration
        return Button {
            viewModel.selectedDuration = duration
        } label: {
            Text("\(duration)")
                .font(.appHeading2)
                .foregroundStyle(isSelected ? Color.appBackground : Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.appPrimary : Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var soundPreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Ambient Sounds")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            Text("\(viewModel.selectedSounds.count) selected")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Sound.allSounds) { sound in
                        SoundChip(
                            sound: sound,
                            isSelected: viewModel.selectedSounds.contains(sound.id),
                            onTap: { viewModel.toggleSound(sound.id) }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var partnerRadarSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Focus Partners")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.partnerRadar) { partner in
                        PartnerChip(
                            partner: partner,
                            isSelected: viewModel.selectedPartner?.id == partner.id,
                            onTap: {
                                if viewModel.selectedPartner?.id == partner.id {
                                    viewModel.selectPartner(nil)
                                } else {
                                    viewModel.selectPartner(partner)
                                }
                            }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startButton: some View {
        Button {
            viewModel.startSession()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Focus")
            }
            .font(.appHeading2)
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Active Session

    private var activeSessionView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            BreathingOrb(
                progress: viewModel.focusService.progress,
                timeString: viewModel.focusService.formattedTime,
                isPaused: viewModel.focusService.isPaused
            )

            VStack(spacing: Spacing.xs) {
                Text(viewModel.focusService.isPaused ? "Paused" : "Focusing")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextSecondary)

                Text(viewModel.focusService.formattedDuration)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            Spacer()

            HStack(spacing: Spacing.xl) {
                Button {
                    viewModel.showCancelConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(Color.appError)
                        .frame(width: 60, height: 60)
                        .background(Color.appSurface)
                        .clipShape(Circle())
                }

                Button {
                    if viewModel.focusService.isPaused {
                        viewModel.resumeSession()
                    } else {
                        viewModel.pauseSession()
                    }
                } label: {
                    Image(systemName: viewModel.focusService.isPaused ? "play.fill" : "pause.fill")
                        .font(.title)
                        .foregroundStyle(Color.appBackground)
                        .frame(width: 80, height: 80)
                        .background(Color.appPrimary)
                        .clipShape(Circle())
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .onChange(of: viewModel.focusService.isCompleted) { _, completed in
            if completed {
                viewModel.completeSession()
            }
        }
    }
}

// MARK: - Sound Chip

struct SoundChip: View {
    let sound: Sound
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: sound.icon)
                Text(sound.name)
            }
            .font(.appCaption)
            .foregroundStyle(isSelected ? Color.appAccent : Color.appTextSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                isSelected ? Color.appAccent.opacity(0.15) : Color.appSurface,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.appAccent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Partner Chip

struct PartnerChip: View {
    let partner: Partner
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color(hex: partner.status.color).opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text(partner.name.prefix(1))
                        .font(.appHeading2)
                        .foregroundStyle(Color(hex: partner.status.color))
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                )

                Text(partner.name.components(separatedBy: " ").first ?? "")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextPrimary)

                Text(partner.status.displayText)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: partner.status.color))
            }
            .padding(Spacing.sm)
            .background(isSelected ? Color.appSurfaceElevated : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    FocusTimerView()
        .preferredColorScheme(.dark)
}
