import SwiftUI

struct SoundPickerView: View {
    @State private var soundService = SoundService.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)

                ScrollView {
                    LazyVStack(spacing: Spacing.lg) {
                        // Active sounds section
                        if !soundService.activeSounds.isEmpty {
                            activeSoundsSection
                        }

                        // Silent option
                        silentOptionSection

                        // All sounds by category
                        ForEach(SoundCategory.allCases, id: \.self) { category in
                            soundCategorySection(category)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text("Sounds")
                    .font(.appDisplay)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                if soundService.activeSoundCount > 0 {
                    Text("\(soundService.activeSoundCount) active")
                        .font(.appCaption)
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.appPrimary.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("Silent")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextTertiary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.appSurface)
                        .clipShape(Capsule())
                }
            }

            Text("Mix up to 3 sounds for your perfect focus environment")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var activeSoundsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Now Playing")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            ForEach(soundService.activeSoundList) { sound in
                ActiveSoundCard(
                    sound: sound,
                    volume: Binding(
                        get: { soundService.volume(for: sound.id) },
                        set: { soundService.setVolume($0, for: sound.id) }
                    ),
                    onRemove: { soundService.deactivateSound(id: sound.id) }
                )
            }

            // Timer bell toggle
            TimerBellToggle()
        }
    }

    private var silentOptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Silence")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            Button {
                soundService.deactivateAll()
            } label: {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(soundService.activeSoundCount == 0 ? Color.appPrimary.opacity(0.15) : Color.appSurface)
                            .frame(width: 48, height: 48)
                        Image(systemName: "speaker.slash.fill")
                            .font(.title3)
                            .foregroundStyle(soundService.activeSoundCount == 0 ? Color.appPrimary : Color.appTextSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Sound")
                            .font(.appBody)
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Pure silence — just the timer")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer()

                    if soundService.activeSoundCount == 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
                .padding(Spacing.sm)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(soundService.activeSoundCount == 0 ? Color.appPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func soundCategorySection(_ category: SoundCategory) -> some View {
        let sounds = Sound.allSounds.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(category.displayName)
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(sounds) { sound in
                    SoundTile(
                        sound: sound,
                        isActive: soundService.isActive(sound.id),
                        onTap: { soundService.toggleSound(sound) }
                    )
                }
            }
        }
    }
}

struct ActiveSoundCard: View {
    let sound: Sound
    @Binding var volume: Double
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: sound.icon)
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(sound.name)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextTertiary)

                    Slider(value: $volume, in: 0...1)
                        .tint(Color.appPrimary)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TimerBellToggle: View {
    @AppStorage("cadence.timerBellEnabled") private var timerBellEnabled: Bool = true

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.appSurface)
                    .frame(width: 48, height: 48)
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(timerBellEnabled ? Color.appPrimary : Color.appTextTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Timer Bell")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)
                Text("Gentle chime when session ends")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Toggle("", isOn: $timerBellEnabled)
                .tint(Color.appPrimary)
        }
        .padding(Spacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SoundTile: View {
    let sound: Sound
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActive ? Color.appPrimary.opacity(0.15) : Color.appSurface)
                        .frame(height: 80)

                    VStack(spacing: Spacing.xs) {
                        Image(systemName: sound.icon)
                            .font(.title)
                            .foregroundStyle(isActive ? Color.appPrimary : Color.appTextSecondary)

                        if isActive {
                            Text("ON")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }

                Text(sound.name)
                    .font(.appCaption)
                    .foregroundStyle(isActive ? Color.appAccent : Color.appTextSecondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.appPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    SoundPickerView()
        .preferredColorScheme(.dark)
}
