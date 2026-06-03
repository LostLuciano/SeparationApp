import UIKit

class PurpleGlowButton: UIButton {
    var isLoading = false {
        didSet {
            updateState()
        }
    }
    
    private let spinner = UIActivityIndicatorView(style: .medium)
    
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
        backgroundColor = StudioColors.purpleAccent
        
        // Text
        titleLabel?.font = Typography.labelLarge
        setTitleColor(StudioColors.textPrimary, for: .normal)
        
        // Corner radius
        layer.cornerRadius = StudioTheme.shared.cornerRadius16
        
        // Border
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        
        // Glow
        GlassEffect.applyPurpleGlow(to: self, radius: 16)
        
        // Height constraint
        heightAnchor.constraint(equalToConstant: StudioTheme.shared.buttonHeightMedium).isActive = true
        
        // Spinner
        spinner.color = StudioColors.textPrimary
        spinner.hidesWhenStopped = true
        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Touch feedback
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside])
    }
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.8
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
            self.transform = .identity
        }
    }
    
    private func updateState() {
        if isLoading {
            spinner.startAnimating()
            setTitle("", for: .normal)
            isEnabled = false
        } else {
            spinner.stopAnimating()
            isEnabled = true
        }
    }
}
