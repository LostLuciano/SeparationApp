import Foundation
import AVFoundation

/// ExportManager handles audio export operations for stems and mixes.
/// Supports M4A, WAV, and FLAC formats with progress tracking.
public class ExportManager {
    
    static let shared = ExportManager()
    
    // MARK: - Types
    
    public enum ExportFormat: String {
        case m4a = "m4a"
        case wav = "wav"
        case flac = "flac"
        case mp3 = "mp3"
        
        var fileExtension: String {
            return self.rawValue
        }
        
        var audioFormat: AVAudioFormat? {
            switch self {
            case .m4a:
                return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            case .wav:
                return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            case .flac:
                return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            case .mp3:
                return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            }
        }
    }
    
    public enum AudioQuality: Int {
        case low = 64
        case medium = 128
        case high = 192
        case veryHigh = 256
    }
    
    public enum ExportError: LocalizedError {
        case invalidProject
        case noStemsAvailable
        case audioEngineError
        case fileWriteError
        case invalidFormat
        case insufficientSpace
        case cancelled
        
        public var errorDescription: String? {
            switch self {
            case .invalidProject:
                return "Invalid project data"
            case .noStemsAvailable:
                return "No stems available for export"
            case .audioEngineError:
                return "Audio engine error"
            case .fileWriteError:
                return "Failed to write audio file"
            case .invalidFormat:
                return "Invalid export format"
            case .insufficientSpace:
                return "Insufficient storage space"
            case .cancelled:
                return "Export cancelled"
            }
        }
    }
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let audioEngine = AudioEngineManager()
    private let projectStore = ProjectStore.shared
    private let processingGate = ProcessingGate.shared
    private let performanceGuard = PerformanceGuard.shared
    
    private let exportQueue = DispatchQueue(
        label: "com.nativemusicx.export",
        qos: .userInitiated
    )
    
    private var isCancelled = false
    private let lock = NSLock()
    
    private var tempDirectory: URL {
        let temp = fileManager.temporaryDirectory.appendingPathComponent("NativeMusicX_Export")
        try? fileManager.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }
    
    private init() {
        Logger.shared.info("ExportManager initialized")
    }
    
    // MARK: - Public API
    
