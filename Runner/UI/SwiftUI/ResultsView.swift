import SwiftUI

struct ResultsView: View {
    var projectName: String
    var onOpenMixer: () -> Void
    var onOpenAnalyzer: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var playingStemId: UUID? = nil
    @State private var stemsList: [Stem] = PreviewData.stems

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 18) {
                headerBar
                successCard
                stemsHeader
                stemsListView
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
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

            Text("Separation Results")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer()
            Color.clear.frame(width: 48, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var successCard: some View {
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
                    Text("\(stemsList.count) Stems Generated")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(projectName)
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    private var stemsHeader: some View {
        HStack {
            Text("Isolated Stems")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text("Duration: 03:24")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.TextMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, 22)
    }

    private var stemsListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(stemsList) { stem in
                    StemRow(
                        stem: stem,
                        isPlaying: playingStemId == stem.id,
                        onPlayToggle: {
                            playingStemId = playingStemId == stem.id ? nil : stem.id
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                GlassButton(title: "Open Mixer", icon: "slider.horizontal.3", isAccented: true, action: onOpenMixer)
                GlassButton(title: "AI Analyzer", icon: "waveform.path", isAccented: false, action: onOpenAnalyzer)
            }

            HStack(spacing: 12) {
                secondaryAction(title: "Export Stems", icon: "square.and.arrow.up", action: {})
                secondaryAction(title: "Save Project", icon: "folder.badge.plus", action: {})
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(DesignSystem.BackgroundDeep.opacity(0.92))
    }

    private func secondaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
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

#Preview {
    ResultsView(projectName: "Ocean Waves", onOpenMixer: {}, onOpenAnalyzer: {})
}
