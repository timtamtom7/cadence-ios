import Foundation
import AVFoundation

@MainActor
@Observable
class SoundService {
    static let shared = SoundService()

    var activeSounds: [String: Sound] = [:]
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioErrors: [String: String] = [:] // Track errors per sound for debugging

    init() {
        setupAudioSession()
        loadSavedSounds()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio setup failed — sounds won't play but app continues
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func loadSavedSounds() {
        Task {
            let savedVolumes = await DatabaseService.shared.loadActiveSounds()
            for (id, volume) in savedVolumes {
                if let sound = Sound.allSounds.first(where: { $0.id == id }) {
                    var mutableSound = sound
                    mutableSound.volume = volume
                    activeSounds[id] = mutableSound
                }
            }
        }
    }

    func toggleSound(_ sound: Sound) {
        if activeSounds[sound.id] != nil {
            deactivateSound(id: sound.id)
        } else {
            activateSound(sound)
        }
    }

    func activateSound(_ sound: Sound) {
        var mutableSound = sound
        mutableSound.volume = 0.5
        activeSounds[sound.id] = mutableSound
        loadAndPlaySound(id: sound.id)
        saveActiveSounds()
    }

    func deactivateSound(id: String) {
        activeSounds.removeValue(forKey: id)
        stopSound(id: id)
        saveActiveSounds()
    }

    func setVolume(_ volume: Double, for soundId: String) {
        guard var sound = activeSounds[soundId] else { return }
        // Clamp volume to prevent distortion at extremes
        sound.volume = max(0.05, min(1.0, volume))
        activeSounds[soundId] = sound
        audioPlayers[soundId]?.volume = Float(sound.volume)
        saveActiveSounds()
    }

    private func loadAndPlaySound(id: String) {
        // Try multiple file extensions and formats
        let extensions = ["mp3", "m4a", "wav", "aac", "aiff"]
        var loaded = false

        for ext in extensions {
            if let url = Bundle.main.url(forResource: id, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1 // Loop indefinitely
                    player.volume = Float(activeSounds[id]?.volume ?? 0.5)
                    player.prepareToPlay()
                    player.play()
                    audioPlayers[id] = player
                    audioErrors[id] = nil
                    loaded = true
                    break
                } catch {
                    audioErrors[id] = "Failed to load \(id).\(ext): \(error.localizedDescription)"
                }
            }
        }

        if !loaded {
            // Sound file not bundled — track as silent placeholder
            // App continues without crashing
            audioErrors[id] = "Sound file not bundled for \(id)"
        }
    }

    private func stopSound(id: String) {
        audioPlayers[id]?.stop()
        audioPlayers.removeValue(forKey: id)
    }

    private func saveActiveSounds() {
        let volumes = activeSounds.mapValues { $0.volume }
        Task {
            await DatabaseService.shared.saveActiveSounds(volumes)
        }
    }

    func isActive(_ soundId: String) -> Bool {
        activeSounds[soundId] != nil
    }

    func volume(for soundId: String) -> Double {
        activeSounds[soundId]?.volume ?? 0.5
    }

    var activeSoundCount: Int {
        activeSounds.count
    }

    var activeSoundList: [Sound] {
        Array(activeSounds.values)
    }

    func deactivateAll() {
        for id in activeSounds.keys {
            stopSound(id: id)
        }
        activeSounds.removeAll()
        saveActiveSounds()
    }

    /// Returns true if all active sounds loaded successfully
    var allSoundsLoaded: Bool {
        audioErrors.isEmpty
    }

    /// Check if a specific sound failed to load
    func soundFailedToLoad(_ soundId: String) -> Bool {
        audioErrors[soundId] != nil
    }
}
