import SwiftUI

struct StudioMixerView: View {
    var projectName: String

    @Environment(\.dismiss) private var dismiss
    @State private var channels: [MixerChannel] = PreviewData.mixerChannels

    private let audioEngine = AudioEngineManager()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 14) {
                headerBar
                MiniPlayerCard(projectName: projectName, duration: "03:24")
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
        .frame(minHeight: 260)
    }

    private var bottomControls: some View {
        HStack(spacing: 12) {
            Button(action: { }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up.fill")
                    Text("Export Mix")
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

            Button(action: { }) {
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
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(DesignSystem.BackgroundDeep.opacity(0.92))
    }

    private func applyMixerChanges(oldChannels: [MixerChannel], newChannels: [MixerChannel]) {
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
                    audioEngine.muteStem(stemKey, muted: new.isMuted)
                    audioEngine.setStemVolume(stem: stemKey, volume: Float(new.volume))
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
