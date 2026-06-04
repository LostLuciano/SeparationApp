import Foundation
import UniformTypeIdentifiers
import AVFoundation

public class AudioImportManager {
    public static let shared = AudioImportManager()
    
    public init() {}
    
    // Allowed UTTypes
    public static let allowedUTTypes: [UTType] = [
        .audio,
        .mp3,
        .wav,
        .mpeg4Audio,
        .aiff,
        .movie,
        .mpeg4Movie,
        .quickTimeMovie
    ]
    
    // Supported file extensions
    public static let supportedExtensions = [
        "mp3", "wav", "m4a", "aac", "flac", "caf", "aiff", "aif", "mp4", "mov", "m4v"
    ]
    
    /// Checks if a file is supported based on extension
    public func isFormatSupported(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return AudioImportManager.supportedExtensions.contains(ext)
    }
    
    /// Copies a security-scoped URL to the app sandbox (Documents/Imports/)
    /// - Parameter sourceURL: The security-scoped URL from Document Picker
    /// - Returns: Local copied URL in sandbox
    public func importFile(from sourceURL: URL) throws -> URL {
        Logger.shared.info("Selected source URL: \(sourceURL)")
        
        // Start accessing security-scoped resource
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        Logger.shared.info("Security scoped access: \(didAccess)")
        
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
                Logger.shared.info("Stopped accessing security-scoped resource")
            }
        }
        
        let fileManager = FileManager.default
        
        // Verify source file exists
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            Logger.shared.error("Import failed: Source file does not exist at path: \(sourceURL.path)")
            throw NSError(domain: "AudioImportManager", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "File tidak bisa diakses. Pastikan file sudah terunduh dari iCloud atau pilih file lain."])
        }
        
        // Check format
        guard isFormatSupported(sourceURL) else {
            Logger.shared.error("Import failed: Format not supported: \(sourceURL.pathExtension)")
            throw NSError(domain: "AudioImportManager", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Format file belum didukung."])
        }
        
        // Get Documents/Imports directory
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.shared.error("Import failed: Could not access Documents directory")
            throw NSError(domain: "AudioImportManager", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Gagal mengakses penyimpanan aplikasi."])
        }
        
        let importsDir = documentsDir.appendingPathComponent("Imports", isDirectory: true)
        
        // Create directory if missing
        if !fileManager.fileExists(atPath: importsDir.path) {
            do {
                try fileManager.createDirectory(at: importsDir, withIntermediateDirectories: true, attributes: nil)
                Logger.shared.info("Created Imports directory at: \(importsDir.path)")
            } catch {
                Logger.shared.error("Import failed: Failed to create Imports directory: \(error.localizedDescription)")
                throw NSError(domain: "AudioImportManager", code: 500,
                              userInfo: [NSLocalizedDescriptionKey: "Gagal membuat folder penyimpanan audio."])
            }
        }
        
        // Sanitize and generate unique filename
        let originalName = sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension
        let sanitizedName = sanitizeFilename(originalName)
        
        var destinationURL = importsDir.appendingPathComponent("\(sanitizedName).\(pathExtension)")
        
        // If file exists, append unique timestamp
        if fileManager.fileExists(atPath: destinationURL.path) {
            let timestamp = Int(Date().timeIntervalSince1970)
            destinationURL = importsDir.appendingPathComponent("\(sanitizedName)_\(timestamp).\(pathExtension)")
            Logger.shared.info("File with same name exists, renamed to: \(destinationURL.lastPathComponent)")
        }
        
        // Copy the file
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            Logger.shared.info("Copied imported audio to: \(destinationURL)")
        } catch {
            Logger.shared.error("Import failed during copy: \(error.localizedDescription)")
            throw NSError(domain: "AudioImportManager", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "File berhasil dipilih tetapi gagal disalin ke penyimpanan aplikasi. Pastikan file sudah terunduh dari iCloud."])
        }
        
        // Verify copy and size > 0
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            Logger.shared.error("Import failed: Copied file does not exist at destination")
            throw NSError(domain: "AudioImportManager", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Gagal memverifikasi file setelah disalin."])
        }
        
        do {
            let attrs = try fileManager.attributesOfItem(atPath: destinationURL.path)
            if let fileSize = attrs[.size] as? UInt64 {
                Logger.shared.info("Copied file verified. Size: \(fileSize) bytes")
                guard fileSize > 0 else {
                    Logger.shared.error("Import failed: Copied file size is 0 bytes")
                    // Clean up 0 byte file
                    try? fileManager.removeItem(at: destinationURL)
                    throw NSError(domain: "AudioImportManager", code: 400,
                                  userInfo: [NSLocalizedDescriptionKey: "File kosong (0 bytes) atau tidak valid."])
                }
            }
        } catch {
            Logger.shared.error("Import failed to verify size: \(error.localizedDescription)")
            throw error
        }
        
        return destinationURL
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return filename.components(separatedBy: allowedCharacters.inverted).joined(separator: "_")
    }
}
