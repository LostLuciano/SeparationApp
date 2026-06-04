import SwiftUI
import UniformTypeIdentifiers

private struct ImportSourceOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let detail: String
    let allowedTypes: [UTType]
}

struct ImportSourceView: View {
    var onImportSelected: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var activeSource: ImportSourceOption?
    @State private var isFileImporterPresented = false
    @State private var importErrorMessage: String?

    private let sources = [
        ImportSourceOption(
            title: "Import Audio",
            subtitle: "WAV, MP3, M4A, AIFF, CAF",
            icon: "music.note",
            detail: "Choose an audio file from Files",
            allowedTypes: [.audio]
        ),
        ImportSourceOption(
            title: "Import Video",
            subtitle: "Extract audio from video",
            icon: "video.fill",
            detail: "Choose MOV, MP4, or other video files",
            allowedTypes: [.movie]
        ),
        ImportSourceOption(
            title: "Browse Files",
            subtitle: "Choose from local files",
            icon: "folder.fill",
            detail: "Select audio or video from device storage",
            allowedTypes: [.audio, .movie]
        ),
        ImportSourceOption(
            title: "From iCloud Drive",
            subtitle: "Import from iCloud",
            icon: "icloud.fill",
            detail: "Browse shared files in iCloud folders",
            allowedTypes: [.audio, .movie]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                headerBar
                descriptionBlock

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(sources) { source in
                            sourceRow(source)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                supportedFormatsCard
            }
        }
        .navigationBarBackButtonHidden()
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: activeSource?.allowedTypes ?? [.audio, .movie],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                importErrorMessage = nil
            }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Back")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
            }

            Spacer()

            Text("Import Source")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.trailing, 40)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHOOSE AUDIO SOURCE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.AccentRed)
                .tracking(1.5)

            Text("Select a file first. Processing starts only after a real audio or video file is imported.")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.TextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var supportedFormatsCard: some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 14) {
            VStack(spacing: 6) {
                Text("Supported Formats")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Text("WAV, MP3, M4A, AIFF, CAF, MOV, MP4")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.TextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func sourceRow(_ source: ImportSourceOption) -> some View {
        GlassListRow(action: {
            activeSource = source
            isFileImporterPresented = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.AccentRed.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: source.icon)
                        .foregroundColor(DesignSystem.SoftRed)
                        .font(.system(size: 18))
                }
                .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(source.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(source.detail)
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.TextMuted)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.TextMuted)
            }
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else { return }
            let didAccessSecurityScope = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if didAccessSecurityScope {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }

            guard FileImportManager.shared.isFormatSupported(selectedURL) else {
                importErrorMessage = "Format file belum didukung. Pakai WAV, MP3, M4A, AIFF, CAF, MOV, atau MP4."
                return
            }

            let importsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Imports", isDirectory: true)
            let importedURL = try FileImportManager.shared.importFile(selectedURL, to: importsDirectory)
            onImportSelected(importedURL)
        } catch let error as CocoaError where error.code == .userCancelled {
            return
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ImportSourceView(onImportSelected: { _ in })
}
