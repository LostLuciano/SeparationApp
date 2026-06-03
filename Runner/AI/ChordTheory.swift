import Foundation

/// ChordTheory provides chord pattern calculations and full vocabulary support
public class ChordTheory {
    
    static let shared = ChordTheory()
    
    // MARK: - Chord Types
    
    public enum ChordType: String, CaseIterable {
        case major = "Major"
        case minor = "Minor"
        case seventh = "Seventh"
        case majorSeventh = "Major 7"
        case minorSeventh = "Minor 7"
        case diminished = "Diminished"
        case augmented = "Augmented"
        case suspended2 = "Sus2"
        case suspended4 = "Sus4"
        case power = "Power"
        case halfDiminished = "Half Dim"
        case dominantSeventh = "Dom 7"
        
        var intervals: [Int] {
            // Semitones from root
            switch self {
            case .major:
                return [0, 4, 7]
            case .minor:
                return [0, 3, 7]
            case .seventh:
                return [0, 4, 7, 10]
            case .majorSeventh:
                return [0, 4, 7, 11]
            case .minorSeventh:
                return [0, 3, 7, 10]
            case .diminished:
                return [0, 3, 6]
            case .augmented:
                return [0, 4, 8]
            case .suspended2:
                return [0, 2, 7]
            case .suspended4:
                return [0, 5, 7]
            case .power:
                return [0, 7]
            case .halfDiminished:
                return [0, 3, 6, 10]
            case .dominantSeventh:
                return [0, 4, 7, 10]
            }
        }
        
        var description: String {
            switch self {
            case .major:
                return "Major triad (root, major third, perfect fifth)"
            case .minor:
                return "Minor triad (root, minor third, perfect fifth)"
            case .seventh:
                return "Dominant seventh (major triad + minor seventh)"
            case .majorSeventh:
                return "Major seventh (major triad + major seventh)"
            case .minorSeventh:
                return "Minor seventh (minor triad + minor seventh)"
            case .diminished:
                return "Diminished triad (root, minor third, diminished fifth)"
            case .augmented:
                return "Augmented triad (root, major third, augmented fifth)"
            case .suspended2:
                return "Suspended 2 (root, major second, perfect fifth)"
            case .suspended4:
                return "Suspended 4 (root, perfect fourth, perfect fifth)"
            case .power:
                return "Power chord (root and perfect fifth)"
            case .halfDiminished:
                return "Half diminished (diminished triad + minor seventh)"
            case .dominantSeventh:
                return "Dominant seventh (major triad + minor seventh)"
            }
        }
    }
    
    // MARK: - Note Names
    
    public enum Note: String, CaseIterable {
        case c = "C"
        case cSharp = "C#"
        case d = "D"
        case dSharp = "D#"
        case e = "E"
        case f = "F"
        case fSharp = "F#"
        case g = "G"
        case gSharp = "G#"
        case a = "A"
        case aSharp = "A#"
        case b = "B"
        
        var semitone: Int {
            switch self {
            case .c: return 0
            case .cSharp: return 1
            case .d: return 2
            case .dSharp: return 3
            case .e: return 4
            case .f: return 5
            case .fSharp: return 6
            case .g: return 7
            case .gSharp: return 8
            case .a: return 9
            case .aSharp: return 10
            case .b: return 11
            }
        }
        
        static func fromSemitone(_ semitone: Int) -> Note {
            let normalized = semitone % 12
            return Note.allCases.first { $0.semitone == normalized } ?? .c
        }
    }
    
    // MARK: - Chord Representation
    
    public struct Chord {
        public let root: Note
        public let type: ChordType
        public let confidence: Float
        public let timestamp: TimeInterval
        
        public var name: String {
            return "\(root.rawValue)\(type.rawValue)"
        }
        
        public var notes: [Note] {
            return type.intervals.map { interval in
                let semitone = (root.semitone + interval) % 12
                return Note.fromSemitone(semitone)
            }
        }
        
        public var description: String {
            return "\(name) - \(type.description)"
        }
    }
    
    // MARK: - Chord Detection
    
    /// Detect chord from pitch class distribution
    /// Input: 12-element array representing confidence for each semitone (C, C#, D, ..., B)
    public func detectChord(from pitchClassDistribution: [Float]) -> Chord? {
        guard pitchClassDistribution.count == 12 else {
            Logger.shared.warning("Invalid pitch class distribution size: \(pitchClassDistribution.count)")
            return nil
        }
        
        var bestChord: Chord?
        var bestScore: Float = 0
        
        // Try all root notes
        for rootNote in Note.allCases {
            // Try all chord types
            for chordType in ChordType.allCases {
                let score = scoreChord(root: rootNote, type: chordType, distribution: pitchClassDistribution)
                
                if score > bestScore {
                    bestScore = score
                    bestChord = Chord(
                        root: rootNote,
                        type: chordType,
                        confidence: score,
                        timestamp: Date().timeIntervalSince1970
                    )
                }
            }
        }
        
        // Only return if confidence is above threshold
        if let chord = bestChord, chord.confidence > 0.3 {
            return chord
        }
        
        return nil
    }
    
    /// Score how well a chord matches the pitch distribution
    private func scoreChord(root: Note, type: ChordType, distribution: [Float]) -> Float {
        var score: Float = 0
        let intervals = type.intervals
        
        // Sum confidence for chord notes
        for interval in intervals {
            let semitone = (root.semitone + interval) % 12
            score += distribution[semitone]
        }
        
        // Penalize non-chord notes
        for (semitone, confidence) in distribution.enumerated() {
            let isChordNote = intervals.contains { (root.semitone + $0) % 12 == semitone }
            if !isChordNote {
                score -= confidence * 0.5
            }
        }
        
        // Normalize
        return max(0, score / Float(intervals.count))
    }
    
