import SwiftUI

private struct StudioTrackContext {
    let hasProject: Bool
    let title: String
    let artist: String
    let duration: String
    let bpm: String
    let meter: String
    let key: String

    static func from(_ project: StemProject?) -> StudioTrackContext {
        StudioTrackContext(
            hasProject: project != nil,
            title: project?.name ?? "No project selected",
            artist: project?.importedFileName.components(separatedBy: ".").first ?? "Import audio to start",
            duration: project?.displayDuration ?? "--:--",
            bpm: project?.bpm.map { "\(Int($0)) BPM" } ?? project?.beatResult.map { "\(Int($0.tempo)) BPM" } ?? "-- BPM",
            meter: project?.beatResult?.timeSignature ?? "--",
            key: project?.key ?? "Analyze required"
        )
    }
}

private struct StudioEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(DesignSystem.TextMuted)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignSystem.TextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .studioGlass(cornerRadius: 20)
    }
}

private struct StudioScreen<Content: View>: View {
    let title: String
    let subtitle: String
    var showsBack: Bool = false
    var trailingIcon: String = "ellipsis"
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        subtitle: String,
        showsBack: Bool = false,
        trailingIcon: String = "ellipsis",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsBack = showsBack
        self.trailingIcon = trailingIcon
        self.content = content()
    }

    var body: some View {
        ZStack {
            StudioBackdrop()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    content
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 108)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if showsBack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.white)
                        .studioGlass(cornerRadius: 18)
                }
            }

            VStack(alignment: showsBack ? .leading : .center, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.TextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: showsBack ? .leading : .center)

            Button(action: {}) {
                Image(systemName: trailingIcon)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(.white)
                    .studioGlass(cornerRadius: 18)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}

private struct StudioBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "050913"),
                    Color(hex: "08111D"),
                    Color(hex: "0B101C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [DesignSystem.AccentRed.opacity(0.22), Color.clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func studioGlass(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.06),
                                DesignSystem.AccentRed.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct ArtworkTile: View {
    var size: CGFloat = 68
    var icon: String = "music.note"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.AccentRed,
                            Color(hex: "3B0D1D"),
                            Color(hex: "0B1020")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            GlassWaveform(sampleCount: 8, isAnimated: false, highlightColor: .white)
                .opacity(0.22)
                .padding(9)
            Image(systemName: icon)
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: size, height: size)
    }
}

private struct StudioPill: View {
    let title: String
    var selected: Bool = false
    var icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(selected ? .white : DesignSystem.TextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? DesignSystem.AccentRed.opacity(0.78) : Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? DesignSystem.SoftRed.opacity(0.45) : DesignSystem.BorderGlass.opacity(0.7), lineWidth: 0.8)
        )
    }
}

private struct StudioMiniPlayer: View {
    let context: StudioTrackContext

    var body: some View {
        HStack(spacing: 12) {
            ArtworkTile(size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(context.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(context.duration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.TextMuted)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(DesignSystem.AccentRed.opacity(0.55))
                    .clipShape(Circle())
            }
        }
        .padding(10)
        .studioGlass(cornerRadius: 18)
    }
}

private struct TimelineWaveform: View {
    var withLoop: Bool = true
    var duration: String = "--:--"

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                HStack(spacing: 2) {
                    ForEach(0..<80, id: \.self) { index in
                        Capsule()
                            .fill(DesignSystem.AccentRed.opacity(index % 7 == 0 ? 0.45 : 0.9))
                            .frame(width: 2.2, height: CGFloat([18, 34, 48, 26, 58, 42, 22, 38][index % 8]))
                    }
                }
                .frame(maxWidth: .infinity)

                if withLoop {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DesignSystem.AccentRed.opacity(0.25))
                        .frame(width: 98, height: 82)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                    Circle()
                        .fill(.white)
                        .frame(width: 7, height: 7)
                        .offset(y: -43)
                }
            }
            .frame(height: 92)

            HStack {
                Text("0:00")
                Spacer()
                Text(duration == "--:--" ? "--:--" : "50%")
                Spacer()
                Text(duration)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(DesignSystem.TextSecondary)
        }
    }
}

private struct LevelMeter: View {
    var title: String
    var stereo: Bool = false
    var isActive: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if stereo {
                    Text(isActive ? "0.0 dB" : "Idle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignSystem.TextSecondary)
                }
            }
            ForEach(0..<(stereo ? 2 : 1), id: \.self) { row in
                HStack(spacing: 2) {
                    Text(stereo ? (row == 0 ? "L" : "R") : "Guitar")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, alignment: .leading)
                    ForEach(0..<30, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(index < 22 ? DesignSystem.SuccessGreen : (index < 27 ? DesignSystem.WarningYellow : DesignSystem.RecordRed))
                            .opacity(isActive && index < (row == 0 ? 24 : 21) ? 1 : 0.12)
                            .frame(height: 5)
                    }
                }
            }
        }
    }
}

struct HomeDashboardView: View {
    var projects: [StemProject]
    var onNavigateToTool: (String) -> Void
    var onProjectSelected: (StemProject) -> Void

    private var context: StudioTrackContext {
        StudioTrackContext.from(projects.first)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            StudioScreen(title: "Studio Session", subtitle: "Good Afternoon", trailingIcon: "waveform") {
                VStack(alignment: .leading, spacing: 16) {
                    continueCard
                    quickActions
                    recentProjects
                    studioTools
                }
            }

            Button(action: { onNavigateToTool("Record Cover") }) {
                Image(systemName: "record.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(colors: [DesignSystem.SoftRed, DesignSystem.PrimaryRed], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(Circle())
                    .shadow(color: DesignSystem.AccentRed.opacity(0.45), radius: 16)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 96)
        }
    }

