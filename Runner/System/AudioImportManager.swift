import Foundation
import UniformTypeIdentifiers
import AVFoundation
import CryptoKit

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
        .quickTimeMovie,
        .item
    ] + ["aac", "caf", "flac", "m4a", "mkv"].compactMap { UTType(filenameExtension: $0) }
    
    // Supported file extensions
    public static let supportedExtensions = [
        "mp3", "wav", "m4a", "aac", "flac", "caf", "aiff", "aif", "mp4", "mov", "m4v", "mkv"
    ]
    
    /// Checks if a file is supported based on extension
    public func isFormatSupported(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return AudioImportManager.supportedExtensions.contains(ext)
    }
    
    /// Copies a security-scoped URL to the app sandbox (Documents/Imports/)
    /// - Parameter sourceURL: The security-scoped URL from Document Picker
    /// - Returns: Local copied URL in sandbox
    public func importPlayableAudio(from sourceURL: URL) async throws -> URL {
        let importedURL = try importFile(from: sourceURL)
        guard isVideoFile(importedURL) else {
            return importedURL
        }

        let audioURL = try await extractAudio(fromVideoAt: importedURL)
        try? FileManager.default.removeItem(at: importedURL)
        try verifyImportedFile(audioURL)
        return audioURL
    }

    public func importFile(from sourceURL: URL) throws -> URL {
        let sourceURL = sourceURL.standardizedFileURL
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
        let originalName = sourceURL.deletingPathExtension().lastPathComponent.isEmpty
            ? "ImportedAudio"
            : sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension.lowercased()
        let sanitizedName = sanitizeFilename(originalName)
        
        var destinationURL = importsDir.appendingPathComponent("\(sanitizedName).\(pathExtension)")
        
        // If file exists, append unique timestamp
        if fileManager.fileExists(atPath: destinationURL.path) {
            destinationURL = importsDir.appendingPathComponent("\(sanitizedName)_\(UUID().uuidString).\(pathExtension)")
            Logger.shared.info("File with same name exists, renamed to: \(destinationURL.lastPathComponent)")
        }
        
        // Copy the file
        do {
            try coordinatedCopy(from: sourceURL, to: destinationURL)
            Logger.shared.info("Copied imported audio to: \(destinationURL)")
        } catch {
            Logger.shared.error("Import failed during copy: \(error.localizedDescription)")
            throw NSError(domain: "AudioImportManager", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "File berhasil dipilih tetapi gagal disalin ke penyimpanan aplikasi. Pastikan file sudah terunduh dari iCloud atau coba pilih dari folder lokal."])
        }
        
        // Verify copy and size > 0
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            Logger.shared.error("Import failed: Copied file does not exist at destination")
            throw NSError(domain: "AudioImportManager", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Gagal memverifikasi file setelah disalin."])
        }

        try verifyImportedFile(destinationURL)

        return destinationURL
    }

    public func contentHash(for url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
            if data.isEmpty { break }
            hasher.update(data: data)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func coordinatedCopy(from sourceURL: URL, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var copyError: Error?

        coordinator.coordinate(readingItemAt: sourceURL, options: [], error: &coordinatorError) { readableURL in
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: readableURL, to: destinationURL)
            } catch {
                copyError = error
            }
        }

        if let coordinatorError {
            throw coordinatorError
        }
        if let copyError {
            throw copyError
        }
    }

    private func verifyImportedFile(_ url: URL) throws {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attrs[.size] as? UInt64 ?? 0
        Logger.shared.info("Copied file verified. Size: \(fileSize) bytes")

        guard fileSize > 0 else {
            try? FileManager.default.removeItem(at: url)
            throw NSError(
                domain: "AudioImportManager",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "File kosong (0 bytes) atau tidak valid."]
            )
        }

        if (try? AVAudioFile(forReading: url)) != nil {
            return
        }

        let asset = AVURLAsset(url: url)
        if !asset.tracks(withMediaType: .audio).isEmpty {
            return
        }

        try? FileManager.default.removeItem(at: url)
        throw NSError(
            domain: "AudioImportManager",
            code: 415,
            userInfo: [NSLocalizedDescriptionKey: "File tidak punya track audio yang bisa diproses."]
        )
    }

    private func isVideoFile(_ url: URL) -> Bool {
        ["mp4", "mov", "m4v", "mkv"].contains(url.pathExtension.lowercased())
    }

    private func extractAudio(fromVideoAt videoURL: URL) async throws -> URL {
        let destinationURL = videoURL
            .deletingPathExtension()
            .appendingPathExtension("m4a")

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        let asset = AVURLAsset(url: videoURL)
        guard !asset.tracks(withMediaType: .audio).isEmpty else {
            throw NSError(
                domain: "AudioImportManager",
                code: 415,
                userInfo: [NSLocalizedDescriptionKey: "Video ini tidak punya track audio."]
            )
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(
                domain: "AudioImportManager",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Gagal menyiapkan ekstraksi audio video."]
            )
        }

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .m4a
        await performExport(exportSession)

        guard exportSession.status == .completed else {
            throw exportSession.error ?? NSError(
                domain: "AudioImportManager",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Gagal mengekstrak audio dari video."]
            )
        }

        Logger.shared.info("Extracted video audio to: \(destinationURL.lastPathComponent)")
        return destinationURL
    }

    private func performExport(_ exportSession: AVAssetExportSession) async {
        await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                continuation.resume()
            }
        }
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = filename.components(separatedBy: allowedCharacters.inverted).joined(separator: "_")
        return sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_")).isEmpty
            ? "ImportedAudio"
            : sanitized
    }
}
