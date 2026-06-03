import UIKit

class FloatingActionButton: UIButton {
    init(icon: String? = nil) {
        super.init(frame: .zero)
        setup(icon: icon)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(icon: nil)
    }
    
    private func setup(icon: String?) {
        // Size
        widthAnchor.constraint(equalToConstant: 56).isActive = true
        heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        // Style
        backgroundColor = StudioColors.purpleAccent
        layer.cornerRadius = 28
        
        // Icon
        if let icon = icon {
            setImage(UIImage(systemName: icon), for: .normal)
            tintColor = StudioColors.textPrimary
        } else {
            setTitle("+", for: .normal)
            titleLabel?.font = Typography.displayMedium
            setTitleColor(StudioColors.textPrimary, for: .normal)
        }
        
        // Glow
        GlassEffect.applyPurpleGlow(to: self, radius: 24)
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 12
        
        // Touch feedback
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside])
    }
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
        }
    }
}
