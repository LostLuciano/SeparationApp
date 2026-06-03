import Foundation
import UIKit

/// Monitors thermal state, memory usage, and processing stage timing.
public class PerformanceGuard {
    
    public static let shared = PerformanceGuard()
    
    public private(set) var currentThermalState: String = "Nominal"
    public private(set) var memoryUsageMB: Int = 0
    public private(set) var stageTiming: [String: Double] = [:]
    
    private var stageStartTime: Date?
    private var currentStage: String?
    private var thermalState: ProcessInfo.ThermalState = .nominal
    private let lock = NSLock()
    
    public init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        // Thermal state monitoring
        #if os(iOS)
        let newThermalState = ProcessInfo.processInfo.thermalState
        if newThermalState != thermalState {
            thermalState = newThermalState
        }
        currentThermalState = String(describing: thermalState)
        #endif
        
        // Memory usage
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.phys_footprint) / 1024 / 1024
            memoryUsageMB = Int(usedMemory)
        }
    }
    
    /// Check if device is thermally throttling
    public func isThermalThrottling() -> Bool {
        return thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }
    
    /// Start timing a processing stage
    public func startStage(_ stageName: String) {
        currentStage = stageName
        stageStartTime = Date()
    }
    
    /// Start an operation (for compatibility)
    public func startOperation(_ operationName: String) {
        startStage(operationName)
    }
    
    /// End timing current stage
    public func endStage() {
        guard let stage = currentStage, let startTime = stageStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        stageTiming[stage] = duration
        print("PerformanceGuard: Stage '\(stage)' took \(String(format: "%.2f", duration))s")
    }
    
    /// End an operation (for compatibility)
    public func endOperation(_ operationName: String) {
        endStage()
    }
    
    /// Add checkpoint during operation
    public func addCheckpoint(_ operationName: String, checkpoint: String) {
        Logger.shared.info("✓ \(operationName) → \(checkpoint)")
    }
    
    /// Get all stage timings
    public func getStageTiming() -> [String: Double] {
        return stageTiming
    }
}

// Memory stats for performance monitoring
import Darwin

func task_vm_info_data_t() -> task_vm_info {
    var info = task_vm_info()
    return info
}
