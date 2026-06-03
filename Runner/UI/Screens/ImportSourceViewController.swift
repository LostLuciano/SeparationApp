import UIKit

class ImportSourceViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let importAudioButton = PurpleGlowButton()
    private let importVideoButton = PurpleGlowButton()
    private let browseFilesButton = PurpleGlowButton()
    
    private let recentLabel = UILabel()
    private let recentStackView = UIStackView()
    
    var onAudioSelected: ((URL) -> Void)?
    var onVideoSelected: ((URL) -> Void)?
    
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
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Impor Audio / Video"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Pilih Sumber"
        subtitleLabel.font = Typography.bodyMedium
        subtitleLabel.textColor = StudioColors.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Import buttons
        importAudioButton.setTitle("Impor Audio", for: .normal)
        importAudioButton.addTarget(self, action: #selector(importAudioTapped), for: .touchUpInside)
        importAudioButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(importAudioButton)
        
        importVideoButton.setTitle("Impor Video", for: .normal)
        importVideoButton.addTarget(self, action: #selector(importVideoTapped), for: .touchUpInside)
        importVideoButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(importVideoButton)
        
        browseFilesButton.setTitle("Browse iPhone Files", for: .normal)
        browseFilesButton.addTarget(self, action: #selector(browseFilesTapped), for: .touchUpInside)
        browseFilesButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(browseFilesButton)
        
        // Recent files
        recentLabel.text = "Recent Files"
        recentLabel.font = Typography.headingMedium
        recentLabel.textColor = StudioColors.textPrimary
        recentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recentLabel)
        
        recentStackView.axis = .vertical
        recentStackView.spacing = StudioTheme.shared.spacing8
        recentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recentStackView)
        
        let recentFiles = ["My Song.wav", "Recording.m4a", "Live Session.caf"]
        for file in recentFiles {
            let fileButton = UIButton(type: .system)
            fileButton.setTitle("📁 " + file, for: .normal)
            fileButton.setTitleColor(StudioColors.purpleAccent, for: .normal)
            fileButton.titleLabel?.font = Typography.labelMedium
            fileButton.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
            fileButton.layer.borderWidth = 1.0
            fileButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            fileButton.layer.cornerRadius = StudioTheme.shared.cornerRadius12
            fileButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            recentStackView.addArrangedSubview(fileButton)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            importAudioButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            importAudioButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            importAudioButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: padding),
            
            importVideoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            importVideoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            importVideoButton.topAnchor.constraint(equalTo: importAudioButton.bottomAnchor, constant: 8),
            
            browseFilesButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            browseFilesButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            browseFilesButton.topAnchor.constraint(equalTo: importVideoButton.bottomAnchor, constant: 8),
            
            recentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            recentLabel.topAnchor.constraint(equalTo: browseFilesButton.bottomAnchor, constant: padding * 1.5),
            
            recentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            recentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            recentStackView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: padding),
            recentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
        ])
    }
    
    @objc private func importAudioTapped() {
        Logger.shared.info("Import audio tapped")
        presentDocumentPicker()
    }
    
    @objc private func importVideoTapped() {
        Logger.shared.info("Import video tapped")
        presentDocumentPicker()
    }
    
    @objc private func browseFilesTapped() {
        Logger.shared.info("Browse files tapped")
        presentDocumentPicker()
    }
    
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ImportSourceViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        Logger.shared.info("Document picked: \(url.lastPathComponent)")
        onAudioSelected?(url)
    }
}
