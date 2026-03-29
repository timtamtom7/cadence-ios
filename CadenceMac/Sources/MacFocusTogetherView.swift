import SwiftUI

// MARK: - Focus Together View

/// Shown when you're paired with a focus partner.
/// Displays partner status, combined focus time, check-in, and ambient sound.
struct MacFocusTogetherView: View {
    let partner: FocusPartner
    let mySessionMinutes: Int
    let onCheckIn: (String) -> Void
    let onEnd: () -> Void

    @State private var checkInText = ""
    @State private var partnerSession: PartnerSession?
    @State private var showCheckInSent = false
    @State private var checkInAnimation = false

    // Quick reactions for during break
    private let quickReactions = ["👍", "💪", "🔥", "☕", "🎯"]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Header
                HStack {
                    Text("Focus Together")
                        .font(.appHeading1)
                        .foregroundStyle(Color.appTextPrimary)

                    Spacer()

                    Button {
                        onEnd()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)

                Spacer()

                // Partner status card
                partnerStatusCard

                // Combined focus time
                combinedTimeCard

                // Check-in section
                checkInSection

                // Ambient sound indicator
                ambientSoundCard

                Spacer()

                // Quick reactions (during break)
                if partner.status == .onBreak {
                    quickReactionsSection
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Partner Status Card

    private var partnerStatusCard: some View {
        HStack(spacing: Spacing.md) {
            // Partner avatar
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 64, height: 64)

                Text(String(partner.name.prefix(1)))
                    .font(.appHeading1)
                    .foregroundStyle(Color.appPrimary)

                // Status indicator
                Circle()
                    .fill(statusColor(for: partner.status))
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(Color.appSurface, lineWidth: 2)
                    }
                    .offset(x: 22, y: 22)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(partner.name)
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: partner.status.icon)
                        .font(.system(size: 12))
                    Text(partner.status.displayText)
                        .font(.appCaption)
                }
                .foregroundStyle(statusColor(for: partner.status))

                if let sessionType = partner.currentSessionType {
                    Text("Working on: \(sessionType)")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextTertiary)
                }
            }

            Spacer()

            // Streak
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                    Text("\(partner.streak)")
                        .font(.appHeading2)
                }
                .foregroundStyle(Color.appWarning)
                Text("day streak")
                    .font(.appCaption2)
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }

    private func statusColor(for status: FocusPartner.PartnerStatus) -> Color {
        switch status {
        case .focusing: return Color.appPrimary
        case .onBreak: return Color.appWarning
        case .available: return Color.appSuccess
        }
    }

    // MARK: - Combined Time Card

    private var combinedTimeCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("Combined Focus Time")
                .font(.appCaption)
                .foregroundStyle(Color.appTextTertiary)

            HStack(spacing: Spacing.xl) {
                VStack(spacing: 2) {
                    Text(formattedMyTime)
                        .font(.appHeading1)
                        .foregroundStyle(Color.appPrimary)
                    Text("Your time")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextTertiary)

                VStack(spacing: 2) {
                    Text(formattedPartnerTime)
                        .font(.appHeading1)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("\(partner.name)'s time")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Image(systemName: "equal")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextTertiary)

                VStack(spacing: 2) {
                    Text(formattedCombinedTime)
                        .font(.appHeading1)
                        .foregroundStyle(Color.appAccent)
                    Text("Total")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }

    private var formattedMyTime: String {
        let h = mySessionMinutes / 60
        let m = mySessionMinutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }

    private var formattedPartnerTime: String {
        let minutes = partnerSession?.elapsedMinutes ?? 0
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }

    private var formattedCombinedTime: String {
        let total = mySessionMinutes + (partnerSession?.elapsedMinutes ?? 0)
        let h = total / 60
        let m = total % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }

    // MARK: - Check-In Section

    private var checkInSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Send a Check-In")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.sm) {
                TextField("e.g. Almost done! 🎯", text: $checkInText)
                    .font(.appBody)
                    .padding(Spacing.sm)
                    .background(Color.appSurfaceElevated)
                    .cornerRadius(8)
                    .foregroundStyle(Color.appTextPrimary)

                Button {
                    guard !checkInText.isEmpty else { return }
                    onCheckIn(checkInText)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCheckInSent = true
                        checkInAnimation = true
                    }
                    checkInText = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCheckInSent = false
                        checkInAnimation = false
                    }
                } label: {
                    Image(systemName: showCheckInSent ? "checkmark.circle.fill" : "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(showCheckInSent ? Color.appSuccess : Color.appBackground)
                        .frame(width: 40, height: 40)
                        .background(showCheckInSent ? Color.appSuccess.opacity(0.2) : Color.appPrimary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .scaleEffect(checkInAnimation ? 1.2 : 1.0)
            }

            Text("Your partner will see this message during their next break")
                .font(.appCaption)
                .foregroundStyle(Color.appTextTertiary)
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }

    // MARK: - Ambient Sound Card

    private var ambientSoundCard: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundStyle(Color.appPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Shared Ambient Sound")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)
                Text("You both hear the same focus soundtrack")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextTertiary)
            }

            Spacer()

            HStack(spacing: Spacing.xxs) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appPrimary)
                        .frame(width: 3, height: CGFloat([12, 18, 14, 20][i]))
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .cornerRadius(12)
    }

    // MARK: - Quick Reactions

    private var quickReactionsSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("\(partner.name) is on break — send a reaction!")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: Spacing.md) {
                ForEach(quickReactions, id: \.self) { reaction in
                    Button {
                        onCheckIn(reaction)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            checkInAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            checkInAnimation = false
                        }
                    } label: {
                        Text(reaction)
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(Color.appSurfaceElevated)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(checkInAnimation ? 1.3 : 1.0)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.appPrimary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    MacFocusTogetherView(
        partner: FocusPartner(
            id: UUID(),
            name: "Taylor S",
            goal: "Deep Work & Coding",
            streak: 14,
            status: .focusing,
            currentSessionType: "Coding",
            joinedAt: Date()
        ),
        mySessionMinutes: 25,
        onCheckIn: { _ in },
        onEnd: {}
    )
    .frame(width: 600, height: 700)
}
