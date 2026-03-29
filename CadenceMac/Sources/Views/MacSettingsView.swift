import SwiftUI
import UniformTypeIdentifiers

struct MacSettingsView: View {
    @State private var profile: UserProfile = UserProfile()
    @State private var defaultDuration: Int = 25
    @State private var notificationsEnabled: Bool = true
    @State private var showExportSheet: Bool = false
    @State private var exportMessage: String = ""

    private let durationOptions = [15, 25, 45, 60, 90]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.appHeading1)
                            .foregroundStyle(Color.appTextPrimary)
                        Spacer()
                    }

                    // Profile Section
                    SettingsSection(title: "Profile") {
                        VStack(spacing: Spacing.md) {
                            SettingsRow {
                                Text("Username")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                TextField("Username", text: $profile.username)
                                    .textFieldStyle(.plain)
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 200)
                            }

                            SettingsDivider()

                            SettingsRow {
                                Text("Daily Focus Goal")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                Picker("", selection: $profile.dailyGoalMinutes) {
                                    ForEach([30, 60, 90, 120, 180], id: \.self) { minutes in
                                        Text("\(minutes) min").tag(minutes)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                        }
                    }

                    // Focus Section
                    SettingsSection(title: "Focus") {
                        VStack(spacing: Spacing.md) {
                            SettingsRow {
                                Text("Default Session Duration")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                Picker("", selection: $defaultDuration) {
                                    ForEach(durationOptions, id: \.self) { minutes in
                                        Text("\(minutes) min").tag(minutes)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                        }
                    }

                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        VStack(spacing: Spacing.md) {
                            SettingsRow {
                                Text("Session Reminders")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                Toggle("", isOn: $notificationsEnabled)
                                    .toggleStyle(.switch)
                                    .tint(Color.appPrimary)
                            }
                        }
                    }

                    // Sound Section
                    SettingsSection(title: "Sound") {
                        VStack(spacing: Spacing.md) {
                            ForEach(Sound.allSounds) { sound in
                                SettingsRow {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: sound.icon)
                                            .foregroundStyle(Color.appPrimary)
                                            .frame(width: 20)
                                        Text(sound.name)
                                            .font(.appBody)
                                            .foregroundStyle(Color.appTextSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }

                    // Data Section
                    SettingsSection(title: "Data") {
                        VStack(spacing: Spacing.md) {
                            SettingsRow {
                                Text("Export Data")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                Button {
                                    exportData()
                                } label: {
                                    Text("Export JSON")
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appPrimary)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.xxs)
                                        .background(Color.appPrimary.opacity(0.15))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }

                            SettingsDivider()

                            SettingsRow {
                                Text("Reset All Data")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appError)
                                Spacer()
                                Button {
                                    resetData()
                                } label: {
                                    Text("Reset")
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appError)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.xxs)
                                        .background(Color.appError.opacity(0.15))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // About Section
                    SettingsSection(title: "About") {
                        VStack(spacing: Spacing.md) {
                            SettingsRow {
                                Text("Version")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                Text("1.0.0")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextTertiary)
                            }

                            SettingsDivider()

                            SettingsRow {
                                Text("Made with")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextSecondary)
                                Spacer()
                                HStack(spacing: Spacing.xxs) {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Color.appError)
                                        .font(.system(size: 12))
                                    Text("for focus")
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appTextTertiary)
                                }
                            }
                        }
                    }

                    if !exportMessage.isEmpty {
                        Text(exportMessage)
                            .font(.appCaption)
                            .foregroundStyle(Color.appPrimary)
                            .padding(Spacing.sm)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .task {
            await loadProfile()
        }
        .onChange(of: profile) { _, newProfile in
            Task {
                await DatabaseService.shared.saveUserProfile(newProfile)
            }
        }
    }

    private func loadProfile() async {
        profile = await DatabaseService.shared.loadUserProfile()
    }

    private func exportData() {
        Task {
            let sessions = await DatabaseService.shared.loadSessions()
            let achievements = await DatabaseService.shared.loadAchievements()
            let streak = await DatabaseService.shared.loadStreak()

            let export = ExportData(
                sessions: sessions,
                achievements: achievements,
                streak: streak,
                exportedAt: Date()
            )

            if let data = try? JSONEncoder().encode(export),
               let json = String(data: data, encoding: .utf8) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cadence_export.json")
                try? json.write(to: tempURL, atomically: true, encoding: .utf8)

                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "cadence_export.json"
                panel.canCreateDirectories = true

                if panel.runModal() == .OK, let url = panel.url {
                    try? FileManager.default.copyItem(at: tempURL, to: url)
                    exportMessage = "Data exported successfully!"
                } else {
                    exportMessage = "Export cancelled"
                }
            } else {
                exportMessage = "Export failed"
            }

            // Clear message after delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            exportMessage = ""
        }
    }

    private func resetData() {
        Task {
            await DatabaseService.shared.resetAllData()
            exportMessage = "All data has been reset"
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            exportMessage = ""
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            VStack(spacing: 0) {
                content
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.appSurfaceElevated)
    }
}

// MARK: - Export Data

struct ExportData: Codable {
    let sessions: [Session]
    let achievements: [Achievement]
    let streak: StreakData
    let exportedAt: Date
}

#Preview {
    MacSettingsView()
        .frame(width: 700, height: 700)
}
