import SwiftUI

struct PreviewData {
    static let projects: [StemProject] = [
        StemProject(
            id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
            name: "Ocean Waves",
            title: "Ocean Waves",
            createdAt: Date(),
            originalAudioURL: URL(fileURLWithPath: "/mock/ocean_waves.mp3"),
            importedFileName: "ocean_waves.mp3",
            duration: 204.0, // 3:24
            format: "MP3",
            sampleRate: 44100.0,
            bpm: 120.0,
            key: "G Major",
            status: .separated,
            stemPaths: [
                "vocals": URL(fileURLWithPath: "/mock/vocals.m4a"),
                "drums": URL(fileURLWithPath: "/mock/drums.m4a"),
                "bass": URL(fileURLWithPath: "/mock/bass.m4a"),
                "guitar": URL(fileURLWithPath: "/mock/guitar.m4a"),
                "piano": URL(fileURLWithPath: "/mock/piano.m4a"),
                "other": URL(fileURLWithPath: "/mock/other.m4a")
            ],
            chordSegments: [
                ChordSegment(name: "G:maj", startTime: 0.0, endTime: 4.2, rootNote: 7, chordType: 1),
                ChordSegment(name: "D:maj", startTime: 4.2, endTime: 8.5, rootNote: 2, chordType: 1),
                ChordSegment(name: "E:min", startTime: 8.5, endTime: 12.8, rootNote: 4, chordType: 2),
                ChordSegment(name: "C:maj", startTime: 12.8, endTime: 16.4, rootNote: 0, chordType: 1)
            ],
            beatResult: BeatTempoResult(
                tempo: 120.0,
                beatTimings: [
                    BeatMarker(time: 0.0, index: 0),
                    BeatMarker(time: 0.5, index: 1),
                    BeatMarker(time: 1.0, index: 2),
                    BeatMarker(time: 1.5, index: 3),
                    BeatMarker(time: 2.0, index: 0),
                    BeatMarker(time: 2.5, index: 1),
                    BeatMarker(time: 3.0, index: 2),
                    BeatMarker(time: 3.5, index: 3)
                ],
                timeSignature: "4/4",
                confidence: 0.98
            ),
            lyricsPath: nil,
            waveformCachePath: nil
        ),
        StemProject(
            id: UUID(),
            name: "Trap Beats Session",
            title: "Trap Beats Session",
            createdAt: Date().addingTimeInterval(-86400),
            originalAudioURL: URL(fileURLWithPath: "/mock/trap_beats.wav"),
            importedFileName: "trap_beats.wav",
            duration: 252.0, // 4:12
            format: "WAV",
            sampleRate: 48000.0,
            bpm: 140.0,
            key: "A Minor",
            status: .separated,
            stemPaths: [
                "vocals": URL(fileURLWithPath: "/mock/vocals.m4a"),
                "drums": URL(fileURLWithPath: "/mock/drums.m4a"),
                "bass": URL(fileURLWithPath: "/mock/bass.m4a"),
                "other": URL(fileURLWithPath: "/mock/other.m4a")
            ],
            chordSegments: [],
            beatResult: nil,
            lyricsPath: nil,
            waveformCachePath: nil
        ),
        StemProject(
            id: UUID(),
            name: "Acoustic Folk",
            title: "Acoustic Folk",
            createdAt: Date().addingTimeInterval(-172800),
            originalAudioURL: URL(fileURLWithPath: "/mock/folk.mp3"),
            importedFileName: "folk.mp3",
            duration: 178.0, // 2:58
            format: "MP3",
            sampleRate: 44100.0,
            bpm: 98.0,
            key: "C Major",
            status: .imported,
            stemPaths: [:],
            chordSegments: [],
            beatResult: nil,
            lyricsPath: nil,
            waveformCachePath: nil
        )
    ]

    static let stems: [Stem] = [
        Stem(name: "Vocals", icon: "mic.fill", duration: "03:24"),
        Stem(name: "Drums", icon: "circle.grid.cross.fill", duration: "03:24"),
        Stem(name: "Bass", icon: "speaker.wave.2.fill", duration: "03:24"),
        Stem(name: "Guitar", icon: "guitars.fill", duration: "03:24"),
        Stem(name: "Piano", icon: "pianokeys", duration: "03:24"),
        Stem(name: "Other", icon: "waveform", duration: "03:24")
    ]
    
    static let lyricLines: [LyricLine] = [
        LyricLine(startTime: 0.0, endTime: 5.0, text: "Welcome to the future of sound"),
        LyricLine(startTime: 5.0, endTime: 18.0, text: "Separate the pieces, look what we found"),
        LyricLine(startTime: 18.0, endTime: 32.0, text: "In the studio, making beats so loud"),
        LyricLine(startTime: 32.0, endTime: 45.0, text: "We rise above the noise, above the crowd"),
        LyricLine(startTime: 45.0, endTime: 60.0, text: "Can you hear the drums beginning to roll?"),
        LyricLine(startTime: 60.0, endTime: 81.0, text: "This is somebody that I used to know")
    ]
    
    static let mixerChannels: [MixerChannel] = [
        MixerChannel(name: "Vocals", volume: 0.85, isMuted: false, isSoloed: false),
        MixerChannel(name: "Drums", volume: 0.75, isMuted: false, isSoloed: false),
        MixerChannel(name: "Bass", volume: 0.60, isMuted: false, isSoloed: false),
        MixerChannel(name: "Guitar", volume: 0.50, isMuted: false, isSoloed: false),
        MixerChannel(name: "Keys", volume: 0.70, isMuted: false, isSoloed: false),
        MixerChannel(name: "Others", volume: 0.45, isMuted: false, isSoloed: false)
    ]
}

struct Stem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let duration: String
}

struct MixerChannel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var volume: Double
    var isMuted: Bool
    var isSoloed: Bool
}