    private var continueCard: some View {
        HStack(spacing: 12) {
            ArtworkTile(size: 74)
            VStack(alignment: .leading, spacing: 5) {
                Text(context.hasProject ? context.title : "Import audio")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(context.hasProject ? context.artist : "Choose a song before processing")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.TextSecondary)
                Text(context.hasProject ? "\(projects.first?.stemPaths.count ?? 0) stems - \(context.duration)" : "No active session")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.TextMuted)
                ProgressView(value: context.hasProject ? 1.0 : 0.0)
                    .tint(DesignSystem.AccentRed)
                    .scaleEffect(y: 0.65)
            }
            Spacer()
            Button(action: { onNavigateToTool(context.hasProject ? "Studio Timeline" : "Import Source") }) {
                Image(systemName: context.hasProject ? "play.fill" : "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(DesignSystem.AccentRed.opacity(0.7))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .studioGlass(cornerRadius: 20)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionTile("Split Stems", "Separate vocals, drums", "camera.macro", true, "Import Source")
                actionTile("Record Cover", "Video + audio input", "video.fill", true, "Record Cover")
                actionTile("Practice Loop", "Loop and isolate", "repeat", false, "Loop Practice")
                actionTile("AI Analyzer", "Key, BPM, chords", "waveform.path.ecg", false, "AI Analyzer")
            }
        }
    }

    private func actionTile(_ title: String, _ caption: String, _ icon: String, _ hot: Bool, _ route: String) -> some View {
        Button(action: { onNavigateToTool(route) }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(hot ? DesignSystem.AccentRed.opacity(0.55) : Color.white.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(caption)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DesignSystem.TextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(minHeight: 62)
            .studioGlass(cornerRadius: 12)
        }
    }

    private var recentProjects: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Projects")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("See All")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DesignSystem.SoftRed)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if projects.isEmpty {
                        StudioEmptyState(
                            icon: "tray",
                            title: "No recent projects",
                            message: "Import audio or finish a recording to create a real project."
                        )
                        .frame(width: 260)
                    } else {
                        ForEach(projects.prefix(6)) { project in
                            Button(action: { onProjectSelected(project) }) {
                                recentCard(title: project.name, subtitle: "\(project.stemPaths.count) Stems - \(project.displayDuration)", icon: "waveform")
                            }
                        }
                    }
                }
            }
        }
    }

    private var studioTools: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Studio Tools")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                toolButton("Studio", "waveform", "Studio Timeline")
                toolButton("Mixer", "slider.horizontal.3", "Mixer")
                toolButton("Chords", "music.quarternote.3", "Chords View")
                toolButton("Devices", "cable.connector", "Audio Devices")
                toolButton("Equalizer", "waveform.path", "Equalizer")
                toolButton("Export", "square.and.arrow.up", "Export")
                toolButton("Lyrics", "text.quote", "Lyrics Sync")
                toolButton("Chord Lyrics", "text.badge.checkmark", "Chord + Lyrics")
                toolButton("AI Jam", "guitars", "AI Jam Session")
                toolButton("Dual Cam", "rectangle.inset.filled.and.person.filled", "Dual Camera Cover")
                toolButton("Performance", "rectangle.expand.vertical", "Performance Mode")
            }
        }
    }

    private func toolButton(_ title: String, _ icon: String, _ route: String) -> some View {
        Button(action: { onNavigateToTool(route) }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DesignSystem.SoftRed)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .studioGlass(cornerRadius: 12)
        }
    }

    private func recentCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkTile(size: 72, icon: icon)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(DesignSystem.TextMuted)
                .lineLimit(1)
        }
        .frame(width: 92, alignment: .leading)
    }
}

struct StudioTimelineView: View {
    var project: StemProject?
    var onNavigateToTool: (String) -> Void = { _ in }
    private var context: StudioTrackContext { StudioTrackContext.from(project) }
    private var chords: [ChordSegment] { project?.chordSegments ?? [] }
    private var beatMarkers: [BeatMarker] { project?.beatResult?.beatTimings ?? [] }

    var body: some View {
        StudioScreen(title: context.title, subtitle: "Waveform, Loop and Chords", trailingIcon: "square.and.arrow.up") {
            VStack(spacing: 14) {
                HStack {
                    StudioPill(title: "Mixer")
                    StudioPill(title: "Studio", selected: true)
                    StudioPill(title: "Record")
                }
                .studioGlass(cornerRadius: 15)

                TimelineWaveform(duration: context.duration)

                HStack(spacing: 10) {
                    infoPanel(title: "Loop Region", value: beatMarkers.count >= 2 ? "\(formatTime(beatMarkers[0].time)) - \(formatTime(beatMarkers[1].time))" : "Not set", accent: true)
                    infoPanel(title: "Loop", value: beatMarkers.isEmpty ? "Off" : "Ready")
                    infoPanel(title: "Count", value: "Set in Practice")
                    infoPanel(title: "Snap", value: project?.beatResult == nil ? "No beat grid" : "Beat")
                }

                chordTrack
                transport
                sections
                StudioMiniPlayer(context: context)
            }
        }
    }

