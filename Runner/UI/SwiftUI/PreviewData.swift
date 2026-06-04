import Foundation

struct Stem: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let name: String
    let icon: String
    let duration: String
    let url: URL
}

struct MixerChannel: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let name: String
    var volume: Double
    var isMuted: Bool
    var isSoloed: Bool
}

private struct StemDisplayMetadata {
    let key: String
    let name: String
    let icon: String

    static let ordered: [StemDisplayMetadata] = [
        StemDisplayMetadata(key: "vocals", name: "Vocals", icon: "mic.fill"),
        StemDisplayMetadata(key: "drums", name: "Drums", icon: "circle.grid.cross.fill"),
        StemDisplayMetadata(key: "bass", name: "Bass", icon: "speaker.wave.2.fill"),
        StemDisplayMetadata(key: "guitar", name: "Guitar", icon: "guitars.fill"),
        StemDisplayMetadata(key: "piano", name: "Piano", icon: "pianokeys"),
        StemDisplayMetadata(key: "other", name: "Other", icon: "waveform")
    ]

    static func metadata(for key: String) -> StemDisplayMetadata {
        ordered.first { $0.key == key }
            ?? StemDisplayMetadata(
                key: key,
                name: key.replacingOccurrences(of: "_", with: " ").capitalized,
                icon: "waveform"
            )
    }
}

extension StemProject {
    var displayStems: [Stem] {
        let knownKeys = Set(StemDisplayMetadata.ordered.map(\.key))
        let orderedKeys = StemDisplayMetadata.ordered.map(\.key)
        let extraKeys = stemPaths.keys.filter { !knownKeys.contains($0) }.sorted()

        return (orderedKeys + extraKeys).compactMap { key in
            guard let url = stemPaths[key] else { return nil }
            let metadata = StemDisplayMetadata.metadata(for: key)
            return Stem(
                key: key,
                name: metadata.name,
                icon: metadata.icon,
                duration: displayDuration,
                url: url
            )
        }
    }

    var displayMixerChannels: [MixerChannel] {
        displayStems.map { stem in
            MixerChannel(
                key: stem.key,
                name: stem.name,
                volume: 0.85,
                isMuted: false,
                isSoloed: false
            )
        }
    }
}
