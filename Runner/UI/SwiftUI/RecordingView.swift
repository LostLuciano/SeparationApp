import SwiftUI

struct RecordingView: View {
    var onRecordFinished: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRecording: Bool = false
    @State private var secondsElapsed: Int = 0
    @State private var inputSource: String = "Internal Microphone"
    @State private var isMetronomeOn: Bool = false
    
    // Instantiate real RecordingManager
    private let recorder = RecordingManager()
    
    // Timer to update elapsed seconds and animate elements
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var timeString: String {
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        let hours = secondsElapsed / 3600
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
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
            
            VStack(spacing: 24) {
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
                    
                    Text("Audio Recorder")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40) // Balance back button
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Live Waveform Area (Simple static/animated wave)
                VStack(spacing: 8) {
                    Text(isRecording ? "RECORDING LIVE AUDIO" : "RECORDER READY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isRecording ? DesignSystem.RecordRed : DesignSystem.TextMuted)
                        .tracking(2.0)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isRecording ? DesignSystem.RecordRed.opacity(0.2) : Color.white.opacity(0.04),
                                        Color.black.opacity(0.3)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                                    .stroke(
                                        isRecording ? 
                                        LinearGradient(colors: [DesignSystem.RecordRed, DesignSystem.RecordRed.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
                            )
                        
                        VStack(spacing: 14) {
                            // Waveform component
                            GlassWaveform(sampleCount: 34, isAnimated: isRecording, highlightColor: DesignSystem.RecordRed)
                                .frame(height: 60)
                                .opacity(isRecording ? 1.0 : 0.4)
                            
                            // Realtime audio level meter
                            AudioLevelMeter(isRecording: isRecording)
                                .opacity(isRecording ? 1.0 : 0.3)
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 20)
                    .shadow(color: isRecording ? DesignSystem.RecordRed.opacity(0.15) : Color.clear, radius: 12, x: 0, y: 5)
                }
                
                // Timer Indicator
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: isRecording ? DesignSystem.RecordRed.opacity(0.3) : Color.clear, radius: 8)
                    
                    Text("HH:MM:SS")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.TextMuted)
                        .tracking(1.0)
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                // Record Controls
                VStack(spacing: 24) {
                    // Quick toggles: Input source, metronome, settings
                    HStack(spacing: 12) {
                        // Input Selector
                        Button(action: { /* Toggle microphone types */ }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 14))
                                Text(inputSource)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, height: 55)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                    .stroke(DesignSystem.BorderGlass, lineWidth: 1)
                            )
                        }
                        
                        // Metronome Switcher
                        Button(action: { isMetronomeOn.toggle() }) {
                            VStack(spacing: 4) {
                                Image(systemName: isMetronomeOn ? "metronome.fill" : "metronome")
                                    .font(.system(size: 14))
                                Text("Metronome")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(isMetronomeOn ? .black : .white)
                            .frame(maxWidth: .infinity, height: 55)
                            .background(isMetronomeOn ? Color.white : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                    .stroke(isMetronomeOn ? Color.white : DesignSystem.BorderGlass, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Recording Action Buttons
                    HStack(spacing: 30) {
                        // Reset button
                        Button(action: {
                            if isRecording {
                                recorder.stopRecording()
                                isRecording = false
                            }
                            secondsElapsed = 0
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))
                        }
                        
                        // Main Record Pulsating Button
                        Button(action: {
                            isRecording.toggle()
                            if isRecording {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_recording.wav")
                                try? recorder.startRecording(to: tempURL)
                            } else {
                                recorder.stopRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(DesignSystem.RecordRed.opacity(isRecording ? 0.3 : 0.1), lineWidth: 6)
                                    .frame(width: 86, height: 86)
                                    .scaleEffect(isRecording ? 1.15 : 1.0)
                                    .animation(isRecording ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isRecording)
                                
                                Circle()
                                    .fill(DesignSystem.RecordRed)
                                    .frame(width: 70, height: 70)
                                
                                // Inner square or circle
                                RoundedRectangle(cornerRadius: isRecording ? 6 : 15)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRecording)
                            }
                        }
                        
                        // Save / Submit button (Simulated split action)
                        Button(action: {
                            if isRecording {
                                recorder.stopRecording()
                                isRecording = false
                            }
                            onRecordFinished()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(DesignSystem.SuccessGreen.opacity(0.8))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(DesignSystem.BorderGlass.opacity(0.5), lineWidth: 1))
                                .shadow(color: DesignSystem.SuccessGreen.opacity(0.3), radius: 6)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onDisappear {
            if isRecording {
                recorder.stopRecording()
            }
        }
        .onReceive(timer) { _ in
            if isRecording {
                secondsElapsed += 1
            }
        }
    }
}

#Preview {
    RecordingView(onRecordFinished: {})
}