    private func infoPanel(title: String, value: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(DesignSystem.TextSecondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((accent ? DesignSystem.AccentRed : Color.white).opacity(accent ? 0.22 : 0.055))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var chordTrack: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chords")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            if chords.isEmpty {
                StudioEmptyState(
                    icon: "music.note.list",
                    title: "No chord track yet",
                    message: "Run Analyze so the app can fill this track from detected chord segments."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(chords.prefix(12).enumerated()), id: \.offset) { index, segment in
                            VStack(spacing: 5) {
                                Text(ChordLibrary.displayName(for: segment.name))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(index == 0 ? DesignSystem.AccentRed.opacity(0.8) : Color.white.opacity(0.08))
                                    .frame(width: 48, height: 42)
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text(ChordLibrary.displayName(for: segment.name))
                                                .font(.system(size: 10, weight: .bold))
                                            Text(formatTime(segment.startTime))
                                                .font(.system(size: 8, weight: .medium))
                                        }
                                        .foregroundStyle(.white.opacity(0.8))
                                    )
                                Rectangle()
                                    .fill(DesignSystem.AccentRed)
                                    .frame(width: 30, height: 2)
                            }
                        }
                    }
                }
            }
            HStack {
                Text("Chord Track")
                Spacer()
                StudioPill(title: chords.isEmpty ? "Missing" : "Analyzed", selected: !chords.isEmpty)
                StudioPill(title: "Edit")
                StudioPill(title: "Simplify")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(DesignSystem.TextSecondary)
        }
        .padding(12)
        .studioGlass(cornerRadius: 18)
    }

    private var transport: some View {
        HStack(spacing: 18) {
            Image(systemName: "shuffle")
            Image(systemName: "backward.fill")
            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(DesignSystem.AccentRed)
                .clipShape(Circle())
            Image(systemName: "repeat")
            Spacer()
            metric(project?.bpm.map { "\(Int($0))" } ?? project?.beatResult.map { "\(Int($0.tempo))" } ?? "--", "BPM")
            metric(context.meter, "Meter")
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.white)
        .padding(12)
        .studioGlass(cornerRadius: 18)
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(DesignSystem.TextMuted)
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sections")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            if beatMarkers.isEmpty {
                StudioEmptyState(
                    icon: "waveform.path.ecg",
                    title: "No sections detected",
                    message: "Analyze the project first. Section labels will use the real beat and AI analysis data when available."
                )
            } else {
                HStack(spacing: 7) {
                    ForEach(Array(beatMarkers.prefix(6).enumerated()), id: \.offset) { index, marker in
                        let item = "Beat \(marker.index + 1)\n\(formatTime(marker.time))"
                        let selected = index == 0
                        Text(item)
                            .font(.system(size: 8, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(selected ? DesignSystem.AccentRed.opacity(0.75) : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(12)
        .studioGlass(cornerRadius: 18)
    }
}

struct MixerDesignView: View {
    var project: StemProject?
    var onNavigateToTool: (String) -> Void = { _ in }
    @State private var volumes: [String: Double] = [
        "Vocals": 0.80, "Drums": 0.65, "Bass": 0.75,
        "Guitar": 0.85, "Keys": 0.40, "Other": 0.30
    ]
    private var context: StudioTrackContext { StudioTrackContext.from(project) }
    private var stems: [String] {
        guard let project else { return [] }
        let labels: [String: String] = [
            "vocals": "Vocals",
            "drums": "Drums",
            "bass": "Bass",
            "guitar": "Guitar",
            "piano": "Keys",
            "keys": "Keys",
            "other": "Other",
            "others": "Other"
        ]
        return project.stemPaths.keys.sorted().compactMap { labels[$0] ?? $0.capitalized }
    }

    var body: some View {
        StudioScreen(title: "Mixer", subtitle: "Stem Mixer Horizontal", showsBack: true, trailingIcon: "gearshape") {
            VStack(spacing: 12) {
                if stems.isEmpty {
                    StudioEmptyState(
                        icon: "slider.horizontal.3",
                        title: "No stems loaded",
                        message: "Split or open a real project before using the mixer."
                    )
                } else {
                    ForEach(stems, id: \.self) { stem in
                        stemRow(stem)
                    }
                    masterOutput
                    StudioMiniPlayer(context: context)
                }
            }
        }
    }

    private func stemRow(_ stem: String) -> some View {
        let colors: [String: Color] = [
            "Vocals": .purple, "Drums": .blue, "Bass": .green,
            "Guitar": .orange, "Keys": .teal, "Other": .gray
        ]
        let icons: [String: String] = [
            "Vocals": "figure.stand", "Drums": "circle.grid.cross",
            "Bass": "guitars", "Guitar": "guitars.fill",
            "Keys": "pianokeys", "Other": "slider.horizontal.3"
        ]
        return HStack(spacing: 10) {
            Image(systemName: icons[stem] ?? "waveform")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background((colors[stem] ?? .gray).opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(stem)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, alignment: .leading)
            Slider(value: Binding(
                get: { volumes[stem] ?? 0.5 },
                set: { volumes[stem] = $0 }
            ))
            .tint(colors[stem] ?? DesignSystem.AccentRed)
            Text("\(Int((volumes[stem] ?? 0) * 100))%")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignSystem.TextSecondary)
                .frame(width: 36)
            StudioPill(title: "S")
            StudioPill(title: "M")
        }
        .padding(10)
        .studioGlass(cornerRadius: 16)
    }

    private var masterOutput: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Master Output")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                StudioPill(title: "0.0 dB")
                StudioPill(title: "", icon: "gearshape")
            }
            LevelMeter(title: "", stereo: true)
        }
        .padding(12)
        .studioGlass(cornerRadius: 18)
    }
}

struct RecordCoverDesignView: View {
    @State private var cameraPosition = "Back"
    @State private var audioSource = "Guitar Input"
    @State private var resolution = "1080p"
    @State private var frameRate = "30 fps"

    var body: some View {
        StudioScreen(title: "00:00:00", subtitle: "\(resolution) - \(frameRate)", showsBack: true, trailingIcon: "camera") {
            VStack(spacing: 12) {
                cameraPreview
                HStack(alignment: .top, spacing: 10) {
                    selectableOptionGroup("Camera", ["Front", "Back"], selection: $cameraPosition)
                    selectableOptionGroup("Audio Source", ["Guitar Input", "Mic", "Guitar + Mic"], selection: $audioSource)
                    selectableOptionGroup("Resolution", ["1080p", "4K"], selection: $resolution)
                }
                selectableOptionGroup("Frame Rate", ["30 fps", "60 fps"], selection: $frameRate)
                LevelMeter(title: "Input Level")
                recordControls
            }
        }
    }

