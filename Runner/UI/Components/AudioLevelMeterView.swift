import UIKit

class AudioLevelMeterView: UIView {
    private let leftBar = UIView()
    private let rightBar = UIView()
    private let peakLabel = UILabel()
    
    private var levelTimer: Timer?
    
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
        layer.cornerRadius = StudioTheme.shared.cornerRadius12
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        
        // Left bar
        leftBar.backgroundColor = StudioColors.statusSuccess
        leftBar.layer.cornerRadius = 2
        leftBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftBar)
        
        // Right bar
        rightBar.backgroundColor = StudioColors.statusSuccess
        rightBar.layer.cornerRadius = 2
        rightBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightBar)
        
        // Peak label
        peakLabel.font = Typography.labelSmall
        peakLabel.textColor = StudioColors.textSecondary
        peakLabel.text = "-∞ dB"
        peakLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(peakLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            leftBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            leftBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftBar.heightAnchor.constraint(equalToConstant: 4),
            
            rightBar.leadingAnchor.constraint(equalTo: leftBar.trailingAnchor, constant: 8),
            rightBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightBar.heightAnchor.constraint(equalToConstant: 4),
            rightBar.widthAnchor.constraint(equalTo: leftBar.widthAnchor),
            
            peakLabel.leadingAnchor.constraint(equalTo: rightBar.trailingAnchor, constant: 12),
            peakLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            peakLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        heightAnchor.constraint(equalToConstant: 32).isActive = true
    }
    
    func updateLevel(left: Float, right: Float) {
        let maxWidth: CGFloat = 60
        let leftWidth = CGFloat(min(max(left, 0), 1)) * maxWidth
        let rightWidth = CGFloat(min(max(right, 0), 1)) * maxWidth
        
        UIView.animate(withDuration: 0.05) {
            self.leftBar.widthAnchor.constraint(equalToConstant: leftWidth).isActive = true
            self.rightBar.widthAnchor.constraint(equalToConstant: rightWidth).isActive = true
            self.layoutIfNeeded()
        }
        
        // Update color based on level
        let peakLevel = max(left, right)
        if peakLevel > 0.9 {
            leftBar.backgroundColor = StudioColors.statusError
            rightBar.backgroundColor = StudioColors.statusError
        } else if peakLevel > 0.7 {
            leftBar.backgroundColor = StudioColors.statusWarning
            rightBar.backgroundColor = StudioColors.statusWarning
        } else {
            leftBar.backgroundColor = StudioColors.statusSuccess
            rightBar.backgroundColor = StudioColors.statusSuccess
        }
        
        // Update dB label
        let dB = 20 * log10(CGFloat(peakLevel))
        peakLabel.text = String(format: "%.1f dB", dB)
    }
    
    func startAnimating() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            let randomLeft = Float.random(in: 0.4...0.8)
            let randomRight = Float.random(in: 0.4...0.8)
            self?.updateLevel(left: randomLeft, right: randomRight)
        }
    }
    
    func stopAnimating() {
        levelTimer?.invalidate()
        levelTimer = nil
        updateLevel(left: 0, right: 0)
    }
}
