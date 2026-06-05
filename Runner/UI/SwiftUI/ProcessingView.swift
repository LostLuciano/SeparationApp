import SwiftUI
import AVFoundation
import UIKit

struct ProcessingStep: Identifiable {
    let id = UUID()
    let name: String
    var status: StepStatus
}

enum StepStatus {
    case completed
    case inProgress
    case pending
    case failed

    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .pending: return "circle"
        case .failed: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .completed: return DesignSystem.SuccessGreen
        case .inProgress: return DesignSystem.AccentRed
        case .pending: return DesignSystem.TextMuted
        case .failed: return DesignSystem.RecordRed
        }
    }

    var text: String {
        switch self {
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        case .pending: return "Pending"
        case .failed: return "Failed"
        }
    }
}

struct ProcessingView: View {
    let audioURL: URL
    var options: StemProcessingOptions = .allStems
    var onComplete: (StemProject) -> Void
    var onCancel: () -> Void

    @State private var progress: Double = 0.0
    @State private var elapsedSeconds: Int = 0
    @State private var statusMessage: String = "Preparing audio..."
    @State private var errorMessage: String?
    @State private var hasStarted = false
    @State private var isFinished = false
    @State private var startedAt = Date()
    @State private var steps: [ProcessingStep] = [
        ProcessingStep(name: "Decode Audio", status: .inProgress),
        ProcessingStep(name: "Preview Cache", status: .pending),
        ProcessingStep(name: "AI Inference", status: .pending),
        ProcessingStep(name: "Open Player", status: .pending),
        ProcessingStep(name: "Full Render", status: .pending)
    ]

    private let previewDuration: TimeInterval = 12.0

