import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SessionViewModel()
    @State private var profile: UserProfile = UserProfile()
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    profileSection
                    goalsSection
                    achievementsSection
                    aboutSection
                    dangerZone
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 120)
            }
        }
        .task {
            profile = await DatabaseService.shared.loadUserProfile()
        }
        .alert("Reset All Data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await DatabaseService.shared.resetAllData()
                    profile = UserProfile()
                    await viewModel.loadData()
                }
            }
        } message: {
            Text("This will delete all your sessions, achievements, and streak data. This cannot be undone.")
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Profile")

            VStack(spacing: Spacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Text(profile.username.prefix(1).uppercased())
                            .font(.appHeading1)
                            .foregroundStyle(Color.appPrimary)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        TextField("Username", text: $profile.username)
                            .font(.appHeading2)
                            .foregroundStyle(Color.appTextPrimary)
                            .onChange(of: profile.username) { _, _ in
                                saveProfile()
                            }

                        Text("Member since \(profile.createdAt.formatted(.dateTime.month().year()))")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer()
                }
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Goals")

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(Color.appPrimary)
                    Text("Daily Focus Goal")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                    Text("\(profile.dailyGoalMinutes) min")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(Spacing.md)

                Divider()
                    .background(Color.appSurfaceElevated)

                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.appPrimary)
                    Text("Notifications")
                        .font(.appBody)
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                    Toggle("", isOn: $profile.notificationsEnabled)
                        .tint(Color.appPrimary)
                        .onChange(of: profile.notificationsEnabled) { _, _ in
                            saveProfile()
                        }
                }
                .padding(Spacing.md)
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Achievements")

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("About")

            VStack(spacing: 0) {
                aboutRow(icon: "info.circle", label: "Version", value: "1.0.0")
                Divider().background(Color.appSurfaceElevated)
                aboutRow(icon: "heart.fill", label: "Made with", value: "SwiftUI")
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Data")

            Button {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.appError)
                    Text("Reset All Data")
                        .font(.appBody)
                        .foregroundStyle(Color.appError)
                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.appHeading2)
            .foregroundStyle(Color.appTextPrimary)
    }

    private func aboutRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.appPrimary)
            Text(label)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
            Text(value)
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(Spacing.md)
    }

    private func saveProfile() {
        Task {
            await DatabaseService.shared.saveUserProfile(profile)
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? Color.appPrimary.opacity(0.15) : Color.appSurface)
                    .frame(width: 48, height: 48)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundStyle(achievement.isEarned ? Color.appPrimary : Color.appTextTertiary)
                    .opacity(achievement.isEarned ? 1 : 0.4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.appBody)
                    .foregroundStyle(achievement.isEarned ? Color.appTextPrimary : Color.appTextTertiary)

                Text(achievement.description)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            if achievement.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appPrimary)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
