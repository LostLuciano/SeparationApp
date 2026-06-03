import UIKit

class Typography {
    // MARK: - Display Fonts (Large, Bold)
    static let displayLarge = UIFont.systemFont(ofSize: 34, weight: .bold)     // 34pt, bold
    static let displayMedium = UIFont.systemFont(ofSize: 28, weight: .bold)    // 28pt, bold
    static let displaySmall = UIFont.systemFont(ofSize: 24, weight: .bold)     // 24pt, bold
    
    // MARK: - Heading Fonts
    static let headingLarge = UIFont.systemFont(ofSize: 22, weight: .semibold) // 22pt, semibold
    static let headingMedium = UIFont.systemFont(ofSize: 18, weight: .semibold)// 18pt, semibold
    static let headingSmall = UIFont.systemFont(ofSize: 16, weight: .semibold) // 16pt, semibold
    
    // MARK: - Body Fonts
    static let bodyLarge = UIFont.systemFont(ofSize: 16, weight: .regular)     // 16pt, regular
    static let bodyMedium = UIFont.systemFont(ofSize: 14, weight: .regular)    // 14pt, regular
    static let bodySmall = UIFont.systemFont(ofSize: 12, weight: .regular)     // 12pt, regular
    
    // MARK: - Label Fonts
    static let labelLarge = UIFont.systemFont(ofSize: 14, weight: .semibold)   // 14pt, semibold
    static let labelMedium = UIFont.systemFont(ofSize: 12, weight: .semibold)  // 12pt, semibold
    static let labelSmall = UIFont.systemFont(ofSize: 10, weight: .semibold)   // 10pt, semibold
    
    // MARK: - Mono Fonts (for code, time, numbers)
    static let monoLarge = UIFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
    static let monoMedium = UIFont.monospacedSystemFont(ofSize: 14, weight: .semibold)
    static let monoSmall = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    
    // MARK: - Line Heights
    static let lineHeightTight: CGFloat = 1.2
    static let lineHeightNormal: CGFloat = 1.5
    static let lineHeightRelaxed: CGFloat = 1.75
}
