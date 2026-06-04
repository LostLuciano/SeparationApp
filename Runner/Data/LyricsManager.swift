import Foundation

/// A single synchronized lyric line with timestamp.
public struct LyricLine: Codable {
    public let startTime: Double
    public let endTime: Double
    public let text: String

    public init(startTime: Double, endTime: Double, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

/// Manages loading and querying time-synced lyrics from project files.
public class LyricsManager {

    public private(set) var lines: [LyricLine] = []
    public private(set) var loadedURL: URL?

    public init() {}

    @discardableResult
    public func loadLyrics(from url: URL) throws -> Bool {
        let data = try Data(contentsOf: url)

        if let decoded = try? JSONDecoder().decode([LyricLine].self, from: data) {
            lines = decoded
        } else {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let rawLines = json?["lyrics"] as? [[String: Any]] ?? []
            lines = rawLines.compactMap { dict -> LyricLine? in
                guard let start = dict["startTime"] as? Double,
                      let end = dict["endTime"] as? Double,
                      let text = dict["text"] as? String else { return nil }
                return LyricLine(startTime: start, endTime: end, text: text)
            }
        }

        loadedURL = url
        return !lines.isEmpty
    }

    public func activeLine(at time: Double) -> LyricLine? {
        return lines.first { time >= $0.startTime && time < $0.endTime }
    }

    public func nextLine(after time: Double) -> LyricLine? {
        return lines.first { $0.startTime > time }
    }

    public func toSerializable() -> [[String: Any]] {
        return lines.map { [
            "startTime": $0.startTime,
            "endTime": $0.endTime,
            "text": $0.text
        ]}
    }
}