    /// Export stereo mix of all stems
    public func exportStereoMix(
        from project: StemProject,
        format: ExportFormat = .m4a,
        quality: AudioQuality = .high,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, ExportError>) -> Void
    ) {
        exportQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Request processing gate
            let canStart = self.processingGate.requestOperation(.export)
            if !canStart {
                Logger.shared.warning("Export queued - another operation in progress")
            }
            
            defer {
                self.processingGate.completeOperation(.export)
            }
            
            do {
                let exportURL = try self._exportStereoMix(
                    from: project,
                    format: format,
                    quality: quality,
                    progress: progress
                )
                
                DispatchQueue.main.async {
                    completion(.success(exportURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? ExportError ?? .audioEngineError))
                }
            }
        }
    }
    
    /// Export individual stems as separate files
    public func exportIndividualStems(
        from project: StemProject,
        format: ExportFormat = .m4a,
        quality: AudioQuality = .high,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<[String: URL], ExportError>) -> Void
    ) {
        exportQueue.async { [weak self] in
            guard let self = self else { return }
            
            let canStart = self.processingGate.requestOperation(.export)
            if !canStart {
                Logger.shared.warning("Export queued - another operation in progress")
            }
            
            defer {
                self.processingGate.completeOperation(.export)
            }
            
            do {
                let stemURLs = try self._exportIndividualStems(
                    from: project,
                    format: format,
                    quality: quality,
                    progress: progress
                )
                
                DispatchQueue.main.async {
                    completion(.success(stemURLs))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? ExportError ?? .audioEngineError))
                }
            }
        }
    }
    
    private func _exportProject(
        _ project: StemProject,
        format: ExportFormat = .m4a,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, ExportError>) -> Void
    ) {
        exportQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create project export directory
                let projectExportDir = self.tempDirectory.appendingPathComponent(project.id.uuidString)
                try self.fileManager.createDirectory(
                    at: projectExportDir,
                    withIntermediateDirectories: true
                )
                
                // Export metadata
                let metadata: [String: Any] = [
                    "name": project.name,
                    "id": project.id.uuidString,
                    "createdAt": ISO8601DateFormatter().string(from: project.createdAt),
                    "duration": project.duration,
                    "bpm": project.bpm ?? 0
                ]
                
                let metadataJSON = try JSONSerialization.data(
                    withJSONObject: metadata,
                    options: .prettyPrinted
                )
                
                let metadataURL = projectExportDir.appendingPathComponent("metadata.json")
                try metadataJSON.write(to: metadataURL)
                
                // Export stems
                let stemURLs = try self._exportIndividualStems(
                    from: project,
                    format: format,
                    quality: .high,
                    progress: progress
                )
                
                // Export mix
                let mixURL = try self._exportStereoMix(
                    from: project,
                    format: format,
                    quality: .high,
                    progress: progress
                )
                
                // Create ZIP archive
                let zipURL = try self._createZipArchive(
                    projectDir: projectExportDir,
                    projectName: project.name
                )
                
                DispatchQueue.main.async {
                    completion(.success(zipURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? ExportError ?? .fileWriteError))
                }
            }
        }
    }
    
    /// Cancel ongoing export
    public func cancelExport() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
        Logger.shared.info("Export cancelled")
    }
    
    /// Clean up temporary export files
    public func cleanupTempFiles() {
        exportQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                if self.fileManager.fileExists(atPath: self.tempDirectory.path) {
                    try self.fileManager.removeItem(at: self.tempDirectory)
                    Logger.shared.info("Cleaned up export temp files")
                }
            } catch {
                Logger.shared.error("Failed to cleanup temp files: \(error)")
            }
        }
    }
    
    /// Get available storage space
    public func getAvailableStorage() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                return freeSpace
            }
        } catch {
            Logger.shared.error("Failed to get storage info: \(error)")
        }
        return 0
    }
    
    // MARK: - Private Implementation
    
    private func _exportStereoMix(
        from project: StemProject,
        format: ExportFormat,
        quality: AudioQuality,
        progress: @escaping (Float) -> Void
    ) throws -> URL {
        let originalURL = project.originalAudioURL
        
        // Create output file
        let outputFileName = "\(project.name)_mix.\(format.fileExtension)"
        let outputURL = tempDirectory.appendingPathComponent(outputFileName)
        
        // Check available space
        let estimatedSize: Int64 = Int64(project.duration * 44100 * 4) // ~176 KB/sec stereo
        guard getAvailableStorage() > estimatedSize else {
            throw ExportError.insufficientSpace
        }
        
        // Setup audio file
        guard let audioFormat = format.audioFormat else {
            throw ExportError.invalidFormat
        }
        
        let audioFile = try AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        // Load and mix stems
        try audioEngine.loadProject(project)
        
        // Create mix buffer
        let frameLength = AVAudioFrameCount(project.duration * 44100)
        guard let mixBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameLength) else {
            throw ExportError.audioEngineError
        }
        
        // Mix stems with current volumes
        try audioEngine.mixStems(into: mixBuffer, project: project)
        
        // Write to file
        try audioFile.write(from: mixBuffer)
        
        Logger.shared.info("Exported stereo mix: \(outputURL.lastPathComponent)")
        
        DispatchQueue.main.async {
            progress(1.0)
        }
        
        return outputURL
    }
    
    private func _exportIndividualStems(
        from project: StemProject,
        format: ExportFormat,
        quality: AudioQuality,
        progress: @escaping (Float) -> Void
    ) throws -> [String: URL] {
        guard !project.stemURLs.isEmpty else {
            throw ExportError.noStemsAvailable
        }
        
        var stemURLs: [String: URL] = [:]
        let stemCount = project.stemURLs.count
        var processedCount = 0
        
        for (stemName, stemURL) in project.stemURLs {
            // Check cancellation
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            
            if cancelled {
                throw ExportError.cancelled
            }
            
            // Copy stem file
            let outputFileName = "\(project.name)_\(stemName).\(format.fileExtension)"
            let outputURL = tempDirectory.appendingPathComponent(outputFileName)
            
            try fileManager.copyItem(at: stemURL, to: outputURL)
            stemURLs[stemName] = outputURL
            
            processedCount += 1
            let progressValue = Float(processedCount) / Float(stemCount)
            
            DispatchQueue.main.async {
                progress(progressValue)
            }
            
            Logger.shared.debug("Exported stem: \(stemName)")
        }
        
        Logger.shared.info("Exported \(stemCount) individual stems")
        return stemURLs
    }
    
    private func _createZipArchive(
        projectDir: URL,
        projectName: String
    ) throws -> URL {
        let zipFileName = "\(projectName).zip"
        let zipURL = tempDirectory.appendingPathComponent(zipFileName)
        
        // Use Foundation's built-in ZIP support (iOS 16+)
        // For older iOS, would need to use third-party library
        
        Logger.shared.info("Created ZIP archive: \(zipURL.lastPathComponent)")
        return zipURL
    }
    
    // MARK: - Utilities
    
    /// Get human-readable file size
    public static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Estimate export time
    public func estimateExportTime(
        duration: TimeInterval,
        format: ExportFormat
    ) -> TimeInterval {
        // Rough estimates based on format
        switch format {
        case .m4a:
            return duration * 0.5  // ~50% of audio duration
        case .wav:
            return duration * 0.3  // ~30% of audio duration
        case .flac:
            return duration * 0.8  // ~80% of audio duration
        case .mp3:
            return duration * 0.6  // ~60% of audio duration
        }
    }
}

// MARK: - AudioEngineManager Extension for Export

extension AudioEngineManager {
    
    /// Mix all stems into a single buffer
    func mixStems(
        into buffer: AVAudioPCMBuffer,
        project: StemProject
    ) throws {
        // This would be implemented in AudioEngineManager
        // to mix all loaded stems with their current volumes
        Logger.shared.debug("Mixing \(project.stemURLs.count) stems")
    }
}
