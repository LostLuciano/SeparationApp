import Foundation
import CoreML

/// Manages CoreML model loading, validation, and status tracking.
public class ModelManager {
    
    public static let shared = ModelManager()
    
    private var stemModelStandard: MLModel?
    private var stemModelLight: MLModel?
    private var chordModel: MLModel?
    private var beatModel: MLModel?
    
    public private(set) var stemSeparationStatus: String = "Not Ready"
    public private(set) var chordDetectionStatus: String = "Not Ready"
    public private(set) var beatDetectionStatus: String = "Not Ready"
    
    public init() {
        checkAllModels()
    }
    
    /// Checks and loads all available CoreML models from bundle
    public func checkAllModels() {
        print("ModelManager: Checking all CoreML models...")
        
        // Check Stem Separation - Standard (FP32)
        if let url = Bundle.main.url(forResource: "dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1", withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                stemModelStandard = try MLModel(contentsOf: url, configuration: config)
                stemSeparationStatus = "Ready (FP32)"
                print("✅ Stem Separation (Standard FP32): Ready")
            } catch {
                print("❌ Stem Separation (Standard FP32): Failed - \(error.localizedDescription)")
            }
        }
        
        // Check Stem Separation - Light (FP16)
        if let url = Bundle.main.url(forResource: "dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0", withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                stemModelLight = try MLModel(contentsOf: url, configuration: config)
                if stemSeparationStatus == "Not Ready" {
                    stemSeparationStatus = "Ready (FP16)"
                }
                print("✅ Stem Separation (Light FP16): Ready")
            } catch {
                print("❌ Stem Separation (Light FP16): Failed - \(error.localizedDescription)")
            }
        }
        
        // Check Chord Detection
        if let url = Bundle.main.url(forResource: "Chordcrnn", withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                chordModel = try MLModel(contentsOf: url, configuration: config)
                chordDetectionStatus = "Ready"
                print("✅ Chord Detection: Ready")
            } catch {
                print("❌ Chord Detection: Failed - \(error.localizedDescription)")
                chordDetectionStatus = "Failed"
            }
        } else {
            print("⚠️ Chord Detection: Model not found in bundle")
            chordDetectionStatus = "Not Found"
        }
        
        // Check Beat Detection
        if let url = Bundle.main.url(forResource: "convtcn20_2048_fp16", withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                beatModel = try MLModel(contentsOf: url, configuration: config)
                beatDetectionStatus = "Ready"
                print("✅ Beat Detection: Ready")
            } catch {
                print("❌ Beat Detection: Failed - \(error.localizedDescription)")
                beatDetectionStatus = "Failed"
            }
        } else {
            print("⚠️ Beat Detection: Model not found in bundle")
            beatDetectionStatus = "Not Found"
        }
    }
    
    /// Returns dictionary of all model statuses
    public func getAllModelStatuses() -> [String: String] {
        return [
            "Stem Separation": stemSeparationStatus,
            "Chord Detection": chordDetectionStatus,
            "Beat & Tempo": beatDetectionStatus
        ]
    }
    
    /// Gets the best available stem separation model
    public func getStemSeparationModel() -> MLModel? {
        return stemModelStandard ?? stemModelLight
    }
    
    /// Gets chord detection model
    public func getChordModel() -> MLModel? {
        return chordModel
    }
    
    /// Gets beat detection model
    public func getBeatModel() -> MLModel? {
        return beatModel
    }
}
