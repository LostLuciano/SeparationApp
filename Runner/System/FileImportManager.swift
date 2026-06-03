import Foundation
import AVFoundation

/// Manages secure file import with format validation for 8+ audio/video formats.
public class FileImportManager {
    
    public static let shared = FileImportManager()
    
    private let supportedFormats = [
        "mp3", "wav", "m4a", "aac", "aiff", "caf", "flac",
        "mov", "mp4", "m4v", "mkv"
    ]
    
    public init() {}
    
    /// Check if file format is supported
    public func isFormatSupported(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return supportedFormats.contains(fileExtension)
    }
    
    /// Validate and copy imported file to sandbox
    /// - Parameter sourceURL: URL of the file to import
    /// - Parameter destinationDir: Target directory in app sandbox
    /// - Returns: URL of copied file in sandbox
    public func importFile(_ sourceURL: URL, to destinationDir: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw NSError(domain: "FileImportManager", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Source file not found"])
        }
        
        guard isFormatSupported(sourceURL) else {
            throw NSError(domain: "FileImportManager", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "File format not supported"])
        }
        
        // Validate audio/video file
        try validateAudioFile(sourceURL)
        
        // Create destination directory if needed
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        
        // Copy file
        let destinationURL = destinationDir.appendingPathComponent(sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        print("FileImportManager: Imported file to \(destinationURL.path)")
        return destinationURL
    }
    
    /// Validate that file is readable audio/video
    private func validateAudioFile(_ url: URL) throws {
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        
        guard duration > 0 && duration.isFinite else {
            throw NSError(domain: "FileImportManager", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid or corrupted audio/video file"])
        }
        
        Logger.shared.info("✓ File validated: duration \(String(format: "%.1f", duration))s")
    }
    
    /// Get list of supported file extensions
    public func getSupportedExtensions() -> [String] {
        return supportedFormats
    }
}
