import SwiftUI

struct ResultsView: View {
    var projectName: String
    var onOpenMixer: () -> Void
    var onOpenAnalyzer: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var playingStemId: UUID? = nil
    
    // Stems local data mapping
    @State private var stemsList: [Stem] = PreviewData.stems
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
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
                    
                    Text("Separation Results")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40) // Balance back button
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Success Badge Card
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
                            Text("6 Stems Generated")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Audio separation successfully completed.")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.TextSecondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                // Stems List title
                HStack {
                    Text("Isolated Stems")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Duration: 03:24")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.TextMuted)
                }
                .padding(.horizontal, 22)
                
                // Stem Rows Scroll List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(stemsList) { stem in
                            StemRow(
                                stem: stem,
                                isPlaying: playingStemId == stem.id,
                                onPlayToggle: {
                                    if playingStemId == stem.id {
                                        playingStemId = nil
                                    } else {
                                        playingStemId = stem.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons at the Bottom
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        GlassButton(title: "Open Mixer", icon: "slider.horizontal.3", isAccented: true, action: onOpenMixer)
                        GlassButton(title: "AI Analyzer", icon: "waveform.path", isAccented: false, action: onOpenAnalyzer)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { /* Mock export */ }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Stems")
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
                        
                        Button(action: { /* Mock save */ }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                Text("Save Project")
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ResultsView(projectName: "Ocean Waves", onOpenMixer: {}, onOpenAnalyzer: {})
}
