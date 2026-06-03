import UIKit

class ResultViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Stems Grid
    private let stemsLabel = UILabel()
    private let stemsStackView = UIStackView()
    
    // Action Buttons
    private let mixerButton = PurpleGlowButton()
    private let analyzerButton = PurpleGlowButton()
    private let exportButton = PurpleGlowButton()
    private let saveButton = PurpleGlowButton()
    
    var project: StemProject?
    var onOpenMixer: (() -> Void)?
    var onOpenAnalyzer: (() -> Void)?
    var onExport: (() -> Void)?
    var onSave: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStemsList()
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
        
        // MARK: - Title
        titleLabel.text = "Separation Complete"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        subtitleLabel.text = "6 Stems Generated"
        subtitleLabel.font = Typography.bodyMedium
        subtitleLabel.textColor = StudioColors.purpleAccent
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // MARK: - Stems Grid
        stemsLabel.text = "Stems"
        stemsLabel.font = Typography.headingMedium
        stemsLabel.textColor = StudioColors.textPrimary
        stemsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stemsLabel)
        
        stemsStackView.axis = .vertical
        stemsStackView.spacing = StudioTheme.shared.spacing8
        stemsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stemsStackView)
        
        let stemNames = [
            ("🎤", "Vocals", StudioColors.stemVocals),
            ("🥁", "Drums", StudioColors.stemDrums),
            ("🎸", "Guitar", StudioColors.stemGuitar),
            ("🎹", "Piano / Synth", StudioColors.stemPiano),
            ("🎺", "Bass", StudioColors.stemBass),
            ("❓", "Others", StudioColors.stemOthers)
        ]
        
        for (emoji, name, color) in stemNames {
            let stemCard = UIButton(type: .system)
            stemCard.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
            stemCard.layer.borderWidth = 1.0
            stemCard.layer.borderColor = color.withAlphaComponent(0.3).cgColor
            stemCard.layer.cornerRadius = StudioTheme.shared.cornerRadius16
            
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = color
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = Typography.labelMedium
                return outgoing
            }
            stemCard.configuration = config
            
            stemCard.setTitle("\(emoji) \(name)", for: .normal)
            stemCard.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            stemsStackView.addArrangedSubview(stemCard)
        }
        
        // MARK: - Action Buttons
        mixerButton.setTitle("Open Studio Mixer", for: .normal)
        mixerButton.addTarget(self, action: #selector(mixerTapped), for: .touchUpInside)
        mixerButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mixerButton)
        
        analyzerButton.setTitle("View AI Analyzer", for: .normal)
        analyzerButton.addTarget(self, action: #selector(analyzerTapped), for: .touchUpInside)
        analyzerButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(analyzerButton)
        
        exportButton.setTitle("Export Stems", for: .normal)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exportButton)
        
        saveButton.setTitle("Simpan Project", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        // MARK: - Constraints
        let padding = StudioTheme.shared.spacing16
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            stemsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            stemsLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: padding),
            
            stemsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            stemsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            stemsStackView.topAnchor.constraint(equalTo: stemsLabel.bottomAnchor, constant: padding),
            
            mixerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            mixerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            mixerButton.topAnchor.constraint(equalTo: stemsStackView.bottomAnchor, constant: padding),
            
            analyzerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            analyzerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            analyzerButton.topAnchor.constraint(equalTo: mixerButton.bottomAnchor, constant: 8),
            
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            exportButton.topAnchor.constraint(equalTo: analyzerButton.bottomAnchor, constant: 8),
            
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            saveButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 8),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
    
    private func loadStemsList() {
        // TODO: Load stems from project
        Logger.shared.info("Loading stems for project: \(project?.title ?? "Unknown")")
    }
    
    @objc private func mixerTapped() {
        Logger.shared.info("Open Mixer")
        onOpenMixer?()
    }
    
    @objc private func analyzerTapped() {
        Logger.shared.info("Open Analyzer")
        onOpenAnalyzer?()
    }
    
    @objc private func exportTapped() {
        Logger.shared.info("Export stems")
        onExport?()
    }
    
    @objc private func saveTapped() {
        Logger.shared.info("Save project")
        onSave?()
    }
}
