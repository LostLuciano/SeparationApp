import Foundation

/// Manages waveform and analysis caching with automatic cleanup.
public class CacheManager {
    
    public static let shared = CacheManager()
    
    private let cacheDirectory: URL
    private let maxCacheSizeMB: Int64 = 500
    private var trackedFiles: Set<String> = []
    
    public init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("MusicXNACache")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Get cache file URL for a given key
    public func getCacheURL(forKey key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    /// Check if cache exists for key
    public func hasCached(forKey key: String) -> Bool {
        let url = getCacheURL(forKey: key)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Create temporary file with tracking
    public func createTempFile(withExtension ext: String) -> URL {
        let fileName = "temp_\(UUID().uuidString).\(ext)"
        let url = cacheDirectory.appendingPathComponent(fileName)
        trackedFiles.insert(url.path)
        return url
    }
    
    /// Track output file
    public func trackOutputFile(_ url: URL) {
        trackedFiles.insert(url.path)
        Logger.shared.info("📤 Tracked output file: \(url.lastPathComponent)")
    }
    
    /// Get current cache size in MB
    public func getCacheSizeMB() -> Int64 {
        var totalSize: Int64 = 0
        if let enumerator = FileManager.default.enumerator(atPath: cacheDirectory.path) {
            for file in enumerator {
                if let filePath = file as? String {
                    let fullPath = cacheDirectory.appendingPathComponent(filePath).path
                    if let attr = try? FileManager.default.attributesOfItem(atPath: fullPath),
                       let size = attr[.size] as? Int64 {
                        totalSize += size
                    }
                }
            }
        }
        return totalSize / (1024 * 1024)
    }
    
    /// Get formatted cache size string
    public func getFormattedCacheSize() -> String {
        let sizeMB = getCacheSizeMB()
        if sizeMB < 1024 {
            return "\(sizeMB) MB"
        } else {
            let sizeGB = Double(sizeMB) / 1024.0
            return String(format: "%.2f GB", sizeGB)
        }
    }
    
    /// Cleanup cache if it exceeds max size
    public func cleanupIfNeeded() {
        let currentSize = getCacheSizeMB()
        if currentSize > maxCacheSizeMB {
            let targetSize = maxCacheSizeMB / 2
            clearOldestCache(until: targetSize)
        }
    }
    
    /// Clear all cache
    public func clearAllCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        trackedFiles.removeAll()
        print("CacheManager: All cache cleared")
    }
    
    private func clearOldestCache(until targetSize: Int64) {
        var files: [(url: URL, date: Date)] = []
        
        if let enumerator = FileManager.default.enumerator(atPath: cacheDirectory.path) {
            for file in enumerator {
                if let filePath = file as? String {
                    let fullURL = cacheDirectory.appendingPathComponent(filePath)
                    if let attr = try? FileManager.default.attributesOfItem(atPath: fullURL.path),
                       let modDate = attr[.modificationDate] as? Date {
                        files.append((fullURL, modDate))
                    }
                }
            }
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        var deletedSize: Int64 = 0
        for (url, _) in files {
            if getCacheSizeMB() <= targetSize {
                break
            }
            if let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attr[.size] as? Int64 {
                try? FileManager.default.removeItem(at: url)
                deletedSize += size
                trackedFiles.remove(url.path)
            }
        }
        
        print("CacheManager: Cleaned \(deletedSize / (1024 * 1024)) MB of old cache")
    }
}
