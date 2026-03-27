import SwiftUI

struct FocusTimerView: View {
    @State private var viewModel = SessionViewModel()
    @State private var predictionService = FocusPredictionService()

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
                    totalHours: viewModel.totalHours,
                    totalSessions: viewModel.totalSessions,
                    onDismiss: {
                        viewModel.showSessionComplete = false
                        viewModel.focusService.stop()
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showPartnerDisconnected) {
            PartnerDisconnectedSheet(
                partnerName: viewModel.matchingService.currentMatch?.partnerName ?? "Partner",
                onReMatch: { viewModel.reMatchOrContinueSolo(rematch: true) },
                onContinueSolo: { viewModel.reMatchOrContinueSolo(rematch: false) }
            )
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
                
                aiSuggestionBanner

                focusModeSection

                durationPickerSection

                soundPreviewSection

                partnerMatchingSection

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
    
    // MARK: - AI Suggestion Banner (Cadence 2.0)
    
    private var aiSuggestionBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "brain")
                .foregroundStyle(Color.appAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Suggestion")
                    .font(.appCaption)
                    .foregroundStyle(Color.appAccent)
                Text("Based on your patterns, try a \(viewModel.totalSessions > 0 ? 50 : 45)-min session")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.appAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
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

    // MARK: - Focus Mode

    private var focusModeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Focus Mode")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(FocusMode.allCases) { mode in
                        FocusModeCard(
                            mode: mode,
                            isSelected: viewModel.selectedFocusMode == mode,
                            onTap: { viewModel.selectFocusMode(mode) }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Duration Picker

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
            Theme.hapticSelection()
            viewModel.selectedDuration = duration
        } label: {
            Text("\(duration)")
                .font(.appHeading2)
                .foregroundStyle(isSelected ? Color.appBackground : Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.appPrimary : Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }

    // MARK: - Sound Preview

    private var soundPreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Ambient Sounds")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                if viewModel.selectedSounds.isEmpty {
                    Text("Silent mode")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextTertiary)
                } else {
                    Text("\(viewModel.selectedSounds.count) selected")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    // Silent option
                    SoundChip(
                        sound: Sound(id: "silent", name: "Silent", icon: "speaker.slash.fill", category: .ambient),
                        isSelected: viewModel.selectedSounds.isEmpty,
                        onTap: { viewModel.selectedSounds.removeAll() }
                    )

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

    // MARK: - Partner Matching

    private var partnerMatchingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Focus Partners")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                if viewModel.selectedPartner != nil {
                    Text("Selected")
                        .font(.appCaption)
                        .foregroundStyle(Color.appPrimary)
                }
            }

            if viewModel.matchingService.isSearching {
                matchingProgressView
            } else {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var matchingProgressView: some View {
        HStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.appPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Finding a partner...")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Matching by \(viewModel.selectedFocusMode.rawValue) mode")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Button {
                Theme.haptic(.light)
                viewModel.matchingService.stopSearching()
            } label: {
                Text("Cancel")
                    .font(.appCaption)
                    .foregroundStyle(Color.appError)
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Start Button

    private var startButton: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Theme.hapticMedium()
                Task {
                    await viewModel.startMatchingSession()
                }
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Focus")
                }
            }
            .buttonStyle(AxiomPrimaryButtonStyle())
            .disabled(viewModel.matchingService.isSearching)

            if let partner = viewModel.selectedPartner {
                Text("You'll focus with \(partner.name)")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            } else if viewModel.selectedSounds.isEmpty {
                Text("Silent session — no ambient sounds")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Active Session

    private var activeSessionView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            if let match = viewModel.matchingService.currentMatch {
                partnerSessionBadge(name: match.partnerName, mode: match.focusMode)
            }

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
                    Theme.hapticMedium()
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
                    Theme.hapticSoft()
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

    private func partnerSessionBadge(name: String, mode: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "person.2.fill")
                .font(.caption)
            Text("Focusing with \(name)")
                .font(.appCaption)
            Text("·")
            Text(mode)
                .font(.appCaption)
        }
        .foregroundStyle(Color.appPrimary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.appPrimary.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Focus Mode Card

struct FocusModeCard: View {
    let mode: FocusMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            Theme.hapticSelection()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextSecondary)

                Text(mode.rawValue)
                    .font(.appBody)
                    .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)

                Text(mode.description)
                    .font(.appCaption2)
                    .foregroundStyle(Color.appTextTertiary)
            }
            .frame(width: 100)
            .padding(Spacing.sm)
            .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.appPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Partner Disconnected Sheet

struct PartnerDisconnectedSheet: View {
    let partnerName: String
    let onReMatch: () -> Void
    let onContinueSolo: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.appError.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appError)
            }

            Text("\(partnerName) left the session")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)

            Text("Your partner disconnected. Would you like to find a new partner or continue solo?")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    Theme.hapticMedium()
                    dismiss()
                    onReMatch()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Find New Partner")
                    }
                }
                .buttonStyle(AxiomPrimaryButtonStyle())

                Button {
                    Theme.haptic(.light)
                    dismiss()
                    onContinueSolo()
                } label: {
                    Text("Continue Solo")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.appBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Sound Chip

struct SoundChip: View {
    let sound: Sound
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            Theme.hapticSelection()
            onTap()
        } label: {
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
        Button {
            Theme.hapticSelection()
            onTap()
        } label: {
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
                    .font(.appCaption2)
                    .foregroundStyle(Color(hex: partner.status.color))
            }
            .padding(Spacing.sm)
            .background(isSelected ? Color.appSurfaceElevated : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
}

#Preview {
    FocusTimerView()
        .preferredColorScheme(.dark)
}
