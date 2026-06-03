import UIKit

class GlassEffect {
    // MARK: - Glass Card Effect
    static func applyGlassEffect(to view: UIView, blur: UIBlurEffect.Style = .dark) {
        // Remove existing blur effect if any
        view.subviews.forEach { subview in
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
        
        // Create blur effect
        let blurEffect = UIBlurEffect(style: blur)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add vibrancy effect
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(vibrancyView, at: 1)
        
        NSLayoutConstraint.activate([
            vibrancyView.topAnchor.constraint(equalTo: view.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Add Glass Border
    static func applyGlassBorder(to view: UIView, width: CGFloat = 1.0) {
        view.layer.borderWidth = width
        view.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
    }
    
    // MARK: - Add Glow Effect
    static func applyPurpleGlow(to view: UIView, radius: CGFloat = 20) {
        view.layer.shadowColor = StudioColors.purpleAccent.cgColor
        view.layer.shadowOpacity = 0.6
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = radius
    }
    
    // MARK: - Add Soft Shadow
    static func applySoftShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
    }
}
