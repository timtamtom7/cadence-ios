import Foundation

enum SoundCategory: String, Codable, CaseIterable {
    case nature
    case ambient
    case noise

    var displayName: String {
        switch self {
        case .nature: return "Nature"
        case .ambient: return "Ambient"
        case .noise: return "Noise"
        }
    }
}

struct Sound: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String // SF Symbol
    let category: SoundCategory
    var volume: Double

    init(id: String, name: String, icon: String, category: SoundCategory, volume: Double = 0.5) {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.volume = volume
    }

    static let allSounds: [Sound] = [
        Sound(id: "rain", name: "Rain", icon: "cloud.rain.fill", category: .nature),
        Sound(id: "forest", name: "Forest", icon: "leaf.fill", category: .nature),
        Sound(id: "ocean", name: "Ocean", icon: "water.waves", category: .nature),
        Sound(id: "cafe", name: "Cafe", icon: "cup.and.saucer.fill", category: .ambient),
        Sound(id: "fire", name: "Fireplace", icon: "flame.fill", category: .ambient),
        Sound(id: "whitenoise", name: "White Noise", icon: "waveform", category: .noise)
    ]
}