    private var cameraPreview: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(hex: "332A25"), Color(hex: "080A12")], startPoint: .top, endPoint: .bottom)
                )
                .frame(height: 250)
            Image(systemName: "figure.guitar")
                .font(.system(size: 92, weight: .medium))
                .foregroundStyle(.white.opacity(0.24))
                .frame(maxWidth: .infinity)
            Text("Monitoring ON")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DesignSystem.SoftRed)
                .padding(14)
            Text(cameraPosition == "Back" ? "Back Camera" : "Front Camera")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private var recordControls: some View {
        HStack {
            GlassIconButton(icon: "headphones", size: 44)
            Spacer()
            Button(action: {}) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(DesignSystem.AccentRed)
                    .clipShape(Circle())
            }
            Spacer()
            GlassIconButton(icon: "waveform", size: 44)
        }
        .padding(.horizontal, 28)
    }

    private func selectableOptionGroup(_ title: String, _ options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            ForEach(options, id: \.self) { option in
                Button(action: { selection.wrappedValue = option }) {
                    StudioPill(title: option, selected: option == selection.wrappedValue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioGlass(cornerRadius: 16)
    }
}

struct LoopPracticeDesignView: View {
    var project: StemProject?
    private var context: StudioTrackContext { StudioTrackContext.from(project) }

    var body: some View {
        StudioScreen(title: "Loop & Practice", subtitle: context.title, showsBack: true, trailingIcon: "square.and.arrow.up") {
            VStack(spacing: 14) {
                TimelineWaveform()
                optionGrid(title: "Loop Settings", items: [("Loop", "On"), ("Count", "Infinite"), ("Fade In", "20 ms"), ("Fade Out", "20 ms")])
                pillSection("Loop Mode", ["Loop", "Loop x2", "Loop x4", "Loop Infinite"], selected: "Loop Infinite")
                pillSection("Stem Isolation", ["None", "Vocals", "Drums", "Bass", "Guitar"], selected: "Guitar")
                pillSection("Speed", ["-25%", "-10%", "100%", "+10%", "+25%"], selected: "100%")
                StudioMiniPlayer(context: context)
            }
        }
    }
}

struct ChordsDesignView: View {
    var project: StemProject?
    @State private var voicing = "Open"
    @State private var transpose: Int = 0
    @State private var capo: Int = 0
    @State private var isPlaying = false
    @State private var audioEngine = AudioEngineManager()
    @State private var playbackStatus = "Ready"
    @State private var selectedChordName: String?
    @State private var libraryRoot = "C"
    @State private var selectedQualitySymbol = ""

    private var context: StudioTrackContext { StudioTrackContext.from(project) }
    private var projectChords: [String] {
        let names = project?.chordSegments.map { ChordLibrary.displayName(for: $0.name) } ?? []
        return Array(NSOrderedSet(array: names)).compactMap { $0 as? String }
    }
    private var activeChordName: String {
        selectedChordName ?? projectChords.first ?? "\(libraryRoot)\(selectedQualitySymbol)"
    }
    private var activeDefinition: ChordDefinition? {
        ChordLibrary.definition(for: activeChordName)
    }
    private var activePattern: GuitarChordPattern? {
        ChordLibrary.pattern(named: voicing, for: transposedChord(activeChordName))
    }
    private var nextChordName: String {
        guard let current = selectedChordName ?? projectChords.first,
              let index = projectChords.firstIndex(of: current),
              index + 1 < projectChords.count else {
            return projectChords.dropFirst().first.map(transposedChord) ?? "No next chord"
        }
        return transposedChord(projectChords[index + 1])
    }

    var body: some View {
        StudioScreen(title: "Chords View", subtitle: "Chord progression and details", showsBack: true) {
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(transposedChord(activeChordName))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        chordDiagram(chord: transposedChord(activeChordName), pattern: activePattern)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        detail("Next Chord", nextChordName)
                        detail("Key", project?.key.map { transposedKey($0) } ?? "Analyze required")
                        detail("Capo", "\(capo)")
                        detail("Voicing", voicing)
                    }
                }
                .padding(14)
                .studioGlass(cornerRadius: 20)

                chordControls
                transportPitchControls
                chordProgressionSection
                chordCatalogSection
                chordLibrary
                StudioMiniPlayer(context: context)
            }
        }
        .onAppear {
            loadProjectAudioIfNeeded()
        }
        .onDisappear {
            audioEngine.stop()
        }
    }

    private var chordControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chord Settings")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            HStack {
                ForEach(ChordLibrary.patternNames, id: \.self) { item in
                    Button(action: { voicing = item }) {
                        StudioPill(title: item, selected: item == voicing)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                rangeStepper("Capo", value: Binding(
                    get: { Double(capo) },
                    set: { capo = Int($0) }
                ), range: 0...12)
                rangeStepper("Transpose", value: Binding(
                    get: { Double(transpose) },
                    set: {
                        transpose = Int($0)
                        audioEngine.setPitchShift(Float(transpose))
                    }
                ), range: -12...12)
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private var transportPitchControls: some View {
        HStack(spacing: 12) {
            Button(action: { shiftPitch(-1) }) {
                Label("Down", systemImage: "minus")
            }
            Button(action: toggleChordPlayback) {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            .tint(DesignSystem.AccentRed)
            Button(action: { shiftPitch(1) }) {
                Label("Up", systemImage: "plus")
            }
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white)
        .padding(12)
        .studioGlass(cornerRadius: 16)
        .overlay(alignment: .bottomLeading) {
            Text(playbackStatus)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.TextMuted)
                .padding(.leading, 14)
                .offset(y: 18)
        }
    }

    private var chordProgressionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chord Progression")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            if projectChords.isEmpty {
                StudioEmptyState(
                    icon: "music.note.list",
                    title: "No detected progression",
                    message: "Run Analyze on a real project to populate chord progression from audio."
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
                    ForEach(projectChords, id: \.self) { chord in
                        Button(action: { selectedChordName = chord }) {
                            StudioPill(title: transposedChord(chord), selected: chord == activeChordName)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("Pattern: \(activePattern?.summary ?? "No pattern available for this chord")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.TextMuted)
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private var chordCatalogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chord Catalog")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(ChordLibrary.allDefinitions.count) chords")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.TextMuted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChordLibrary.roots, id: \.self) { root in
                        Button(action: {
                            libraryRoot = root
                            selectedChordName = "\(root)\(selectedQualitySymbol)"
                        }) {
                            StudioPill(title: root, selected: root == libraryRoot)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                ForEach(ChordLibrary.qualities) { quality in
                    Button(action: {
                        selectedQualitySymbol = quality.symbol
                        selectedChordName = "\(libraryRoot)\(quality.symbol)"
                    }) {
                        StudioPill(
                            title: quality.symbol.isEmpty ? "Major" : quality.symbol,
                            selected: quality.symbol == selectedQualitySymbol
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            if let definition = activeDefinition {
                Text("Notes: \(definition.notes.joined(separator: " - "))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.TextMuted)
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private func chordDiagram(chord: String, pattern: GuitarChordPattern?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                .frame(width: 98, height: 118)
            VStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.12)).frame(width: 82, height: 1)
                }
            }
            HStack(spacing: 13) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 100)
                }
            }
            if let pattern {
                ForEach(pattern.positions, id: \.self) { position in
                    let point = pointForFret(position, baseFret: pattern.baseFret)
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(x: point.x, y: point.y)
                }
                if pattern.baseFret > 1 {
                    Text("fr \(pattern.baseFret)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(DesignSystem.TextMuted)
                        .offset(x: -36, y: -48)
                }
            }
            Text(chord)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(DesignSystem.SoftRed)
                .offset(y: 50)
        }
    }

    private var chordLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(projectChords.isEmpty ? "Available patterns" : "Chords in this song")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            let rows = projectChords.isEmpty ? [activeChordName] : projectChords
            ForEach(rows, id: \.self) { chord in
                HStack {
                    Text(transposedChord(chord)).font(.system(size: 13, weight: .bold))
                    Text(ChordLibrary.fullName(for: transposedChord(chord))).font(.system(size: 12))
                    Spacer()
                    Text("\(ChordLibrary.patterns(for: chord).count) patterns")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DesignSystem.TextMuted)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                Divider().background(Color.white.opacity(0.08))
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private func shiftPitch(_ semitoneDelta: Int) {
        transpose = max(-12, min(12, transpose + semitoneDelta))
        audioEngine.setPitchShift(Float(transpose))
        playbackStatus = "Pitch shifted \(transpose) semitones"
    }

    private func toggleChordPlayback() {
        if isPlaying {
            audioEngine.pause()
            isPlaying = false
            playbackStatus = "Paused"
        } else {
            do {
                if project != nil {
                    try audioEngine.play()
                    audioEngine.setPitchShift(Float(transpose))
                    isPlaying = true
                    playbackStatus = "Playing at \(transpose) semitones"
                } else {
                    playbackStatus = "Open a project to hear pitch shift"
                }
            } catch {
                playbackStatus = error.localizedDescription
            }
        }
    }

    private func loadProjectAudioIfNeeded() {
        guard let project else { return }
        do {
            try audioEngine.loadStemFiles(project.stemPaths)
            audioEngine.setPitchShift(Float(transpose))
            playbackStatus = "Loaded \(project.stemPaths.count) stems"
        } catch {
            playbackStatus = error.localizedDescription
        }
    }

    private func transposedChord(_ chord: String) -> String {
        ChordLibrary.transpose(chord, semitones: transpose)
    }

    private func transposedKey(_ key: String) -> String {
        ChordLibrary.fullName(for: ChordLibrary.transpose(key, semitones: transpose))
    }

    private func pointForFret(_ position: GuitarFretPosition, baseFret: Int) -> CGPoint {
        let stringIndex = 6 - position.string
        let fretOffset = max(0, min(4, position.fret - baseFret))
        return CGPoint(
            x: CGFloat(stringIndex - 2) * 16.5,
            y: CGFloat(fretOffset - 2) * 18.0
        )
    }
}

struct AnalyzeDesignView: View {
    var project: StemProject?
    var onNavigateToTool: (String) -> Void = { _ in }
    var showsBack: Bool = true
    private var context: StudioTrackContext { StudioTrackContext.from(project) }

    var body: some View {
        StudioScreen(title: "Analyze Result", subtitle: "AI Song Analysis", showsBack: showsBack) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ArtworkTile(size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.title).font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        Text(context.artist).font(.system(size: 11)).foregroundStyle(DesignSystem.TextSecondary)
                    }
                    Spacer()
                }
                .padding(12)
                .studioGlass(cornerRadius: 18)

                analysisRows
                detectedDataSection
                GlassButton(title: "View in Studio", icon: "waveform", isAccented: true) {
                    onNavigateToTool("Studio Timeline")
                }
            }
        }
    }

    private var analysisRows: some View {
        VStack(spacing: 0) {
            ForEach([
                ("Key", context.key),
                ("Tempo", context.bpm),
                ("Time Signature", context.meter),
                ("Detected Chords", "\(project?.chordSegments.count ?? 0)"),
                ("Beat Confidence", project?.beatResult.map { "\(Int($0.confidence * 100))%" } ?? "--"),
                ("Lyrics", project?.lyricsPath == nil ? "Not loaded" : "Loaded")
            ], id: \.0) { row in
                HStack {
                    Text(row.0)
                    Spacer()
                    Text(row.1)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(row.0 == "Key" ? .white : DesignSystem.TextSecondary)
                .padding(.vertical, 12)
                Divider().background(Color.white.opacity(0.08))
            }
        }
        .padding(.horizontal, 14)
        .studioGlass(cornerRadius: 18)
    }

    private var detectedDataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detected Chords")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            if let project, !project.chordSegments.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(Array(project.chordSegments.prefix(16).enumerated()), id: \.offset) { _, segment in
                        StudioPill(
                            title: "\(ChordLibrary.displayName(for: segment.name)) \(formatTime(segment.startTime))",
                            selected: false
                        )
                    }
                }
            } else {
                StudioEmptyState(
                    icon: "waveform.path.ecg",
                    title: "No AI analysis yet",
                    message: "Run chord and beat analysis on a real project to fill this screen."
                )
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }
}

