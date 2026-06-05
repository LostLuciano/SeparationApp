import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    var allowedTypes: [UTType] = AudioImportManager.allowedUTTypes
    var onPick: (URL) -> Void
    var onError: (Error) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let contentTypes = allowedTypes.isEmpty ? AudioImportManager.allowedUTTypes : allowedTypes
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: false)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        Logger.shared.info("Opening Files picker with \(contentTypes.count) allowed content types")
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let sourceURL = urls.first else {
                Logger.shared.error("Import failed: No URL returned from picker")
                parent.onError(NSError(domain: "DocumentPickerView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Tidak ada file yang dipilih."]))
                return
            }

            Task {
                do {
                    let localURL = try await AudioImportManager.shared.importPlayableAudio(from: sourceURL)
                    await MainActor.run {
                        parent.onPick(localURL)
                    }
                } catch {
                    await MainActor.run {
                        parent.onError(error)
                    }
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            Logger.shared.info("Files picker cancelled by user")
        }
    }
}
