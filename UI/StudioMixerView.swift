import SwiftUI

struct StudioMixerView: View {
    var projectName: String
    @Environment(\.dismiss) private var dismiss
    
    // Store mixer channel states
    @State private var channels: [MixerChannel] = PreviewData.mixerChannels
    
    // Instantiate real AudioEngineManager
    private let audioEngine = AudioEngineManager()
    
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
                    
                    Text("Studio Mixer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40) // Balance back button
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Mini Player Card Component
                MiniPlayerCard(projectName: projectName, duration: "03:24")
                    .padding(.horizontal, 20)
                
                // Mixer Console Section Title
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
                .padding(.top, 4)
                
                // Horizontal scroll list of Mixer Channels
                ZStack {
                    // Ambient red glow behind mixer faders
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                        .fill(DesignSystem.AccentRed.opacity(0.05))
                        .frame(height: 300)
                        .blur(radius: 20)
                        .padding(.horizontal, 20)
                    
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
                    }
                }
                
                Spacer()
                
                // Bottom Console Controls
                HStack(spacing: 12) {
                    Button(action: { /* Mock export */ }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Export Mix")
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
                    
                    Button(action: { /* Settings */ }) {
                        Image(systemName: "slider.horizontal.2.square")
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
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
        .onChange(of: channels) { oldChannels, newChannels in
            guard oldChannels.count == newChannels.count else { return }
            for i in 0..<newChannels.count {
                let old = oldChannels[i]
                let new = newChannels[i]
                let stemKey = mapStemName(new.name)
                
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
                        // Restore previous mute/volume state
                        audioEngine.muteStem(stemKey, muted: new.isMuted)
                        audioEngine.setStemVolume(stem: stemKey, volume: Float(new.volume))
                    }
                }
            }
        }
    }
    
    private func mapStemName(_ name: String) -> String {
        switch name {
        case "Vocals": return "vocals"
        case "Drums": return "drums"
        case "Bass": return "bass"
        case "Guitar": return "guitar"
        case "Keys": return "piano"
        case "Others": return "other"
        default: return name.lowercased()
        }
    }
}

#Preview {
    StudioMixerView(projectName: "Ocean Waves")
}
