import SwiftUI

struct HomeView: View {
    var onNavigateToTool: (String) -> Void
    var onProjectSelected: (String) -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Top Custom Navigation Bar / Status Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Studio")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DesignSystem.AccentRed)
                            .tracking(1.5)
                        Text("AI Music Studio")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Profile Icon/Button
                    Button(action: { onNavigateToTool("Settings") }) {
                        ZStack {
                            Circle()
                                .fill(DesignSystem.SurfaceLightGlass)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "waveform")
                                .foregroundColor(DesignSystem.AccentRed)
                                .font(.system(size: 18))
                        }
                        .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))
                    }
                }
                .padding(.top, 16)
                
                // Hero Card - "Create. Enhance. Release."
                ZStack(alignment: .bottomLeading) {
                    // Background glass with glowing gradient
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.AccentRed.opacity(0.35),
                                    DesignSystem.PrimaryRed.opacity(0.15),
                                    Color.black.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                        .blur(radius: 0.5)
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
                    
                    // Waveform decoration in background
                    VStack {
                        Spacer()
                        GlassWaveform(sampleCount: 38, isAnimated: true, highlightColor: DesignSystem.AccentRed)
                            .opacity(0.25)
                            .padding(.bottom, 12)
                            .padding(.horizontal, 16)
                    }
                    .frame(height: 180)
                    
                    // Foreground content
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CREATE. ENHANCE. RELEASE.")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.AccentRed)
                            .tracking(2.0)
                        
                        Text("Next-Gen Audio Separation")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Isolate vocals, drums, bass, and keys instantly with high-fidelity Neural separating engine.")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.TextSecondary)
                            .lineLimit(2)
                            .padding(.trailing, 40)
                    }
                    .padding(20)
                }
                .frame(height: 180)
                .shadow(color: DesignSystem.AccentRed.opacity(0.2), radius: 15, x: 0, y: 8)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            quickActionCard(title: "New Project", icon: "plus.rectangle.on.folder", caption: "Split stems", isPrimary: true) {
                                onNavigateToTool("Import Source")
                            }
                            
                            quickActionCard(title: "Studio Mixer", icon: "slider.horizontal.3", caption: "Mix tracks", isPrimary: false) {
                                onNavigateToTool("Studio Mixer")
                            }
                            
                            quickActionCard(title: "AI Analyzer", icon: "waveform.path", caption: "Chords & BPM", isPrimary: false) {
                                onNavigateToTool("AI Analyzer")
                            }
                            
                            quickActionCard(title: "Record Audio", icon: "mic.fill", caption: "Capture sound", isPrimary: false) {
                                onNavigateToTool("Record")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Recent Projects
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Projects")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { /* Navigate to projects tab */ }) {
                            Text("See All")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DesignSystem.SoftRed)
                        }
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(PreviewData.projects.prefix(3)) { project in
                            GlassListRow(action: {
                                onProjectSelected(project.name)
                            }) {
                                HStack(spacing: 12) {
                                    // Thumbnail icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                            .fill(
                                                LinearGradient(
                                                    colors: [DesignSystem.AccentRed.opacity(0.4), DesignSystem.PrimaryRed.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: project.format == "WAV" ? "waveform" : "music.note")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                    }
                                    
                                    // Details
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("\(project.stemPaths.count) Stems · \(project.displayDuration) · \(formatDate(project.createdAt))")
                                            .font(.system(size: 12))
                                            .foregroundColor(DesignSystem.TextMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    // Arrow Icon
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(DesignSystem.TextMuted)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }
                }
                
                // Extra padding for floating tab bar safety
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Component for quick action cards
    private func quickActionCard(title: String, icon: String, caption: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack(alignment: .center) {
                    Circle()
                        .fill(isPrimary ? Color.white : DesignSystem.AccentRed.opacity(0.2))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: icon)
                        .foregroundColor(isPrimary ? DesignSystem.AccentRed : .white)
                        .font(.system(size: 16, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(caption)
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.TextSecondary)
                }
            }
            .padding(16)
            .frame(width: 135, height: 125, alignment: .leading)
            .background(isPrimary ? 
                        LinearGradient(colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [DesignSystem.SurfaceGlass, Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(isPrimary ? DesignSystem.SoftRed.opacity(0.4) : DesignSystem.BorderGlass, lineWidth: 1)
            )
            .shadow(color: isPrimary ? DesignSystem.AccentRed.opacity(0.2) : Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HomeView(onNavigateToTool: { _ in }, onProjectSelected: { _ in })
    }
}
