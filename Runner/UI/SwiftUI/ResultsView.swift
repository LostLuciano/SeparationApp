import SwiftUI
import AVFoundation

struct ResultsView: View {
    var project: StemProject
    var onOpenMixer: () -> Void
    var onOpenAnalyzer: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var playingStemId: UUID? = nil
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isExporting = false
    @State private var exportStatus: String?

    private var stemsList: [Stem] {
        project.displayStems
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 18) {
                headerBar
                successCard
                stemsHeader
                stemsListView
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            audioPlayer?.stop()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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

            Text("Separation Results")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer()
            Color.clear.frame(width: 48, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var successCard: some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.SuccessGreen.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(DesignSystem.SuccessGreen)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stemsList.count) Stems Generated")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(project.name)
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    private var stemsHeader: some View {
        HStack {
            Text("Isolated Stems")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text("Duration: \(project.displayDuration)")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.TextMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, 22)
    }

    private var stemsListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(stemsList) { stem in
                    StemRow(
                        stem: stem,
                        isPlaying: playingStemId == stem.id,
                        onPlayToggle: {
                            toggleStemPlayback(stem)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            if let exportStatus {
                Text(exportStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.TextMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                GlassButton(title: "Open Mixer", icon: "slider.horizontal.3", isAccented: true, action: onOpenMixer)
                GlassButton(title: "AI Analyzer", icon: "waveform.path", isAccented: false, action: onOpenAnalyzer)
            }

            HStack(spacing: 12) {
                secondaryAction(
                    title: isExporting ? "Exporting" : "Export Stems",
                    icon: isExporting ? "hourglass" : "square.and.arrow.up",
                    action: exportStems
                )
                secondaryAction(title: "Saved", icon: "checkmark.circle", action: {})
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(DesignSystem.BackgroundDeep.opacity(0.92))
    }

    private func secondaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(DesignSystem.BorderGlass, lineWidth: 1)
            )
        }
    }

    private func toggleStemPlayback(_ stem: Stem) {
        if playingStemId == stem.id {
            audioPlayer?.stop()
            audioPlayer = nil
            playingStemId = nil
            return
        }

        do {
            audioPlayer?.stop()
            let player = try AVAudioPlayer(contentsOf: stem.url)
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            playingStemId = stem.id
        } catch {
            print("ResultsView: Failed to play stem \(stem.name): \(error.localizedDescription)")
            playingStemId = nil
        }
    }

    private func exportStems() {
        guard !isExporting else { return }
        isExporting = true
        exportStatus = "Exporting stems..."

        ExportManager.shared.exportIndividualStems(
            from: project,
            format: .m4a,
            quality: .high,
            progress: { progress in
                exportStatus = "Exporting stems \(Int(progress * 100))%"
            },
            completion: { result in
                isExporting = false
                switch result {
                case .success(let urls):
                    exportStatus = "Exported \(urls.count) stems to app export cache."
                case .failure(let error):
                    exportStatus = error.localizedDescription
                }
            }
        )
    }
}

#Preview {
    ResultsView(
        project: StemProject(
            id: UUID(),
            name: "Preview",
            title: "Preview",
            createdAt: Date(),
            originalAudioURL: URL(fileURLWithPath: "/tmp/input.m4a"),
            importedFileName: "input.m4a",
            duration: 0,
            format: "M4A",
            sampleRate: 44100,
            bpm: nil,
            key: nil,
            status: .separated,
            stemPaths: [:],
            chordSegments: [],
            beatResult: nil,
            lyricsPath: nil,
            waveformCachePath: nil
        ),
        onOpenMixer: {},
        onOpenAnalyzer: {}
    )
}
