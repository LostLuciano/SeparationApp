import Foundation

public enum ProjectStatus: String, Codable {
    case imported = "Imported"
    case separating = "Separating"
    case separated = "Separated"
    case analyzing = "Analyzing"
    case analyzed = "Analyzed"
    case recording = "Recording"
    case exporting = "Exporting"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

public struct StemProject: Codable, Identifiable {
    public let id: UUID
    public var name: String  // Alias for title
    public var title: String
    public var createdAt: Date
    public var createdDate: Date { createdAt }  // For compatibility
    public var originalAudioURL: URL
    public var importedFileName: String
    public var duration: Double
    public var format: String
    public var sampleRate: Double
    public var bpm: Double?
    public var key: String?
    public var status: ProjectStatus
    public var stemPaths: [String: URL]          // "vocals", "drums", "bass", "guitar", "piano", "others"
    public var chordSegments: [ChordSegment]
    public var beatResult: BeatTempoResult?
    public var lyricsPath: URL?
    public var waveformCachePath: URL?
    
    // Aliases for stem-specific URLs
    public var vocalsURL: URL? { stemPaths["vocals"] }
    public var drumsURL: URL? { stemPaths["drums"] }
    public var bassURL: URL? { stemPaths["bass"] }
    public var guitarURL: URL? { stemPaths["guitar"] }
    public var pianoURL: URL? { stemPaths["piano"] }
    public var otherURL: URL? { stemPaths["other"] }
    
    /// All stem URLs as a dictionary
    public var stemURLs: [String: URL] {
        return stemPaths
    }
    
    // MARK: - Computed Properties
    public var displayDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var projectDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Projects/\(id.uuidString)")
    }
    
    public var stemDirectory: URL {
        projectDirectory.appendingPathComponent("stems")
    }
    
    public var analysisDirectory: URL {
        projectDirectory.appendingPathComponent("analysis")
    }
    
    // MARK: - Methods
    public mutating func setStemPath(_ stem: String, url: URL) {
        stemPaths[stem] = url
    }
    
    public func getStemPath(_ stem: String) -> URL? {
        return stemPaths[stem]
    }
    
    public func allStemsAvailable() -> Bool {
        let requiredStems = ["vocals", "drums", "bass", "guitar", "piano", "others"]
        return requiredStems.allSatisfy { stemPaths[$0] != nil }
    }
}
