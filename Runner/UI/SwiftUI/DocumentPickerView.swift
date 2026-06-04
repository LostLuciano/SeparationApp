import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onError: (Error) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: AudioImportManager.allowedUTTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        Logger.shared.info("Opening Files picker with asCopy: true")
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

            do {
                let localURL = try AudioImportManager.shared.importFile(from: sourceURL)
                parent.onPick(localURL)
            } catch {
                parent.onError(error)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            Logger.shared.info("Files picker cancelled by user")
        }
    }
}