    // MARK: - Chord Progression Analysis
    
    public struct ChordProgression {
        public let chords: [Chord]
        public let key: Note?
        public let confidence: Float
        
        public var description: String {
            let chordNames = chords.map { $0.name }.joined(separator: " - ")
            let keyString = key?.rawValue ?? "Unknown"
            return "\(chordNames) (Key: \(keyString))"
        }
    }
    
    /// Analyze chord progression from sequence of chords
    public func analyzeProgression(_ chords: [Chord]) -> ChordProgression {
        guard !chords.isEmpty else {
            return ChordProgression(chords: [], key: nil, confidence: 0)
        }
        
        // Detect key from root notes
        let key = detectKey(from: chords)
        
        // Calculate confidence as average of all chord confidences
        let avgConfidence = chords.map { $0.confidence }.reduce(0, +) / Float(chords.count)
        
        return ChordProgression(chords: chords, key: key, confidence: avgConfidence)
    }
    
    /// Detect musical key from chord sequence
    private func detectKey(from chords: [Chord]) -> Note? {
        guard !chords.isEmpty else { return nil }
        
        // Count root note occurrences
        var rootCounts: [Note: Int] = [:]
        for chord in chords {
            rootCounts[chord.root, default: 0] += 1
        }
        
        // Most common root is likely the key
        return rootCounts.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Chord Vocabulary
    
    public struct ChordVocabulary {
        public let allChords: [String]
        public let majorChords: [String]
        public let minorChords: [String]
        public let seventhChords: [String]
        
        public init() {
            var all: [String] = []
            var major: [String] = []
            var minor: [String] = []
            var seventh: [String] = []
            
            for note in Note.allCases {
                for chordType in ChordType.allCases {
                    let chord = Chord(root: note, type: chordType, confidence: 1.0, timestamp: 0)
                    all.append(chord.name)
                    
                    switch chordType {
                    case .major, .augmented, .suspended2, .suspended4, .power:
                        major.append(chord.name)
                    case .minor, .diminished, .halfDiminished:
                        minor.append(chord.name)
                    case .seventh, .majorSeventh, .minorSeventh, .dominantSeventh:
                        seventh.append(chord.name)
                    }
                }
            }
            
            self.allChords = all.sorted()
            self.majorChords = major.sorted()
            self.minorChords = minor.sorted()
            self.seventhChords = seventh.sorted()
        }
    }
    
    /// Get complete chord vocabulary
    public func getVocabulary() -> ChordVocabulary {
        return ChordVocabulary()
    }
    
    // MARK: - Chord Similarity
    
    /// Calculate similarity between two chords (0.0 to 1.0)
    public func calculateSimilarity(between chord1: Chord, and chord2: Chord) -> Float {
        // Same root and type = 1.0
        if chord1.root == chord2.root && chord1.type == chord2.type {
            return 1.0
        }
        
        // Same root, different type = 0.7
        if chord1.root == chord2.root {
            return 0.7
        }
        
        // Different root, same type = 0.5
        if chord1.type == chord2.type {
            return 0.5
        }
        
        // Calculate note overlap
        let notes1 = Set(chord1.notes)
        let notes2 = Set(chord2.notes)
        let overlap = Float(notes1.intersection(notes2).count)
        let total = Float(notes1.union(notes2).count)
        
        return overlap / total
    }
    
    // MARK: - Chord Transitions
    
    /// Get common chord transitions from current chord
    public func getCommonTransitions(from chord: Chord) -> [Chord] {
        let vocabulary = getVocabulary()
        
        // Sort by similarity to current chord
        let transitions = vocabulary.allChords
            .compactMap { chordName -> Chord? in
                // Parse chord name to create Chord object
                guard let rootStr = chordName.first.map(String.init),
                      let root = Note(rawValue: rootStr) else {
                    return nil
                }
                
                // Find matching chord type
                for chordType in ChordType.allCases {
                    if chordName.contains(chordType.rawValue) {
                        return Chord(root: root, type: chordType, confidence: 0.5, timestamp: 0)
                    }
                }
                return nil
            }
            .sorted { chord1, chord2 in
                let sim1 = calculateSimilarity(between: chord, and: chord1)
                let sim2 = calculateSimilarity(between: chord, and: chord2)
                return sim1 > sim2
            }
            .prefix(5)
            .map { $0 }
        
        return transitions
    }
    
    // MARK: - Utilities
    
    /// Convert frequency to nearest note
    public func frequencyToNote(_ frequency: Float) -> Note {
        // A4 = 440 Hz = semitone 57 (from C0)
        let a4Frequency: Float = 440
        let a4Semitone: Float = 57
        
        let semitone = a4Semitone + 12 * log2(frequency / a4Frequency)
        let roundedSemitone = Int(round(semitone)) % 12
        
        return Note.fromSemitone(roundedSemitone)
    }
    
    /// Convert note to frequency
    public func noteToFrequency(_ note: Note, octave: Int = 4) -> Float {
        let a4Frequency: Float = 440
        let a4Semitone: Float = 57
        
        let noteSemitone = Float(note.semitone + octave * 12)
        let semitoneOffset = noteSemitone - a4Semitone
        
        return a4Frequency * pow(2, semitoneOffset / 12)
    }
}
