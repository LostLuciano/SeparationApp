import Foundation
import AVFoundation
import Accelerate

/// Struct mapping a timing beat index boundary.
public struct BeatMarker: Codable, Sendable {
    public let time: Double
    public let index: Int

    public init(time: Double, index: Int) {
        self.time = time
        self.index = index
    }
}

/// Consolidated struct of tempo metadata.
public struct BeatTempoResult: Codable, Sendable {
    public let tempo: Double
    public let beatTimings: [BeatMarker]
    public let timeSignature: String
    public let confidence: Double

    public init(tempo: Double, beatTimings: [BeatMarker], timeSignature: String = "4/4", confidence: Double = 0.0) {
        self.tempo = tempo
        self.beatTimings = beatTimings
        self.timeSignature = timeSignature
        self.confidence = confidence
    }
}

/// Real local beat and tempo estimation based on an onset-energy envelope.
public class BeatDetectionManager {

    public init() {}

    public func analyzeBeats(audioURL: URL) async throws -> BeatTempoResult {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw NSError(
                domain: "BeatDetectionManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Audio track not found."]
            )
        }

        let (samples, sampleRate, duration) = try loadMonoSamples(url: audioURL)
        let hopSize = 1024
        let windowSize = 2048
        let envelope = energyEnvelope(samples: samples, windowSize: windowSize, hopSize: hopSize)
        guard envelope.count > 3 else {
            throw NSError(
                domain: "BeatDetectionManager",
                code: 422,
                userInfo: [NSLocalizedDescriptionKey: "Not enough audio data for beat analysis."]
            )
        }

        await Task.yield()

        let onsets = onsetEnvelope(from: envelope)
        let peakTimes = detectPeaks(onsets: onsets, sampleRate: sampleRate, hopSize: hopSize)
        let tempo = try estimateTempo(from: peakTimes)
        let interval = 60.0 / tempo

        var beatTimings: [BeatMarker] = []
        var time = peakTimes.first ?? 0
        var beatIndex = 0

        while time < duration {
            beatTimings.append(BeatMarker(time: time, index: beatIndex % 4))
            beatIndex += 1
            time += interval
        }

        let confidence = min(0.95, max(0.35, Double(peakTimes.count) / max(duration, 1.0) / 4.0))
        return BeatTempoResult(tempo: tempo, beatTimings: beatTimings, timeSignature: "4/4", confidence: confidence)
    }

    private func loadMonoSamples(url: URL) throws -> (samples: [Float], sampleRate: Double, duration: Double) {
        let file = try AVAudioFile(forReading: url)
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else {
            throw NSError(
                domain: "BeatDetectionManager",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer."]
            )
        }

        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData else {
            throw NSError(
                domain: "BeatDetectionManager",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Audio buffer has no float data."]
            )
        }

        let count = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        var mono = [Float](repeating: 0, count: count)

        if channelCount <= 1 {
            mono = Array(UnsafeBufferPointer(start: channelData[0], count: count))
        } else {
            for channel in 0..<channelCount {
                let samples = UnsafeBufferPointer(start: channelData[channel], count: count)
                for index in 0..<count {
                    mono[index] += samples[index] / Float(channelCount)
                }
            }
        }

        let sampleRate = buffer.format.sampleRate
        let duration = Double(count) / sampleRate
        return (mono, sampleRate, duration)
    }

    private func energyEnvelope(samples: [Float], windowSize: Int, hopSize: Int) -> [Float] {
        guard samples.count >= windowSize else { return [] }
        var envelope: [Float] = []
        var start = 0

        while start + windowSize <= samples.count {
            var energy: Float = 0
            samples.withUnsafeBufferPointer { pointer in
                let base = pointer.baseAddress!.advanced(by: start)
                vDSP_svesq(base, 1, &energy, vDSP_Length(windowSize))
            }
            envelope.append(energy / Float(windowSize))
            start += hopSize
        }

        return envelope
    }

    private func onsetEnvelope(from energy: [Float]) -> [Float] {
        guard energy.count > 1 else { return [] }
        var onsets = [Float](repeating: 0, count: energy.count)

        for index in 1..<energy.count {
            onsets[index] = max(0, energy[index] - energy[index - 1])
        }

        return onsets
    }

    private func detectPeaks(onsets: [Float], sampleRate: Double, hopSize: Int) -> [Double] {
        guard onsets.count > 2 else { return [] }

        let mean = onsets.reduce(Float(0), +) / Float(onsets.count)
        let variance = onsets.reduce(Float(0)) { result, value in
            let delta = value - mean
            return result + delta * delta
        } / Float(onsets.count)
        let threshold = mean + sqrt(variance) * 0.7
        let minPeakDistance = max(1, Int(0.22 * sampleRate / Double(hopSize)))

        var peaks: [Int] = []
        var lastPeak = -minPeakDistance

        for index in 1..<(onsets.count - 1) {
            guard index - lastPeak >= minPeakDistance else { continue }
            if onsets[index] > threshold,
               onsets[index] >= onsets[index - 1],
               onsets[index] >= onsets[index + 1] {
                peaks.append(index)
                lastPeak = index
            }
        }

        return peaks.map { Double($0 * hopSize) / sampleRate }
    }

    private func estimateTempo(from peakTimes: [Double]) throws -> Double {
        let intervals = zip(peakTimes.dropFirst(), peakTimes).map { current, previous in
            current - previous
        }.filter { $0 >= 0.25 && $0 <= 1.6 }

        guard !intervals.isEmpty else {
            throw NSError(
                domain: "BeatDetectionManager",
                code: 422,
                userInfo: [NSLocalizedDescriptionKey: "No stable beat intervals detected."]
            )
        }

        let sorted = intervals.sorted()
        let medianInterval = sorted[sorted.count / 2]
        var tempo = 60.0 / medianInterval

        while tempo < 70 {
            tempo *= 2
        }
        while tempo > 180 {
            tempo /= 2
        }

        return (tempo * 10).rounded() / 10
    }
}
