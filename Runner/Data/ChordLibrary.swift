import Foundation

public struct GuitarFretPosition: Codable, Hashable {
    public let string: Int
    public let fret: Int
    public let finger: Int?

    public init(string: Int, fret: Int, finger: Int? = nil) {
        self.string = string
        self.fret = fret
        self.finger = finger
    }
}

public struct GuitarChordPattern: Codable, Hashable, Identifiable {
    public var id: String { "\(name)-\(baseFret)-\(positions)" }
    public let name: String
    public let summary: String
    public let baseFret: Int
    public let positions: [GuitarFretPosition]
    public let mutedStrings: Set<Int>

    public init(
        name: String,
        summary: String,
        baseFret: Int,
        positions: [GuitarFretPosition],
        mutedStrings: Set<Int> = []
    ) {
        self.name = name
        self.summary = summary
        self.baseFret = baseFret
        self.positions = positions
        self.mutedStrings = mutedStrings
    }
}

public struct ChordQuality: Codable, Hashable, Identifiable {
    public var id: String { symbol }
    public let symbol: String
    public let displayName: String
    public let intervals: [Int]
    public let aliases: [String]

    public init(symbol: String, displayName: String, intervals: [Int], aliases: [String]) {
        self.symbol = symbol
        self.displayName = displayName
        self.intervals = intervals
        self.aliases = aliases
    }
}

public struct ChordDefinition: Codable, Hashable, Identifiable {
    public var id: String { "\(root)\(quality.symbol)" }
    public let root: String
    public let quality: ChordQuality
    public let notes: [String]

    public var displayName: String {
        quality.symbol.isEmpty ? root : "\(root)\(quality.symbol)"
    }

    public var fullName: String {
        "\(root) \(quality.displayName)"
    }
}

public enum ChordLibrary {
    public static let roots = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    public static let qualities: [ChordQuality] = [
        ChordQuality(symbol: "", displayName: "Major", intervals: [0, 4, 7], aliases: ["maj", "major", "M"]),
        ChordQuality(symbol: "m", displayName: "Minor", intervals: [0, 3, 7], aliases: ["min", "minor", "-"]),
        ChordQuality(symbol: "5", displayName: "Power Chord", intervals: [0, 7], aliases: ["power", "no3"]),
        ChordQuality(symbol: "dim", displayName: "Diminished", intervals: [0, 3, 6], aliases: ["o"]),
        ChordQuality(symbol: "aug", displayName: "Augmented", intervals: [0, 4, 8], aliases: ["+"]),
        ChordQuality(symbol: "sus2", displayName: "Suspended 2", intervals: [0, 2, 7], aliases: []),
        ChordQuality(symbol: "sus4", displayName: "Suspended 4", intervals: [0, 5, 7], aliases: ["sus"]),
        ChordQuality(symbol: "6", displayName: "Sixth", intervals: [0, 4, 7, 9], aliases: []),
        ChordQuality(symbol: "m6", displayName: "Minor Sixth", intervals: [0, 3, 7, 9], aliases: ["min6"]),
        ChordQuality(symbol: "7", displayName: "Dominant Seventh", intervals: [0, 4, 7, 10], aliases: ["dom7"]),
        ChordQuality(symbol: "maj7", displayName: "Major Seventh", intervals: [0, 4, 7, 11], aliases: ["M7", "major7"]),
        ChordQuality(symbol: "m7", displayName: "Minor Seventh", intervals: [0, 3, 7, 10], aliases: ["min7", "-7"]),
        ChordQuality(symbol: "mMaj7", displayName: "Minor Major Seventh", intervals: [0, 3, 7, 11], aliases: ["mM7"]),
        ChordQuality(symbol: "dim7", displayName: "Diminished Seventh", intervals: [0, 3, 6, 9], aliases: ["o7"]),
        ChordQuality(symbol: "m7b5", displayName: "Half Diminished", intervals: [0, 3, 6, 10], aliases: ["ø", "half-dim"]),
        ChordQuality(symbol: "add9", displayName: "Add Nine", intervals: [0, 4, 7, 14], aliases: []),
        ChordQuality(symbol: "9", displayName: "Dominant Ninth", intervals: [0, 4, 7, 10, 14], aliases: []),
        ChordQuality(symbol: "maj9", displayName: "Major Ninth", intervals: [0, 4, 7, 11, 14], aliases: ["M9"]),
        ChordQuality(symbol: "m9", displayName: "Minor Ninth", intervals: [0, 3, 7, 10, 14], aliases: ["min9"]),
        ChordQuality(symbol: "11", displayName: "Eleventh", intervals: [0, 4, 7, 10, 14, 17], aliases: []),
        ChordQuality(symbol: "13", displayName: "Thirteenth", intervals: [0, 4, 7, 10, 14, 21], aliases: [])
    ]

