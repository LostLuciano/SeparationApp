import Foundation
import AVFoundation

/// Manages multi-channel stem playback, mixing, recording, and real-time DSP effects using AVAudioEngine.
public class AudioEngineManager {
    
    private let audioEngine = AVAudioEngine()
    private let mainMixer = AVAudioMixerNode()
    private let dynamicsProcessor = AVAudioUnitDynamicsProcessor()
    private let timePitchNode = AVAudioUnitTimePitch()
    
    // Mapping of stem names to their respective player nodes
    private var players: [String: AVAudioPlayerNode] = [:]
    // Dictionary tracking local URLs for loaded stem files
    private var stemFiles: [String: URL] = [:]
    // Track loaded AVAudioFiles to support seeking
    private var audioFiles: [String: AVAudioFile] = [:]
    private var currentPosition: Double = 0.0
    private var rampTokens: [String: UUID] = [:]
    private let rampLock = NSLock()
    private var channelVolumes: [String: Float] = [:]
    private var mutedStemKeys: Set<String> = []
    private var soloedStemKeys: Set<String> = []
    
    private let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
    private static let nominalSliderVolume: Float = 0.85
    private static let masterHeadroom: Float = 0.86
    private static let maxLoudnessCompensation: Float = 1.22
    
    public init() {
        configureAudioSession()
        setupAudioEngine()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("AVAudioSession: Configured category to .playback for background audio.")
        } catch {
            print("AVAudioSession: Failed to set category: \(error.localizedDescription)")
        }
    }
    
    /// Initializes player nodes, attaches them to the audio engine graph, and configures mixer routing.
    private func setupAudioEngine() {
        audioEngine.attach(mainMixer)
        audioEngine.attach(dynamicsProcessor)
        audioEngine.attach(timePitchNode)
        
        configureMasterBus()

        // Route all stems through a protected master bus before playback.
        audioEngine.connect(mainMixer, to: dynamicsProcessor, format: nil)
        audioEngine.connect(dynamicsProcessor, to: timePitchNode, format: nil)
        audioEngine.connect(timePitchNode, to: audioEngine.outputNode, format: nil)
        
        for name in stemNames {
            let player = AVAudioPlayerNode()
            players[name] = player
            audioEngine.attach(player)
            
            // Connect each player to the main mixer
            // format: nil lets AVAudioEngine resolve matching connections dynamically
            audioEngine.connect(player, to: mainMixer, format: nil)
        }
    }

    private func configureMasterBus() {
        mainMixer.outputVolume = 1.0

        dynamicsProcessor.threshold = -3.0
        dynamicsProcessor.headRoom = 5.0
        dynamicsProcessor.attackTime = 0.003
        dynamicsProcessor.releaseTime = 0.08
        dynamicsProcessor.masterGain = 0.0
    }
    
    /// Loads isolated stem files into player buffers.
    /// - Parameter stems: Dictionary mapping stem names to local file system URLs.
    public func loadStemFiles(_ stems: [String: URL]) throws {
        // Skip reload if identical
        if self.stemFiles == stems && !audioFiles.isEmpty {
            print("AVAudioEngine: Stems already loaded, skipping reload.")
            return
        }
        
        self.stemFiles = stems
        self.audioFiles.removeAll()
        resetMixState(for: Set(stems.keys))
        
        for (name, url) in stems {
            guard let player = players[name] else { continue }
            player.stop()
            
            do {
                let file = try AVAudioFile(forReading: url)
                self.audioFiles[name] = file
                print("Loaded audio file for \(name): \(url.lastPathComponent) (length: \(file.length) frames)")
            } catch {
                print("Failed to read stem file \(name): \(error.localizedDescription)")
                throw error
            }
        }
        
        // Schedule all files from the beginning
        currentPosition = 0.0
        reschedulePlayers(at: 0.0)
        
        // Prepare the engine
        audioEngine.prepare()
        applyCurrentMix()
    }

    private func resetMixState(for stems: Set<String>) {
        channelVolumes = Dictionary(uniqueKeysWithValues: stemNames.map { stem in
            (stem, stems.contains(stem) ? Self.nominalSliderVolume : 0.0)
        })
        mutedStemKeys.removeAll()
        soloedStemKeys.removeAll()
    }
    
    private func reschedulePlayers(at time: Double) {
        for (name, player) in players {
            player.stop() // stops playback and removes scheduled events
            
            guard let file = audioFiles[name] else { continue }
            let sampleRate = file.fileFormat.sampleRate
            let startFrame = AVAudioFramePosition(time * sampleRate)
            
            if startFrame < file.length {
                let frameCount = AVAudioFrameCount(file.length - startFrame)
                player.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil, completionHandler: nil)
                print("Rescheduled \(name) from frame \(startFrame) / \(file.length) (\(frameCount) frames)")
            }
        }
    }
    
    /// Seeks all player nodes to the specified position in seconds.
    public func seek(to time: Double) {
        currentPosition = time
        let wasRunning = audioEngine.isRunning
        let isPlaying = players.values.contains { $0.isPlaying }
        
        reschedulePlayers(at: time)
        
        if wasRunning && isPlaying {
            for (_, player) in players {
                player.play()
            }
        }
    }
    
    /// Starts simultaneous playback of all loaded players.
    public func play() throws {
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        
        for (_, player) in players {
            player.play()
        }
        print("AVAudioEngine: Started simultaneous playback of all stem player nodes.")
    }
    
    /// Pauses all players.
    public func pause() {
        for (_, player) in players {
            player.pause()
        }
        print("AVAudioEngine: Paused playback.")
    }
    
    /// Stops all players and resets the audio engine.
    public func stop() {
        for (_, player) in players {
            player.stop()
        }
        audioEngine.stop()
        print("AVAudioEngine: Stopped engine graph.")
    }
    
    /// Implement setStemVolume as requested
    public func setStemVolume(stem: String, volume: Float) {
        let clampedVolume = max(0.0, min(volume, 1.0))
        
        let pathOnDisk = stemFiles[stem]?.lastPathComponent ?? "unknown"
        let isNodePlaying = players[stem]?.isPlaying ?? false
        let nodeExists = players[stem] != nil
        
        if players[stem] != nil {
            channelVolumes[stem] = clampedVolume
            applyCurrentMix()
        } else {
            print("Unknown stem volume target: \(stem)")
        }
        
        // Target Fix: debug log requested
        print("""
        setStemVolume called
        stem: \(stem)
        volume: \(clampedVolume)
        node exists: \(nodeExists)
        file path: \(pathOnDisk)
        is playing: \(isNodePlaying)
        """)
    }

    /// Applies all channel levels together so the mix stays consistent when one stem is lowered or muted.
    public func applyBalancedMix(volumes: [String: Float], mutedStems: Set<String>, soloedStems: Set<String>) {
        for (stem, volume) in volumes {
            channelVolumes[stem] = max(0.0, min(volume, 1.0))
        }
        mutedStemKeys = mutedStems
        soloedStemKeys = soloedStems
        applyCurrentMix()
    }

    public static func balancedGains(
        volumes: [String: Float],
        mutedStems: Set<String> = [],
        soloedStems: Set<String> = []
    ) -> [String: Float] {
        let stems = Array(Set(stemNamesForMixing).union(volumes.keys)).sorted()
        let soloMode = !soloedStems.isEmpty
        var rawGains: [String: Float] = [:]
        var activeEnergy: Float = 0.0

        for stem in stems {
            let sliderVolume = max(0.0, min(volumes[stem] ?? nominalSliderVolume, 1.0))
            let shouldMute = mutedStems.contains(stem) || (soloMode && !soloedStems.contains(stem))
            let gain = shouldMute ? 0.0 : sliderVolumeToAudioGain(sliderVolume)
            rawGains[stem] = gain
            activeEnergy += gain * gain
        }

        let referenceGain = sliderVolumeToAudioGain(nominalSliderVolume)
        let referenceEnergy = Float(max(stems.count, 1)) * referenceGain * referenceGain
        let needsCompensation = rawGains.values.contains { $0 < referenceGain * 0.25 }
        let compensation: Float
        if needsCompensation && activeEnergy > 0.0001 {
            compensation = min(maxLoudnessCompensation, max(1.0, sqrt(referenceEnergy / activeEnergy)))
        } else {
            compensation = 1.0
        }

        return rawGains.mapValues { min(1.0, $0 * compensation * masterHeadroom) }
    }

    private static var stemNamesForMixing: [String] {
        ["vocals", "drums", "bass", "guitar", "piano", "other"]
    }

    private static func sliderVolumeToAudioGain(_ volume: Float) -> Float {
        guard volume > 0.001 else { return 0.0 }
        let shaped = pow(max(0.0, min(volume, 1.0)), 1.35)
        return min(1.0, shaped)
    }

    private func applyCurrentMix() {
        let gains = Self.balancedGains(
            volumes: channelVolumes,
            mutedStems: mutedStemKeys,
            soloedStems: soloedStemKeys
        )

        for stem in stemNames {
            guard let player = players[stem] else { continue }
            rampVolume(for: stem, player: player, to: gains[stem] ?? 0.0)
        }
    }

    private func rampVolume(for stem: String, player: AVAudioPlayerNode, to targetVolume: Float) {
        let token = UUID()
        let startVolume = player.volume
        rampLock.lock()
        rampTokens[stem] = token
        rampLock.unlock()

        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak player] in
            let steps: Int32 = 10
            for step in 1...steps {
                guard let self, let player else { return }
                self.rampLock.lock()
                let isCurrent = self.rampTokens[stem] == token
                self.rampLock.unlock()
                guard isCurrent else { return }

                let amount = Float(step) / Float(steps)
                let easedAmount = amount * amount * (3.0 - 2.0 * amount)
                player.volume = startVolume + (targetVolume - startVolume) * easedAmount
                usleep(4_000)
            }
        }
    }
    
    /// Adjusts the volume slider value for a specific stem channel.
    /// - Parameters:
    ///   - stem: The identifier of the stem ("vocals", "drums", etc.)
    ///   - volume: A float value between 0.0 (silent) and 1.0 (full volume).
    public func setVolume(stem: String, volume: Float) {
        setStemVolume(stem: stem, volume: volume)
    }
    
    /// Mutes or unmutes a specific stem.
    /// - Parameters:
    ///   - stem: The identifier of the stem.
    ///   - muted: True to mute, False to restore.
    public func muteStem(_ stem: String, muted: Bool) {
        guard players[stem] != nil else { return }
        if muted {
            mutedStemKeys.insert(stem)
        } else {
            mutedStemKeys.remove(stem)
        }
        applyCurrentMix()
        print("AVAudioEngine: \(stem) is \(muted ? "muted" : "unmuted")")
    }
    
    /// Solos a specific stem by muting all other active channels.
    /// - Parameter stem: The identifier of the stem to isolate.
    public func soloStem(_ stem: String) {
        setSoloStem(stem, soloed: true)
    }

    public func setSoloStem(_ stem: String, soloed: Bool) {
        guard players[stem] != nil else { return }
        if soloed {
            soloedStemKeys.insert(stem)
        } else {
            soloedStemKeys.remove(stem)
        }
        applyCurrentMix()
        print("AVAudioEngine: \(stem) solo is \(soloed ? "enabled" : "disabled")")
    }
    
    /// Adjusts the overall playback speed (tempo) without modifying pitch.
    /// - Parameter speed: Playback speed multiplier (e.g. 0.5 to 2.0).
    public func setPlaybackSpeed(_ speed: Float) {
        timePitchNode.rate = speed
        print("AVAudioEngine: Set playback speed to \(speed)")
    }
    
    /// Adjusts the overall playback pitch in semitones (-12 to +12).
    /// - Parameter semitones: Pitch offset in semitones.
    public func setPitchShift(_ semitones: Float) {
        // pitch is in cents, 1 semitone = 100 cents
        timePitchNode.pitch = semitones * 100.0
        print("AVAudioEngine: Set pitch shift to \(semitones) semitones (\(semitones * 100.0) cents)")
    }
    
    /// Extracts the audio track from a video file and writes it to a destination M4A URL.
    public func extractAudio(from videoURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: videoURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        if exportSession.status == .failed {
            throw exportSession.error ?? NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Audio extraction failed"])
        }
        print("AVAudioEngine: Successfully extracted audio from video: \(videoURL.lastPathComponent) -> \(outputURL.lastPathComponent)")
    }
    
    /// Merges/mixes two audio files together into a single M4A file.
    public func mixAudioFiles(file1URL: URL, file2URL: URL, outputURL: URL) async throws {
        let composition = AVMutableComposition()
        
        let asset1 = AVURLAsset(url: file1URL)
        let asset2 = AVURLAsset(url: file2URL)
        
        // Wait for audio tracks to load asynchronously
        guard let audioTrack1 = try? await asset1.loadTracks(withMediaType: .audio).first,
              let audioTrack2 = try? await asset2.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "AudioEngineManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load audio tracks from inputs"])
        }
        
        let compTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let duration1 = try await asset1.load(.duration)
        let duration2 = try await asset2.load(.duration)
        
        let timeRange1 = CMTimeRange(start: .zero, duration: duration1)
        let timeRange2 = CMTimeRange(start: .zero, duration: duration2)
        
        try compTrack1?.insertTimeRange(timeRange1, of: audioTrack1, at: .zero)
        try compTrack2?.insertTimeRange(timeRange2, of: audioTrack2, at: .zero)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession for composition"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        if exportSession.status == .failed {
            throw exportSession.error ?? NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mashup composition export failed"])
        }
        print("AVAudioEngine: Successfully mixed/mashup files: \(file1URL.lastPathComponent) + \(file2URL.lastPathComponent) -> \(outputURL.lastPathComponent)")
    }
    
    /// Exports the current stem mix with individual volume adjustments into a single output file using offline rendering.
    public func exportStemMix(volumes: [String: Float], outputURL: URL) async throws {
        try await exportStemMix(
            volumes: volumes,
            outputURL: outputURL,
            startTime: 0.0,
            duration: nil,
            quality: .high
        )
    }

    public func exportStemMix(
        volumes: [String: Float],
        outputURL: URL,
        startTime: Double,
        duration: Double?,
        quality: AudioExportQuality
    ) async throws {
        // Stop current playing engine
        let wasRunning = audioEngine.isRunning
        if wasRunning {
            self.stop()
        }
        
        // Setup offline manual rendering mode
        let maxNumberOfFrames: AVAudioFrameCount = 4096
        
        // We need to calculate the maximum duration from loaded audio files
        var maxDuration: Double = 0.0
        for (_, file) in audioFiles {
            let duration = Double(file.length) / file.fileFormat.sampleRate
            if duration > maxDuration {
                maxDuration = duration
            }
        }
        
        guard maxDuration > 0 else {
            throw NSError(domain: "AudioEngineManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No stem audio files loaded for exporting"])
        }

        let safeStartTime = max(0.0, min(startTime, maxDuration))
        let renderDuration = min(duration ?? (maxDuration - safeStartTime), maxDuration - safeStartTime)
        guard renderDuration > 0 else {
            throw NSError(domain: "AudioEngineManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid export range"])
        }
        
        // Temporarily adjust volumes of players to match the export configuration
        let originalVolumes = players.mapValues { $0.volume }
        for (stem, vol) in volumes {
            if let player = players[stem] {
                player.volume = vol
            }
        }
        
        // Enable manual rendering mode
        let format = mainMixer.outputFormat(forBus: 0)
        do {
            try audioEngine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
        } catch {
            // Restore volumes
            for (stem, vol) in originalVolumes {
                players[stem]?.volume = vol
            }
            throw error
        }
        
        // Start engine
        try audioEngine.start()
        
        // Schedule play from selected export range
        reschedulePlayers(at: safeStartTime)
        for (_, player) in players {
            player.play()
        }
        
        // Open output file for writing
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: exportSettings(for: quality, format: format))
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxNumberOfFrames)!
        
        var totalFramesRendered: AVAudioFramePosition = 0
        let totalFramesToRender = AVAudioFramePosition(renderDuration * format.sampleRate)
        
        while totalFramesRendered < totalFramesToRender {
            let framesToRender = min(maxNumberOfFrames, AVAudioFrameCount(totalFramesToRender - totalFramesRendered))
            let status = try audioEngine.renderOffline(framesToRender, to: buffer)
            
            switch status {
            case .success:
                try outputFile.write(from: buffer)
                totalFramesRendered += AVAudioFramePosition(framesToRender)
            case .insufficientDataFromInputNode:
                // Node had no data; continue
                break;
            case .cannotDoInCurrentContext:
                break;
            case .error:
                throw NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error during offline rendering"])
            @unknown default:
                break;
            }
        }
        
        // Clean up: stop, disable manual rendering, and restore engine state
        for (_, player) in players {
            player.stop()
        }
        audioEngine.stop()
        audioEngine.disableManualRenderingMode()
        
        // Restore volumes
        for (stem, vol) in originalVolumes {
            players[stem]?.volume = vol
        }
        
        // Restart engine if it was running before
        if wasRunning {
            try? audioEngine.start()
            reschedulePlayers(at: currentPosition)
        }
    }

    private func exportSettings(for quality: AudioExportQuality, format: AVAudioFormat) -> [String: Any] {
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)

        if quality == .lossless {
            return [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channelCount,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsNonInterleaved: false
            ]
        }

        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVEncoderBitRateKey: channelCount * quality.bitRatePerChannel,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    /// Loads stems from a StemProject - compatibility method for ExportManager
    /// - Parameter project: StemProject containing stem data and URLs
    public func loadProject(_ project: StemProject) throws {
        try loadStemFiles(project.stemPaths)
    }
}