struct AudioDevicesDesignView: View {
    @State private var selectedInput = "Default Input"
    @State private var selectedOutput = "Default Output"
    @State private var directMonitor = true

    var body: some View {
        StudioScreen(title: "Audio Devices", subtitle: "Input, Output and Interface", showsBack: true, trailingIcon: "arrow.clockwise") {
            VStack(alignment: .leading, spacing: 14) {
                selectableDeviceSection("Input", [("Default Input", "Current route", "cable.connector"), ("External Interface", "Available when connected", "music.mic")], selection: $selectedInput)
                selectableDeviceSection("Output", [("Default Output", "Current route", "speaker.wave.2"), ("Wired Headphones", "Available when connected", "headphones"), ("Bluetooth", "Available when paired", "dot.radiowaves.left.and.right")], selection: $selectedOutput)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Direct Monitor").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            Text("Hear your instrument without delay").font(.system(size: 10)).foregroundStyle(DesignSystem.TextMuted)
                        }
                        Spacer()
                        Toggle("", isOn: $directMonitor).labelsHidden().tint(DesignSystem.AccentRed)
                    }
                }
                .padding(14)
                .studioGlass(cornerRadius: 18)
                Text("Input: \(selectedInput) - Output: \(selectedOutput)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.TextSecondary)
                StudioMiniPlayer(context: .from(nil))
            }
        }
    }

    private func selectableDeviceSection(
        _ title: String,
        _ rows: [(String, String, String)],
        selection: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            ForEach(rows, id: \.0) { row in
                Button(action: { selection.wrappedValue = row.0 }) {
                    deviceRow(row, selected: selection.wrappedValue == row.0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private func deviceSection(_ title: String, _ rows: [(String, String, String)]) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
        ForEach(rows, id: \.0) { row in
            HStack(spacing: 12) {
                Image(systemName: row.2)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.0).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    Text(row.1).font(.system(size: 10)).foregroundStyle(row.1 == "Connected" ? DesignSystem.SuccessGreen : DesignSystem.TextMuted)
                    LevelMeter(title: "")
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(DesignSystem.TextMuted)
            }
            .padding(10)
            .studioGlass(cornerRadius: 14)
        }
    }
}

private func deviceRow(_ row: (String, String, String), selected: Bool) -> some View {
    HStack(spacing: 12) {
        Image(systemName: row.2)
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        VStack(alignment: .leading, spacing: 3) {
            Text(row.0).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            Text(row.1).font(.system(size: 10)).foregroundStyle(row.1 == "Connected" ? DesignSystem.SuccessGreen : DesignSystem.TextMuted)
            LevelMeter(title: "")
        }
        Spacer()
        Image(systemName: selected ? "checkmark.circle.fill" : "chevron.right")
            .foregroundStyle(selected ? DesignSystem.SoftRed : DesignSystem.TextMuted)
    }
    .padding(10)
    .studioGlass(cornerRadius: 14)
}

struct EqualizerDesignView: View {
    var project: StemProject?
    private var context: StudioTrackContext { StudioTrackContext.from(project) }

    var body: some View {
        StudioScreen(title: "Guitar", subtitle: "Stem Equalizer", showsBack: true) {
            VStack(spacing: 14) {
                eqCurve
                pillSection("Preset", ["Custom", "Acoustic", "Lead"], selected: "Custom")
                optionGrid(title: "Controls", items: [("High Pass", "80 Hz"), ("Low Pass", "16.0 kHz"), ("Gain", "0.0 dB"), ("Q", "1.2")])
                StudioMiniPlayer(context: context)
            }
        }
    }

    private var eqCurve: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.035))
                .frame(height: 240)
            VStack {
                HStack {
                    Text("+12dB")
                    Spacer()
                }
                Spacer()
                HStack {
                    Text("0dB")
                    Spacer()
                }
                Spacer()
                HStack {
                    Text("-12dB")
                    Spacer()
                }
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(DesignSystem.TextMuted)
            .padding(16)
            Path { path in
                path.move(to: CGPoint(x: 34, y: 150))
                path.addCurve(to: CGPoint(x: 120, y: 90), control1: CGPoint(x: 70, y: 132), control2: CGPoint(x: 78, y: 62))
                path.addCurve(to: CGPoint(x: 210, y: 82), control1: CGPoint(x: 148, y: 124), control2: CGPoint(x: 176, y: 42))
                path.addCurve(to: CGPoint(x: 320, y: 112), control1: CGPoint(x: 244, y: 112), control2: CGPoint(x: 286, y: 130))
            }
            .stroke(DesignSystem.SoftRed, lineWidth: 2)
        }
        .studioGlass(cornerRadius: 20)
    }
}

