import Foundation
import AVFoundation
import Photos
import MediaPlayer
import Speech
import UIKit

public enum PermissionType {
    case microphone
    case camera
    case photoLibrary
    case mediaLibrary
    case speechRecognition
}

public enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

public class PermissionManager {
    
    public static let shared = PermissionManager()
    
    private init() {}
    
    /// Checks the current status of a specific permission type
    public func checkPermissionStatus(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .microphone:
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return .authorized
            case .denied:
                return .denied
            case .undetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
            
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                return .authorized
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            @unknown default:
                return .notDetermined
            }
            
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                return .authorized
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            @unknown default:
                return .notDetermined
            }
            
        case .mediaLibrary:
            switch MPMediaLibrary.authorizationStatus() {
            case .authorized:
                return .authorized
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            @unknown default:
                return .notDetermined
            }
            
        case .speechRecognition:
            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized:
                return .authorized
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            @unknown default:
                return .notDetermined
            }
        }
    }
    
    /// Requests microphone permission
    public func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = checkPermissionStatus(for: .microphone)
        if status == .authorized {
            Logger.shared.info("Microphone permission granted")
            completion(true)
            return
        } else if status == .denied || status == .restricted {
            Logger.shared.warning("Microphone permission denied")
            completion(false)
            return
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    Logger.shared.info("Microphone permission granted")
                } else {
                    Logger.shared.warning("Microphone permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// Requests camera permission
    public func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = checkPermissionStatus(for: .camera)
        if status == .authorized {
            Logger.shared.info("Camera permission granted")
            completion(true)
            return
        } else if status == .denied || status == .restricted {
            Logger.shared.warning("Camera permission denied")
            completion(false)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    Logger.shared.info("Camera permission granted")
                } else {
                    Logger.shared.warning("Camera permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// Requests photo library permission
    public func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = checkPermissionStatus(for: .photoLibrary)
        if status == .authorized {
            Logger.shared.info("Photo library permission granted")
            completion(true)
            return
        } else if status == .denied || status == .restricted {
            Logger.shared.warning("Photo library permission denied")
            completion(false)
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            DispatchQueue.main.async {
                let granted = (newStatus == .authorized || newStatus == .limited)
                if granted {
                    Logger.shared.info("Photo library permission granted")
                } else {
                    Logger.shared.warning("Photo library permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// Requests media library permission
    public func requestMediaLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = checkPermissionStatus(for: .mediaLibrary)
        if status == .authorized {
            Logger.shared.info("Media library permission granted")
            completion(true)
            return
        } else if status == .denied || status == .restricted {
            Logger.shared.warning("Media library permission denied")
            completion(false)
            return
        }
        
        MPMediaLibrary.requestAuthorization { newStatus in
            DispatchQueue.main.async {
                let granted = (newStatus == .authorized)
                if granted {
                    Logger.shared.info("Media library permission granted")
                } else {
                    Logger.shared.warning("Media library permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// Requests speech recognition permission
    public func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        let status = checkPermissionStatus(for: .speechRecognition)
        if status == .authorized {
            Logger.shared.info("Speech recognition permission granted")
            completion(true)
            return
        } else if status == .denied || status == .restricted {
            Logger.shared.warning("Speech recognition permission denied")
            completion(false)
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { newStatus in
            DispatchQueue.main.async {
                let granted = (newStatus == .authorized)
                if granted {
                    Logger.shared.info("Speech recognition permission granted")
                } else {
                    Logger.shared.warning("Speech recognition permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// Shows a fallback alert directing the user to iPhone Settings
    public func showPermissionDeniedAlert(for type: PermissionType, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Izin Diperlukan",
            message: "Fitur ini membutuhkan izin dari pengaturan iPhone. Silakan buka Settings untuk mengaktifkan izin.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Buka Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    /// Shows a fallback alert using the top-most view controller
    public func showPermissionDeniedAlert(for type: PermissionType) {
        guard let topVC = getTopViewController() else {
            Logger.shared.error("Could not find top view controller to present permission alert")
            return
        }
        showPermissionDeniedAlert(for: type, from: topVC)
    }
    
    /// Helper to find the top-most view controller in the app window
    public func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
}
