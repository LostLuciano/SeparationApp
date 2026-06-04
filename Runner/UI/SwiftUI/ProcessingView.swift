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
            backgroundGradient
            contentView
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            cancelButton
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(timer) { _ in
            handleTimerTick()
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

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerView
                progressRing
                elapsedSummary
                processingStepsCard
                engineDetailsCard
            }
            .padding(.bottom, 16)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Processing Stems")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 16)
    }

    private var progressRing: some View {
        GlassProgressRing(progress: progress, subtitle: "Separating Vocal & Instruments")
            .padding(.top, 10)
    }

    private var elapsedSummary: some View {
        HStack(spacing: 40) {
            timeStat(title: "Elapsed", value: formatTime(elapsedSeconds), valueColor: .white)
            timeStat(title: "ETA", value: formatTime(etaSeconds), valueColor: DesignSystem.SoftRed)
        }
        .padding(.vertical, 8)
    }

    private var processingStepsCard: some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Processing Steps")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                ForEach(steps) { step in
                    processingStepRow(step)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var engineDetailsCard: some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 12) {
            HStack {
                engineDetail(title: "Engine", value: "Neural Engine Core v2", alignment: .leading, valueColor: .white)

                Spacer()

                engineDetail(title: "Mode", value: "High Quality (Hifi)", alignment: .trailing, valueColor: DesignSystem.SoftRed)
            }
        }
        .padding(.horizontal, 20)
    }

    private var cancelButton: some View {
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
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(DesignSystem.BackgroundDeep.opacity(0.92))
    }

    private func timeStat(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(DesignSystem.TextMuted)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(valueColor)
        }
    }

    private func processingStepRow(_ step: ProcessingStep) -> some View {
        HStack {
            Image(systemName: step.status.icon)
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

    private func engineDetail(
        title: String,
        value: String,
        alignment: HorizontalAlignment,
        valueColor: Color
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(DesignSystem.TextMuted)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(valueColor)
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

    private func handleTimerTick() {
        if progress < 1.0 {
            progress += 0.01

            if Int(progress * 100) % 10 == 0 {
                elapsedSeconds += 1
            }

            updateSteps()
        } else {
            timer.upstream.connect().cancel()
            onComplete()
        }
    }
}

#Preview {
    ProcessingView(onComplete: {}, onCancel: {})
}
