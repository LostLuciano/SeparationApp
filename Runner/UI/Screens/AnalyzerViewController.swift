import UIKit

class AnalyzerViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Tab Bar
    private let tabBar = FloatingTabBar(tabs: ["Chords", "Beat", "Lyrics"])
    
    // MARK: - Chords Tab Content
    private let chordsContainer = UIView()
    private let currentChordView = ChordPatternView(chord: "Am", notes: "A · C · E", quality: "Minor")
    private let chordInfoCard = GlassCardView()
    private let chordTimelineView = ChordTimelineView()
    private let chordProgressionLabel = UILabel()
    
    // MARK: - Beat Tab Content
    private let beatContainer = UIView()
    private let bpmLabel = UILabel()
    private let confidenceLabel = UILabel()
    private let timeSignatureLabel = UILabel()
    private let beatGridView = BeatGridView()
    private let tapTempoButton = UIButton(type: .system)
    
    // MARK: - Lyrics Tab Content
    private let lyricsContainer = UIView()
    private let lyricsView = LyricsKaraokeView()
    
    var project: StemProject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tabBar.delegate = self
        loadAnalysis()
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
        
        // MARK: - Tab Bar
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabBar)
        
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            tabBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            tabBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            tabBar.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // MARK: - Chords Container
        chordsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chordsContainer)
        
        // Current chord
        currentChordView.translatesAutoresizingMaskIntoConstraints = false
        chordsContainer.addSubview(currentChordView)
        
        // Chord info
        chordInfoCard.translatesAutoresizingMaskIntoConstraints = false
        chordsContainer.addSubview(chordInfoCard)
        
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        chordInfoCard.addSubview(infoStack)
        
        let qualityLabel = UILabel()
        qualityLabel.text = "Quality: Minor"
        qualityLabel.font = Typography.labelSmall
        qualityLabel.textColor = StudioColors.textSecondary
        infoStack.addArrangedSubview(qualityLabel)
        
        let romanLabel = UILabel()
        romanLabel.text = "Roman: i"
        romanLabel.font = Typography.labelSmall
        romanLabel.textColor = StudioColors.textSecondary
        infoStack.addArrangedSubview(romanLabel)
        
        let nextLabel = UILabel()
        nextLabel.text = "Next: Bm"
        nextLabel.font = Typography.labelSmall
        nextLabel.textColor = StudioColors.textSecondary
        infoStack.addArrangedSubview(nextLabel)
        
        let keyLabel = UILabel()
        keyLabel.text = "Key: A Minor"
        keyLabel.font = Typography.labelSmall
        keyLabel.textColor = StudioColors.textSecondary
        infoStack.addArrangedSubview(keyLabel)
        
        let confidenceLabel = UILabel()
        confidenceLabel.text = "Confidence: 98%"
        confidenceLabel.font = Typography.labelSmall
        confidenceLabel.textColor = StudioColors.statusSuccess
        infoStack.addArrangedSubview(confidenceLabel)
        
        NSLayoutConstraint.activate([
            infoStack.leadingAnchor.constraint(equalTo: chordInfoCard.leadingAnchor, constant: 12),
            infoStack.topAnchor.constraint(equalTo: chordInfoCard.topAnchor, constant: 12),
            infoStack.trailingAnchor.constraint(equalTo: chordInfoCard.trailingAnchor, constant: -12),
            infoStack.bottomAnchor.constraint(equalTo: chordInfoCard.bottomAnchor, constant: -12)
        ])
        
        // Chord progression
        chordProgressionLabel.text = "Am | A | Bm | B# | C | Dm | E | F | G"
        chordProgressionLabel.font = Typography.bodySmall
        chordProgressionLabel.textColor = StudioColors.textSecondary
        chordProgressionLabel.numberOfLines = 0
        chordProgressionLabel.translatesAutoresizingMaskIntoConstraints = false
        chordsContainer.addSubview(chordProgressionLabel)
        
        // Chord timeline
        chordTimelineView.translatesAutoresizingMaskIntoConstraints = false
        chordsContainer.addSubview(chordTimelineView)
        
        for i in 0..<9 {
            chordTimelineView.addChord(["Am", "A", "Bm", "B#", "C", "Dm", "E", "F", "G"][i], index: i)
        }
        
        NSLayoutConstraint.activate([
            currentChordView.leadingAnchor.constraint(equalTo: chordsContainer.leadingAnchor, constant: padding),
            currentChordView.widthAnchor.constraint(equalToConstant: 120),
            currentChordView.topAnchor.constraint(equalTo: chordsContainer.topAnchor),
            
            chordInfoCard.leadingAnchor.constraint(equalTo: currentChordView.trailingAnchor, constant: padding),
            chordInfoCard.trailingAnchor.constraint(equalTo: chordsContainer.trailingAnchor, constant: -padding),
            chordInfoCard.topAnchor.constraint(equalTo: chordsContainer.topAnchor),
            chordInfoCard.heightAnchor.constraint(equalTo: currentChordView.heightAnchor),
            
            chordProgressionLabel.leadingAnchor.constraint(equalTo: chordsContainer.leadingAnchor, constant: padding),
            chordProgressionLabel.trailingAnchor.constraint(equalTo: chordsContainer.trailingAnchor, constant: -padding),
            chordProgressionLabel.topAnchor.constraint(equalTo: currentChordView.bottomAnchor, constant: padding),
            
            chordTimelineView.leadingAnchor.constraint(equalTo: chordsContainer.leadingAnchor, constant: padding),
            chordTimelineView.trailingAnchor.constraint(equalTo: chordsContainer.trailingAnchor, constant: -padding),
            chordTimelineView.topAnchor.constraint(equalTo: chordProgressionLabel.bottomAnchor, constant: padding),
            chordTimelineView.bottomAnchor.constraint(equalTo: chordsContainer.bottomAnchor, constant: -padding)
        ])
        
        // MARK: - Beat Container
        beatContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(beatContainer)
        
        bpmLabel.text = "130 BPM"
        bpmLabel.font = Typography.displayMedium
        bpmLabel.textColor = StudioColors.purpleAccent
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false
        beatContainer.addSubview(bpmLabel)
        
        confidenceLabel.text = "Confidence: 96%"
        confidenceLabel.font = Typography.labelSmall
        confidenceLabel.textColor = StudioColors.statusSuccess
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        beatContainer.addSubview(confidenceLabel)
        
        timeSignatureLabel.text = "Time Signature: 4/4"
        timeSignatureLabel.font = Typography.labelSmall
        timeSignatureLabel.textColor = StudioColors.textSecondary
        timeSignatureLabel.translatesAutoresizingMaskIntoConstraints = false
        beatContainer.addSubview(timeSignatureLabel)
        
        beatGridView.beats = 4
        beatGridView.translatesAutoresizingMaskIntoConstraints = false
        beatContainer.addSubview(beatGridView)
        
        tapTempoButton.setTitle("Tap Tempo", for: .normal)
        tapTempoButton.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        tapTempoButton.layer.borderWidth = 1.0
        tapTempoButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        tapTempoButton.layer.cornerRadius = StudioTheme.shared.cornerRadius16
        tapTempoButton.setTitleColor(StudioColors.textPrimary, for: .normal)
        tapTempoButton.titleLabel?.font = Typography.labelMedium
        tapTempoButton.translatesAutoresizingMaskIntoConstraints = false
        beatContainer.addSubview(tapTempoButton)
        
        NSLayoutConstraint.activate([
            bpmLabel.leadingAnchor.constraint(equalTo: beatContainer.leadingAnchor, constant: padding),
            bpmLabel.topAnchor.constraint(equalTo: beatContainer.topAnchor),
            
            confidenceLabel.trailingAnchor.constraint(equalTo: beatContainer.trailingAnchor, constant: -padding),
            confidenceLabel.topAnchor.constraint(equalTo: beatContainer.topAnchor),
            
            timeSignatureLabel.leadingAnchor.constraint(equalTo: beatContainer.leadingAnchor, constant: padding),
            timeSignatureLabel.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 8),
            
            beatGridView.leadingAnchor.constraint(equalTo: beatContainer.leadingAnchor, constant: padding),
            beatGridView.trailingAnchor.constraint(equalTo: beatContainer.trailingAnchor, constant: -padding),
            beatGridView.topAnchor.constraint(equalTo: timeSignatureLabel.bottomAnchor, constant: padding),
            beatGridView.heightAnchor.constraint(equalToConstant: 100),
            
            tapTempoButton.leadingAnchor.constraint(equalTo: beatContainer.leadingAnchor, constant: padding),
            tapTempoButton.trailingAnchor.constraint(equalTo: beatContainer.trailingAnchor, constant: -padding),
            tapTempoButton.topAnchor.constraint(equalTo: beatGridView.bottomAnchor, constant: padding),
            tapTempoButton.heightAnchor.constraint(equalToConstant: 44),
            tapTempoButton.bottomAnchor.constraint(equalTo: beatContainer.bottomAnchor, constant: -padding)
        ])
        
        // MARK: - Lyrics Container
        lyricsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lyricsContainer)
        
        lyricsView.translatesAutoresizingMaskIntoConstraints = false
        lyricsContainer.addSubview(lyricsView)
        
        NSLayoutConstraint.activate([
            lyricsView.leadingAnchor.constraint(equalTo: lyricsContainer.leadingAnchor, constant: padding),
            lyricsView.trailingAnchor.constraint(equalTo: lyricsContainer.trailingAnchor, constant: -padding),
            lyricsView.topAnchor.constraint(equalTo: lyricsContainer.topAnchor),
            lyricsView.bottomAnchor.constraint(equalTo: lyricsContainer.bottomAnchor),
            lyricsView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        // MARK: - Main Constraints
        NSLayoutConstraint.activate([
            chordsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chordsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chordsContainer.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: padding),
            chordsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            
            beatContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            beatContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            beatContainer.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: padding),
            beatContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            
            lyricsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            lyricsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            lyricsContainer.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: padding),
            lyricsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        // Hide beat and lyrics by default
        beatContainer.isHidden = true
        lyricsContainer.isHidden = true
    }
    
    private func loadAnalysis() {
        Logger.shared.info("Loading analysis for project: \(project?.title ?? "Unknown")")
    }
}

// MARK: - FloatingTabBarDelegate
extension AnalyzerViewController: FloatingTabBarDelegate {
    func floatingTabBar(_ tabBar: FloatingTabBar, didSelectTab index: Int) {
        chordsContainer.isHidden = (index != 0)
        beatContainer.isHidden = (index != 1)
        lyricsContainer.isHidden = (index != 2)
    }
}
