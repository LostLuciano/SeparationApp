import Foundation

/// Metadata for individual tracks/stems.
public struct TrackMetadata: Codable {
    public let stemType: String // "vocals", "drums", "bass", etc.
    public let duration: Double
    public let sampleRate: Double
    public let bitRate: Int
    public let format: String // "m4a", "wav", etc.
    
    public init(stemType: String, duration: Double, sampleRate: Double, bitRate: Int, format: String) {
        self.stemType = stemType
        self.duration = duration
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.format = format
    }
}
