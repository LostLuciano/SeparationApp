import SwiftUI

struct LyricsViewerView: View {
    var project: StemProject?

    @Environment(\.dismiss) private var dismiss

    @State private var lyricsList: [LyricLine] = []
    @State private var highlightedIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var loadMessage: String?

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 18) {
                headerBar
                trackInfoHeader
                if lyricsList.isEmpty {
                    emptyLyricsState
                } else {
                    lyricsListView
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !lyricsList.isEmpty {
                playbackControls
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadProjectLyrics()
        }
        .onReceive(timer) { _ in
            guard isPlaying, !lyricsList.isEmpty else { return }
            highlightedIndex = highlightedIndex < lyricsList.count - 1 ? highlightedIndex + 1 : 0
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

            Text("AI Lyrics Sync")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()
            Color.clear.frame(width: 48, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var trackInfoHeader: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                .fill(DesignSystem.AccentRed)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(project?.name ?? "No Project Selected")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(loadMessage ?? "Lyrics are loaded from the selected project.")
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.TextMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var emptyLyricsState: some View {
        Spacer()
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(DesignSystem.TextMuted)

                    Text("No lyrics yet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(project == nil ? "Select a project first." : "This project does not have a real transcription file yet.")
                        .font(.system(size: 13))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
            )
    }

    private var lyricsListView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(lyricsList.indices, id: \.self) { index in
                        lyricRow(lyricsList[index], index: index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .padding(.bottom, 12)
                .onAppear {
                    proxy.scrollTo(highlightedIndex, anchor: .center)
                }
                .onChange(of: highlightedIndex) { _, newIndex in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private var playbackControls: some View {
        BottomActionBar {
            HStack {
                Button(action: {
                    if highlightedIndex > 0 {
                        highlightedIndex -= 1
                    }
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 48)

                Button(action: { isPlaying.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.AccentRed)
                            .frame(width: 48, height: 48)

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .shadow(color: DesignSystem.AccentRed.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    if highlightedIndex < lyricsList.count - 1 {
                        highlightedIndex += 1
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(.bottom, 8)
        .background(DesignSystem.BackgroundDeep.opacity(0.92))
    }

    private func lyricRow(_ item: LyricLine, index: Int) -> some View {
        let isHighlighted = index == highlightedIndex

        return HStack(alignment: .top, spacing: 14) {
            Text(formatTime(item.startTime))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isHighlighted ? .white : DesignSystem.TextMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isHighlighted ? DesignSystem.AccentRed : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(item.text)
                .font(.system(size: 15, weight: isHighlighted ? .bold : .medium))
                .foregroundColor(isHighlighted ? .white : DesignSystem.TextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isHighlighted
            ? LinearGradient(colors: [DesignSystem.AccentRed.opacity(0.35), DesignSystem.PrimaryRed.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [DesignSystem.SurfaceGlass, Color.clear], startPoint: .leading, endPoint: .trailing)
        )
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(isHighlighted ? DesignSystem.AccentRed.opacity(0.6) : DesignSystem.BorderGlass, lineWidth: 1)
        )
        .id(index)
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .shadow(color: isHighlighted ? DesignSystem.AccentRed.opacity(0.15) : Color.clear, radius: 8)
    }

    private func loadProjectLyrics() {
        guard let lyricsPath = project?.lyricsPath else {
            lyricsList = []
            loadMessage = "No transcription file in this project."
            return
        }

        do {
            let data = try Data(contentsOf: lyricsPath)
            if let decoded = try? JSONDecoder().decode([LyricLine].self, from: data) {
                lyricsList = decoded
            } else {
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let rawLines = object?["lyrics"] as? [[String: Any]] ?? []
                lyricsList = rawLines.compactMap { item in
                    guard let start = item["startTime"] as? Double,
                          let end = item["endTime"] as? Double,
                          let text = item["text"] as? String else { return nil }
                    return LyricLine(startTime: start, endTime: end, text: text)
                }
            }

            loadMessage = lyricsList.isEmpty ? "Lyrics file was empty." : "\(lyricsList.count) synced lines loaded."
        } catch {
            lyricsList = []
            loadMessage = error.localizedDescription
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    LyricsViewerView(project: nil)
}
