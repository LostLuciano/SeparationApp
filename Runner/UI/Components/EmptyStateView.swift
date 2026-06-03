import UIKit

class EmptyStateView: UIView {
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    
    init(title: String, message: String, icon: String = "🎵") {
        super.init(frame: .zero)
        setup(title: title, message: message, icon: icon)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "No Data", message: "Nothing here yet", icon: "🎵")
    }
    
    private func setup(title: String, message: String, icon: String) {
        backgroundColor = UIColor(white: 1.0, alpha: 0.02)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius24
        
        // Icon
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 48)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconLabel)
        
        // Title
        titleLabel.text = title
        titleLabel.font = Typography.headingMedium
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Message
        messageLabel.text = message
        messageLabel.font = Typography.bodySmall
        messageLabel.textColor = StudioColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        // Layout
        let spacing = StudioTheme.shared.spacing16
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: topAnchor, constant: spacing * 2),
            
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: spacing),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: spacing / 2),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing * 2)
        ])
    }
}
