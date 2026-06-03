import SwiftUI

// MARK: - Glass Card Modifier & View
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.SurfaceGlass)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.2))
                    .blur(radius: 1)
            )
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.05),
                                DesignSystem.AccentRed.opacity(0.2),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.3), radius: shadowRadius, x: 0, y: 6)
    }
}

extension View {
    func glassStyle(cornerRadius: CGFloat = DesignSystem.Radius.medium, shadowRadius: CGFloat = 10) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = DesignSystem.Radius.medium
    var padding: CGFloat = 16
    let content: Content
    
    init(cornerRadius: CGFloat = DesignSystem.Radius.medium, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassStyle(cornerRadius: cornerRadius)
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    var title: String
    var icon: String? = nil
    var isAccented: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(isAccented ? 
                          LinearGradient(colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed], startPoint: .top, endPoint: .bottom) :
                          LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                         )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(isAccented ? DesignSystem.SoftRed.opacity(0.4) : Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: isAccented ? DesignSystem.AccentRed.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Glass Icon Button
struct GlassIconButton: View {
    var icon: String
    var size: CGFloat = 44
    var isRed: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isRed ? DesignSystem.AccentRed.opacity(0.8) : DesignSystem.SurfaceLightGlass)
                )
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(
                    Circle()
                        .stroke(isRed ? DesignSystem.SoftRed.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: isRed ? DesignSystem.AccentRed.opacity(0.4) : Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Glass Segmented Control
struct GlassSegmentedControl: View {
    @Binding var selectedIndex: Int
    var options: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedIndex = index
                    }
                }) {
                    Text(options[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedIndex == index ? .white : DesignSystem.TextSecondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                .fill(selectedIndex == index ? DesignSystem.AccentRed : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(DesignSystem.SurfaceGlass)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(DesignSystem.BorderGlass, lineWidth: 1)
        )
    }
}

// MARK: - Glass List Row
struct GlassListRow<Content: View>: View {
    var action: (() -> Void)? = nil
    var content: Content
    
    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    contentRow
                }
            } else {
                contentRow
            }
        }
    }
    
    private var contentRow: some View {
        HStack {
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.SurfaceGlass)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(DesignSystem.BorderGlass, lineWidth: 0.8)
        )
    }
}

// MARK: - Glass Search Bar
struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.TextMuted)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(DesignSystem.TextMuted))
                .font(.system(size: 15))
                .foregroundColor(.white)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.TextMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignSystem.SurfaceGlass)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                .stroke(DesignSystem.BorderGlass, lineWidth: 1)
        )
    }
}

// MARK: - Glass Progress Ring
struct GlassProgressRing: View {
    var progress: Double // Range: 0 to 1
    var subtitle: String = "Processing..."
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 14)
                    .frame(width: 160, height: 160)
                
                // Glowing background
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        DesignSystem.AccentRed.opacity(0.3),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .frame(width: 160, height: 160)
                    .blur(radius: 6)
                
                // Actual progress circle
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.AccentRed, DesignSystem.SoftRed, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .frame(width: 160, height: 160)
                
                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.TextSecondary)
                }
            }
            
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.TextSecondary)
        }
        .padding(24)
        .glassStyle(cornerRadius: DesignSystem.Radius.extraLarge)
    }
}

// MARK: - Glass Waveform
struct GlassWaveform: View {
    var sampleCount: Int = 30
    var isAnimated: Bool = false
    var highlightColor: Color = DesignSystem.AccentRed
    
    @State private var waveHeights: [CGFloat] = []
    
