import Foundation
import AVFoundation
import Accelerate

/// Real-time waveform generation from audio files for visualization.
public class WaveformGenerator {
    
    public init() {}
    
    /// Generate waveform data points from audio file for display
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - channelCount: Number of channels to extract (usually 1 or 2)
    ///   - samplesPerPixel: How many audio samples to average per pixel
    /// - Returns: Array of normalized amplitude values (0.0 to 1.0)
    public func generateWaveform(
        from url: URL,
        channelCount: Int = 1,
        samplesPerPixel: Int = 512
    ) throws -> [Float] {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "WaveformGenerator", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
        }
        
        try audioFile.read(into: buffer)
        
        guard let channelData = buffer.floatChannelData else {
            throw NSError(domain: "WaveformGenerator", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "No float channel data"])
        }
        
        let totalSamples = Int(buffer.frameLength)
        let waveformPointCount = totalSamples / samplesPerPixel
        var waveformData: [Float] = []
        
        // For each pixel, find the peak absolute value in that chunk
        for pixelIndex in 0..<waveformPointCount {
            let startSample = pixelIndex * samplesPerPixel
            let endSample = min(startSample + samplesPerPixel, totalSamples)
            
            var maxAmplitude: Float = 0.0
            
            // Check all requested channels and find max
            for ch in 0..<min(channelCount, Int(format.channelCount)) {
                let channel = channelData[ch]
                for sampleIndex in startSample..<endSample {
                    let amplitude = abs(channel[sampleIndex])
                    if amplitude > maxAmplitude {
                        maxAmplitude = amplitude
                    }
                }
            }
            
            waveformData.append(maxAmplitude)
        }
        
        // Normalize to 0.0-1.0 range
        var maxVal: Float = 0.0
        vDSP_maxv(waveformData, 1, &maxVal, vDSP_Length(waveformData.count))
        
        if maxVal > 0 {
            var scale = 1.0 / maxVal
            waveformData.withUnsafeMutableBufferPointer { buf in
                guard let ptr = buf.baseAddress else { return }
                vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(buf.count))
            }
        }
        
        print("WaveformGenerator: Generated \(waveformData.count) waveform points from audio")
        return waveformData
    }
}
