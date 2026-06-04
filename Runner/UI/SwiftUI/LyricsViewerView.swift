import SwiftUI

struct LyricsViewerView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Lyrics list from mock data
    @State private var lyricsList: [LyricLine] = PreviewData.lyricLines
    @State private var highlightedIndex: Int = 5 // Defaults to highlighting "somebody that I used to know"
    @State private var isPlaying: Bool = false
    
    // Timer to cycle highlighted lyric when playing
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
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
                    
                    Text("AI Lyrics Sync")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40) // Balance back button
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Track Info Header
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
                        Text("Ocean Waves (Lyrics Mode)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("AI Transcribed · Sync Lock Active")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.TextMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Lyrics Scroll List
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(0..<lyricsList.count, id: \.self) { index in
                                let item = lyricsList[index]
                                let isHighlighted = index == highlightedIndex
                                
                                HStack(spacing: 14) {
                                    // Timestamp
                                    Text(formatTime(item.startTime))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(isHighlighted ? .white : DesignSystem.TextMuted)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(isHighlighted ? DesignSystem.AccentRed : Color.white.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    
                                    // Lyrics sentence
                                    Text(item.text)
                                        .font(.system(size: 15, weight: isHighlighted ? .bold : .medium))
                                        .foregroundColor(isHighlighted ? .white : DesignSystem.TextSecondary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(isHighlighted ? 
                                            LinearGradient(colors: [DesignSystem.AccentRed.opacity(0.35), DesignSystem.PrimaryRed.opacity(0.1)], startPoint: .leading, endPoint: .trailing) : 
                                            LinearGradient(colors: [DesignSystem.SurfaceGlass, Color.clear], startPoint: .leading, endPoint: .trailing)
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .onAppear {
                            proxy.scrollTo(highlightedIndex, anchor: .center)
                            PermissionManager.shared.requestSpeechRecognitionPermission { granted in
                                if !granted {
                                    PermissionManager.shared.showPermissionDeniedAlert(for: .speechRecognition)
                                }
                            }
                        }
                        .onChange(of: highlightedIndex) { _, newIndex in
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Bottom Sync playback controls
                BottomActionBar {
                    HStack {
                        // Previous
                        Button(action: {
                            if highlightedIndex > 0 {
                                highlightedIndex -= 1
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Play/Pause
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
                        
                        // Next
                        Button(action: {
                            if highlightedIndex < lyricsList.count - 1 {
                                highlightedIndex += 1
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
        .onReceive(timer) { _ in
            if isPlaying {
                if highlightedIndex < lyricsList.count - 1 {
                    highlightedIndex += 1
                } else {
                    highlightedIndex = 0 // Loop back
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    LyricsViewerView()
}
