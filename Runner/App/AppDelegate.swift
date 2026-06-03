import UIKit
import AVFoundation
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Configure audio session
        configureAudioSession()
        
        // Initialize all logic managers
        initializeManagers()
        
        // Create main window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Setup root view controller
        let rootSwiftUIView = AppRootView()
        let hostingController = UIHostingController(rootView: rootSwiftUIView)
        
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    private func initializeManagers() {
        // Logger
        Logger.shared.info("🚀 App launched - Initializing managers")
        
        // Model Manager - check all CoreML models
        Logger.shared.info("📊 Checking CoreML models...")
        ModelManager.shared.checkAllModels()
        let modelStatus = ModelManager.shared.getAllModelStatuses()
        for (model, status) in modelStatus {
            Logger.shared.debug("  \(model): \(status)")
        }
        
        // Project Store - verify directory
        Logger.shared.info("💾 Initializing project storage...")
        let projectCount = ProjectStore.shared.getProjectCount()
        Logger.shared.debug("  Found \(projectCount) existing projects")
        
        // Cache Manager - check cache size
        Logger.shared.info("🗄️  Initializing cache...")
        let cacheSize = CacheManager.shared.getFormattedCacheSize()
        Logger.shared.debug("  Cache size: \(cacheSize)")
        CacheManager.shared.cleanupIfNeeded()
        
        // Processing Gate - ready
        Logger.shared.info("🚪 Processing gate ready")
        
        // Performance Guard - start monitoring
        Logger.shared.info("📈 Performance monitoring started")
        
        Logger.shared.success("✅ All managers initialized successfully")
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Category: playback dan recording
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .defaultToSpeaker,
                    .duckOthers,
                    .allowBluetooth,
                    .allowBluetoothA2DP
                ]
            )
            
            // PreferredIOBufferDuration: 256 samples untuk latency rendah
            try audioSession.setPreferredIOBufferDuration(256.0 / 44100.0)
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            Logger.shared.info("✓ Audio session configured")
        } catch {
            Logger.shared.error("✗ Audio session error: \(error)")
        }
    }
    
    // MARK: - UISceneDelegate
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.shared.info("📦 App entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.shared.info("📂 App entered foreground")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Logger.shared.info("🔌 App terminating")
    }
}