    init(sampleCount: Int = 30, isAnimated: Bool = false, highlightColor: Color = DesignSystem.AccentRed) {
        self.sampleCount = sampleCount
        self.isAnimated = isAnimated
        self.highlightColor = highlightColor
        
        var heights: [CGFloat] = []
        for _ in 0..<sampleCount {
            heights.append(CGFloat.random(in: 0.15...0.95))
        }
        _waveHeights = State(initialValue: heights)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<waveHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                highlightColor.opacity(0.8),
                                Color.white.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 50 * waveHeights[index])
                    .animation(
                        isAnimated ? 
                            Animation.easeInOut(duration: Double.random(in: 0.4...0.8))
                                .repeatForever(autoreverses: true) : 
                            .default,
                        value: waveHeights[index]
                    )
            }
        }
        .onAppear {
            if isAnimated {
                // Mutate the heights periodically to animate
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    for i in 0..<waveHeights.count {
                        withAnimation {
                            waveHeights[i] = CGFloat.random(in: 0.15...0.95)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stem Row
struct StemRow: View {
    var stem: Stem
    var isPlaying: Bool
    var onPlayToggle: () -> Void
    
    var body: some View {
        GlassListRow {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isPlaying ? DesignSystem.AccentRed.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: stem.icon)
                        .foregroundColor(isPlaying ? DesignSystem.AccentRed : .white)
                        .font(.system(size: 16))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(stem.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(stem.duration)
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.TextMuted)
                }
                
                Spacer()
                
                // Small simulator VU meter when playing
                if isPlaying {
                    HStack(spacing: 2) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(DesignSystem.AccentRed)
                                .frame(width: 2, height: CGFloat.random(in: 6...18))
                                .animation(Animation.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: isPlaying)
                        }
                    }
                    .padding(.trailing, 8)
                }
                
                // Play Button
                Button(action: onPlayToggle) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(isPlaying ? DesignSystem.AccentRed : Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Mixer Fader
struct MixerFader: View {
    var channel: MixerChannel
    @Binding var volume: Double
    @Binding var isMuted: Bool
    @Binding var isSoloed: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Level Meter & Volume Text
            Text("\(Int(volume * 100))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.TextSecondary)
            
            HStack(spacing: 6) {
                // Audio level indicator on the side of fader
                VStack(spacing: 2) {
                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                isMuted ? DesignSystem.TextMuted.opacity(0.3) :
                                (Double(10 - index) / 10.0 <= volume ? 
                                 (index < 2 ? DesignSystem.RecordRed : (index < 4 ? DesignSystem.WarningYellow : DesignSystem.SuccessGreen)) : 
                                 Color.white.opacity(0.1))
                            )
                            .frame(width: 4, height: 8)
                    }
                }
                
                // Slider vertical
                ZStack(alignment: .bottom) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 14, height: 180)
                    
                    // Value track fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isMuted ? [DesignSystem.TextMuted.opacity(0.5)] : [DesignSystem.AccentRed, DesignSystem.SoftRed],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: CGFloat(180 * volume))
                    
                    // Thumb slider handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 22, height: 10)
                        .offset(y: CGFloat(-180 * volume + 5))
                        .shadow(color: Color.black.opacity(0.5), radius: 3)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newVol = Double(1.0 - (value.location.y / 180.0))
                                    volume = max(0.0, min(1.0, newVol))
                                }
                        )
                }
                .frame(width: 22, height: 180)
            }
            
            // Channel Name
            Text(channel.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Buttons M & S
            HStack(spacing: 4) {
                // Mute
                Button(action: { isMuted.toggle() }) {
                    Text("M")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(isMuted ? DesignSystem.RecordRed : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                // Solo
                Button(action: { isSoloed.toggle() }) {
                    Text("S")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSoloed ? .black : .white)
                        .frame(width: 20, height: 20)
                        .background(isSoloed ? DesignSystem.WarningYellow : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(DesignSystem.SurfaceGlass)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(DesignSystem.BorderGlass, lineWidth: 0.8)
        )
    }
}

// MARK: - Mini Player Card
struct MiniPlayerCard: View {
    var projectName: String = "Ocean Waves"
    var duration: String = "03:24"
    @State private var isPlaying = false
    @State private var playProgress: Double = 0.35 // Simulation
    
    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                // Artwork Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "music.note")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                
                // Info & playback progress bar
                VStack(alignment: .leading, spacing: 4) {
                    Text(projectName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Simulated progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DesignSystem.AccentRed)
                                .frame(width: geo.size.width * playProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    HStack {
                        Text("01:12")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.TextMuted)
                        Spacer()
                        Text(duration)
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.TextMuted)
                    }
                }
                
                // Media Controls
                HStack(spacing: 12) {
                    Button(action: { playProgress = max(0, playProgress - 0.1) }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { isPlaying.toggle() }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(DesignSystem.AccentRed)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { playProgress = min(1, playProgress + 0.1) }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Audio Level Meter
struct AudioLevelMeter: View {
    @State private var level: Double = 0.5
    var isRecording: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                ForEach(0..<20) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            Double(index) / 20.0 <= level ? 
                            (index > 16 ? DesignSystem.RecordRed : (index > 12 ? DesignSystem.WarningYellow : DesignSystem.SuccessGreen)) : 
                            Color.white.opacity(0.08)
                        )
                        .frame(width: 6, height: 28)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DesignSystem.SurfaceGlass)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
        .onAppear {
            if isRecording {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        level = Double.random(in: 0.15...0.95)
                    }
                }
            }
        }
    }
}

// MARK: - Bottom Action Bar
struct BottomActionBar<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(12)
        .background(DesignSystem.SurfaceGlass)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .stroke(DesignSystem.BorderGlass, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}
