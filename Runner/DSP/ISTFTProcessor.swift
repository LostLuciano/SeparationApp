import Foundation
import AVFoundation
import Accelerate

/// Inverse Short-Time Fourier Transform processor for signal reconstruction.
public class ISTFTProcessor {
    
    let nFFT: Int
    let hopSize: Int
    let windowFunction: [Float]
    
    public init(nFFT: Int = 4096, hopSize: Int = 1024) {
        self.nFFT = nFFT
        self.hopSize = hopSize
        
        // Create Hann window
        var window = [Float](repeating: 0, count: nFFT)
        vDSP_hann_window(&window, vDSP_Length(nFFT), Int32(vDSP_HANN_NORM))
        self.windowFunction = window
    }
    
    /// Reconstruct time-domain signal from STFT frames
    public func reconstructFromSTFT(
        real: [[Float]],
        imag: [[Float]],
        sampleRate: Double = 44100.0
    ) -> AVAudioPCMBuffer? {
        guard !real.isEmpty, real.count == imag.count else { return nil }
        
        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        let halfN = nFFT / 2
        let totalFrames = (real.count - 1) * hopSize + nFFT
        var output = [Float](repeating: 0, count: totalFrames)
        
        for (frameIdx, (realFrame, imagFrame)) in zip(real, imag).enumerated() {
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
                    vDSP_vmul(timeDomain, 1, windowFunction, 1, &windowed, 1, vDSP_Length(nFFT))
                    
                    let offset = frameIdx * hopSize
                    for i in 0..<nFFT {
                        if offset + i < output.count {
                            output[offset + i] += windowed[i]
                        }
                    }
                }
            }
        }
        
        // Normalize
        var maxVal: Float = 0
        vDSP_maxv(output, 1, &maxVal, vDSP_Length(output.count))
        if maxVal > 0 {
            var scale = 1.0 / maxVal
            output.withUnsafeMutableBufferPointer { buf in
                guard let ptr = buf.baseAddress else { return }
                vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(buf.count))
            }
        }
        
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ), let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(output.count)
        ) else { return nil }
        
        pcmBuffer.frameLength = AVAudioFrameCount(output.count)
        pcmBuffer.floatChannelData![0].update(from: output, count: output.count)
        
        return pcmBuffer
    }
}
