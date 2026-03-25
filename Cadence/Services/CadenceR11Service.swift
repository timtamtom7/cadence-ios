import Foundation
import WatchConnectivity

// R11: Focus Modes, Sound Mixing, Apple Watch for Cadence
@MainActor
final class CadenceR11Service: ObservableObject {
    static let shared = CadenceR11Service()

    @Published var customFocusModes: [FocusMode] = []

    private init() {}

    // MARK: - Custom Focus Modes

    struct FocusMode: Identifiable, Codable {
        let id: UUID
        var name: String
        var icon: String
        var color: String
        var soundMix: [SoundMixEntry]
        var allowedApps: [String]
    }

    struct SoundMixEntry: Identifiable, Codable {
        let id: UUID
        var soundName: String
        var volume: Float
    }

    static let presetModes: [FocusMode] = [
        FocusMode(id: UUID(), name: "Deep Work", icon: "brain", color: "#6366f1", soundMix: [], allowedApps: []),
        FocusMode(id: UUID(), name: "Creative", icon: "paintbrush", color: "#ec4899", soundMix: [], allowedApps: []),
        FocusMode(id: UUID(), name: "Study", icon: "book", color: "#10b981", soundMix: [], allowedApps: []),
        FocusMode(id: UUID(), name: "Meditation", icon: "leaf", color: "#8b5cf6", soundMix: [], allowedApps: []),
        FocusMode(id: UUID(), name: "Workout", icon: "figure.run", color: "#f59e0b", soundMix: [], allowedApps: [])
    ]

    func createMode(name: String, icon: String, color: String) -> FocusMode {
        let mode = FocusMode(id: UUID(), name: name, icon: icon, color: color, soundMix: [], allowedApps: [])
        customFocusModes.append(mode)
        return mode
    }

    // MARK: - Sound Mixing

    func createSoundMix(entries: [SoundMixEntry]) -> [SoundMixEntry] {
        return entries
    }

    // MARK: - Apple Watch

    func sendToWatch(sessionData: FocusSession) {
        let message: [String: Any] = [
            "type": "focusSession",
            "duration": sessionData.duration,
            "mode": sessionData.modeName
        ]

        if WCSession.isSupported() {
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
    }

    struct FocusSession {
        let id: UUID
        let duration: TimeInterval
        let modeName: String
        let completedAt: Date
    }
}
