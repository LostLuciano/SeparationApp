import UIKit

class ProcessingStageRowView: UIView {
    private let stageLabel = UILabel()
    private let statusIndicator = UIView()
    private let statusLabel = UILabel()
    
    enum StageStatus {
        case pending, running, done, failed
        
        var color: UIColor {
            switch self {
            case .pending: return StudioColors.statusPending
            case .running: return StudioColors.statusWarning
            case .done: return StudioColors.statusSuccess
            case .failed: return StudioColors.statusError
            }
        }
        
        var text: String {
            switch self {
            case .pending: return "Pending"
            case .running: return "Running"
            case .done: return "Done"
            case .failed: return "Failed"
            }
        }
    }
    
    init(stage: String) {
        super.init(frame: .zero)
        setup(stage: stage)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(stage: "Unknown")
    }
    
    private func setup(stage: String) {
        // Background
        backgroundColor = UIColor(white: 1.0, alpha: 0.03)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius12
        
        // Stage label
        stageLabel.text = stage
        stageLabel.font = Typography.labelMedium
        stageLabel.textColor = StudioColors.textPrimary
        stageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stageLabel)
        
        // Status indicator
        statusIndicator.layer.cornerRadius = 6
        statusIndicator.backgroundColor = StudioColors.statusPending
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusIndicator)
        
        // Status label
        statusLabel.text = "Pending"
        statusLabel.font = Typography.labelSmall
        statusLabel.textColor = StudioColors.textSecondary
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        // Layout
        let padding = StudioTheme.shared.spacing12
        
        NSLayoutConstraint.activate([
            stageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            statusIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func updateStatus(_ status: StageStatus) {
        statusIndicator.backgroundColor = status.color
        statusLabel.text = status.text
        
        if status == .running {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1.0
            animation.toValue = 0.3
            animation.duration = 0.6
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.repeatCount = .infinity
            animation.autoreverses = true
            statusIndicator.layer.add(animation, forKey: "pulse")
        } else {
            statusIndicator.layer.removeAnimation(forKey: "pulse")
        }
    }
}
