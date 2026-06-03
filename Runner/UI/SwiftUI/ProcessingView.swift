import SwiftUI

struct ProcessingStep: Identifiable {
    let id = UUID()
    let name: String
    var status: StepStatus
}

enum StepStatus {
    case completed
    case inProgress
    case pending
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .pending: return "circle"
        }
    }
    
    var color: Color {
        switch self {
        case .completed: return DesignSystem.SuccessGreen
        case .inProgress: return DesignSystem.AccentRed
        case .pending: return DesignSystem.TextMuted
        }
    }
    
    var text: String {
        switch self {
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        case .pending: return "Pending"
        }
    }
}

struct ProcessingView: View {
    var onComplete: () -> Void
    var onCancel: () -> Void
    
    @State private var progress: Double = 0.0
    @State private var elapsedSeconds: Int = 0
    @State private var steps: [ProcessingStep] = [
        ProcessingStep(name: "Decode Audio", status: .inProgress),
        ProcessingStep(name: "STFT Transform", status: .pending),
        ProcessingStep(name: "AI Inference", status: .pending),
        ProcessingStep(name: "Reconstruction", status: .pending),
        ProcessingStep(name: "Export Stems", status: .pending)
    ]
    
    // Timer to simulate progress
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var etaSeconds: Int {
        let totalTime = 12.0 // Total simulated time in seconds
        let remaining = totalTime - (progress * totalTime)
        return max(0, Int(remaining))
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
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Processing Stems")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                // Progress Circular Indicator
                GlassProgressRing(progress: progress, subtitle: "Separating Vocal & Instruments")
                    .padding(.top, 10)
                
                // Elapsed & ETA Information
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Elapsed")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.TextMuted)
                        Text(formatTime(elapsedSeconds))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("ETA")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.TextMuted)
                        Text(formatTime(etaSeconds))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DesignSystem.SoftRed)
                    }
                }
                .padding(.vertical, 8)
                
                // Pipeline Steps list
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Processing Steps")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        ForEach(steps) { step in
                            HStack {
                                Image(systemName: step.icon)
                                    .foregroundColor(step.status.color)
                                    .font(.system(size: 14))
                                    .rotationEffect(step.status == .inProgress ? Angle(degrees: progress * 360) : .zero)
                                
                                Text(step.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(step.status == .pending ? DesignSystem.TextMuted : .white)
                                
                                Spacer()
                                
                                Text(step.status.text)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(step.status.color)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Engine Setup Details
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Engine")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.TextMuted)
                            Text("Neural Engine Core v2")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Mode")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.TextMuted)
                            Text("High Quality (Hifi)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignSystem.SoftRed)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Cancel Button
                Button(action: onCancel) {
                    Text("Cancel Processing")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                .stroke(DesignSystem.BorderGlass, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
        .onReceive(timer) { _ in
            if progress < 1.0 {
                progress += 0.01
                
                // Simulate elapsed timer every 1.0 unit (approx 1 second)
                if Int(progress * 100) % 10 == 0 {
                    elapsedSeconds += 1
                }
                
                // Update step statuses based on progress milestones
                updateSteps()
            } else {
                // Completed!
                timer.upstream.connect().cancel()
                onComplete()
            }
        }
    }
    
    private func updateSteps() {
        // Simple milestones mapping progress to stages
        if progress >= 0.2 && steps[0].status == .inProgress {
            steps[0].status = .completed
            steps[1].status = .inProgress
        }
        if progress >= 0.45 && steps[1].status == .inProgress {
            steps[1].status = .completed
            steps[2].status = .inProgress
        }
        if progress >= 0.75 && steps[2].status == .inProgress {
            steps[2].status = .completed
            steps[3].status = .inProgress
        }
        if progress >= 0.9 && steps[3].status == .inProgress {
            steps[3].status = .completed
            steps[4].status = .inProgress
        }
        if progress >= 1.0 {
            steps[4].status = .completed
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    ProcessingView(onComplete: {}, onCancel: {})
}
