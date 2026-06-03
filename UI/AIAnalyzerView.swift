import SwiftUI

struct AIAnalyzerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnalyzerTab: Int = 0 // 0 = Chords, 1 = Beat
    
    // Beat analysis specific state
    @State private var isMetronomeActive = false
    @State private var bpmCount = 120
    
    // Instantiate real MetronomeManager from Runner audio package
    private let metronome = MetronomeManager()
    
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
                        
                        Text("G Major")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Scale: Ionian (G, A, B, C, D, E, F#)")
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
                                .trim(from: 0.0, to: 0.98)
                                .stroke(DesignSystem.AccentRed, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(Angle(degrees: -90))
                            
                            Text("98%")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Confidence")
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
                
                LazyVGrid(columns: chordGridColumns, spacing: 12) {
                    let segments = PreviewData.projects[0].chordSegments
                    ForEach(0..<12, id: \.self) { index in
                        let chord = !segments.isEmpty ? segments[index % segments.count].name : "C:maj"
                        VStack(spacing: 8) {
                            Text("Bar \(index + 1)")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.TextMuted)
                            
                            Text(chord)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(index == 0 || index == 4 ? DesignSystem.SoftRed : .white)
                        }
                        .padding(.vertical, 14)
                        .background(DesignSystem.SurfaceGlass)
                        .background(index == 0 || index == 4 ? DesignSystem.AccentRed.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                .stroke(index == 0 || index == 4 ? DesignSystem.AccentRed.opacity(0.4) : DesignSystem.BorderGlass, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Detail Stats Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Detailed Metrics")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
                    VStack(spacing: 12) {
                        metricRow(title: "Total Chords", value: "42")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Unique Chords", value: "12")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Suggested Key signature", value: "G Major (1 Sharp)")
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
                            Text("\(bpmCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            Text("BPM")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DesignSystem.AccentRed)
                        }
                        
                        Text("Time Signature: 4/4")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("96% Confidence")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignSystem.SuccessGreen)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(DesignSystem.SuccessGreen.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text("Stable beatgrid")
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
                    .frame(maxWidth: .infinity, height: 48)
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
                    .frame(maxWidth: .infinity, height: 48)
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
                        // Simulated beat grid lines + Waveform
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
                        metricRow(title: "Time Signature", value: "4/4")
                        Divider().background(DesignSystem.BorderGlass)
                        metricRow(title: "Grid Subdivision", value: "1/16 Note")
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
}

#Preview {
    AIAnalyzerView()
}