struct RecorderOnlyDesignView: View {
    var body: some View {
        StudioScreen(title: "Recorder", subtitle: "Audio Recording Only", showsBack: true) {
            VStack(spacing: 18) {
                TimelineWaveform(withLoop: false)
                    .padding(.vertical, 20)
                    .studioGlass(cornerRadius: 20)
                Text("Ready - 00:00")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DesignSystem.TextSecondary)
                HStack {
                    StudioPill(title: "Marker")
                    StudioPill(title: "Add Marker")
                    Spacer()
                }
                HStack {
                    GlassIconButton(icon: "metronome", size: 48)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(DesignSystem.AccentRed)
                            .clipShape(Circle())
                    }
                    Spacer()
                    GlassIconButton(icon: "pause.fill", size: 58)
                }
                LevelMeter(title: "Input Level")
                StudioMiniPlayer(context: .from(nil))
            }
        }
    }
}

struct ExportDesignView: View {
    var project: StemProject?

    @State private var audioMode = "Guitar + Backing"
    @State private var videoCamera = "Rear Camera"
    @State private var quality = AudioExportQuality.high
    @State private var frameRate = "60 fps"
    @State private var startMinute: Double = 0
    @State private var startSecond: Double = 0
    @State private var durationSeconds: Double = 30
    @State private var exportStatus = "Ready"
    @State private var isExporting = false
    @State private var audioEngine = AudioEngineManager()

