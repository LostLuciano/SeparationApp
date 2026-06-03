import Foundation

/// Centralized logging system with performance tracking.
public class Logger {
    
    public static let shared = Logger()
    
    public init() {}
    
    /// Log with formatted output
    public func log(_ message: String, level: String = "info") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(level)] \(message)"
        print(logEntry)
    }
    
    /// Log success message
    public func success(_ message: String) {
        log(message, level: "success")
    }
    
    /// Log info message
    public func info(_ message: String) {
        log(message, level: "info")
    }
    
    /// Log warning message
    public func warning(_ message: String) {
        log(message, level: "warning")
    }
    
    /// Log error message
    public func error(_ message: String) {
        log(message, level: "error")
    }
    
    /// Log debug message
    public func debug(_ message: String) {
        log(message, level: "debug")
    }
    
    /// Log performance metric
    public func performance(_ message: String, duration: TimeInterval) {
        let durationMs = duration * 1000
        log("\(message) — \(String(format: "%.2f", durationMs))ms", level: "performance")
    }
}