    private let elapsedTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var etaSeconds: Int {
        guard progress > 0.02, !isFinished, errorMessage == nil else { return 0 }
        let elapsed = Date().timeIntervalSince(startedAt)
        let estimatedTotal = elapsed / min(progress, 0.99)
        return max(0, Int(estimatedTotal - elapsed))
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
        .onReceive(elapsedTimer) { _ in
            if hasStarted && !isFinished && errorMessage == nil {
                elapsedSeconds += 1
            }
        }
        .task {
            await startProcessingIfNeeded()
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
                statusText
                elapsedSummary
                processingStepsCard
                if let errorMessage {
                    errorCard(errorMessage)
                } else {
                    engineDetailsCard
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("Processing Stems")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text(audioURL.lastPathComponent)
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.TextMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 28)

            Text("\(options.templateName) - \(options.displaySummary)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignSystem.SoftRed)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .padding(.top, 16)
    }

    private var progressRing: some View {
        GlassProgressRing(progress: progress, subtitle: "Preparing playable stems")
            .padding(.top, 10)
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(errorMessage == nil ? DesignSystem.TextSecondary : DesignSystem.RecordRed)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)
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
                engineDetail(title: "Engine", value: "CoreML Dense U-Net", alignment: .leading, valueColor: .white)

                Spacer()

                engineDetail(title: "Source", value: "User Audio", alignment: .trailing, valueColor: DesignSystem.SoftRed)
            }
        }
        .padding(.horizontal, 20)
    }

    private func errorCard(_ message: String) -> some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.RecordRed)
                    Text("Processing failed")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.TextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text(errorMessage == nil ? "Cancel Processing" : "Back")
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

    private func startProcessingIfNeeded() async {
        let shouldStart = await MainActor.run { () -> Bool in
            if hasStarted { return false }
            hasStarted = true
            startedAt = Date()
            return true
        }

        guard shouldStart else { return }

        do {
            let sourceHash = try? AudioImportManager.shared.contentHash(for: audioURL)
            if let sourceHash,
               let cachedProject = ProjectStore.shared.findReusableProject(
                    sourceHash: sourceHash,
                    requiredStems: options.selectedStems
               ) {
                await MainActor.run {
                    progress = 1.0
                    statusMessage = "Cached project ready."
                    isFinished = true
                    steps = steps.map { ProcessingStep(name: $0.name, status: .completed) }
                    onComplete(cachedProject)
                }
                return
            }

            let generatedStems = try await CoreMLStemSeparatorWrapper.shared.separate(
                audioURL: audioURL,
                processingMode: "Performance",
                modelQuality: "Performance",
                selectedStems: options.selectedStems,
                previewDuration: previewDuration
            ) { message, value in
                Task { @MainActor in
                    updateProgress(value, message: "Preview: \(message)")
                }
            }

            await MainActor.run {
                updateProgress(0.94, message: "Saving quick playable project...")
            }

            let project = try await createProject(
                from: audioURL,
                generatedStems: generatedStems,
                sourceHash: sourceHash,
                status: .separating,
                runAnalysis: false
            )

            startFullSeparationInBackground(projectID: project.id)

            await MainActor.run {
                progress = 1.0
                statusMessage = "Preview ready. Full song keeps rendering in the background."
                isFinished = true
                steps = steps.enumerated().map { index, step in
                    ProcessingStep(name: step.name, status: index < 4 ? .completed : .inProgress)
                }
                onComplete(project)
            }
        } catch {
            await MainActor.run {
                failProcessing(error.localizedDescription)
            }
        }
    }

    @MainActor
    private func updateProgress(_ value: Double, message: String) {
        progress = min(max(value, progress), 0.99)
        statusMessage = message
        updateSteps()
    }

    @MainActor
    private func failProcessing(_ message: String) {
        errorMessage = message
        statusMessage = "Real processing could not finish."
        isFinished = true

        if let activeIndex = steps.firstIndex(where: { $0.status == .inProgress }) {
            steps[activeIndex].status = .failed
        }
    }

    private func createProject(
        from sourceURL: URL,
        generatedStems: [String: URL],
        sourceHash: String?,
        status: ProjectStatus,
        runAnalysis: Bool
    ) async throws -> StemProject {
        guard !generatedStems.isEmpty else {
            throw NSError(
                domain: "ProcessingView",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Separation finished without any stem files."]
            )
        }

        let metadata = await readAudioMetadata(from: sourceURL)
        var project = StemProject(
            id: UUID(),
            name: sourceURL.deletingPathExtension().lastPathComponent,
            title: sourceURL.deletingPathExtension().lastPathComponent,
            createdAt: Date(),
            originalAudioURL: sourceURL,
            importedFileName: sourceURL.lastPathComponent,
            duration: metadata.duration,
            format: sourceURL.pathExtension.uppercased(),
            sampleRate: metadata.sampleRate,
            bpm: nil,
            key: nil,
            status: status,
            sourceHash: sourceHash,
            renderProgress: status == .separating ? previewDuration / max(metadata.duration, previewDuration) : 1.0,
            stemPaths: [:],
            chordSegments: [],
            beatResult: nil,
            lyricsPath: nil,
            waveformCachePath: nil
        )

        try FileManager.default.createDirectory(at: project.stemDirectory, withIntermediateDirectories: true)

        for (stem, tempURL) in generatedStems {
            let fileExtension = tempURL.pathExtension.isEmpty ? "m4a" : tempURL.pathExtension
            let destination = project.stemDirectory.appendingPathComponent("\(stem).\(fileExtension)")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: tempURL, to: destination)
            project.setStemPath(stem, url: destination)
        }

        if runAnalysis {
            await Self.enrichProjectAnalysis(&project, sourceURL: sourceURL)
        }

        try ProjectStore.shared.save(project)
        return project
    }

    private func startFullSeparationInBackground(projectID: UUID) {
        let sourceURL = audioURL
        let selectedOptions = options

        Task.detached(priority: .utility) {
            let backgroundTaskID = await MainActor.run {
                UIApplication.shared.beginBackgroundTask(withName: "Full Stem Render") {
                    Logger.shared.warning("Background full separation time is about to expire")
                }
            }
            defer {
                if backgroundTaskID != .invalid {
                    DispatchQueue.main.async {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                }
            }

            var lastSavedProgress = 0.0
            do {
                Logger.shared.info("Background full separation started for project \(projectID.uuidString)")
                let fullStems = try await CoreMLStemSeparatorWrapper.shared.separate(
                    audioURL: sourceURL,
                    processingMode: "Performance",
                    modelQuality: "Performance",
                    selectedStems: selectedOptions.selectedStems,
                    previewDuration: nil
                ) { message, value in
                    Logger.shared.info("Background full separation \(Int(value * 100))%: \(message)")
                    if value - lastSavedProgress >= 0.08 || value >= 0.99 {
                        lastSavedProgress = value
                        do {
                            var project = try ProjectStore.shared.load(projectID)
                            project.status = .separating
                            project.renderProgress = min(max(value, project.renderProgress ?? 0), 0.99)
                            try ProjectStore.shared.save(project)
                        } catch {
                            Logger.shared.error("Could not update render progress: \(error.localizedDescription)")
                        }
                    }
                }

                var project = try ProjectStore.shared.load(projectID)
                try FileManager.default.createDirectory(at: project.stemDirectory, withIntermediateDirectories: true)

                for (stem, tempURL) in fullStems {
                    let fileExtension = tempURL.pathExtension.isEmpty ? "m4a" : tempURL.pathExtension
                    let destination = project.stemDirectory.appendingPathComponent("\(stem).\(fileExtension)")
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: destination)
                    project.setStemPath(stem, url: destination)
                }

                await ProcessingView.enrichProjectAnalysis(&project, sourceURL: sourceURL)
                project.status = .separated
                project.renderProgress = 1.0
                try ProjectStore.shared.save(project)
                Logger.shared.info("Background full separation finished for project \(projectID.uuidString)")
            } catch {
                Logger.shared.error("Background full separation failed: \(error.localizedDescription)")
                do {
                    var project = try ProjectStore.shared.load(projectID)
                    project.status = .failed
                    try ProjectStore.shared.save(project)
                } catch {
                    Logger.shared.error("Could not mark project failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private static func enrichProjectAnalysis(_ project: inout StemProject, sourceURL: URL) async {
        do {
            let beatResult = try await BeatDetectionManager().analyzeBeats(audioURL: sourceURL)
            project.beatResult = beatResult
            project.bpm = beatResult.tempo
        } catch {
            print("ProcessingView: Beat analysis skipped: \(error.localizedDescription)")
        }

        do {
            let chordSegments = try await ChordDetectionManager().analyzeChords(audioURL: sourceURL)
            project.chordSegments = chordSegments
            project.key = inferKey(from: chordSegments)
        } catch {
            print("ProcessingView: Chord analysis skipped: \(error.localizedDescription)")
        }
    }

    private func readAudioMetadata(from url: URL) async -> (duration: Double, sampleRate: Double) {
        let asset = AVURLAsset(url: url)
        let duration: Double
        if let loadedDuration = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(loadedDuration)
            duration = seconds.isFinite ? seconds : 0
        } else {
            duration = 0
        }

        let sampleRate = (try? AVAudioFile(forReading: url).fileFormat.sampleRate) ?? 44100.0
        return (duration, sampleRate)
    }

    private static func inferKey(from segments: [ChordSegment]) -> String? {
        guard let firstChord = segments.first?.name else { return nil }
        return firstChord.replacingOccurrences(of: ":", with: " ")
    }

    private func updateSteps() {
        let milestones: [Double] = [0.12, 0.28, 0.78, 0.92, 0.98]

        for index in steps.indices {
            if progress >= milestones[index] {
                steps[index].status = .completed
            } else if index == 0 || progress >= milestones[index - 1] {
                steps[index].status = .inProgress
            } else {
                steps[index].status = .pending
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    ProcessingView(
        audioURL: URL(fileURLWithPath: "/tmp/input.m4a"),
        options: .allStems,
        onComplete: { _ in },
        onCancel: {}
    )
}
