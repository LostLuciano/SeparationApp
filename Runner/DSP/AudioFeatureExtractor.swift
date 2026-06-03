import Foundation
import AVFoundation
import Accelerate

/// Real DSP feature extraction using Apple's Accelerate framework (vDSP).
/// Provides STFT, iSTFT, log-mel spectrogram, and chroma extraction
/// needed by CoreMLStemSeparator and ChordDetectionManager.
public class AudioFeatureExtractor {

    public init() {}

    // MARK: - Resampling

    /// Resamples an AVAudioPCMBuffer to a target sample rate using AVAudioConverter.
    public func resampleAudio(inputBuffer: AVAudioPCMBuffer, targetSampleRate: Double) -> AVAudioPCMBuffer? {
        let inputFormat = inputBuffer.format
        guard inputFormat.sampleRate != targetSampleRate else { return inputBuffer }

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: inputFormat.channelCount,
            interleaved: false
        ) else { return nil }

        let ratio = targetSampleRate / inputFormat.sampleRate
        let estimatedFrames = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 512
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: estimatedFrames),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else { return nil }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        if let err = error {
            print("AudioFeatureExtractor: Resampling error: \(err.localizedDescription)")
            return nil
        }
        print("AudioFeatureExtractor: Resampled \(Int(inputFormat.sampleRate))Hz → \(Int(targetSampleRate))Hz")
        return outputBuffer
    }

    // MARK: - Chroma (NNLS approximation)

    /// Computes a 12-bin chromagram from a PCM buffer.
    /// Returns [timeFrames][12] pitch class energies.
    public func computeChroma(pcmBuffer: AVAudioPCMBuffer, nFFT: Int = 4096, hopSize: Int = 2048) -> [[Float]] {
        guard let channelData = pcmBuffer.floatChannelData else { return [] }
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(pcmBuffer.frameLength)))

        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return [] }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        let halfN = nFFT / 2
        var hanningWindow = [Float](repeating: 0, count: nFFT)
        vDSP_hann_window(&hanningWindow, vDSP_Length(nFFT), Int32(vDSP_HANN_NORM))

        var chromaFrames: [[Float]] = []
        let sampleRate = Float(pcmBuffer.format.sampleRate)

        var frameStart = 0
        while frameStart + nFFT <= samples.count {
            var windowed = [Float](repeating: 0, count: nFFT)
            let frameSlice = Array(samples[frameStart..<(frameStart + nFFT)])
            vDSP_vmul(frameSlice, 1, hanningWindow, 1, &windowed, 1, vDSP_Length(nFFT))

            var realPart = [Float](repeating: 0, count: halfN)
            var imagPart = [Float](repeating: 0, count: halfN)

            windowed.withUnsafeMutableBufferPointer { ptr in
                realPart.withUnsafeMutableBufferPointer { rBuf in
                    imagPart.withUnsafeMutableBufferPointer { iBuf in
                        var splitComplex = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                        ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                            vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                        }
                        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                    }
                }
            }

            var chroma = [Float](repeating: 0, count: 12)
            let binWidth = sampleRate / Float(nFFT)

            for k in 1..<halfN {
                let freq = Float(k) * binWidth
                let power = realPart[k] * realPart[k] + imagPart[k] * imagPart[k]
                let midi = 69.0 + 12.0 * log2(freq / 440.0)
                let pitchClass = Int(midi.truncatingRemainder(dividingBy: 12))
                let idx = ((pitchClass % 12) + 12) % 12
                chroma[idx] += power
            }

            chromaFrames.append(chroma)
            frameStart += hopSize
        }

        print("AudioFeatureExtractor: Chroma: \(chromaFrames.count) frames × 12 pitch classes")
        return chromaFrames
    }

    /// Reconstructs stereo time-domain signal from Left and Right STFT frames using overlap-add synthesis.
    public func computeISTFTStereo(
        realL: [[Float]], imagL: [[Float]],
        realR: [[Float]], imagR: [[Float]],
        nFFT: Int = 4096,
        hopSize: Int = 1024,
        sampleRate: Double = 44100.0
    ) -> AVAudioPCMBuffer? {
        guard !realL.isEmpty, realL.count == imagL.count,
              realL.count == realR.count, realR.count == imagR.count else { return nil }
        
        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        let halfN = nFFT / 2
        let totalFrames = (realL.count - 1) * hopSize + nFFT
        var leftOutput = [Float](repeating: 0, count: totalFrames)
        var rightOutput = [Float](repeating: 0, count: totalFrames)

        var hanningWindow = [Float](repeating: 0, count: nFFT)
        vDSP_hann_window(&hanningWindow, vDSP_Length(nFFT), Int32(vDSP_HANN_NORM))

        // Reconstruct Left Channel
        for (frameIdx, (realFrame, imagFrame)) in zip(realL, imagL).enumerated() {
            var rPart = realFrame
            var iPart = imagFrame

            rPart.withUnsafeMutableBufferPointer { rBuf in
                iPart.withUnsafeMutableBufferPointer { iBuf in
                    var splitComplex = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_INVERSE))

                    var timeDomain = [Float](repeating: 0, count: nFFT)
                    timeDomain.withUnsafeMutableBufferPointer { ptr in
                        ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { dst in
                            vDSP_ztoc(&splitComplex, 1, dst, 2, vDSP_Length(halfN))
                        }
                    }

                    var windowed = [Float](repeating: 0, count: nFFT)
                    vDSP_vmul(timeDomain, 1, hanningWindow, 1, &windowed, 1, vDSP_Length(nFFT))

                    let offset = frameIdx * hopSize
                    for i in 0..<nFFT {
                        if offset + i < leftOutput.count {
                            leftOutput[offset + i] += windowed[i]
                        }
                    }
                }
            }
        }

        // Reconstruct Right Channel
        for (frameIdx, (realFrame, imagFrame)) in zip(realR, imagR).enumerated() {
            var rPart = realFrame
            var iPart = imagFrame

            rPart.withUnsafeMutableBufferPointer { rBuf in
                iPart.withUnsafeMutableBufferPointer { iBuf in
                    var splitComplex = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_INVERSE))

                    var timeDomain = [Float](repeating: 0, count: nFFT)
                    timeDomain.withUnsafeMutableBufferPointer { ptr in
                        ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { dst in
                            vDSP_ztoc(&splitComplex, 1, dst, 2, vDSP_Length(halfN))
                        }
                    }

                    var windowed = [Float](repeating: 0, count: nFFT)
                    vDSP_vmul(timeDomain, 1, hanningWindow, 1, &windowed, 1, vDSP_Length(nFFT))

                    let offset = frameIdx * hopSize
                    for i in 0..<nFFT {
                        if offset + i < rightOutput.count {
                            rightOutput[offset + i] += windowed[i]
                        }
                    }
                }
            }
        }

        // Normalize both channels
        var maxValL: Float = 0
        var maxValR: Float = 0
        vDSP_maxv(leftOutput, 1, &maxValL, vDSP_Length(leftOutput.count))
        vDSP_maxv(rightOutput, 1, &maxValR, vDSP_Length(rightOutput.count))
        let maxVal = max(maxValL, maxValR)
        if maxVal > 0 {
            var scale = 1.0 / maxVal
            leftOutput.withUnsafeMutableBufferPointer { buf in
                guard let ptr = buf.baseAddress else { return }
                vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(buf.count))
            }
            rightOutput.withUnsafeMutableBufferPointer { buf in
                guard let ptr = buf.baseAddress else { return }
                vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(buf.count))
            }
        }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: false
        ), let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(leftOutput.count)
        ) else { return nil }

        pcmBuffer.frameLength = AVAudioFrameCount(leftOutput.count)
        pcmBuffer.floatChannelData![0].update(from: leftOutput, count: leftOutput.count)
        pcmBuffer.floatChannelData![1].update(from: rightOutput, count: rightOutput.count)

        print("AudioFeatureExtractor: iSTFTStereo → \(leftOutput.count) stereo samples reconstructed")
        return pcmBuffer
    }
}
