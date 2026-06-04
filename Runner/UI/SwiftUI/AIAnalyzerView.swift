import SwiftUI

struct AIAnalyzerView: View {
    var project: StemProject?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnalyzerTab: Int = 0 // 0 = Chords, 1 = Beat
    
    // Beat analysis specific state
    @State private var isMetronomeActive = false
    @State private var bpmCount = 120
    
    // Instantiate real MetronomeManager from Runner audio package
    private let metronome = MetronomeManager()

    private var chordSegments: [ChordSegment] {
        project?.chordSegments ?? []
    }

    private var beatResult: BeatTempoResult? {
        project?.beatResult
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header Bar
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
                    
                    Text("AI Audio Analyzer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40) // Balance back button
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Switcher: Chords vs Beat
                GlassSegmentedControl(selectedIndex: $selectedAnalyzerTab, options: ["Chords", "Beats & BPM"])
                    .padding(.horizontal, 20)
                
                ScrollView(showsIndicators: false) {
                    if selectedAnalyzerTab == 0 {
                        chordsContent
                    } else {
                        beatsContent
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onDisappear {
            metronome.stop()
        }
        .onAppear {
            if let bpm = project?.bpm {
                bpmCount = max(40, min(240, Int(bpm.rounded())))
            }
        }
        .onChange(of: isMetronomeActive) { _, active in
            if active {
                metronome.start(bpm: Double(bpmCount))
            } else {
                metronome.stop()
            }
        }
        .onChange(of: bpmCount) { _, newBPM in
            if isMetronomeActive {
                metronome.updateBPM(Double(newBPM))
            }
        }
    }
    
    // MARK: - Chords Analyzer View
    private var chordsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Main Key Info Hero Card
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.AccentRed.opacity(0.25),
                                DesignSystem.PrimaryRed.opacity(0.1),
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), DesignSystem.AccentRed.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DETECTED KEY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.SoftRed)
                            .tracking(1.5)
                        
                        Text(project?.key ?? "Not analyzed")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                        
                        Text(project == nil ? "Select a project to view analysis." : "Generated from this project's real audio analysis.")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                    
                    Spacer()
                    
                    // Confidence Ring UI
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0.0, to: min(Double(chordSegments.count) / 24.0, 1.0))
                                .stroke(DesignSystem.AccentRed, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(Angle(degrees: -90))
                            
                            Text("\(chordSegments.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Chords")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                }
                .padding(18)
            }
            .frame(height: 120)
            .padding(.horizontal, 20)
            .shadow(color: DesignSystem.AccentRed.opacity(0.2), radius: 12, x: 0, y: 5)
            
            // Chord Grid
            VStack(alignment: .leading, spacing: 12) {
                Text("Chord Progression Timeline")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                
                let chordGridColumns = [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]
                
                if chordSegments.isEmpty {
                    GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
                        Text("No chord timeline is available for this project yet.")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.TextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                } else {
                    LazyVGrid(columns: chordGridColumns, spacing: 12) {
                        ForEach(Array(chordSegments.prefix(16).enumerated()), id: \.offset) { index, segment in
                            VStack(spacing: 8) {
                                Text(formatTime(segment.startTime))
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.TextMuted)

                                Text(segment.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(index == 0 ? DesignSystem.SoftRed : .white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .padding(.vertical, 14)
                            .background(DesignSystem.SurfaceGlass)
                            .background(index == 0 ? DesignSystem.AccentRed.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                    .stroke(index == 0 ? DesignSystem.AccentRed.opacity(0.4) : DesignSystem.BorderGlass, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Detail Stats Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Detailed Metrics")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
                    VStack(spacing: 12) {
                        metricRow(title: "Total Chords", value: "\(chordSegments.count)")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Unique Chords", value: "\(Set(chordSegments.map(\.name)).count)")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Suggested Key", value: project?.key ?? "Not analyzed")
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer(minLength: 40)
        }
    }
    
    // MARK: - Beat Analyzer View
    private var beatsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Main BPM Hero Card
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.AccentRed.opacity(0.25),
                                DesignSystem.PrimaryRed.opacity(0.1),
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), DesignSystem.AccentRed.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DETECTED TEMPO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.SoftRed)
                            .tracking(1.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(project?.bpm == nil ? "--" : "\(Int((project?.bpm ?? 0).rounded()))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            Text("BPM")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DesignSystem.AccentRed)
                        }
                        
                        Text("Time Signature: \(beatResult?.timeSignature ?? "Not analyzed")")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(beatResult.map { "\(Int($0.confidence * 100))% Confidence" } ?? "No beat data")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(beatResult == nil ? DesignSystem.TextMuted : DesignSystem.SuccessGreen)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background((beatResult == nil ? DesignSystem.TextMuted : DesignSystem.SuccessGreen).opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text("\(beatResult?.beatTimings.count ?? 0) beat markers")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.TextMuted)
                    }
                }
                .padding(18)
            }
            .frame(height: 120)
            .padding(.horizontal, 20)
            .shadow(color: DesignSystem.AccentRed.opacity(0.2), radius: 12, x: 0, y: 5)
            
            // Metronome & Tap controls
            HStack(spacing: 12) {
                // Tap tempo button
                Button(action: { bpmCount += 1 }) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text("Tap Tempo")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(DesignSystem.BorderGlass, lineWidth: 1)
                    )
                }
                
                // Metronome toggle button
                Button(action: { isMetronomeActive.toggle() }) {
                    HStack {
                        Image(systemName: isMetronomeActive ? "metronome.fill" : "metronome")
                        Text("Metronome")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isMetronomeActive ? .black : .white)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(isMetronomeActive ? Color.white : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(isMetronomeActive ? Color.white : DesignSystem.BorderGlass, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Beat Visual Waveform Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Beatgrid Grid Waveform")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .center) {
                            // Vertical Beat Grid Indicators
                            HStack(spacing: 0) {
                                ForEach(0..<8) { index in
                                    Rectangle()
                                        .fill(index % 4 == 0 ? DesignSystem.AccentRed.opacity(0.5) : Color.white.opacity(0.1))
                                        .frame(width: 1.5)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            // Waveform
                            GlassWaveform(sampleCount: 26, isAnimated: isMetronomeActive, highlightColor: DesignSystem.AccentRed)
                                .opacity(0.8)
                        }
                        .frame(height: 70)
                        
                        HStack {
                            Text("00:00")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.TextMuted)
                            Spacer()
                            Text("4/4 Beat grid (16th subdivision)")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.TextSecondary)
                            Spacer()
                            Text("00:10")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.TextMuted)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Subdivision Details
            VStack(alignment: .leading, spacing: 10) {
                Text("Subdivision Details")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
                    VStack(spacing: 12) {
                        metricRow(title: "Time Signature", value: beatResult?.timeSignature ?? "Not analyzed")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Beat Markers", value: "\(beatResult?.beatTimings.count ?? 0)")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Metronome Sound", value: "Woodblock")
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer(minLength: 40)
        }
    }
    
    // Row Helper View
    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(DesignSystem.TextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    AIAnalyzerView(project: nil)
}
