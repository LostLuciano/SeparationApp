import UIKit

class GlassCardView: UIView {
    private let blurEffect = UIBlurEffect(style: .dark)
    private let blurView = UIVisualEffectView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Background
        backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        
        // Setup blur
        blurView.effect = blurEffect
        blurView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Border
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius24
        layer.masksToBounds = true
        
        // Shadow
        let shadow = StudioTheme.shared.cardShadow()
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOpacity = shadow.opacity
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.radius
    }
}
