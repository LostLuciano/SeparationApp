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
    var onImportSelected: (URL, StemProcessingOptions) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var activeSource: ImportSourceOption?
    @State private var isDocumentPickerPresented = false
    @State private var importErrorMessage: String?
    @State private var selectedTemplate = StemProcessingOptions.allStems

    private let sources = [
        ImportSourceOption(
            title: "Import Audio",
            subtitle: "WAV, MP3, M4A, AAC, AIFF, CAF, FLAC",
            icon: "music.note",
            detail: "Choose an audio file from Files",
            allowedTypes: FileImportManager.shared.getSupportedAudioUTTypes()
        ),
        ImportSourceOption(
            title: "Import Video",
            subtitle: "Extract audio from MOV, MP4, M4V, MKV",
            icon: "video.fill",
            detail: "Choose video files to extract audio",
            allowedTypes: FileImportManager.shared.getSupportedVideoUTTypes()
        ),
        ImportSourceOption(
            title: "Browse Files",
            subtitle: "Choose from local files",
            icon: "folder.fill",
            detail: "Select audio or video from device storage",
            allowedTypes: FileImportManager.shared.getSupportedUTTypes()
        ),
        ImportSourceOption(
            title: "From iCloud Drive",
            subtitle: "Import from iCloud",
            icon: "icloud.fill",
            detail: "Browse shared files in iCloud folders",
            allowedTypes: FileImportManager.shared.getSupportedUTTypes()
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
                        stemTemplatePicker
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
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPickerView(
                onPick: { importedURL in
                    isDocumentPickerPresented = false
                    onImportSelected(importedURL, selectedTemplate)
                },
                onError: { error in
                    isDocumentPickerPresented = false
                    importErrorMessage = error.localizedDescription
                }
            )
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

    private var stemTemplatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Stem Template")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(selectedTemplate.displaySummary)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(StemProcessingOptions.templates, id: \.self) { template in
                    Button(action: { selectedTemplate = template }) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(template.templateName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(template.displaySummary)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DesignSystem.TextMuted)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                        .background(template == selectedTemplate ? DesignSystem.AccentRed.opacity(0.35) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(template == selectedTemplate ? DesignSystem.SoftRed.opacity(0.65) : DesignSystem.BorderGlass, lineWidth: 0.9)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .glassStyle(cornerRadius: DesignSystem.Radius.medium)
    }

    private var supportedFormatsCard: some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 14) {
            VStack(spacing: 6) {
                Text("Supported Formats")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Text("WAV, MP3, M4A, AAC, AIFF, CAF, FLAC, MOV, MP4, M4V, MKV")
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
            isDocumentPickerPresented = true
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

}

#Preview {
    ImportSourceView(onImportSelected: { _, _ in })
}
