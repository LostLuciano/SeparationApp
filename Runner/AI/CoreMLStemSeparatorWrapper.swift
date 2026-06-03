import Foundation

/// CoreMLStemSeparatorWrapper wraps the existing CoreMLStemSeparator with ProcessingGate control.
/// Ensures only one separation operation runs at a time and respects performance constraints.
public class CoreMLStemSeparatorWrapper {
    
    static let shared = CoreMLStemSeparatorWrapper()
    
    private let separator = CoreMLStemSeparator()
    private let processingGate = ProcessingGate.shared
    private let performanceGuard = PerformanceGuard.shared
    private let cacheManager = CacheManager.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Separate audio with processing gate control
    public func separate(
        audioURL: URL,
        processingMode: String? = nil,
        modelQuality: String? = nil,
        onProgress: @escaping (String, Double) -> Void
    ) async throws -> [String: URL] {
        
        // Check thermal state
        if performanceGuard.isThermalThrottling() {
            Logger.shared.warning("⚠️ Device is thermally throttled, separation may be slow")
            onProgress("⚠️ Device is hot, processing may be slower", 0.01)
        }
        
        // Start performance tracking
        performanceGuard.startOperation("Stem Separation")
        defer {
            performanceGuard.endOperation("Stem Separation")
        }
        
        // Wrap progress callback to add performance tracking
        let wrappedProgress: (String, Double) -> Void = { [weak self] message, progress in
            self?.performanceGuard.addCheckpoint("Stem Separation", checkpoint: message)
            onProgress(message, progress)
        }
        
        do {
            wrappedProgress("Starting stem separation...", 0.02)
            
            let result = try await separator.separate(
                audioURL: audioURL,
                processingMode: processingMode,
                modelQuality: modelQuality,
                onProgress: wrappedProgress
            )
            
            // Track output files
            for (stem, url) in result {
                cacheManager.trackOutputFile(url)
            }
            
            wrappedProgress("✅ Separation completed successfully", 1.0)
            Logger.shared.info("✅ Stem separation completed: \(result.count) stems")
            
            return result
            
        } catch {
            Logger.shared.error("❌ Stem separation failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Status
    
    public func isSeparationInProgress() -> Bool {
        return performanceGuard.currentThermalState != "Nominal"
    }
}
