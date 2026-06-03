import UIKit

class StudioSettingsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Background
        let bgView = LiquidBackgroundView()
        view.insertSubview(bgView, at: 0)
        bgView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: view.topAnchor),
            bgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let safeArea = view.safeAreaLayoutGuide
        let padding = StudioTheme.shared.spacing16
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Pengaturan Studio"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        var topAnchor = titleLabel.bottomAnchor
        
        // MARK: - UI Style Section
        let uiStyleLabel = UILabel()
        uiStyleLabel.text = "Gaya Tampilan"
        uiStyleLabel.font = Typography.headingMedium
        uiStyleLabel.textColor = StudioColors.textPrimary
        uiStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(uiStyleLabel)
        
        NSLayoutConstraint.activate([
            uiStyleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            uiStyleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding)
        ])
        
        let uiSettings = ["Tema UI", "Accent Color", "Glass Effect", "Blur Amount", "Saturation"]
        topAnchor = uiStyleLabel.bottomAnchor
        
        for setting in uiSettings {
            let settingView = createSettingRow(title: setting)
            contentView.addSubview(settingView)
            
            NSLayoutConstraint.activate([
                settingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                settingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
                settingView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                settingView.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            topAnchor = settingView.bottomAnchor
        }
        
        // MARK: - Audio Hardware Section
        let audioLabel = UILabel()
        audioLabel.text = "Audio Hardware"
        audioLabel.font = Typography.headingMedium
        audioLabel.textColor = StudioColors.textPrimary
        audioLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(audioLabel)
        
        NSLayoutConstraint.activate([
            audioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            audioLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding)
        ])
        
        let audioSettings = ["Buffer Size", "Sample Rate", "Direct Monitoring"]
        topAnchor = audioLabel.bottomAnchor
        
        for setting in audioSettings {
            let settingView = createSettingRow(title: setting)
            contentView.addSubview(settingView)
            
            NSLayoutConstraint.activate([
                settingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                settingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
                settingView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                settingView.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            topAnchor = settingView.bottomAnchor
        }
        
        // MARK: - AI & DSP Section
        let aiLabel = UILabel()
        aiLabel.text = "AI & DSP"
        aiLabel.font = Typography.headingMedium
        aiLabel.textColor = StudioColors.textPrimary
        aiLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aiLabel)
        
        NSLayoutConstraint.activate([
            aiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            aiLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding)
        ])
        
        let aiSettings = ["Mode CoreML", "Model Pemisah", "Auto Chord", "Auto Beat"]
        topAnchor = aiLabel.bottomAnchor
        
        for setting in aiSettings {
            let settingView = createSettingRow(title: setting)
            contentView.addSubview(settingView)
            
            NSLayoutConstraint.activate([
                settingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                settingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
                settingView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                settingView.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            topAnchor = settingView.bottomAnchor
        }
        
        // MARK: - Model Status Section
        let modelLabel = UILabel()
        modelLabel.text = "Status Model AI"
        modelLabel.font = Typography.headingMedium
        modelLabel.textColor = StudioColors.textPrimary
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(modelLabel)
        
        NSLayoutConstraint.activate([
            modelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            modelLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding)
        ])
        
        let modelStatuses = ["Stem Separation", "Chord Detection", "Beat & Tempo"]
        topAnchor = modelLabel.bottomAnchor
        
        for status in modelStatuses {
            let statusView = UIView()
            statusView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            statusView.layer.borderWidth = 1.0
            statusView.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            statusView.layer.cornerRadius = StudioTheme.shared.cornerRadius12
            statusView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(statusView)
            
            let label = UILabel()
            label.text = status
            label.font = Typography.labelMedium
            label.textColor = StudioColors.textPrimary
            label.translatesAutoresizingMaskIntoConstraints = false
            statusView.addSubview(label)
            
            let statusIndicator = UILabel()
            statusIndicator.text = "✓ Ready"
            statusIndicator.font = Typography.labelSmall
            statusIndicator.textColor = StudioColors.statusSuccess
            statusIndicator.translatesAutoresizingMaskIntoConstraints = false
            statusView.addSubview(statusIndicator)
            
            NSLayoutConstraint.activate([
                statusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
                statusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
                statusView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                statusView.heightAnchor.constraint(equalToConstant: 44),
                
                label.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 12),
                label.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
                
                statusIndicator.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -12),
                statusIndicator.centerYAnchor.constraint(equalTo: statusView.centerYAnchor)
            ])
            
            topAnchor = statusView.bottomAnchor
        }
        
        // Add bottom padding
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomView)
        
        NSLayoutConstraint.activate([
            bottomView.topAnchor.constraint(equalTo: topAnchor, constant: padding * 2),
            bottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding)
        ])
    }
    
    private func createSettingRow(title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        container.layer.borderWidth = 1.0
        container.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        container.layer.cornerRadius = StudioTheme.shared.cornerRadius12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = Typography.labelMedium
        label.textColor = StudioColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        let arrow = UILabel()
        arrow.text = "›"
        arrow.font = Typography.bodyLarge
        arrow.textColor = StudioColors.textSecondary
        arrow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(arrow)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            arrow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            arrow.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
}