    public static let patternNames = ["Open", "Barre", "Power Chord", "Triad", "CAGED", "Arpeggio"]

    public static var allDefinitions: [ChordDefinition] {
        roots.flatMap { root in
            qualities.map { definition(root: root, quality: $0) }
        }
    }

    public static func definition(root: String, quality: ChordQuality) -> ChordDefinition {
        let rootIndex = roots.firstIndex(of: normalizeRoot(root)) ?? 0
        let notes = quality.intervals.map { roots[(rootIndex + ($0 % 12)) % 12] }
        return ChordDefinition(root: roots[rootIndex], quality: quality, notes: notes)
    }

    public static func definition(for chordName: String) -> ChordDefinition? {
        let parsed = parse(chordName)
        guard let quality = quality(for: parsed.suffix) else { return nil }
        return definition(root: parsed.root, quality: quality)
    }

    public static func displayName(for chordName: String) -> String {
        definition(for: chordName)?.displayName ?? chordName.replacingOccurrences(of: ":", with: "")
    }

    public static func fullName(for chordName: String) -> String {
        definition(for: chordName)?.fullName ?? displayName(for: chordName)
    }

    public static func transpose(_ chordName: String, semitones: Int) -> String {
        let parsed = parse(chordName)
        let root = normalizeRoot(parsed.root)
        guard let index = roots.firstIndex(of: root) else { return chordName }
        let shifted = (index + semitones % 12 + 12) % 12
        return "\(roots[shifted])\(canonicalSuffix(parsed.suffix))"
    }

    public static func patterns(for chordName: String) -> [GuitarChordPattern] {
        guard let definition = definition(for: chordName) else { return [] }
        return patterns(for: definition)
    }

    public static func patterns(for definition: ChordDefinition) -> [GuitarChordPattern] {
        [
            openPattern(for: definition),
            barrePattern(for: definition),
            powerPattern(for: definition),
            triadPattern(for: definition),
            cagedPattern(for: definition),
            arpeggioPattern(for: definition)
        ].compactMap { $0 }
    }

    public static func pattern(named name: String, for chordName: String) -> GuitarChordPattern? {
        patterns(for: chordName).first { $0.name == name } ?? patterns(for: chordName).first
    }

    public static func parse(_ chordName: String) -> (root: String, suffix: String) {
        var value = chordName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: " Major", with: "")
            .replacingOccurrences(of: " major", with: "")
            .replacingOccurrences(of: " Minor", with: "m")
            .replacingOccurrences(of: " minor", with: "m")

        if value.hasSuffix("maj") {
            value = String(value.dropLast(3))
        }

