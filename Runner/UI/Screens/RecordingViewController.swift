import UIKit

class RecordingViewController: UIViewController {
    private let contentView = UIView()
    
    // Recording Mode
    private let modeSegment = StudioSegmentedControl(items: ["Audio Saja", "Overdub Mix"])
    
    // Recording Title
    private let titleLabel = UILabel()
    
    // Input Level Meter
    private let levelMeterLabel = UILabel()
    private let levelMeterView = AudioLevelMeterView()
    private let dbLabel = UILabel()
    
    // Headphone Monitoring
    private let monitorLabel = UILabel()
    private let monitorSegment = StudioSegmentedControl(items: ["Off", "Input", "Mix"])
    
    // Record Button
    private let recordButton = UIButton(type: .system)
    private var isRecording = false
    
    // Timer
    private let timerLabel = UILabel()
    
    // Metronome
    private let metronomeToggle = UIButton(type: .system)
    
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Title
        titleLabel.text = "Sesi Rekaman"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Mode selection
        modeSegment.selectedSegmentIndex = 0
        modeSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(modeSegment)
        
        // Recording video label
        let videoLabel = UILabel()
        videoLabel.text = "Rekam Video Sesi"
        videoLabel.font = Typography.labelMedium
        videoLabel.textColor = StudioColors.textSecondary
        videoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(videoLabel)
        
        // Input Level
        levelMeterLabel.text = "Input Level"
        levelMeterLabel.font = Typography.labelMedium
        levelMeterLabel.textColor = StudioColors.textPrimary
        levelMeterLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelMeterLabel)
        
        levelMeterView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelMeterView)
        
        dbLabel.text = "-12 dB"
        dbLabel.font = Typography.labelSmall
        dbLabel.textColor = StudioColors.textSecondary
        dbLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dbLabel)
        
        // Headphone monitoring
        monitorLabel.text = "Headphone Monitoring"
        monitorLabel.font = Typography.labelMedium
        monitorLabel.textColor = StudioColors.textPrimary
        monitorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monitorLabel)
        
        monitorSegment.selectedSegmentIndex = 0
        monitorSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monitorSegment)
        
        // Timer
        timerLabel.text = "00:00:00"
        timerLabel.font = Typography.monoLarge
        timerLabel.textColor = StudioColors.purpleAccent
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timerLabel)
        
        // Record button (large red circle)
        recordButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 120).isActive = true
        recordButton.backgroundColor = StudioColors.statusError
        recordButton.layer.cornerRadius = 60
        recordButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        recordButton.imageView?.contentMode = .scaleAspectFill
        recordButton.tintColor = .white
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recordButton)
        
        // Metronome
        metronomeToggle.setTitle("🎵 Metronome", for: .normal)
        metronomeToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        metronomeToggle.layer.borderWidth = 1.0
        metronomeToggle.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        metronomeToggle.layer.cornerRadius = StudioTheme.shared.cornerRadius16
        metronomeToggle.setTitleColor(StudioColors.textPrimary, for: .normal)
        metronomeToggle.titleLabel?.font = Typography.labelMedium
        metronomeToggle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metronomeToggle)
        
        metronomeToggle.heightAnchor.constraint(equalToConstant: StudioTheme.shared.buttonHeightMedium).isActive = true
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            modeSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            modeSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            modeSegment.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),
            modeSegment.heightAnchor.constraint(equalToConstant: 32),
            
            videoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            videoLabel.topAnchor.constraint(equalTo: modeSegment.bottomAnchor, constant: padding),
            
            levelMeterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            levelMeterLabel.topAnchor.constraint(equalTo: videoLabel.bottomAnchor, constant: padding * 1.5),
            
            levelMeterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            levelMeterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            levelMeterView.topAnchor.constraint(equalTo: levelMeterLabel.bottomAnchor, constant: 8),
            
            dbLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            dbLabel.topAnchor.constraint(equalTo: levelMeterView.bottomAnchor, constant: 8),
            
            monitorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            monitorLabel.topAnchor.constraint(equalTo: dbLabel.bottomAnchor, constant: padding),
            
            monitorSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            monitorSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            monitorSegment.topAnchor.constraint(equalTo: monitorLabel.bottomAnchor, constant: 8),
            monitorSegment.heightAnchor.constraint(equalToConstant: 32),
            
            timerLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: monitorSegment.bottomAnchor, constant: padding * 2),
            
            recordButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            recordButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: padding * 2),
            
            metronomeToggle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            metronomeToggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            metronomeToggle.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: padding * 2)
        ])
        
        levelMeterView.startAnimating()
    }
    
    @objc private func recordTapped() {
        isRecording.toggle()
        
        if isRecording {
            recordButton.backgroundColor = StudioColors.statusError
            timerLabel.textColor = StudioColors.statusError
            Logger.shared.info("Recording started")
        } else {
            recordButton.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
            timerLabel.textColor = StudioColors.textSecondary
            Logger.shared.info("Recording stopped")
        }
    }
}
