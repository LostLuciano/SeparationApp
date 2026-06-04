import UIKit

class StemChannelView: UIView {
    let titleLabel = UILabel()
    let volumeSlider = UISlider()
    let dbLabel = UILabel()
    let muteButton = UIButton(type: .system)
    let soloButton = UIButton(type: .system)
    
    var onVolumeChange: ((Float) -> Void)?
    var onMute: ((Bool) -> Void)?
    var onSolo: ((Bool) -> Void)?
    
    init(title: String, color: UIColor) {
        super.init(frame: .zero)
        setup(title: title, color: color)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "Unknown", color: AppStudioColors.stemOthers)
    }
    
    private func setup(title: String, color: UIColor) {
        // Background
        backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius16
        
        // Title
        titleLabel.text = title
        titleLabel.font = StudioTypography.labelMedium
        titleLabel.textColor = color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Volume slider
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = 0.7
        volumeSlider.minimumTrackTintColor = color
        volumeSlider.maximumTrackTintColor = UIColor(white: 1.0, alpha: 0.15)
        volumeSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(volumeSlider)
        
        // dB Label
        dbLabel.text = "-6 dB"
        dbLabel.font = StudioTypography.labelSmall
        dbLabel.textColor = AppStudioColors.textSecondary
        dbLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dbLabel)
        
        // Mute button
        muteButton.setImage(UIImage(systemName: "speaker.slash"), for: .normal)
        muteButton.tintColor = AppStudioColors.textSecondary
        muteButton.addTarget(self, action: #selector(muteToggled), for: .touchUpInside)
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(muteButton)
        
        // Solo button
        soloButton.setImage(UIImage(systemName: "headphones"), for: .normal)
        soloButton.tintColor = AppStudioColors.textSecondary
        soloButton.addTarget(self, action: #selector(soloToggled), for: .touchUpInside)
        soloButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(soloButton)
        
        // Layout
        let padding = StudioTheme.shared.spacing12
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            
            volumeSlider.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: padding),
            volumeSlider.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            volumeSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            dbLabel.leadingAnchor.constraint(equalTo: volumeSlider.trailingAnchor, constant: padding),
            dbLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dbLabel.widthAnchor.constraint(equalToConstant: 50),
            
            muteButton.leadingAnchor.constraint(equalTo: dbLabel.trailingAnchor, constant: padding),
            muteButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            muteButton.widthAnchor.constraint(equalToConstant: 32),
            
            soloButton.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor, constant: 4),
            soloButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            soloButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            soloButton.widthAnchor.constraint(equalToConstant: 32),
            
            bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding)
        ])
    }
    
    @objc private func sliderChanged() {
        let dB = 20 * log10(CGFloat(volumeSlider.value))
        dbLabel.text = String(format: "%.1f dB", dB)
        onVolumeChange?(volumeSlider.value)
    }
    
    @objc private func muteToggled() {
        let isMuted = muteButton.tintColor == AppStudioColors.purpleAccent
        muteButton.tintColor = isMuted ? AppStudioColors.textSecondary : AppStudioColors.purpleAccent
        onMute?(!isMuted)
    }
    
    @objc private func soloToggled() {
        let isSolo = soloButton.tintColor == AppStudioColors.purpleAccent
        soloButton.tintColor = isSolo ? AppStudioColors.textSecondary : AppStudioColors.purpleAccent
        onSolo?(!isSolo)
    }
}