    var body: some View {
        StudioScreen(title: "Export", subtitle: "Export Audio / Video", showsBack: true, trailingIcon: "square.and.arrow.up") {
            VStack(spacing: 14) {
                selectablePillSection("Audio", ["Guitar Only", "Guitar + Backing", "Full Mix"], selection: $audioMode)
                exportRangeCard
                qualityCard
                selectablePillSection("Video", ["Front Camera", "Rear Camera"], selection: $videoCamera)
                selectablePillSection("Frame Rate", ["30 fps", "60 fps"], selection: $frameRate)
                Text(exportStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.TextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                GlassButton(title: isExporting ? "Exporting..." : "Export Audio", icon: "waveform", isAccented: true) {
                    exportAudio()
                }
                .disabled(isExporting || project == nil)
                GlassButton(title: "Export Video", icon: "square.and.arrow.up", isAccented: false) {
                    exportStatus = "Video export settings saved. Camera render wiring comes next."
                }
            }
        }
    }

    private var exportRangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Range")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            HStack {
                rangeStepper("Min", value: $startMinute, range: 0...30)
                rangeStepper("Sec", value: $startSecond, range: 0...59)
                rangeStepper("Length", value: $durationSeconds, range: 5...600)
            }
            Text("Start \(Int(startMinute)):\(String(format: "%02d", Int(startSecond))) - \(Int(durationSeconds)) seconds")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignSystem.TextMuted)
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private var qualityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Audio Quality")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(AudioExportQuality.allCases, id: \.self) { item in
                    Button(action: { quality = item }) {
                        StudioPill(title: item.rawValue, selected: item == quality)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private func selectablePillSection(_ title: String, _ items: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button(action: { selection.wrappedValue = item }) {
                        StudioPill(title: item, selected: item == selection.wrappedValue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .studioGlass(cornerRadius: 18)
    }

    private func exportAudio() {
        guard let project else {
            exportStatus = "Open a project first."
            return
        }

        isExporting = true
        exportStatus = "Rendering \(quality.rawValue)..."

        Task {
            do {
                try audioEngine.loadStemFiles(project.stemPaths)
                let exportDirectory = project.projectDirectory.appendingPathComponent("exports")
                try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

                let outputURL = exportDirectory.appendingPathComponent(
                    "\(project.name)-\(audioMode.replacingOccurrences(of: " ", with: "-"))-\(Int(Date().timeIntervalSince1970)).\(quality.fileExtension)"
                )

                try await audioEngine.exportStemMix(
                    volumes: exportVolumes(for: project),
                    outputURL: outputURL,
                    startTime: startMinute * 60 + startSecond,
                    duration: durationSeconds,
                    quality: quality
                )

                await MainActor.run {
                    exportStatus = "Exported: \(outputURL.lastPathComponent)"
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportStatus = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }

    private func exportVolumes(for project: StemProject) -> [String: Float] {
        var volumes = Dictionary(uniqueKeysWithValues: project.stemPaths.keys.map { ($0, Float(0.85)) })

        switch audioMode {
        case "Guitar Only":
            volumes = volumes.mapValues { _ in 0.0 }
            volumes["guitar"] = 1.0
        case "Guitar + Backing":
            volumes["guitar"] = 1.0
            volumes["vocals"] = 0.0
        default:
            break
        }

        return AudioEngineManager.balancedGains(volumes: volumes)
    }
}

struct SettingsDesignView: View {
    var onNavigateToTool: (String) -> Void = { _ in }
    var showsBack: Bool = true
    @State private var selectedLanguage = "English"
    @State private var selectedTheme = "Dark"
    @State private var settingsStatus = "Tap a row to configure."

    var body: some View {
        StudioScreen(title: "Settings", subtitle: "App and Preferences", showsBack: showsBack) {
            VStack(spacing: 14) {
                ForEach(["General", "Audio", "Recording", "MIDI & Sync", "Advanced"], id: \.self) { row in
                    Button(action: { settingsStatus = "\(row) settings opened." }) {
                        settingRow(row)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: { selectedLanguage = selectedLanguage == "English" ? "Indonesia" : "English" }) {
                    settingRow("Language", value: selectedLanguage)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    HStack {
                        ForEach(["System", "Light", "Dark"], id: \.self) { theme in
                            Button(action: { selectedTheme = theme }) {
                                StudioPill(title: theme, selected: selectedTheme == theme)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .studioGlass(cornerRadius: 18)
                Text(settingsStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.TextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: { settingsStatus = "Studio version 1.0.0" }) {
                    settingRow("About Studio", value: "Version 1.0.0")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func settingRow(_ title: String, value: String? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.TextSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DesignSystem.TextMuted)
        }
        .padding(14)
        .studioGlass(cornerRadius: 16)
    }
}

struct LyricsSyncDesignView: View {
    var project: StemProject?
    @State private var lyrics: [LyricLine] = []

    var body: some View {
        StudioScreen(title: "Lyrics Sync", subtitle: "Apple Music style", showsBack: true) {
            if lyrics.isEmpty {
                StudioEmptyState(
                    icon: "text.quote",
                    title: "No synced lyrics",
                    message: "Attach or generate a lyrics file for this project to use realtime lyrics sync."
                )
            } else {
                VStack(spacing: 18) {
                    Text(project?.name ?? "Lyrics")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Array(lyrics.prefix(8).enumerated()), id: \.offset) { index, line in
                        Text(line.text)
                            .font(.system(size: index == 0 ? 24 : 18, weight: index == 0 ? .bold : .semibold))
                            .foregroundStyle(index == 0 ? .white : DesignSystem.TextMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                }
                .padding(18)
                .studioGlass(cornerRadius: 22)
            }
        }
        .onAppear(perform: loadLyrics)
    }

    private func loadLyrics() {
        guard let path = project?.lyricsPath,
              let data = try? Data(contentsOf: path) else {
            lyrics = []
            return
        }
        if let decoded = try? JSONDecoder().decode([LyricLine].self, from: data) {
            lyrics = decoded
        } else {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let rawLines = object?["lyrics"] as? [[String: Any]] ?? []
            lyrics = rawLines.compactMap { item in
                guard let start = item["startTime"] as? Double,
                      let end = item["endTime"] as? Double,
                      let text = item["text"] as? String else { return nil }
                return LyricLine(startTime: start, endTime: end, text: text)
            }
        }
    }
}

struct ChordLyricsDesignView: View {
    var project: StemProject?
    @State private var lyrics: [LyricLine] = []

    var body: some View {
        StudioScreen(title: "Chord + Lyrics", subtitle: "Synced learning view", showsBack: true) {
            if lyrics.isEmpty {
                StudioEmptyState(
                    icon: "text.badge.checkmark",
                    title: "No chord lyrics yet",
                    message: "This view needs real lyrics and analyzed chord segments from the selected project."
                )
            } else {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(lyrics.prefix(8).enumerated()), id: \.offset) { _, line in
                        chordLyric(chordForLyric(line), line.text)
                    }
                }
                .padding(18)
                .studioGlass(cornerRadius: 22)
            }
        }
        .onAppear(perform: loadLyrics)
    }

    private func chordLyric(_ chord: String, _ lyric: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chord)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DesignSystem.SoftRed)
            Text(lyric)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func chordForLyric(_ lyric: LyricLine) -> String {
        guard let segment = project?.chordSegments.first(where: {
            lyric.startTime >= $0.startTime && lyric.startTime < $0.endTime
        }) else {
            return "--"
        }
        return ChordLibrary.displayName(for: segment.name)
    }

    private func loadLyrics() {
        guard let path = project?.lyricsPath,
              let data = try? Data(contentsOf: path) else {
            lyrics = []
            return
        }
        if let decoded = try? JSONDecoder().decode([LyricLine].self, from: data) {
            lyrics = decoded
        } else {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let rawLines = object?["lyrics"] as? [[String: Any]] ?? []
            lyrics = rawLines.compactMap { item in
                guard let start = item["startTime"] as? Double,
                      let end = item["endTime"] as? Double,
                      let text = item["text"] as? String else { return nil }
                return LyricLine(startTime: start, endTime: end, text: text)
            }
        }
    }
}

struct AIJamSessionDesignView: View {
    var project: StemProject?

    var body: some View {
        StudioScreen(title: "AI Jam Session", subtitle: "Realtime chord detection", showsBack: true) {
            VStack(spacing: 18) {
                TimelineWaveform(withLoop: false, duration: project?.displayDuration ?? "--:--")
                VStack(spacing: 4) {
                    Text("Chord Detected")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignSystem.TextSecondary)
                    Text(project?.chordSegments.first.map { ChordLibrary.displayName(for: $0.name) } ?? "--")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(.white)
                    Text(project?.chordSegments.isEmpty == false ? "From latest project analysis" : "Connect guitar input to detect realtime chords")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(project?.chordSegments.isEmpty == false ? DesignSystem.SuccessGreen : DesignSystem.TextMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .studioGlass(cornerRadius: 24)
                LevelMeter(title: "Guitar Input")
            }
        }
    }
}

struct DualCameraCoverDesignView: View {
    var body: some View {
        StudioScreen(title: "Dual Camera Cover", subtitle: "Picture in Picture", showsBack: true, trailingIcon: "camera") {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [Color(hex: "2A241F"), Color(hex: "070A10")], startPoint: .top, endPoint: .bottom))
                    .frame(height: 420)
                    .overlay(Image(systemName: "figure.guitar").font(.system(size: 110)).foregroundStyle(.white.opacity(0.18)))
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.65))
                    .frame(width: 118, height: 158)
                    .overlay(Image(systemName: "person.crop.rectangle").font(.system(size: 38)).foregroundStyle(.white.opacity(0.75)))
                    .padding(18)
            }
            .studioGlass(cornerRadius: 26)
        }
    }
}

struct PerformanceModeDesignView: View {
    var project: StemProject?
    private var context: StudioTrackContext { StudioTrackContext.from(project) }
    private var currentChord: String {
        project?.chordSegments.first.map { ChordLibrary.displayName(for: $0.name) } ?? "--"
    }

    var body: some View {
        ZStack {
            StudioBackdrop()
            VStack(spacing: 24) {
                TimelineWaveform(duration: context.duration)
                Text(currentChord)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 10) {
                    StudioPill(title: project?.beatResult == nil ? "Loop not set" : "Beat grid ready", selected: project?.beatResult != nil)
                    StudioPill(title: context.bpm)
                    StudioPill(title: context.meter)
                }
            }
            .padding(18)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private func detail(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(DesignSystem.TextMuted)
        Text(value)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
    }
}

private func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "--:--" }
    let totalSeconds = Int(seconds.rounded(.down))
    return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
}

private func optionGrid(title: String, items: [(String, String)]) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.0)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignSystem.TextSecondary)
                    Text(item.1)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.055))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    .padding(14)
    .studioGlass(cornerRadius: 18)
}

private func rangeStepper(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
    VStack(spacing: 8) {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(DesignSystem.TextMuted)
        HStack(spacing: 8) {
            Button(action: { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) }) {
                Image(systemName: "minus")
            }
            Text("\(Int(value.wrappedValue))")
                .font(.system(size: 13, weight: .bold))
                .frame(width: 38)
            Button(action: { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) }) {
                Image(systemName: "plus")
            }
        }
        .foregroundStyle(.white)
    }
    .padding(10)
    .frame(maxWidth: .infinity)
    .background(Color.white.opacity(0.055))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

private func pillSection(_ title: String, _ items: [String], selected: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                StudioPill(title: item, selected: item == selected)
            }
        }
    }
    .padding(14)
    .studioGlass(cornerRadius: 18)
}
