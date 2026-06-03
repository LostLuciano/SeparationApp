import UIKit

class StudioColors {
    // MARK: - Primary Colors
    static let darkBg = UIColor(red: 0.08, green: 0.06, blue: 0.15, alpha: 1.0)      // Dark purple-black
    static let darkBg2 = UIColor(red: 0.12, green: 0.10, blue: 0.20, alpha: 1.0)     // Slightly lighter
    static let purpleAccent = UIColor(red: 0.75, green: 0.40, blue: 1.0, alpha: 1.0) // Bright purple
    static let purpleDim = UIColor(red: 0.50, green: 0.25, blue: 0.75, alpha: 1.0)   // Dim purple
    
    // MARK: - Glass Colors
    static let glassLight = UIColor(white: 1.0, alpha: 0.08)   // Translucent white for cards
    static let glassMedium = UIColor(white: 1.0, alpha: 0.12)  // Medium glass effect
    static let glassDark = UIColor(white: 0.0, alpha: 0.15)    // Dark glass overlay
    
    // MARK: - Text Colors
    static let textPrimary = UIColor(white: 1.0, alpha: 1.0)   // White
    static let textSecondary = UIColor(white: 1.0, alpha: 0.7) // 70% white
    static let textTertiary = UIColor(white: 1.0, alpha: 0.5)  // 50% white
    
    // MARK: - Status Colors
    static let statusSuccess = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)  // Green
    static let statusWarning = UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0) // Orange
    static let statusError = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)    // Red
    static let statusPending = UIColor(white: 1.0, alpha: 0.3)                        // Dim gray
    
    // MARK: - Stem Colors
    static let stemVocals = UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)     // Pink
    static let stemDrums = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)      // Orange
    static let stemBass = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)       // Cyan
    static let stemGuitar = UIColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1.0)     // Yellow
    static let stemPiano = UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0)      // Light purple
    static let stemOthers = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)     // Gray
    
    // MARK: - Gradient Colors
    static func darkGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.15, green: 0.08, blue: 0.30, alpha: 1.0).cgColor,  // Dark purple
            UIColor(red: 0.08, green: 0.06, blue: 0.15, alpha: 1.0).cgColor   // Dark black
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }
    
    static func purpleGlowGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.75, green: 0.40, blue: 1.0, alpha: 0.3).cgColor,
            UIColor(red: 0.75, green: 0.40, blue: 1.0, alpha: 0.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }
}
