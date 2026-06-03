import UIKit

class ExportViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Export options
    private let formatSegment = StudioSegmentedControl(items: ["M4A", "WAV", "FLAC"])
    private let qualitySlider = UISlider()
    private let qualityLabel = UILabel()
    
    // Export button
    private let exportButton = PurpleGlowButton()
    private let progressRing = ProcessingRingView()
    
    var project: StemProject?
    var onComplete: (() -> Void)?
    
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
        titleLabel.text = "Export Mix"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Project info
        let projectLabel = UILabel()
        projectLabel.text = project?.title ?? "Unknown Project"
        projectLabel.font = Typography.bodyMedium
        projectLabel.textColor = StudioColors.textSecondary
        projectLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(projectLabel)
        
        // Format section
        let formatLabel = UILabel()
        formatLabel.text = "Format"
        formatLabel.font = Typography.labelMedium
        formatLabel.textColor = StudioColors.textPrimary
        formatLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formatLabel)
        
        formatSegment.selectedSegmentIndex = 0
        formatSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formatSegment)
        
        // Quality section
        let qualityTitleLabel = UILabel()
        qualityTitleLabel.text = "Quality"
        qualityTitleLabel.font = Typography.labelMedium
        qualityTitleLabel.textColor = StudioColors.textPrimary
        qualityTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(qualityTitleLabel)
        
        qualitySlider.minimumValue = 64
        qualitySlider.maximumValue = 320
        qualitySlider.value = 192
        qualitySlider.minimumTrackTintColor = StudioColors.purpleAccent
        qualitySlider.maximumTrackTintColor = UIColor(white: 1.0, alpha: 0.15)
        qualitySlider.addTarget(self, action: #selector(qualityChanged), for: .valueChanged)
        qualitySlider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(qualitySlider)
        
        qualityLabel.text = "192 kbps"
        qualityLabel.font = Typography.labelSmall
        qualityLabel.textColor = StudioColors.textSecondary
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(qualityLabel)
        
        // Advanced Options
        let advancedLabel = UILabel()
        advancedLabel.text = "Advanced Options"
        advancedLabel.font = Typography.labelMedium
        advancedLabel.textColor = StudioColors.textPrimary
        advancedLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(advancedLabel)
        
        let normalizationToggle = UIButton(type: .system)
        normalizationToggle.setTitle("🔊 Normalize Audio Level", for: .normal)
        normalizationToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        normalizationToggle.layer.borderWidth = 1.0
        normalizationToggle.layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        normalizationToggle.layer.cornerRadius = StudioTheme.shared.cornerRadius12
        normalizationToggle.setTitleColor(StudioColors.textPrimary, for: .normal)
        normalizationToggle.titleLabel?.font = Typography.labelMedium
        normalizationToggle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(normalizationToggle)
        
        normalizationToggle.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Progress Ring
        progressRing.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressRing)
        
        NSLayoutConstraint.activate([
            progressRing.widthAnchor.constraint(equalToConstant: 140),
            progressRing.heightAnchor.constraint(equalToConstant: 140),
            progressRing.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        progressRing.isHidden = true
        
        // Export button
        exportButton.setTitle("Export Mix", for: .normal)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exportButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            projectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            projectLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            formatLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            formatLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: padding),
            
            formatSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            formatSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            formatSegment.topAnchor.constraint(equalTo: formatLabel.bottomAnchor, constant: 8),
            formatSegment.heightAnchor.constraint(equalToConstant: 32),
            
            qualityTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            qualityTitleLabel.topAnchor.constraint(equalTo: formatSegment.bottomAnchor, constant: padding),
            
            qualitySlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            qualitySlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding * 2 - 40),
            qualitySlider.topAnchor.constraint(equalTo: qualityTitleLabel.bottomAnchor, constant: 8),
            
            qualityLabel.leadingAnchor.constraint(equalTo: qualitySlider.trailingAnchor, constant: 8),
            qualityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            qualityLabel.centerYAnchor.constraint(equalTo: qualitySlider.centerYAnchor),
            qualityLabel.widthAnchor.constraint(equalToConstant: 60),
            
            advancedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            advancedLabel.topAnchor.constraint(equalTo: qualitySlider.bottomAnchor, constant: padding),
            
            normalizationToggle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            normalizationToggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            normalizationToggle.topAnchor.constraint(equalTo: advancedLabel.bottomAnchor, constant: 8),
            
            progressRing.topAnchor.constraint(equalTo: normalizationToggle.bottomAnchor, constant: padding * 2),
            
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            exportButton.topAnchor.constraint(equalTo: progressRing.bottomAnchor, constant: padding),
            exportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
    
    @objc private func qualityChanged() {
        let quality = Int(qualitySlider.value)
        qualityLabel.text = "\(quality) kbps"
    }
    
    @objc private func exportTapped() {
        Logger.shared.info("Starting export for project: \(project?.title ?? "Unknown")")
        
        exportButton.isHidden = true
        progressRing.isHidden = false
        
        // Simulate export progress
        var progress: CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            progress += 0.02
            if progress >= 1.0 {
                timer.invalidate()
                self?.completeExport()
            } else {
                self?.progressRing.progress = progress
            }
        }
    }
    
    private func completeExport() {
        Logger.shared.info("Export completed")
        onComplete?()
    }
}
