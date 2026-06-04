import SwiftUI

struct StudioMixerView: View {
    var project: StemProject

    @Environment(\.dismiss) private var dismiss
    @State private var channels: [MixerChannel] = []
    @State private var audioEngine = AudioEngineManager()
    @State private var isPlaying = false
    @State private var loadError: String?
    @State private var exportMessage: String?
    @State private var isExporting = false

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 14) {
                headerBar
                realMiniPlayer
                    .padding(.horizontal, 20)
                mixerHeader
                mixerConsole
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadProjectAudio()
        }
        .onDisappear {
            audioEngine.stop()
        }
        .onChange(of: channels) { oldChannels, newChannels in
            applyMixerChanges(oldChannels: oldChannels, newChannels: newChannels)
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

            Text("Studio Mixer")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()
            Color.clear.frame(width: 48, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var realMiniPlayer: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: "music.note")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(loadError ?? exportMessage ?? "\(channels.count) stems loaded - \(project.displayDuration)")
                        .font(.system(size: 11))
                        .foregroundColor(loadError == nil ? DesignSystem.TextMuted : DesignSystem.RecordRed)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Spacer()

                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(DesignSystem.AccentRed)
                        .clipShape(Circle())
                }
                .disabled(channels.isEmpty || loadError != nil)
                .opacity(channels.isEmpty || loadError != nil ? 0.45 : 1.0)
            }
        }
    }

    private var mixerHeader: some View {
        HStack {
            Text("Mixer Console")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(DesignSystem.TextSecondary)
                .tracking(1.0)
            Spacer()
            Text("Stereo Output")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.TextMuted)
        }
        .padding(.horizontal, 22)
        .padding(.top, 2)
    }

    private var mixerConsole: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.AccentRed.opacity(0.05))
                    .frame(height: min(geometry.size.height, 300))
                    .blur(radius: 20)
                    .padding(.horizontal, 20)

                if channels.isEmpty {
                    emptyMixerState
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach($channels) { $channel in
                                MixerFader(
                                    channel: channel,
                                    volume: $channel.volume,
                                    isMuted: $channel.isMuted,
                                    isSoloed: $channel.isSoloed
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .frame(minHeight: min(geometry.size.height, 300))
                    }
                }
            }
        }
        .frame(minHeight: 260)
    }

    private var emptyMixerState: some View {
        VStack(spacing: 8) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(DesignSystem.TextMuted)

            Text("No stems available")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            Text("Finish separation first to load mixer channels.")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.TextMuted)
        }
        .padding(.horizontal, 24)
    }

    private var bottomControls: some View {
        HStack(spacing: 12) {
            Button(action: exportCurrentMix) {
                HStack(spacing: 6) {
                    Image(systemName: isExporting ? "hourglass" : "square.and.arrow.up.fill")
                    Text(isExporting ? "Exporting" : "Export Mix")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                        .stroke(DesignSystem.SoftRed.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: DesignSystem.AccentRed.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .disabled(channels.isEmpty || isExporting || loadError != nil)
            .opacity(channels.isEmpty || isExporting || loadError != nil ? 0.55 : 1.0)

            Button(action: loadProjectAudio) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(DesignSystem.BorderGlass, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(DesignSystem.BackgroundDeep.opacity(0.92))
    }

    private func loadProjectAudio() {
        loadError = nil
        exportMessage = nil
        channels = project.displayMixerChannels

        do {
            try audioEngine.loadStemFiles(project.stemPaths)
        } catch {
            loadError = error.localizedDescription
            channels = []
        }
    }

    private func togglePlayback() {
        if isPlaying {
            audioEngine.pause()
            isPlaying = false
        } else {
            do {
                try audioEngine.play()
                isPlaying = true
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    private func exportCurrentMix() {
        guard !channels.isEmpty else { return }
        isExporting = true
        exportMessage = nil

        let volumes = Dictionary(uniqueKeysWithValues: channels.map { channel in
            (channel.key, Float(channel.isMuted ? 0.0 : channel.volume))
        })

        Task {
            do {
                let exportDirectory = project.projectDirectory.appendingPathComponent("exports")
                try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
                let outputURL = exportDirectory.appendingPathComponent("mix-\(Int(Date().timeIntervalSince1970)).m4a")
                try await audioEngine.exportStemMix(volumes: volumes, outputURL: outputURL)

                await MainActor.run {
                    exportMessage = "Exported mix: \(outputURL.lastPathComponent)"
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }

    private func applyMixerChanges(oldChannels: [MixerChannel], newChannels: [MixerChannel]) {
        guard oldChannels.count == newChannels.count else { return }

        for i in 0..<newChannels.count {
            let old = oldChannels[i]
            let new = newChannels[i]
            let stemKey = new.key

            if old.volume != new.volume {
                audioEngine.setStemVolume(stem: stemKey, volume: Float(new.volume))
            }
            if old.isMuted != new.isMuted {
                audioEngine.muteStem(stemKey, muted: new.isMuted)
            }
            if old.isSoloed != new.isSoloed {
                if new.isSoloed {
                    audioEngine.soloStem(stemKey)
                } else {
                    audioEngine.muteStem(stemKey, muted: new.isMuted)
                    audioEngine.setStemVolume(stem: stemKey, volume: Float(new.volume))
                }
            }
        }
    }
}

#Preview {
    StudioMixerView(
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
        )
    )
}
