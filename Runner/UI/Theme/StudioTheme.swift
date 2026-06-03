import UIKit

class StudioTheme {
    static let shared = StudioTheme()
    
    // MARK: - Spacing
    let spacing2: CGFloat = 2
    let spacing4: CGFloat = 4
    let spacing8: CGFloat = 8
    let spacing12: CGFloat = 12
    let spacing16: CGFloat = 16
    let spacing20: CGFloat = 20
    let spacing24: CGFloat = 24
    let spacing32: CGFloat = 32
    
    // MARK: - Corner Radius
    let cornerRadius12: CGFloat = 12
    let cornerRadius16: CGFloat = 16
    let cornerRadius24: CGFloat = 24
    let cornerRadius32: CGFloat = 32
    
    // MARK: - Sizes
    let buttonHeightSmall: CGFloat = 36
    let buttonHeightMedium: CGFloat = 44
    let buttonHeightLarge: CGFloat = 52
    
    let iconSizeSmall: CGFloat = 16
    let iconSizeMedium: CGFloat = 24
    let iconSizeLarge: CGFloat = 32
    
    // MARK: - Animation Durations
    let animationFast: TimeInterval = 0.2
    let animationNormal: TimeInterval = 0.3
    let animationSlow: TimeInterval = 0.5
    
    // MARK: - Shadows
    func cardShadow() -> (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        return (UIColor.black, 0.15, CGSize(width: 0, height: 4), 12)
    }
    
    func glowShadow() -> (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        return (StudioColors.purpleAccent, 0.4, CGSize(width: 0, height: 0), 20)
    }
}
