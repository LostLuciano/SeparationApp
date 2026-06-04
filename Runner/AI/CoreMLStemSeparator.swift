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
    private var modelCache: [String: LoadedStemModel] = [:]

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

    private final class StreamingStereoChunkReader {
        private let audioFile: AVAudioFile
        private let nFFT: Int
        private let hopSize: Int
        private let chunkFrames: Int
        private let maxReadFrames: AVAudioFrameCount = 32768
        private var leftBuffer: [Float] = []
        private var rightBuffer: [Float] = []
        private var reachedEnd = false

        init(audioFile: AVAudioFile, nFFT: Int, hopSize: Int, chunkFrames: Int) {
            self.audioFile = audioFile
            self.nFFT = nFFT
            self.hopSize = hopSize
            self.chunkFrames = chunkFrames
        }

        func nextChunk() throws -> (left: [Float], right: [Float], actualFrames: Int)? {
            let desiredSamples = (chunkFrames - 1) * hopSize + nFFT

            while leftBuffer.count < desiredSamples && !reachedEnd {
                try readMoreSamples(targetSamples: desiredSamples - leftBuffer.count)
            }

            guard leftBuffer.count >= nFFT else { return nil }

            let availableFrames = ((leftBuffer.count - nFFT) / hopSize) + 1
            let actualFrames = min(chunkFrames, availableFrames)
            let chunkSampleCount = (actualFrames - 1) * hopSize + nFFT
            let consumedSamples = actualFrames * hopSize

            let leftChunk = Array(leftBuffer.prefix(chunkSampleCount))
            let rightChunk = Array(rightBuffer.prefix(chunkSampleCount))

            leftBuffer = Array(leftBuffer.dropFirst(min(consumedSamples, leftBuffer.count)))
            rightBuffer = Array(rightBuffer.dropFirst(min(consumedSamples, rightBuffer.count)))

            return (leftChunk, rightChunk, actualFrames)
        }

        private func readMoreSamples(targetSamples: Int) throws {
            let remainingFrames = audioFile.length - audioFile.framePosition
            guard remainingFrames > 0 else {
                reachedEnd = true
                return
            }

            let requestedFrames = min(
                maxReadFrames,
                AVAudioFrameCount(max(targetSamples, hopSize)),
                AVAudioFrameCount(remainingFrames)
            )

            guard let readBuffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: requestedFrames
            ) else {
                throw NSError(
                    domain: "CoreMLStemSeparator",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to allocate streaming read buffer."]
                )
            }

            try audioFile.read(into: readBuffer, frameCount: requestedFrames)

            guard readBuffer.frameLength > 0 else {
                reachedEnd = true
                return
            }

            guard let channelData = readBuffer.floatChannelData else {
                throw NSError(
                    domain: "CoreMLStemSeparator",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Streaming buffer has no float channel data."]
                )
            }

            let frameLength = Int(readBuffer.frameLength)
            let leftSamples = UnsafeBufferPointer(start: channelData[0], count: frameLength)
            let rightSamples = readBuffer.format.channelCount >= 2
                ? UnsafeBufferPointer(start: channelData[1], count: frameLength)
                : leftSamples

            leftBuffer.append(contentsOf: leftSamples)
            rightBuffer.append(contentsOf: rightSamples)

            if audioFile.framePosition >= audioFile.length {
                reachedEnd = true
            }
        }
    }

    public init() {}

    public func separate(
        audioURL: URL,
        processingMode: String?,
        modelQuality: String?,
        selectedStems: [String]? = nil,
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
                selectedStems: selectedStems,
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
        selectedStems: [String]?,
        onProgress: @escaping (String, Double) -> Void
    ) async throws -> [String: URL] {
        onProgress("Memuat model CoreML...", 0.05)
        let loadedModel = try loadModel(modelQuality: modelQuality)
        nFFT = loadedModel.nFFT
        hopSize = loadedModel.hopSize
        nBins = loadedModel.nBins
        chunkFrames = loadedModel.chunkFrames
        onProgress("Model aktif: \(loadedModel.name)", 0.07)

        onProgress("Menyiapkan streaming PCM 44.1kHz stereo...", 0.1)
        let streamingURL = try normalizeAudioForStreamingIfNeeded(url: audioURL)
        defer {
            if streamingURL != audioURL {
                try? FileManager.default.removeItem(at: streamingURL)
            }
        }

        let streamingFile = try AVAudioFile(forReading: streamingURL)
        let totalSamples = Int(streamingFile.length)
        let totalFrames = totalSamples >= nFFT
            ? ((totalSamples - nFFT) / hopSize) + 1
            : 0

        guard totalFrames > 0 else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "STFT produced zero frames."]
            )
        }

        let requestedStems = normalizedStemSelection(selectedStems)
        var stemSTFTs: [String: StemSTFTBuffer] = [:]
        for stem in requestedStems {
            stemSTFTs[stem] = StemSTFTBuffer(frameCount: totalFrames, binCount: nBins)
        }

        let totalChunks = Int(ceil(Double(totalFrames) / Double(chunkFrames)))
        let chunkReader = StreamingStereoChunkReader(
            audioFile: streamingFile,
            nFFT: nFFT,
            hopSize: hopSize,
            chunkFrames: chunkFrames
        )

        onProgress("Streaming STFT + inferensi CoreML (\(totalChunks) chunks)...", 0.2)

        var globalFrameStart = 0
        var chunkCount = 0

        while let chunk = try chunkReader.nextChunk() {
            try Task.checkCancellation()

            let leftSTFT = computeChannelSTFT(samples: chunk.left)
            let rightSTFT = computeChannelSTFT(samples: chunk.right)
            let actualFrames = min(
                chunk.actualFrames,
                leftSTFT.real.count,
                rightSTFT.real.count,
                totalFrames - globalFrameStart
            )

            guard actualFrames > 0 else { break }

            let inputArray = try makeInputArray(
                leftSTFT: leftSTFT,
                rightSTFT: rightSTFT,
                startFrame: 0,
                actualFrames: actualFrames
            )

            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "mixture": MLFeatureValue(multiArray: inputArray)
            ])
            let prediction = try await loadedModel.model.prediction(from: provider)

            for stem in requestedStems {
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
                    startFrame: globalFrameStart,
                    actualFrames: actualFrames
                )
            }

            globalFrameStart += actualFrames
            chunkCount += 1

            let currentProgress = 0.3 + (Double(chunkCount) / Double(totalChunks)) * 0.48
            onProgress("Streaming chunk \(chunkCount)/\(totalChunks)", currentProgress)
            await Task.yield()

            if globalFrameStart >= totalFrames {
                break
            }
        }

        onProgress("Rekonstruksi waveform stereo (\(requestedStems.count) stems)...", 0.82)
        return try writeStemOutputs(from: stemSTFTs, selectedStems: requestedStems, onProgress: onProgress)
    }

    private func normalizedStemSelection(_ selectedStems: [String]?) -> [String] {
        let available = Set(stemNames)
        let requested = selectedStems?
            .map { $0.lowercased() }
            .filter { available.contains($0) }

        guard let requested, !requested.isEmpty else {
            return stemNames
        }

        return stemNames.filter { requested.contains($0) }
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

        let normalizedQuality = modelQuality?.lowercased() ?? ""
        let wantsHighQuality = normalizedQuality.contains("high") || normalizedQuality.contains("standard")
        let orderedCandidates: [ModelCandidate] = wantsHighQuality
            ? [highQuality, lightQuality]
            : [lightQuality, highQuality]

        for candidate in orderedCandidates {
            if let cachedModel = modelCache[candidate.name] {
                print("[StemSeparator] Reusing CoreML model: \(candidate.name)")
                return cachedModel
            }

            guard let modelURL = Bundle.main.url(forResource: candidate.name, withExtension: "mlmodelc") else {
                continue
            }

            let config = MLModelConfiguration()
            config.computeUnits = .all
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            let loadedModel = LoadedStemModel(
                model: model,
                name: candidate.name,
                nFFT: candidate.nFFT,
                hopSize: candidate.hopSize,
                nBins: candidate.nFFT / 2,
                chunkFrames: candidate.chunkFrames
            )
            modelCache[candidate.name] = loadedModel
            print("[StemSeparator] Loaded CoreML model: \(candidate.name)")
            return loadedModel
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
        let input = try MLMultiArray(
            shape: [NSNumber(value: 1), NSNumber(value: 4), NSNumber(value: chunkFrames), NSNumber(value: nBins)],
            dataType: .float32
        )

        guard input.dataType == .float32 else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected CoreML input array type."]
            )
        }

        let pointer = input.dataPointer.bindMemory(to: Float.self, capacity: input.count)
        for index in 0..<input.count {
            pointer[index] = 0
        }

        let strides = input.strides.map { $0.intValue }
        func offset(channel: Int, frame: Int, bin: Int) -> Int {
            channel * strides[1] + frame * strides[2] + bin * strides[3]
        }

        for frame in 0..<actualFrames {
            let sourceFrame = startFrame + frame
            for bin in 0..<nBins {
                pointer[offset(channel: 0, frame: frame, bin: bin)] = leftSTFT.real[sourceFrame][bin]
                pointer[offset(channel: 1, frame: frame, bin: bin)] = leftSTFT.imag[sourceFrame][bin]
                pointer[offset(channel: 2, frame: frame, bin: bin)] = rightSTFT.real[sourceFrame][bin]
                pointer[offset(channel: 3, frame: frame, bin: bin)] = rightSTFT.imag[sourceFrame][bin]
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

        func offset(channel: Int, frame: Int, bin: Int) -> Int {
            channel * strides[1] + frame * strides[2] + bin * strides[3]
        }

        for frame in 0..<outputFrames {
            let targetFrame = startFrame + frame
            for bin in 0..<outputBins {
                buffer.realL[targetFrame][bin] = pointer[offset(channel: 0, frame: frame, bin: bin)]
                buffer.imagL[targetFrame][bin] = pointer[offset(channel: 1, frame: frame, bin: bin)]
                buffer.realR[targetFrame][bin] = pointer[offset(channel: 2, frame: frame, bin: bin)]
                buffer.imagR[targetFrame][bin] = pointer[offset(channel: 3, frame: frame, bin: bin)]
            }
        }
    }

    private func normalizeAudioForStreamingIfNeeded(url: URL) throws -> URL {
        let sourceFile = try AVAudioFile(forReading: url)
        let sourceFormat = sourceFile.processingFormat

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 2,
            interleaved: false
        ) else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create streaming target format."]
            )
        }

        let alreadyStreamable =
            abs(sourceFormat.sampleRate - targetSampleRate) < 0.5 &&
            sourceFormat.channelCount == 2 &&
            sourceFormat.commonFormat == .pcmFormatFloat32 &&
            !sourceFormat.isInterleaved

        if alreadyStreamable {
            return url
        }

        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw NSError(
                domain: "CoreMLStemSeparator",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create streaming audio converter."]
            )
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("streaming-pcm-\(UUID().uuidString).caf")

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: targetFormat.settings)
        let readCapacity: AVAudioFrameCount = 32768

        while sourceFile.framePosition < sourceFile.length {
            let remainingFrames = sourceFile.length - sourceFile.framePosition
            let frameCount = min(readCapacity, AVAudioFrameCount(remainingFrames))

            guard let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                frameCapacity: frameCount
            ) else {
                throw NSError(
                    domain: "CoreMLStemSeparator",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to allocate converter input buffer."]
                )
            }

            try sourceFile.read(into: inputBuffer, frameCount: frameCount)
            if inputBuffer.frameLength == 0 { break }

            let ratio = targetFormat.sampleRate / sourceFormat.sampleRate
            let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1024

            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputCapacity
            ) else {
                throw NSError(
                    domain: "CoreMLStemSeparator",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to allocate converter output buffer."]
                )
            }

            var consumedInput = false
            var conversionError: NSError?
            converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
                if consumedInput {
                    outStatus.pointee = .noDataNow
                    return nil
                }

                consumedInput = true
                outStatus.pointee = .haveData
                return inputBuffer
            }

            if let conversionError {
                throw conversionError
            }

            if outputBuffer.frameLength > 0 {
                try outputFile.write(from: outputBuffer)
            }
        }

        try flushConverter(converter, outputFile: outputFile, targetFormat: targetFormat)
        return outputURL
    }

    private func flushConverter(
        _ converter: AVAudioConverter,
        outputFile: AVAudioFile,
        targetFormat: AVAudioFormat
    ) throws {
        guard let flushBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: 4096
        ) else { return }

        var conversionError: NSError?
        converter.convert(to: flushBuffer, error: &conversionError) { _, outStatus in
            outStatus.pointee = .endOfStream
            return nil
        }

        if let conversionError {
            throw conversionError
        }

        if flushBuffer.frameLength > 0 {
            try outputFile.write(from: flushBuffer)
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
        selectedStems: [String],
        onProgress: @escaping (String, Double) -> Void
    ) throws -> [String: URL] {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("stem-output-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        var outputPaths: [String: URL] = [:]
        for (index, stem) in selectedStems.enumerated() {
            guard let stemData = stemSTFTs[stem] else { continue }

            let progress = 0.82 + (Double(index) / Double(max(selectedStems.count, 1))) * 0.16
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

            let outputURL = outputDirectory.appendingPathComponent("\(stem).m4a")
            try writeAudioBuffer(pcmBuffer, to: outputURL)
            outputPaths[stem] = outputURL
        }

        return outputPaths
    }

    private func writeAudioBuffer(_ buffer: AVAudioPCMBuffer, to url: URL) throws {
        let channelCount = Int(buffer.format.channelCount)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: targetSampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVEncoderBitRateKey: channelCount * 96000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        let audioFile = try AVAudioFile(forWriting: url, settings: settings)
        try audioFile.write(from: buffer)
    }
}
