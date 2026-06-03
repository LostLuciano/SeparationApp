import UIKit

class MixerViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Player Section
    private let playerCard = GlassCardView()
    private let waveformView = WaveformView()
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    private let durationLabel = UILabel()
    
    // Stem Channels
    private let mixerLabel = UILabel()
    private let channelsStackView = UIStackView()
    private var stemChannels: [StemChannelView] = []
    
    // Performance Controls
    private let performanceLabel = UILabel()
    private let tempoSlider = UISlider()
    private let tempoLabel = UILabel()
    private let pitchSlider = UISlider()
    private let pitchLabel = UILabel()
    
    // Export Button
    private let exportButton = PurpleGlowButton()
    
    var project: StemProject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMixer()
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
        
        let padding = StudioTheme.shared.spacing16
        
        // MARK: - Player Section
        playerCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playerCard)
        
        // Waveform
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        playerCard.addSubview(waveformView)
        
        // Play/Pause buttons
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = StudioColors.purpleAccent
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playerCard.addSubview(playButton)
        
        pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        pauseButton.tintColor = StudioColors.purpleAccent
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        playerCard.addSubview(pauseButton)
        
        // Time labels
        timeLabel.text = "0:00"
        timeLabel.font = Typography.monoSmall
        timeLabel.textColor = StudioColors.textSecondary
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        playerCard.addSubview(timeLabel)
        
        durationLabel.text = "0:00"
        durationLabel.font = Typography.monoSmall
        durationLabel.textColor = StudioColors.textSecondary
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        playerCard.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            playerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            playerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            playerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            waveformView.leadingAnchor.constraint(equalTo: playerCard.leadingAnchor, constant: 12),
            waveformView.trailingAnchor.constraint(equalTo: playerCard.trailingAnchor, constant: -12),
            waveformView.topAnchor.constraint(equalTo: playerCard.topAnchor, constant: 12),
            waveformView.heightAnchor.constraint(equalToConstant: 80),
            
            playButton.leadingAnchor.constraint(equalTo: playerCard.leadingAnchor, constant: 12),
            playButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 12),
            playButton.widthAnchor.constraint(equalToConstant: 32),
            
            pauseButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            pauseButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 32),
            
            timeLabel.leadingAnchor.constraint(equalTo: pauseButton.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: playerCard.trailingAnchor, constant: -12),
            durationLabel.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            
            playerCard.bottomAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 12)
        ])
        
        // MARK: - Mixer Label
        mixerLabel.text = "Studio Mixer"
        mixerLabel.font = Typography.headingMedium
        mixerLabel.textColor = StudioColors.textPrimary
        mixerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mixerLabel)
        
        NSLayoutConstraint.activate([
            mixerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            mixerLabel.topAnchor.constraint(equalTo: playerCard.bottomAnchor, constant: padding)
        ])
        
        // MARK: - Stem Channels
        channelsStackView.axis = .vertical
        channelsStackView.spacing = StudioTheme.shared.spacing8
        channelsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(channelsStackView)
        
        let stemData = [
            ("Master", StudioColors.purpleAccent),
            ("🎤 Vocals", StudioColors.stemVocals),
            ("🥁 Drums", StudioColors.stemDrums),
            ("🎸 Bass", StudioColors.stemBass),
            ("🎸 Guitar", StudioColors.stemGuitar),
            ("🎹 Piano/Synth", StudioColors.stemPiano),
            ("❓ Others", StudioColors.stemOthers)
        ]
        
        for (name, color) in stemData {
            let channel = StemChannelView(title: name, color: color)
            channelsStackView.addArrangedSubview(channel)
            stemChannels.append(channel)
        }
        
        NSLayoutConstraint.activate([
            channelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            channelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            channelsStackView.topAnchor.constraint(equalTo: mixerLabel.bottomAnchor, constant: padding)
        ])
        
        // MARK: - Performance Controls
        performanceLabel.text = "Performance"
        performanceLabel.font = Typography.headingMedium
        performanceLabel.textColor = StudioColors.textPrimary
        performanceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(performanceLabel)
        
        // Tempo control
        let tempoContainer = UIView()
        tempoContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tempoContainer)
        
        let tempoTitleLabel = UILabel()
        tempoTitleLabel.text = "Tempo"
        tempoTitleLabel.font = Typography.labelMedium
        tempoTitleLabel.textColor = StudioColors.textPrimary
        tempoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tempoContainer.addSubview(tempoTitleLabel)
        
        tempoSlider.minimumValue = 0.5
        tempoSlider.maximumValue = 2.0
        tempoSlider.value = 1.0
        tempoSlider.minimumTrackTintColor = StudioColors.purpleAccent
        tempoSlider.maximumTrackTintColor = UIColor(white: 1.0, alpha: 0.15)
        tempoSlider.translatesAutoresizingMaskIntoConstraints = false
        tempoContainer.addSubview(tempoSlider)
        
        tempoLabel.text = "1.0x"
        tempoLabel.font = Typography.labelSmall
        tempoLabel.textColor = StudioColors.textSecondary
        tempoLabel.translatesAutoresizingMaskIntoConstraints = false
        tempoContainer.addSubview(tempoLabel)
        
        NSLayoutConstraint.activate([
            tempoTitleLabel.leadingAnchor.constraint(equalTo: tempoContainer.leadingAnchor),
            tempoTitleLabel.topAnchor.constraint(equalTo: tempoContainer.topAnchor),
            
            tempoSlider.leadingAnchor.constraint(equalTo: tempoContainer.leadingAnchor),
            tempoSlider.trailingAnchor.constraint(equalTo: tempoContainer.trailingAnchor, constant: -60),
            tempoSlider.topAnchor.constraint(equalTo: tempoTitleLabel.bottomAnchor, constant: 8),
            
            tempoLabel.leadingAnchor.constraint(equalTo: tempoSlider.trailingAnchor, constant: 8),
            tempoLabel.centerYAnchor.constraint(equalTo: tempoSlider.centerYAnchor),
            tempoLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        // Pitch control
        let pitchContainer = UIView()
        pitchContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pitchContainer)
        
        let pitchTitleLabel = UILabel()
        pitchTitleLabel.text = "Pitch"
        pitchTitleLabel.font = Typography.labelMedium
        pitchTitleLabel.textColor = StudioColors.textPrimary
        pitchTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pitchContainer.addSubview(pitchTitleLabel)
        
        pitchSlider.minimumValue = -12
        pitchSlider.maximumValue = 12
        pitchSlider.value = 0
        pitchSlider.minimumTrackTintColor = StudioColors.purpleAccent
        pitchSlider.maximumTrackTintColor = UIColor(white: 1.0, alpha: 0.15)
        pitchSlider.translatesAutoresizingMaskIntoConstraints = false
        pitchContainer.addSubview(pitchSlider)
        
        pitchLabel.text = "0 st"
        pitchLabel.font = Typography.labelSmall
        pitchLabel.textColor = StudioColors.textSecondary
        pitchLabel.translatesAutoresizingMaskIntoConstraints = false
        pitchContainer.addSubview(pitchLabel)
        
        NSLayoutConstraint.activate([
            pitchTitleLabel.leadingAnchor.constraint(equalTo: pitchContainer.leadingAnchor),
            pitchTitleLabel.topAnchor.constraint(equalTo: pitchContainer.topAnchor),
            
            pitchSlider.leadingAnchor.constraint(equalTo: pitchContainer.leadingAnchor),
            pitchSlider.trailingAnchor.constraint(equalTo: pitchContainer.trailingAnchor, constant: -60),
            pitchSlider.topAnchor.constraint(equalTo: pitchTitleLabel.bottomAnchor, constant: 8),
            
            pitchLabel.leadingAnchor.constraint(equalTo: pitchSlider.trailingAnchor, constant: 8),
            pitchLabel.centerYAnchor.constraint(equalTo: pitchSlider.centerYAnchor),
            pitchLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        // MARK: - Export Button
        exportButton.setTitle("Export Mix to Stereo M4A", for: .normal)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exportButton)
        
        // MARK: - Final Constraints
        NSLayoutConstraint.activate([
            performanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            performanceLabel.topAnchor.constraint(equalTo: channelsStackView.bottomAnchor, constant: padding),
            
            tempoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            tempoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            tempoContainer.topAnchor.constraint(equalTo: performanceLabel.bottomAnchor, constant: padding),
            
            pitchContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            pitchContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            pitchContainer.topAnchor.constraint(equalTo: tempoContainer.bottomAnchor, constant: padding),
            
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            exportButton.topAnchor.constraint(equalTo: pitchContainer.bottomAnchor, constant: padding),
            exportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
    
    private func setupMixer() {
        Logger.shared.info("Setting up mixer for project: \(project?.title ?? "Unknown")")
        // TODO: Load stems and configure mixer
    }
}
