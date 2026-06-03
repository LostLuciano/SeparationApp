import Foundation
import AVFoundation
import Accelerate

/// Short-Time Fourier Transform processor for spectral analysis.
public class STFTProcessor {
    
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
    
    /// Compute STFT of audio buffer
    public func computeSTFT(pcmBuffer: AVAudioPCMBuffer) -> (real: [[Float]], imag: [[Float]]) {
        guard let channelData = pcmBuffer.floatChannelData else { return ([], []) }
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(pcmBuffer.frameLength)))
        
        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return ([], []) }
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        let halfN = nFFT / 2
        var realFrames: [[Float]] = []
        var imagFrames: [[Float]] = []
        
        var frameStart = 0
        while frameStart + nFFT <= samples.count {
            var windowed = [Float](repeating: 0, count: nFFT)
            let frameSlice = Array(samples[frameStart..<(frameStart + nFFT)])
            vDSP_vmul(frameSlice, 1, windowFunction, 1, &windowed, 1, vDSP_Length(nFFT))
            
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
            
            realFrames.append(realPart)
            imagFrames.append(imagPart)
            frameStart += hopSize
        }
        
        return (realFrames, imagFrames)
    }
}
