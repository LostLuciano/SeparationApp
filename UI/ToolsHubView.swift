import SwiftUI

struct ToolItem: Identifiable {
    let id = UUID()
    let title: String
    let caption: String
    let icon: String
    let isRed: Bool
}

struct ToolsHubView: View {
    var onNavigateToTool: (String) -> Void
    
    private let tools: [ToolItem] = [
        ToolItem(title: "Import Audio", caption: "WAV, MP3, M4A", icon: "square.and.arrow.down", isRed: true),
        ToolItem(title: "Stem Separation", caption: "Split vocal/drums", icon: "waveform.path.badge.plus", isRed: true),
        ToolItem(title: "Studio Mixer", caption: "Adjust level & pan", icon: "slider.horizontal.3", isRed: false),
        ToolItem(title: "AI Analyzer", caption: "Chords & tempo", icon: "waveform.path", isRed: false),
        ToolItem(title: "Lyrics Viewer", caption: "Timed karaoke lyrics", icon: "text.alignleft", isRed: false),
        ToolItem(title: "Recording", caption: "Capture direct mic", icon: "mic.fill", isRed: false),
        ToolItem(title: "Export Mix", caption: "Save separated stems", icon: "square.and.arrow.up", isRed: false),
        ToolItem(title: "Settings", caption: "Configure audio setup", icon: "gearshape.fill", isRed: false)
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UTILITIES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignSystem.AccentRed)
                        .tracking(2.0)
                    Text("Tools Studio")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Tools Hero Card (cohesive styling)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
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
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), DesignSystem.AccentRed.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Background waveform
                VStack {
                    Spacer()
                    GlassWaveform(sampleCount: 22, isAnimated: true, highlightColor: DesignSystem.AccentRed)
                        .opacity(0.2)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                }
                .frame(height: 100)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI ASSISTANT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(DesignSystem.AccentRed)
                            .tracking(1.5)
                        
                        Text("Smart Audio Tools")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Analyze chords, beat grids, and lyrics instantly.")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(DesignSystem.AccentRed.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "cpu")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))
                }
                .padding(16)
            }
            .frame(height: 100)
            .padding(.horizontal, 20)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tools) { tool in
                        Button(action: {
                            onNavigateToTool(tool.title)
                        }) {
                            VStack(alignment: .leading, spacing: 14) {
                                // Icon Header
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(tool.isRed ? DesignSystem.AccentRed.opacity(0.2) : Color.white.opacity(0.08))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: tool.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(tool.isRed ? DesignSystem.AccentRed : .white)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(DesignSystem.TextMuted)
                                }
                                
                                // Text Content
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tool.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(1)
                                    
                                    Text(tool.caption)
                                        .font(.system(size: 11))
                                        .foregroundColor(DesignSystem.TextSecondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
                            .background(DesignSystem.SurfaceGlass)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                    .stroke(tool.isRed ? DesignSystem.SoftRed.opacity(0.3) : DesignSystem.BorderGlass, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ToolsHubView(onNavigateToTool: { _ in })
    }
}
