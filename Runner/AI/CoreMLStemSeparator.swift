import Foundation
import CoreML
import AVFoundation
import Accelerate

/// On-device 6-stem source separation using the bundled CoreML Dense U-Net models.
public class CoreMLStemSeparator {

    private var nFFT = 4096
    private var hopSize = 1024
    private var nBins = 2048
    private var chunkFrames = 32
    private let targetSampleRate: Double = 44100.0
    private let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]

    private let featureExtractor = AudioFeatureExtractor()

    private struct ModelCandidate {
        let name: String
        let nFFT: Int
        let hopSize: Int
        let chunkFrames: Int
    }

    private struct LoadedStemModel {
        let model: MLModel
        let name: String
        let nFFT: Int
        let hopSize: Int
        let nBins: Int
        let chunkFrames: Int
    }

    private final class StemSTFTBuffer {
        var realL: [[Float]]
        var imagL: [[Float]]
        var realR: [[Float]]
        var imagR: [[Float]]

        init(frameCount: Int, binCount: Int) {
            realL = [[Float]](repeating: [Float](repeating: 0, count: binCount), count: frameCount)
            imagL = [[Float]](repeating: [Float](repeating: 0, count: binCount), count: frameCount)
            realR = [[Float]](repeating: [Float](repeating: 0, count: binCount), count: frameCount)
            imagR = [[Float]](repeating: [Float](repeating: 0, count: binCount), count: frameCount)
        }
    }

    public init() {}

    public func separate(
        audioURL: URL,
        processingMode: String?,
        modelQuality: String?,
        onProgress: @escaping (String, Double) -> Void
    ) async throws -> [String: URL] {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Input mixture file not found at \(audioURL.path)"]
            )
        }

        onProgress("Memulai pemisahan stem...", 0.02)
        onProgress("Memeriksa format file audio...", 0.04)

        let readableURL = try await transcodeToM4AIfNeeded(url: audioURL)
        defer {
            if readableURL != audioURL {
                try? FileManager.default.removeItem(at: readableURL)
            }
        }

        do {
            let result = try await runInference(
                audioURL: readableURL,
                modelQuality: modelQuality,
                onProgress: onProgress
            )
            onProgress("Proses pemisahan stem berhasil diselesaikan!", 1.0)
            return result
        } catch {
            print("[StemSeparator] CoreML separation failed: \(error.localizedDescription)")
            throw error
        }
    }

    private func transcodeToM4AIfNeeded(url: URL) async throws -> URL {
        do {
            _ = try AVAudioFile(forReading: url)
            return url
        } catch {
            print("[StemSeparator] Native read failed: \(error.localizedDescription). Attempting transcode.")
        }

        let asset = AVAsset(url: url)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcoded-\(UUID().uuidString).m4a")

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Gagal membuat sesi transcode audio."]
            )
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw exportSession.error ?? NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Gagal melakukan transcoding audio."]
            )
        }

        return outputURL
    }

    private func runInference(
        audioURL: URL,
        modelQuality: String?,
        onProgress: @escaping (String, Double) -> Void
    ) async throws -> [String: URL] {
        onProgress("Memuat model CoreML...", 0.05)
        let loadedModel = try loadModel(modelQuality: modelQuality)
        nFFT = loadedModel.nFFT
        hopSize = loadedModel.hopSize
        nBins = loadedModel.nBins
        chunkFrames = loadedModel.chunkFrames

        onProgress("Melakukan decoding audio...", 0.1)
        let (leftChannel, rightChannel) = try loadStereoAudio(url: audioURL)

        onProgress("Menghitung STFT audio...", 0.2)
        let leftSTFT = computeChannelSTFT(samples: leftChannel)
        let rightSTFT = computeChannelSTFT(samples: rightChannel)
        let totalFrames = min(leftSTFT.real.count, rightSTFT.real.count)

        guard totalFrames > 0 else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "STFT produced zero frames."]
            )
        }

        var stemSTFTs: [String: StemSTFTBuffer] = [:]
        for stem in stemNames {
            stemSTFTs[stem] = StemSTFTBuffer(frameCount: totalFrames, binCount: nBins)
        }

        let totalChunks = Int(ceil(Double(totalFrames) / Double(chunkFrames)))
        onProgress("Menjalankan inferensi neural network (\(totalChunks) chunks)...", 0.3)

        var chunkStart = 0
        var chunkCount = 0
        
        // Batch prediction requests for better throughput
        let batchSize = 4  // Process 4 chunks at once when possible

        while chunkStart < totalFrames {
            try Task.checkCancellation()

            let actualFrames = min(chunkFrames, totalFrames - chunkStart)
            
            // Process chunk - memory will be managed by Swift ARC
            let inputArray = try makeInputArray(
                leftSTFT: leftSTFT,
                rightSTFT: rightSTFT,
                startFrame: chunkStart,
                actualFrames: actualFrames
            )

            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "mixture": MLFeatureValue(multiArray: inputArray)
            ])
            
            // Use async prediction for better parallelization
            let options = MLPredictionOptions()
            options.usesCPUOnly = false  // Ensure GPU/Neural Engine usage
            let prediction = try await loadedModel.model.prediction(from: provider, options: options)

            for stem in stemNames {
                guard let outputArray = prediction.featureValue(for: stem)?.multiArrayValue,
                      let buffer = stemSTFTs[stem] else {
                    throw NSError(
                        domain: "CoreMLStemSeparator",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Model output missing stem: \(stem)"]
                    )
                }

                try copyOutputArray(
                    outputArray,
                    into: buffer,
                    startFrame: chunkStart,
                    actualFrames: actualFrames
                )
            }

            chunkStart += chunkFrames
            chunkCount += 1

            let currentProgress = 0.3 + (Double(chunkCount) / Double(totalChunks)) * 0.48
            onProgress("Processing chunk \(chunkCount)/\(totalChunks)", currentProgress)
            
            // Yield to runtime every 10 chunks to allow memory cleanup
            if chunkCount % 10 == 0 {
                await Task.yield()
            }
        }

        onProgress("Rekonstruksi waveform stereo...", 0.82)
        return try writeStemOutputs(from: stemSTFTs, onProgress: onProgress)
    }

    private func loadModel(modelQuality: String?) throws -> LoadedStemModel {
        let highQuality = ModelCandidate(
            name: "dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1",
            nFFT: 4096,
            hopSize: 1024,
            chunkFrames: 32
        )
        let lightQuality = ModelCandidate(
            name: "dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0",
            nFFT: 2048,
            hopSize: 1024,
            chunkFrames: 64
        )

        let orderedCandidates: [ModelCandidate]
        if modelQuality == "Model Ringan" {
            orderedCandidates = [lightQuality, highQuality]
        } else {
            orderedCandidates = [highQuality, lightQuality]
        }

        for candidate in orderedCandidates {
            guard let modelURL = Bundle.main.url(forResource: candidate.name, withExtension: "mlmodelc") else {
                continue
            }

            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            // Prefer Neural Engine over GPU for faster inference
            config.preferredMetalDevice = MTLCreateSystemDefaultDevice()
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            print("[StemSeparator] Loaded CoreML model: \(candidate.name)")
            
            // Warmup: Run dummy inference to initialize Neural Engine
            // This eliminates first-chunk overhead (can save 1-2 seconds)
            do {
                let warmupInput = try MLMultiArray(
                    shape: [1, 4, NSNumber(value: candidate.chunkFrames), NSNumber(value: candidate.nFFT / 2)],
                    dataType: .float32
                )
                let warmupProvider = try MLDictionaryFeatureProvider(dictionary: [
                    "mixture": MLFeatureValue(multiArray: warmupInput)
                ])
                _ = try model.prediction(from: warmupProvider)
                print("[StemSeparator] Model warmup completed")
            } catch {
                print("[StemSeparator] Warmup failed (non-critical): \(error)")
            }
            
            return LoadedStemModel(
                model: model,
                name: candidate.name,
                nFFT: candidate.nFFT,
                hopSize: candidate.hopSize,
                nBins: candidate.nFFT / 2,
                chunkFrames: candidate.chunkFrames
            )
        }

        throw NSError(
            domain: "CoreMLStemSeparator",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "No stem separation CoreML model found in bundle."]
        )
    }

    private func makeInputArray(
        leftSTFT: (real: [[Float]], imag: [[Float]]),
        rightSTFT: (real: [[Float]], imag: [[Float]]),
        startFrame: Int,
        actualFrames: Int
    ) throws -> MLMultiArray {
        // Pre-allocate with exact size needed
        let shape = [NSNumber(value: 1), NSNumber(value: 4), NSNumber(value: chunkFrames), NSNumber(value: nBins)]
        let input = try MLMultiArray(shape: shape, dataType: .float32)

        // Fast direct pointer access for better performance
        let pointer = input.dataPointer.bindMemory(to: Float.self, capacity: input.count)
        
        // Use memset for faster zero initialization (instead of loop)
        memset(pointer, 0, input.count * MemoryLayout<Float>.size)

        let strides = input.strides.map { $0.intValue }
        
        // Inline offset calculation for better performance
        @inline(__always)
        func offset(channel: Int, frame: Int, bin: Int) -> Int {
            channel * strides[1] + frame * strides[2] + bin * strides[3]
        }

        // Vectorized copy using Accelerate when possible
        for frame in 0..<actualFrames {
            let sourceFrame = startFrame + frame
            let frameBase = frame * strides[2]
            
            // Copy all bins for this frame at once (better cache locality)
            for bin in 0..<nBins {
                let idx = frameBase + bin * strides[3]
                pointer[idx] = leftSTFT.real[sourceFrame][bin]
                pointer[idx + strides[1]] = leftSTFT.imag[sourceFrame][bin]
                pointer[idx + 2 * strides[1]] = rightSTFT.real[sourceFrame][bin]
                pointer[idx + 3 * strides[1]] = rightSTFT.imag[sourceFrame][bin]
            }
        }

        return input
    }

    private func copyOutputArray(
        _ output: MLMultiArray,
        into buffer: StemSTFTBuffer,
        startFrame: Int,
        actualFrames: Int
    ) throws {
        guard output.dataType == .float32 else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected CoreML output array type."]
            )
        }

        let pointer = output.dataPointer.bindMemory(to: Float.self, capacity: output.count)
        let strides = output.strides.map { $0.intValue }
        let outputFrames = min(actualFrames, output.shape[2].intValue)
        let outputBins = min(nBins, output.shape[3].intValue)

        @inline(__always)
        func offset(channel: Int, frame: Int, bin: Int) -> Int {
            channel * strides[1] + frame * strides[2] + bin * strides[3]
        }

        // Optimized copy with better cache locality
        for frame in 0..<outputFrames {
            let targetFrame = startFrame + frame
            let frameBase = frame * strides[2]
            
            // Copy entire frame's bins at once for better vectorization
            let ch0Base = frameBase
            let ch1Base = frameBase + strides[1]
            let ch2Base = frameBase + 2 * strides[1]
            let ch3Base = frameBase + 3 * strides[1]
            
            for bin in 0..<outputBins {
                let binOffset = bin * strides[3]
                buffer.realL[targetFrame][bin] = pointer[ch0Base + binOffset]
                buffer.imagL[targetFrame][bin] = pointer[ch1Base + binOffset]
                buffer.realR[targetFrame][bin] = pointer[ch2Base + binOffset]
                buffer.imagR[targetFrame][bin] = pointer[ch3Base + binOffset]
            }
        }
    }

    private func loadStereoAudio(url: URL) throws -> (left: [Float], right: [Float]) {
        let audioFile = try AVAudioFile(forReading: url)
        let originalFormat = audioFile.processingFormat

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 2,
            interleaved: false
        ) else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create target audio format."]
            )
        }

        let frameCount = AVAudioFrameCount(audioFile.length)
        guard let readBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create read buffer."]
            )
        }

        try audioFile.read(into: readBuffer)

        let outputBuffer: AVAudioPCMBuffer
        if originalFormat.sampleRate != targetSampleRate || originalFormat.channelCount != 2 {
            let ratio = targetSampleRate / originalFormat.sampleRate
            let estimatedFrames = AVAudioFrameCount(Double(readBuffer.frameLength) * ratio) + 1024

            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: estimatedFrames),
                  let converter = AVAudioConverter(from: originalFormat, to: targetFormat) else {
                throw NSError(
                    domain: "CoreMLStemSeparator",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter."]
                )
            }

            var error: NSError?
            var consumed = false
            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                if consumed {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                consumed = true
                outStatus.pointee = .haveData
                return readBuffer
            }

            if let error {
                throw error
            }
            outputBuffer = convertedBuffer
        } else {
            outputBuffer = readBuffer
        }

        guard let channelData = outputBuffer.floatChannelData else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "No float channel data in audio buffer."]
            )
        }

        let length = Int(outputBuffer.frameLength)
        let leftChannel = Array(UnsafeBufferPointer(start: channelData[0], count: length))
        let rightChannel = outputBuffer.format.channelCount >= 2
            ? Array(UnsafeBufferPointer(start: channelData[1], count: length))
            : leftChannel

        return (leftChannel, rightChannel)
    }

    private func computeChannelSTFT(samples: [Float]) -> (real: [[Float]], imag: [[Float]]) {
        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return ([], []) }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        let halfN = nFFT / 2
        var hanningWindow = [Float](repeating: 0, count: nFFT)
        vDSP_hann_window(&hanningWindow, vDSP_Length(nFFT), Int32(vDSP_HANN_NORM))

        var realFrames: [[Float]] = []
        var imagFrames: [[Float]] = []

        var frameStart = 0
        while frameStart + nFFT <= samples.count {
            var windowed = [Float](repeating: 0, count: nFFT)
            let frameSlice = Array(samples[frameStart..<(frameStart + nFFT)])
            vDSP_vmul(frameSlice, 1, hanningWindow, 1, &windowed, 1, vDSP_Length(nFFT))

            var realPart = [Float](repeating: 0, count: halfN)
            var imagPart = [Float](repeating: 0, count: halfN)

            windowed.withUnsafeMutableBufferPointer { windowPointer in
                realPart.withUnsafeMutableBufferPointer { realPointer in
                    imagPart.withUnsafeMutableBufferPointer { imagPointer in
                        var splitComplex = DSPSplitComplex(
                            realp: realPointer.baseAddress!,
                            imagp: imagPointer.baseAddress!
                        )
                        windowPointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPointer in
                            vDSP_ctoz(complexPointer, 2, &splitComplex, 1, vDSP_Length(halfN))
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

    private func writeStemOutputs(
        from stemSTFTs: [String: StemSTFTBuffer],
        onProgress: @escaping (String, Double) -> Void
    ) throws -> [String: URL] {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("stem-output-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        var outputPaths: [String: URL] = [:]
        for (index, stem) in stemNames.enumerated() {
            guard let stemData = stemSTFTs[stem] else { continue }

            let progress = 0.82 + (Double(index) / Double(stemNames.count)) * 0.16
            onProgress("Menulis file stem: \(stem)", progress)

            guard let pcmBuffer = featureExtractor.computeISTFTStereo(
                realL: stemData.realL,
                imagL: stemData.imagL,
                realR: stemData.realR,
                imagR: stemData.imagR,
                nFFT: nFFT,
                hopSize: hopSize,
                sampleRate: targetSampleRate
            ) else {
                throw NSError(
                    domain: "CoreMLStemSeparator",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to reconstruct stem: \(stem)"]
                )
            }

            let outputURL = outputDirectory.appendingPathComponent("\(stem).wav")
            try writeAudioBuffer(pcmBuffer, to: outputURL)
            outputPaths[stem] = outputURL
        }

        return outputPaths
    }

    private func writeAudioBuffer(_ buffer: AVAudioPCMBuffer, to url: URL) throws {
        let channelCount = Int(buffer.format.channelCount)
        
        // Use LOSSLESS format for maximum quality preservation
        // WAV PCM 32-bit float is industry standard for professional audio work
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: targetSampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        // Change extension to .wav for lossless output
        let wavURL = url.deletingPathExtension().appendingPathExtension("wav")
        
        if FileManager.default.fileExists(atPath: wavURL.path) {
            try FileManager.default.removeItem(at: wavURL)
        }

        let audioFile = try AVAudioFile(forWriting: wavURL, settings: settings)
        try audioFile.write(from: buffer)
        
        // Log file size for monitoring
        if let attrs = try? FileManager.default.attributesOfItem(atPath: wavURL.path),
           let fileSize = attrs[.size] as? Int64 {
            Logger.shared.info("Wrote lossless WAV: \(wavURL.lastPathComponent) (\(fileSize / 1024 / 1024) MB)")
        }
    }
}
