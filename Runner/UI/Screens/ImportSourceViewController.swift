import UIKit
import Photos
import MediaPlayer
import AVFoundation
import UniformTypeIdentifiers

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
        titleLabel.font = StudioTypography.headingLarge
        titleLabel.textColor = AppStudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Pilih Sumber"
        subtitleLabel.font = StudioTypography.bodyMedium
        subtitleLabel.textColor = AppStudioColors.textSecondary
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
        recentLabel.font = StudioTypography.headingMedium
        recentLabel.textColor = AppStudioColors.textPrimary
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
            fileButton.setTitleColor(AppStudioColors.purpleAccent, for: .normal)
            fileButton.titleLabel?.font = StudioTypography.labelMedium
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
        
        let alert = UIAlertController(title: "Impor Audio", message: "Pilih sumber audio Anda", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Files App", style: .default, handler: { [weak self] _ in
            self?.presentDocumentPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Music Library", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            PermissionManager.shared.requestMediaLibraryPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.presentMediaPicker()
                } else {
                    PermissionManager.shared.showPermissionDeniedAlert(for: .mediaLibrary, from: self)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = importAudioButton
            popover.sourceRect = importAudioButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func importVideoTapped() {
        Logger.shared.info("Import video tapped")
        
        PermissionManager.shared.requestPhotoLibraryPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.presentImagePicker(for: .photoLibrary)
            } else {
                PermissionManager.shared.showPermissionDeniedAlert(for: .photoLibrary, from: self)
            }
        }
    }
    
    @objc private func browseFilesTapped() {
        Logger.shared.info("Browse files tapped")
        presentDocumentPicker()
    }
    
    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: AudioImportManager.allowedUTTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = self
        picker.shouldShowFileExtensions = true
        Logger.shared.info("Opening Files picker with asCopy: true")
        present(picker, animated: true)
    }
    
    private func presentMediaPicker() {
        let mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
        mediaPicker.delegate = self
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.showsItemsWithProtectedAssets = false
        present(mediaPicker, animated: true)
    }
    
    private func presentImagePicker(for sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            Logger.shared.error("Source type not available: \(sourceType)")
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = ["public.movie"]
        present(imagePicker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ImportSourceViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let sourceURL = urls.first else { return }
        
        do {
            let localURL = try AudioImportManager.shared.importFile(from: sourceURL)
            
            let fileExtension = localURL.pathExtension.lowercased()
            let videoFormats = ["mov", "mp4", "m4v", "mkv"]
            if videoFormats.contains(fileExtension), let onVideoSelected = onVideoSelected {
                onVideoSelected(localURL)
            } else {
                onAudioSelected?(localURL)
            }
        } catch {
            Logger.shared.error("Import failed: \(error.localizedDescription)")
            
            let alert = UIAlertController(
                title: "Import Gagal",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - MPMediaPickerControllerDelegate
extension ImportSourceViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true) { [weak self] in
            guard let item = mediaItemCollection.items.first else { return }
            if let assetURL = item.assetURL {
                Logger.shared.info("Media picker picked audio: \(item.title ?? "Song")")
                self?.onAudioSelected?(assetURL)
            } else {
                Logger.shared.error("Selected media item has no asset URL")
            }
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ImportSourceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            if let mediaURL = info[.mediaURL] as? URL {
                Logger.shared.info("Video picked: \(mediaURL.lastPathComponent)")
                self?.onVideoSelected?(mediaURL)
            } else {
                Logger.shared.error("No video URL found in info dict")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
