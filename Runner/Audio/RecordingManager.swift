import Foundation
import AVFoundation

/// Manages high-quality audio recording with real-time level monitoring.
public class RecordingManager {
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private var audioFile: AVAudioFile?
    private var isRecording = false
    
    public var currentLevelLeft: Float = 0.0
    public var currentLevelRight: Float = 0.0
    public var recordingDuration: Double = 0.0
    private var recordingStartTime: Date?
    
    public init() {
        inputNode = audioEngine.inputNode
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true)
            print("RecordingManager: Audio session configured for recording")
        } catch {
            print("RecordingManager: Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    /// Starts recording to a destination URL
    public func startRecording(to url: URL) throws {
        guard !isRecording else { return }
        
        let format = inputNode.outputFormat(forBus: 0) ?? AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        
        let tapBlock: AVAudioNodeTapBlock = { [weak self] buffer, _ in
            try? self?.audioFile?.write(from: buffer)
            self?.updateLevels(from: buffer)
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format, block: tapBlock)
        audioEngine.prepare()
        try audioEngine.start()
        
        recordingStartTime = Date()
        isRecording = true
        print("RecordingManager: Started recording to \(url.lastPathComponent)")
    }
    
    /// Stops recording
    public func stopRecording() {
        guard isRecording else { return }
        
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        recordingDuration = Date().timeIntervalSince(recordingStartTime ?? Date())
        print("RecordingManager: Stopped recording after \(recordingDuration) seconds")
    }
    
    private func updateLevels(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS for left channel
        if buffer.format.channelCount > 0 {
            let leftChannel = channelData[0]
            var sumSquare: Float = 0
            for i in 0..<frameLength {
                let val = leftChannel[i]
                sumSquare += val * val
            }
            let rms = sqrt(sumSquare / Float(frameLength))
            currentLevelLeft = rms
        }
        
        // Calculate RMS for right channel if stereo
        if buffer.format.channelCount > 1 {
            let rightChannel = channelData[1]
            var sumSquare: Float = 0
            for i in 0..<frameLength {
                let val = rightChannel[i]
                sumSquare += val * val
            }
            let rms = sqrt(sumSquare / Float(frameLength))
            currentLevelRight = rms
        }
    }
    
    public func getRecordingDuration() -> String {
        let seconds = Int(recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
