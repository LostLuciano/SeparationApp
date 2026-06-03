import UIKit

class MainTabBarController: UITabBarController {
    private let floatingTabBar = UIView()
    private let floatingFAB = FloatingActionButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupFloatingFAB()
    }
    
    private func setupTabBar() {
        // Create view controllers
        let homeVC = HomeViewController()
        let libraryVC = LibraryViewController()
        let analyzerVC = AnalyzerViewController()
        let profileVC = ProfileViewController()
        
        // Wrap in navigation controllers
        let homeNav = UINavigationController(rootViewController: homeVC)
        let libraryNav = UINavigationController(rootViewController: libraryVC)
        let analyzerNav = UINavigationController(rootViewController: analyzerVC)
        let profileNav = UINavigationController(rootViewController: profileVC)
        
        // Configure tab items
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        libraryNav.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "music.note.list"), selectedImage: UIImage(systemName: "music.note.list"))
        analyzerNav.tabBarItem = UITabBarItem(title: "Analyzer", image: UIImage(systemName: "waveform"), selectedImage: UIImage(systemName: "waveform.circle.fill"))
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        // Set view controllers
        viewControllers = [homeNav, libraryNav, analyzerNav, profileNav]
        
        // Customize tab bar appearance
        tabBar.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        tabBar.tintColor = StudioColors.purpleAccent
        tabBar.unselectedItemTintColor = StudioColors.textSecondary
        tabBar.isTranslucent = true
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .dark)
            appearance.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            
            appearance.stackedLayoutAppearance.normal.iconColor = StudioColors.textSecondary
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: StudioColors.textSecondary]
            
            appearance.stackedLayoutAppearance.selected.iconColor = StudioColors.purpleAccent
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: StudioColors.purpleAccent]
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupFloatingFAB() {
        floatingFAB.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        floatingFAB.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floatingFAB)
        
        let tabBarHeight = tabBar.bounds.height
        
        NSLayoutConstraint.activate([
            floatingFAB.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingFAB.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(tabBarHeight / 2 + 28))
        ])
    }
    
    @objc private func fabTapped() {
        Logger.shared.info("FAB tapped - New project")
        
        // Show new project options
        let alert = UIAlertController(title: "Buat Proyek Baru", message: "Pilih sumber audio", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Impor Audio", style: .default) { _ in
            let importVC = ImportSourceViewController()
            importVC.onAudioSelected = { url in
                self.startProcessing(with: url)
            }
            let nav = UINavigationController(rootViewController: importVC)
            self.present(nav, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Rekam Audio", style: .default) { _ in
            let recordVC = RecordingViewController()
            let nav = UINavigationController(rootViewController: recordVC)
            self.present(nav, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func startProcessing(with audioURL: URL) {
        // Create new project
        let fileName = audioURL.deletingPathExtension().lastPathComponent
        let project = StemProject(
            id: UUID(),
            name: fileName,
            title: fileName,
            createdAt: Date(),
            originalAudioURL: audioURL,
            importedFileName: audioURL.lastPathComponent,
            duration: 0,
            format: audioURL.pathExtension.uppercased(),
            sampleRate: 44100,
            bpm: nil,
            key: nil,
            status: .imported,
            stemPaths: [:],
            chordSegments: [],
            beatResult: nil,
            lyricsPath: nil,
            waveformCachePath: nil
        )
        
        // Show processing screen
        let processingVC = ProcessingViewController()
        processingVC.project = project
        processingVC.onComplete = { [weak self] in
            // Show result screen
            let resultVC = ResultViewController()
            resultVC.project = project
            resultVC.onOpenMixer = {
                let mixerVC = MixerViewController()
                mixerVC.project = project
                self?.present(mixerVC, animated: true)
            }
            resultVC.onOpenAnalyzer = {
                let analyzerVC = AnalyzerViewController()
                analyzerVC.project = project
                self?.present(analyzerVC, animated: true)
            }
            
            self?.present(resultVC, animated: true)
        }
        processingVC.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        let nav = UINavigationController(rootViewController: processingVC)
        present(nav, animated: true)
    }
}
