import UIKit

class StudioSegmentedControl: UISegmentedControl {
    override init(items: [Any]?) {
        super.init(items: items)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Background
        backgroundColor = UIColor(white: 0.1, alpha: 0.3)
        
        // Segment colors
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.labelMedium,
            .foregroundColor: StudioColors.textSecondary
        ]
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.labelMedium,
            .foregroundColor: StudioColors.purpleAccent
        ]
        
        setTitleTextAttributes(normalAttributes, for: .normal)
        setTitleTextAttributes(selectedAttributes, for: .selected)
        
        // Appearance
        if #available(iOS 13.0, *) {
            setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
            setBackgroundImage(UIImage(), for: .selected, barMetrics: .default)
            setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        }
        
        // Corner radius
        layer.cornerRadius = StudioTheme.shared.cornerRadius12
        clipsToBounds = true
        
        // Border
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
    }
}
