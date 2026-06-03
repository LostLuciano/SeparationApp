import UIKit

class ProfileViewController: UIViewController {
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
        
        // Profile Header
        let profileCard = GlassCardView()
        profileCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileCard)
        
        let avatarLabel = UILabel()
        avatarLabel.text = "🎵"
        avatarLabel.font = UIFont.systemFont(ofSize: 48)
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(avatarLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = "Musisi Baru"
        nameLabel.font = Typography.headingMedium
        nameLabel.textColor = StudioColors.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(nameLabel)
        
        let levelLabel = UILabel()
        levelLabel.text = "Free · Level 1"
        levelLabel.font = Typography.labelSmall
        levelLabel.textColor = StudioColors.textSecondary
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        profileCard.addSubview(levelLabel)
        
        NSLayoutConstraint.activate([
            profileCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            profileCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            profileCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            avatarLabel.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: padding),
            avatarLabel.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: padding),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarLabel.trailingAnchor, constant: padding),
            nameLabel.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: padding),
            
            levelLabel.leadingAnchor.constraint(equalTo: avatarLabel.trailingAnchor, constant: padding),
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            levelLabel.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -padding)
        ])
        
        // Stats
        let statsStack = UIStackView()
        statsStack.axis = .vertical
        statsStack.spacing = padding
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsStack)
        
        let stats = [
            ("📊", "Analisis Proyek", "12 projects analyzed"),
            ("🎙️", "Rekaman Tersimpan", "8 recordings saved"),
            ("💾", "Cache Size", "245 MB"),
            ("ℹ️", "Tentang Aplikasi", "MusicX Native v1.0.0")
        ]
        
        for (icon, title, subtitle) in stats {
            let statCard = UIButton(type: .system)
            statCard.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            statCard.layer.borderWidth = 1.0
            statCard.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            statCard.layer.cornerRadius = StudioTheme.shared.cornerRadius16
            
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = StudioColors.textPrimary
            statCard.configuration = config
            
            statCard.setTitle("\(icon) \(title)", for: .normal)
            statCard.titleLabel?.font = Typography.labelMedium
            statCard.heightAnchor.constraint(equalToConstant: 48).isActive = true
            
            statsStack.addArrangedSubview(statCard)
        }
        
        NSLayoutConstraint.activate([
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            statsStack.topAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: padding),
            statsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
}