        let rootCandidates = ["C#", "Db", "D#", "Eb", "F#", "Gb", "G#", "Ab", "A#", "Bb", "C", "D", "E", "F", "G", "A", "B"]
        guard let root = rootCandidates.first(where: { value.hasPrefix($0) }) else {
            return (value, "")
        }
        return (normalizeRoot(root), String(value.dropFirst(root.count)))
    }

    private static func quality(for suffix: String) -> ChordQuality? {
        let cleaned = canonicalSuffix(suffix)
        return qualities.first { quality in
            quality.symbol == cleaned || quality.aliases.contains { $0.caseInsensitiveCompare(cleaned) == .orderedSame }
        } ?? (cleaned.isEmpty ? qualities.first : nil)
    }

    private static func canonicalSuffix(_ suffix: String) -> String {
        let cleaned = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned == "maj" || cleaned == "major" { return "" }
        if cleaned == "min" || cleaned == "minor" || cleaned == "-" { return "m" }
        if cleaned == "dom7" { return "7" }
        return cleaned
    }

    private static func normalizeRoot(_ root: String) -> String {
        [
            "Db": "C#",
            "Eb": "D#",
            "Gb": "F#",
            "Ab": "G#",
            "Bb": "A#"
        ][root] ?? root
    }

    private static func rootFret(root: String, stringSemitone: Int, minimumFret: Int = 0) -> Int {
        let rootIndex = roots.firstIndex(of: normalizeRoot(root)) ?? 0
        var fret = (rootIndex - stringSemitone + 12) % 12
        while fret < minimumFret { fret += 12 }
        return fret
    }

    private static func openPattern(for definition: ChordDefinition) -> GuitarChordPattern? {
        let openShapes: [String: [Int]] = [
            "C": [-1, 3, 2, 0, 1, 0],
            "D": [-1, -1, 0, 2, 3, 2],
            "E": [0, 2, 2, 1, 0, 0],
            "G": [3, 2, 0, 0, 0, 3],
            "A": [-1, 0, 2, 2, 2, 0],
            "Dm": [-1, -1, 0, 2, 3, 1],
            "Em": [0, 2, 2, 0, 0, 0],
            "Am": [-1, 0, 2, 2, 1, 0],
            "D7": [-1, -1, 0, 2, 1, 2],
            "E7": [0, 2, 0, 1, 0, 0],
            "G7": [3, 2, 0, 0, 0, 1],
            "A7": [-1, 0, 2, 0, 2, 0],
            "B7": [-1, 2, 1, 2, 0, 2]
        ]
        let key = definition.displayName
        guard let frets = openShapes[key] else { return nil }
        return patternFromFrets(
            name: "Open",
            summary: "standard open-position guitar voicing",
            frets: frets,
            baseFret: 1
        )
    }

    private static func barrePattern(for definition: ChordDefinition) -> GuitarChordPattern? {
        let majorFamily = ["", "7", "maj7", "6", "9", "add9", "sus2", "sus4"]
        let minorFamily = ["m", "m7", "m6", "m9", "mMaj7"]
        let rootOnSixth = rootFret(root: definition.root, stringSemitone: 4, minimumFret: 1)
        let rootOnFifth = rootFret(root: definition.root, stringSemitone: 9, minimumFret: 1)
        let frets: [Int]
        if minorFamily.contains(definition.quality.symbol) {
            frets = [rootOnSixth, rootOnSixth + 2, rootOnSixth + 2, rootOnSixth, rootOnSixth, rootOnSixth]
        } else if majorFamily.contains(definition.quality.symbol) {
            frets = [rootOnSixth, rootOnSixth + 2, rootOnSixth + 2, rootOnSixth + 1, rootOnSixth, rootOnSixth]
        } else {
            frets = [-1, rootOnFifth, rootOnFifth + 2, rootOnFifth + 2, rootOnFifth + 1, rootOnFifth]
        }
        return patternFromFrets(
            name: "Barre",
            summary: "movable E/A-shape barre voicing",
            frets: frets,
            baseFret: max(1, frets.filter { $0 > 0 }.min() ?? 1)
        )
    }

    private static func powerPattern(for definition: ChordDefinition) -> GuitarChordPattern? {
        let fret = rootFret(root: definition.root, stringSemitone: 4, minimumFret: 1)
        return patternFromFrets(
            name: "Power Chord",
            summary: "root + fifth + octave, no third",
            frets: [fret, fret + 2, fret + 2, -1, -1, -1],
            baseFret: fret
        )
    }

    private static func triadPattern(for definition: ChordDefinition) -> GuitarChordPattern? {
        let rootOnThird = rootFret(root: definition.root, stringSemitone: 7, minimumFret: 2)
        let thirdOffset = definition.quality.intervals.contains(3) ? 3 : 4
        return patternFromFrets(
            name: "Triad",
            summary: "compact top-string root position triad",
            frets: [-1, -1, -1, rootOnThird, rootOnThird + thirdOffset - 5, rootOnThird],
            baseFret: max(1, rootOnThird - 2)
        )
    }

    private static func cagedPattern(for definition: ChordDefinition) -> GuitarChordPattern? {
        let rootOnFifth = rootFret(root: definition.root, stringSemitone: 9, minimumFret: 1)
        let minor = definition.quality.symbol.hasPrefix("m")
        return patternFromFrets(
            name: "CAGED",
            summary: minor ? "movable A-minor CAGED shape" : "movable A-major CAGED shape",
            frets: [-1, rootOnFifth, rootOnFifth + 2, rootOnFifth + 2, rootOnFifth + (minor ? 1 : 2), rootOnFifth],
            baseFret: rootOnFifth
        )
    }

    private static func arpeggioPattern(for definition: ChordDefinition) -> GuitarChordPattern? {
        let rootOnSixth = rootFret(root: definition.root, stringSemitone: 4, minimumFret: 1)
        let minor = definition.quality.intervals.contains(3)
        return patternFromFrets(
            name: "Arpeggio",
            summary: "root-third-fifth picking map across strings",
            frets: [rootOnSixth, rootOnSixth + 2, rootOnSixth + 2, rootOnSixth + (minor ? 0 : 1), rootOnSixth, rootOnSixth + 3],
            baseFret: rootOnSixth
        )
    }

    private static func patternFromFrets(name: String, summary: String, frets: [Int], baseFret: Int) -> GuitarChordPattern {
        var positions: [GuitarFretPosition] = []
        var muted = Set<Int>()

        for (offset, fret) in frets.enumerated() {
            let string = 6 - offset
            if fret < 0 {
                muted.insert(string)
            } else if fret > 0 {
                positions.append(GuitarFretPosition(string: string, fret: fret))
            }
        }

        return GuitarChordPattern(
            name: name,
            summary: summary,
            baseFret: baseFret,
            positions: positions,
            mutedStrings: muted
        )
    }
}
