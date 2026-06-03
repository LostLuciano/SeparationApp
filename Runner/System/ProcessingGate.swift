import Foundation

/// Prevents concurrent CPU-intensive operations - only one processing operation at a time.
public class ProcessingGate {
    
    public static let shared = ProcessingGate()
    
    /// Enum for different processing operation types
    public enum ProcessingOperation: Equatable {
        case separation
        case chordDetection
        case beatDetection
        case export
        case recording
        case analysis
    }
    
    private var isProcessing = false
    private var currentOperation: ProcessingOperation?
    private let queue = DispatchQueue(label: "com.musicx.processinggate", attributes: .concurrent)
    
    public init() {}
    
    /// Check if processing is currently active
    public var isActive: Bool {
        var result = false
        queue.sync {
            result = isProcessing
        }
        return result
    }
    
    /// Request to start a processing operation
    /// - Returns: true if operation can start immediately, false if already processing
    public func requestOperation(_ operation: ProcessingOperation) -> Bool {
        var acquired = false
        queue.async(flags: .barrier) {
            if !self.isProcessing {
                self.isProcessing = true
                self.currentOperation = operation
                acquired = true
            }
        }
        return acquired
    }
    
    /// Complete a processing operation
    public func completeOperation(_ operation: ProcessingOperation) {
        queue.async(flags: .barrier) {
            if self.currentOperation == operation {
                self.isProcessing = false
                self.currentOperation = nil
            }
        }
    }
    
    /// Try to acquire processing lock
    /// - Returns: true if lock was acquired, false if already processing
    public func tryAcquire() -> Bool {
        var acquired = false
        queue.async(flags: .barrier) {
            if !self.isProcessing {
                self.isProcessing = true
                acquired = true
            }
        }
        return acquired
    }
    
    /// Release processing lock
    public func release() {
        queue.async(flags: .barrier) {
            self.isProcessing = false
        }
    }
    
    /// Execute closure only if gate is not active
    /// - Returns: true if executed, false if gate was active
    public func execute(_ block: @escaping () -> Void) -> Bool {
        if tryAcquire() {
            DispatchQueue.global(qos: .userInitiated).async {
                block()
                self.release()
            }
            return true
        }
        return false
    }
}
