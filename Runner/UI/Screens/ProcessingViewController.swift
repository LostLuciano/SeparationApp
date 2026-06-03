import UIKit

class ProcessingViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let filenameLabel = UILabel()
    
    // Progress
    private let progressRing = ProcessingRingView()
    private let percentageLabel = UILabel()
    
    // Stages
    private let stagesLabel = UILabel()
    private let stagesStackView = UIStackView()
    private let stages: [ProcessingStageRowView] = []
    
    // Info
    private let modeLabel = UILabel()
    private let timerLabel = UILabel()
    private let etaLabel = UILabel()
    
    // Cancel Button
    private let cancelButton = UIButton(type: .system)
    
    var project: StemProject?
    var onCancel: (() -> Void)?
    var onComplete: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startProcessing()
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
        titleLabel.text = "Separation in Progress"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        filenameLabel.text = project?.title ?? "Unknown Audio"
        filenameLabel.font = Typography.bodyMedium
        filenameLabel.textColor = StudioColors.textSecondary
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(filenameLabel)
        
        // MARK: - Progress Ring
        progressRing.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressRing)
        
        percentageLabel.font = Typography.displaySmall
        percentageLabel.textColor = StudioColors.purpleAccent
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            progressRing.widthAnchor.constraint(equalToConstant: 180),
            progressRing.heightAnchor.constraint(equalToConstant: 180),
            progressRing.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            percentageLabel.centerXAnchor.constraint(equalTo: progressRing.centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: progressRing.centerYAnchor)
        ])
        
        // MARK: - Stages
        stagesLabel.text = "Processing Stages"
        stagesLabel.font = Typography.headingMedium
        stagesLabel.textColor = StudioColors.textPrimary
        stagesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stagesLabel)
        
        stagesStackView.axis = .vertical
        stagesStackView.spacing = StudioTheme.shared.spacing8
        stagesStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stagesStackView)
        
        let stageNames = ["Decode Audio", "STFT Transform", "AI Inference", "Reconstruction", "Export Stems"]
        for stageName in stageNames {
            let stageView = ProcessingStageRowView(stage: stageName)
            stagesStackView.addArrangedSubview(stageView)
        }
        
        // MARK: - Info Section
        let infoCard = GlassCardView()
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCard)
        
        modeLabel.text = "Mode: Light FP16 · Neural Engine"
        modeLabel.font = Typography.labelSmall
        modeLabel.textColor = StudioColors.textSecondary
        modeLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(modeLabel)
        
        timerLabel.text = "Elapsed: 00:00"
        timerLabel.font = Typography.monoMedium
        timerLabel.textColor = StudioColors.textPrimary
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(timerLabel)
        
        etaLabel.text = "ETA: 03:00"
        etaLabel.font = Typography.monoMedium
        etaLabel.textColor = StudioColors.textPrimary
        etaLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(etaLabel)
        
        NSLayoutConstraint.activate([
            modeLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            modeLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            
            timerLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            timerLabel.topAnchor.constraint(equalTo: modeLabel.bottomAnchor, constant: 8),
            
            etaLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            etaLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),
            etaLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12)
        ])
        
        // MARK: - Cancel Button
        cancelButton.setTitle("Batalkan", for: .normal)
        cancelButton.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        cancelButton.layer.cornerRadius = StudioTheme.shared.cornerRadius16
        cancelButton.setTitleColor(StudioColors.statusError, for: .normal)
        cancelButton.titleLabel?.font = Typography.labelLarge
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cancelButton)
        
        cancelButton.heightAnchor.constraint(equalToConstant: StudioTheme.shared.buttonHeightMedium).isActive = true
        
        // MARK: - Constraints
        let padding = StudioTheme.shared.spacing16
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            filenameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            filenameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            progressRing.topAnchor.constraint(equalTo: filenameLabel.bottomAnchor, constant: padding * 1.5),
            
            stagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            stagesLabel.topAnchor.constraint(equalTo: progressRing.bottomAnchor, constant: padding * 1.5),
            
            stagesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            stagesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            stagesStackView.topAnchor.constraint(equalTo: stagesLabel.bottomAnchor, constant: padding),
            
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            infoCard.topAnchor.constraint(equalTo: stagesStackView.bottomAnchor, constant: padding),
            
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            cancelButton.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: padding),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
    
    private func startProcessing() {
        Logger.shared.info("Starting processing for project: \(project?.title ?? "Unknown")")
        
        // Simulate progress
        var progress: CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            progress += 0.01
            if progress >= 1.0 {
                timer.invalidate()
                self?.completeProcessing()
            } else {
                self?.progressRing.progress = progress
                self?.percentageLabel.text = String(format: "%.0f%%", progress * 100)
            }
        }
    }
    
    private func completeProcessing() {
        Logger.shared.info("Processing completed")
        onComplete?()
    }
    
    @objc private func cancelTapped() {
        Logger.shared.info("Processing cancelled")
        onCancel?()
    }
}
