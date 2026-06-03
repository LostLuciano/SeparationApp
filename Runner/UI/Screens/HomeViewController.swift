import UIKit

class HomeViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Buttons
    private let importAudioButton = PurpleGlowButton()
    private let importVideoButton = PurpleGlowButton()
    private let newProjectButton = PurpleGlowButton()
    
    // Tools Grid
    private let toolsLabel = UILabel()
    private let toolsStackView = UIStackView()
    private let toolButtons: [UIButton] = []
    
    // Model Status
    private let modelStatusLabel = UILabel()
    private let stemModelView = UIView()
    private let chordModelView = UIView()
    private let beatModelView = UIView()
    
    private var onImportAudio: (() -> Void)?
    private var onImportVideo: (() -> Void)?
    private var onNewProject: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkModelStatus()
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
        
        // Safe area
        let safeArea = view.safeAreaLayoutGuide
        
        // Scroll view
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
        
        // MARK: - Header Section
        titleLabel.text = "Studio"
        titleLabel.font = Typography.displayLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        subtitleLabel.text = "AI Audio · Stem · Chord"
        subtitleLabel.font = Typography.bodyMedium
        subtitleLabel.textColor = StudioColors.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // MARK: - Import Section
        let importLabel = UILabel()
        importLabel.text = "Mulai Proyek Baru"
        importLabel.font = Typography.headingMedium
        importLabel.textColor = StudioColors.textPrimary
        importLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(importLabel)
        
        importAudioButton.setTitle("Impor Audio", for: .normal)
        importAudioButton.addTarget(self, action: #selector(importAudioTapped), for: .touchUpInside)
        importAudioButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(importAudioButton)
        
        importVideoButton.setTitle("Impor Video", for: .normal)
        importVideoButton.addTarget(self, action: #selector(importVideoTapped), for: .touchUpInside)
        importVideoButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(importVideoButton)
        
        // MARK: - Tools Section
        toolsLabel.text = "Tools"
        toolsLabel.font = Typography.headingMedium
        toolsLabel.textColor = StudioColors.textPrimary
        toolsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toolsLabel)
        
        toolsStackView.axis = .vertical
        toolsStackView.spacing = StudioTheme.shared.spacing8
        toolsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toolsStackView)
        
        let toolItems = [
            ("🎚", "Stem Mixer"),
            ("🎼", "Chord Viewer"),
            ("♩", "Tempo & Beat"),
            ("🎤", "Rekam Audio"),
            ("📹", "Rekam Video"),
            ("📚", "Library")
        ]
        
        for (emoji, title) in toolItems {
            let toolCard = UIButton(type: .system)
            toolCard.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
            toolCard.layer.borderWidth = 1.0
            toolCard.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            toolCard.layer.cornerRadius = StudioTheme.shared.cornerRadius16
            
            var config = UIButton.Configuration.plain()
            config.image = nil
            config.baseForegroundColor = StudioColors.textPrimary
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = Typography.labelMedium
                return outgoing
            }
            toolCard.configuration = config
            
            toolCard.setTitle("\(emoji) \(title)", for: .normal)
            toolCard.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            toolsStackView.addArrangedSubview(toolCard)
        }
        
        // MARK: - Model Status Section
        modelStatusLabel.text = "Status Model AI"
        modelStatusLabel.font = Typography.headingMedium
        modelStatusLabel.textColor = StudioColors.textPrimary
        modelStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(modelStatusLabel)
        
        // Stem Model
        stemModelView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        stemModelView.layer.borderWidth = 1.0
        stemModelView.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        stemModelView.layer.cornerRadius = StudioTheme.shared.cornerRadius12
        stemModelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stemModelView)
        
        let stemLabel = UILabel()
        stemLabel.text = "🎵 Stem Model"
        stemLabel.font = Typography.labelMedium
        stemLabel.textColor = StudioColors.textPrimary
        stemLabel.translatesAutoresizingMaskIntoConstraints = false
        stemModelView.addSubview(stemLabel)
        
        let stemStatus = UILabel()
        stemStatus.text = "Ready"
        stemStatus.font = Typography.labelSmall
        stemStatus.textColor = StudioColors.statusSuccess
        stemStatus.translatesAutoresizingMaskIntoConstraints = false
        stemModelView.addSubview(stemStatus)
        
        NSLayoutConstraint.activate([
            stemLabel.leadingAnchor.constraint(equalTo: stemModelView.leadingAnchor, constant: 12),
            stemLabel.centerYAnchor.constraint(equalTo: stemModelView.centerYAnchor),
            stemStatus.trailingAnchor.constraint(equalTo: stemModelView.trailingAnchor, constant: -12),
            stemStatus.centerYAnchor.constraint(equalTo: stemModelView.centerYAnchor),
            stemModelView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Chord Model
        chordModelView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        chordModelView.layer.borderWidth = 1.0
        chordModelView.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        chordModelView.layer.cornerRadius = StudioTheme.shared.cornerRadius12
        chordModelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chordModelView)
        
        let chordLabel = UILabel()
        chordLabel.text = "🎼 Chord Model"
        chordLabel.font = Typography.labelMedium
        chordLabel.textColor = StudioColors.textPrimary
        chordLabel.translatesAutoresizingMaskIntoConstraints = false
        chordModelView.addSubview(chordLabel)
        
        let chordStatus = UILabel()
        chordStatus.text = "Ready"
        chordStatus.font = Typography.labelSmall
        chordStatus.textColor = StudioColors.statusSuccess
        chordStatus.translatesAutoresizingMaskIntoConstraints = false
        chordModelView.addSubview(chordStatus)
        
        NSLayoutConstraint.activate([
            chordLabel.leadingAnchor.constraint(equalTo: chordModelView.leadingAnchor, constant: 12),
            chordLabel.centerYAnchor.constraint(equalTo: chordModelView.centerYAnchor),
            chordStatus.trailingAnchor.constraint(equalTo: chordModelView.trailingAnchor, constant: -12),
            chordStatus.centerYAnchor.constraint(equalTo: chordModelView.centerYAnchor),
            chordModelView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Beat Model
        beatModelView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        beatModelView.layer.borderWidth = 1.0
        beatModelView.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        beatModelView.layer.cornerRadius = StudioTheme.shared.cornerRadius12
        beatModelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(beatModelView)
        
        let beatLabel = UILabel()
        beatLabel.text = "♩ Beat Model"
        beatLabel.font = Typography.labelMedium
        beatLabel.textColor = StudioColors.textPrimary
        beatLabel.translatesAutoresizingMaskIntoConstraints = false
        beatModelView.addSubview(beatLabel)
        
        let beatStatus = UILabel()
        beatStatus.text = "Ready"
        beatStatus.font = Typography.labelSmall
        beatStatus.textColor = StudioColors.statusSuccess
        beatStatus.translatesAutoresizingMaskIntoConstraints = false
        beatModelView.addSubview(beatStatus)
        
        NSLayoutConstraint.activate([
            beatLabel.leadingAnchor.constraint(equalTo: beatModelView.leadingAnchor, constant: 12),
            beatLabel.centerYAnchor.constraint(equalTo: beatModelView.centerYAnchor),
            beatStatus.trailingAnchor.constraint(equalTo: beatModelView.trailingAnchor, constant: -12),
            beatStatus.centerYAnchor.constraint(equalTo: beatModelView.centerYAnchor),
            beatModelView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // MARK: - Constraints
        let padding = StudioTheme.shared.spacing16
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            importLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            importLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: padding * 1.5),
            
            importAudioButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            importAudioButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            importAudioButton.topAnchor.constraint(equalTo: importLabel.bottomAnchor, constant: padding),
            
            importVideoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            importVideoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            importVideoButton.topAnchor.constraint(equalTo: importAudioButton.bottomAnchor, constant: 8),
            
            toolsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            toolsLabel.topAnchor.constraint(equalTo: importVideoButton.bottomAnchor, constant: padding * 1.5),
            
            toolsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            toolsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            toolsStackView.topAnchor.constraint(equalTo: toolsLabel.bottomAnchor, constant: padding),
            
            modelStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            modelStatusLabel.topAnchor.constraint(equalTo: toolsStackView.bottomAnchor, constant: padding * 1.5),
            
            stemModelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            stemModelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            stemModelView.topAnchor.constraint(equalTo: modelStatusLabel.bottomAnchor, constant: padding),
            
            chordModelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            chordModelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            chordModelView.topAnchor.constraint(equalTo: stemModelView.bottomAnchor, constant: 8),
            
            beatModelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            beatModelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            beatModelView.topAnchor.constraint(equalTo: chordModelView.bottomAnchor, constant: 8),
            beatModelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
    
    private func checkModelStatus() {
        // TODO: Connect to ModelManager untuk check status actual
        Logger.shared.info("Checking AI model status...")
    }
    
    @objc private func importAudioTapped() {
        Logger.shared.info("Import Audio tapped")
        onImportAudio?()
    }
    
    @objc private func importVideoTapped() {
        Logger.shared.info("Import Video tapped")
        onImportVideo?()
    }
}
