import Foundation
import AVFoundation

@MainActor
@Observable
class SoundService {
    static let shared = SoundService()

    var activeSounds: [String: Sound] = [:]
    private var audioPlayers: [String: AVAudioPlayer] = [:]

    init() {
        setupAudioSession()
        loadSavedSounds()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio setup failed, sounds won't play
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
        playSound(id: sound.id)
        saveActiveSounds()
    }

    func deactivateSound(id: String) {
        activeSounds.removeValue(forKey: id)
        stopSound(id: id)
        saveActiveSounds()
    }

    func setVolume(_ volume: Double, for soundId: String) {
        guard var sound = activeSounds[soundId] else { return }
        sound.volume = volume
        activeSounds[soundId] = sound
        audioPlayers[soundId]?.volume = Float(volume)
        saveActiveSounds()
    }

    private func playSound(id: String) {
        // R1: No actual audio files bundled
        // In production, load from bundle: Bundle.main.url(forResource: id, withExtension: "mp3")
        // For now, we track state without actual playback
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
}
