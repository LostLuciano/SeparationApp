import Foundation
import AVFoundation

/// Model tracking a chord identification duration segment.
public struct ChordSegment: Codable {
    public let name: String
    public let startTime: Double
    public let endTime: Double
    public let rootNote: Int
    public let chordType: Int

    public init(name: String, startTime: Double, endTime: Double, rootNote: Int, chordType: Int) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.rootNote = rootNote
        self.chordType = chordType
    }
}

/// Real local chord estimation based on chroma features.
public class ChordDetectionManager {

    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private let featureExtractor = AudioFeatureExtractor()

    public init() {}

    public func analyzeChords(audioURL: URL) async throws -> [ChordSegment] {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw NSError(
                domain: "ChordDetectionManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Audio track not found."]
            )
        }

        let buffer = try loadPCMBuffer(url: audioURL)
        let hopSize = 2048
        let chromaFrames = featureExtractor.computeChroma(pcmBuffer: buffer, nFFT: 4096, hopSize: hopSize)
        guard !chromaFrames.isEmpty else { return [] }

        await Task.yield()

        let frameDuration = Double(hopSize) / buffer.format.sampleRate
        let framesPerSegment = max(1, Int(round(2.0 / frameDuration)))
        var rawSegments: [ChordSegment] = []

        var frameIndex = 0
        while frameIndex < chromaFrames.count {
            let endFrame = min(frameIndex + framesPerSegment, chromaFrames.count)
            let averaged = averageChroma(Array(chromaFrames[frameIndex..<endFrame]))
            guard let estimate = estimateChord(from: averaged) else {
                frameIndex = endFrame
                continue
            }

            rawSegments.append(
                ChordSegment(
                    name: estimate.name,
                    startTime: Double(frameIndex) * frameDuration,
                    endTime: Double(endFrame) * frameDuration,
                    rootNote: estimate.root,
                    chordType: estimate.type
                )
            )

            frameIndex = endFrame
        }

        return mergeAdjacent(rawSegments)
    }

    private func loadPCMBuffer(url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else {
            throw NSError(
                domain: "ChordDetectionManager",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer."]
            )
        }

        try file.read(into: buffer)
        return buffer
    }

    private func averageChroma(_ frames: [[Float]]) -> [Float] {
        guard !frames.isEmpty else { return [Float](repeating: 0, count: 12) }
        var result = [Float](repeating: 0, count: 12)

        for frame in frames {
            for index in 0..<min(frame.count, 12) {
                result[index] += frame[index]
            }
        }

        let divisor = Float(frames.count)
        return result.map { $0 / divisor }
    }

    private func estimateChord(from chroma: [Float]) -> (name: String, root: Int, type: Int)? {
        guard chroma.contains(where: { $0 > 0 }) else { return nil }

        var bestScore: Float = 0
        var bestRoot = 0
        var bestType = 1

        for root in 0..<12 {
            let majorScore = chordScore(chroma, root: root, intervals: [0, 4, 7])
            if majorScore > bestScore {
                bestScore = majorScore
                bestRoot = root
                bestType = 1
            }

            let minorScore = chordScore(chroma, root: root, intervals: [0, 3, 7])
            if minorScore > bestScore {
                bestScore = minorScore
                bestRoot = root
                bestType = 2
            }
        }

        let totalEnergy = chroma.reduce(Float(0), +)
        guard totalEnergy > 0, bestScore / totalEnergy > 0.18 else { return nil }

        let suffix = bestType == 1 ? "maj" : "min"
        return ("\(noteNames[bestRoot]):\(suffix)", bestRoot, bestType)
    }

    private func chordScore(_ chroma: [Float], root: Int, intervals: [Int]) -> Float {
        intervals.reduce(Float(0)) { score, interval in
            score + chroma[(root + interval) % 12]
        }
    }

    private func mergeAdjacent(_ segments: [ChordSegment]) -> [ChordSegment] {
        guard var current = segments.first else { return [] }
        var merged: [ChordSegment] = []

        for segment in segments.dropFirst() {
            if segment.name == current.name {
                current = ChordSegment(
                    name: current.name,
                    startTime: current.startTime,
                    endTime: segment.endTime,
                    rootNote: current.rootNote,
                    chordType: current.chordType
                )
            } else {
                merged.append(current)
                current = segment
            }
        }

        merged.append(current)
        return merged
    }
}
