import Foundation

/// DemoDataManager provides instant access to precomputed demo stems and analysis data.
/// Avoids redundant inference for demo tracks by using bundled precomputed results.
public class DemoDataManager {
    
    static let shared = DemoDataManager()
    
    private let fileManager = FileManager.default
    private let cacheManager = CacheManager.shared
    
    private init() {
        Logger.shared.info("DemoDataManager initialized")
    }
    
    // MARK: - Demo Track Stems
    
    /// Get precomputed stems for a demo track (instant, no inference)
    public func getDemoStems(for trackName: String) throws -> [String: URL] {
        Logger.shared.info("📦 Loading precomputed stems for: \(trackName)")
        
        let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
        var stems: [String: URL] = [:]
        
        // Map demo track to stem files
        let stemMapping: [String: String] = [
            "vocals": "Vocals.m4a",
            "drums": "Drums.m4a",
            "bass": "Others.m4a",
            "guitar": "Guitar.m4a",
            "piano": "Others.m4a",
            "other": "Others.m4a"
        ]
        
        for stem in stemNames {
            guard let fileName = stemMapping[stem],
                  let bundleURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
                Logger.shared.warning("⚠️ Demo stem not found: \(stem)")
                continue
            }
            
            // Copy to temp location for consistency
            let tempURL = cacheManager.createTempFile(withExtension: "m4a")
            try fileManager.copyItem(at: bundleURL, to: tempURL)
            stems[stem] = tempURL
            
            Logger.shared.debug("✅ Loaded demo stem: \(stem)")
        }
        
        guard !stems.isEmpty else {
            throw NSError(domain: "DemoDataManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No demo stems found for: \(trackName)"])
        }
        
        Logger.shared.info("✅ Loaded \(stems.count) demo stems for: \(trackName)")
        return stems
    }
    
    /// Check if demo stems are available
    public func hasDemoStems(for trackName: String) -> Bool {
        let stemFiles = ["Vocals.m4a", "Drums.m4a", "Guitar.m4a", "Others.m4a"]
        
        for fileName in stemFiles {
            if Bundle.main.url(forResource: fileName, withExtension: nil) == nil {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Demo Analysis Data
    
    /// Get precomputed analysis data for a demo track
    public func getDemoAnalysisData(for trackName: String) throws -> DemoAnalysisData {
        Logger.shared.info("📊 Loading precomputed analysis for: \(trackName)")
        
        // Map track names to analysis files
        let analysisFileMapping: [String: String] = [
            "Classical Symphony": "classical-analysis-data.json",
            "Trap Beats": "trap-analysis-data.json",
            "EDM Dance": "edm-analysis-data.json",
            "Dubstep Wobble": "dubstep-analysis-data.json",
            "Country Road": "country-analysis-data.json",
            "Drum & Bass": "drumNBass-analysis-data.json",
            "Folk Rock": "folkRock-analysis-data.json",
            "Latino Vibes": "latino-analysis-data.json",
            "Heavy Metal": "metal-analysis-data.json",
            "Reggaeton Dance": "reggaeton-analysis-data.json",
            "RnB Soul": "rnb-analysis-data.json"
        ]
        
        guard let fileName = analysisFileMapping[trackName],
              let bundleURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            throw NSError(domain: "DemoDataManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Analysis data not found for: \(trackName)"])
        }
        
        let data = try Data(contentsOf: bundleURL)
        let decoder = JSONDecoder()
        let analysisData = try decoder.decode(DemoAnalysisData.self, from: data)
        
        Logger.shared.info("✅ Loaded analysis data for: \(trackName)")
        return analysisData
    }
    
    /// Check if analysis data is available
    public func hasAnalysisData(for trackName: String) -> Bool {
        let analysisFileMapping: [String: String] = [
            "Classical Symphony": "classical-analysis-data.json",
            "Trap Beats": "trap-analysis-data.json",
            "EDM Dance": "edm-analysis-data.json",
            "Dubstep Wobble": "dubstep-analysis-data.json",
            "Country Road": "country-analysis-data.json",
            "Drum & Bass": "drumNBass-analysis-data.json",
            "Folk Rock": "folkRock-analysis-data.json",
            "Latino Vibes": "latino-analysis-data.json",
            "Heavy Metal": "metal-analysis-data.json",
            "Reggaeton Dance": "reggaeton-analysis-data.json",
            "RnB Soul": "rnb-analysis-data.json"
        ]
        
        guard let fileName = analysisFileMapping[trackName] else {
            return false
        }
        
        return Bundle.main.url(forResource: fileName, withExtension: nil) != nil
    }
    
    // MARK: - Demo Track List
    
    /// Get list of all available demo tracks
    public func getAvailableDemoTracks() -> [String] {
        return [
            "Classical Symphony",
            "Trap Beats",
            "EDM Dance",
            "Dubstep Wobble",
            "Country Road",
            "Drum & Bass",
            "Folk Rock",
            "Latino Vibes",
            "Heavy Metal",
            "Reggaeton Dance",
            "RnB Soul"
        ]
    }
    
    /// Check if a track is a demo track
    public func isDemoTrack(_ trackName: String) -> Bool {
        return getAvailableDemoTracks().contains(trackName)
    }
}

// MARK: - Analysis Data Structure

public struct DemoAnalysisData: Codable {
    public let bpm: Float?
    public let chords: [ChordSegment]?
    public let beats: [TimeInterval]?
    
    public struct ChordSegment: Codable {
        public let name: String
        public let startTime: TimeInterval
        public let endTime: TimeInterval
    }
}
