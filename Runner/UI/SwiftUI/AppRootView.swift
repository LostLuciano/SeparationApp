import SwiftUI
import Combine

private enum AppRuntimeState {
    static var selectedTab = 0
    static var activePath = NavigationPath()
    static var selectedProjectID: UUID?
    static var pendingInputURL: URL?
    static var pendingProcessingOptions = StemProcessingOptions.allStems
}

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = AppRuntimeState.selectedTab
    @State private var activePath = AppRuntimeState.activePath

    @State private var projects: [StemProject] = []
    @State private var selectedProject: StemProject?
    @State private var pendingInputURL: URL? = AppRuntimeState.pendingInputURL
    @State private var pendingProcessingOptions: StemProcessingOptions = AppRuntimeState.pendingProcessingOptions

    var body: some View {
        NavigationStack(path: $activePath) {
            ZStack {
                LinearGradient(
                    colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                currentTabView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                customTabBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                reloadProjects(selecting: AppRuntimeState.selectedProjectID)
            }
            .onChange(of: scenePhase) { _, _ in
                persistRuntimeState()
            }
            .onReceive(NotificationCenter.default.publisher(for: .projectStoreDidUpdate).receive(on: RunLoop.main)) { notification in
                let updatedID = notification.userInfo?["projectID"] as? UUID
                reloadProjects(selecting: updatedID ?? selectedProject?.id)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .actionsSplit:
                    ActionsSplitView(
                        latestProject: selectedProject ?? projects.first,
                        onPresetSelected: { options in
                            pendingProcessingOptions = options
                            activePath.append(NavigationDestination.importSources)
                        },
                        onProjectSelected: { project in
                            selectedProject = project
                            activePath.append(NavigationDestination.results)
                        },
                        onNavigateToTool: navigateToTool
                    )
                case .studioTimeline:
                    StudioTimelineView(project: selectedProject, onNavigateToTool: navigateToTool)
                case .importSources:
                    ImportSourceView(
                        initialTemplate: pendingProcessingOptions,
                        onImportSelected: { importedURL, options in
                            pendingInputURL = importedURL
                            pendingProcessingOptions = options
                            activePath.append(NavigationDestination.processing)
                        }
                    )
                case .processing:
                    if let inputURL = pendingInputURL {
                        ProcessingView(
                            audioURL: inputURL,
                            options: pendingProcessingOptions,
                            onComplete: { project in
                                selectedProject = project
                                pendingInputURL = nil
                                pendingProcessingOptions = .allStems
                                reloadProjects(selecting: project.id)
                                activePath.append(NavigationDestination.results)
                            },
                            onCancel: {
                                pendingInputURL = nil
                                pendingProcessingOptions = .allStems
                                popNavigation()
                            }
                        )
                    } else {
                        ImportSourceView(onImportSelected: { importedURL, options in
                            pendingInputURL = importedURL
                            pendingProcessingOptions = options
                            activePath.append(NavigationDestination.processing)
                        })
                    }
                case .results:
                    if let project = selectedProject {
                        ResultsView(
                            project: project,
                            onOpenMixer: {
                                activePath.append(NavigationDestination.mixer)
                            },
                            onOpenAnalyzer: {
                                activePath.append(NavigationDestination.analyzer)
                            }
                        )
                    } else {
                        StudioTimelineView(project: nil, onNavigateToTool: navigateToTool)
                    }
                case .mixer:
                    if let project = selectedProject {
                        StudioMixerView(project: project)
                    } else {
                        MixerDesignView(project: nil, onNavigateToTool: navigateToTool)
                    }
                case .analyzer:
                    AnalyzeDesignView(project: selectedProject, onNavigateToTool: navigateToTool)
                case .lyrics:
                    LyricsSyncDesignView(project: selectedProject)
                case .recording:
                    RecordingView(onRecordFinished: { recordedURL in
                        pendingInputURL = recordedURL
                        pendingProcessingOptions = .allStems
                        activePath.append(NavigationDestination.processing)
                    })
                case .recordCover:
                    RecordCoverDesignView()
                case .loopPractice:
                    LoopPracticeDesignView(project: selectedProject)
                case .chords:
                    ChordsDesignView(project: selectedProject)
                case .audioDevices:
                    AudioDevicesDesignView()
                case .equalizer:
                    EqualizerDesignView(project: selectedProject)
                case .export:
                    ExportDesignView(project: selectedProject)
                case .settings:
                    SettingsDesignView(onNavigateToTool: navigateToTool)
                case .chordLyrics:
                    ChordLyricsDesignView(project: selectedProject)
                case .aiJam:
                    AIJamSessionDesignView(project: selectedProject)
                case .dualCamera:
                    DualCameraCoverDesignView()
                case .performanceMode:
                    PerformanceModeDesignView(project: selectedProject)
                case .legacyRecording:
                    RecordingView(onRecordFinished: { recordedURL in
                        pendingInputURL = recordedURL
                        pendingProcessingOptions = .allStems
                        activePath.append(NavigationDestination.processing)
                    })
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var currentTabView: some View {
        Group {
            switch selectedTab {
            case 0:
                HomeDashboardView(
                    projects: projects,
                    onNavigateToTool: { tool in
                        navigateToTool(tool)
                    },
                    onProjectSelected: { project in
                        selectedProject = project
                        activePath.append(NavigationDestination.results)
                    }
                )
            case 1:
                StudioTimelineView(project: selectedProject, onNavigateToTool: navigateToTool)
            case 3:
                AnalyzeDesignView(project: selectedProject, onNavigateToTool: navigateToTool, showsBack: false)
            case 4:
                SettingsDesignView(onNavigateToTool: navigateToTool, showsBack: false)
            default:
                EmptyView()
            }
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, icon: "house.fill", label: "Home")
            tabButton(index: 1, icon: "slider.horizontal.below.waveform", label: "Studio")

            Button(action: {
                activePath.append(NavigationDestination.actionsSplit)
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: DesignSystem.AccentRed.opacity(0.4), radius: 6, x: 0, y: 3)

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .offset(y: -10)
            .frame(maxWidth: .infinity)

            tabButton(index: 3, icon: "waveform.path.ecg", label: "Analyze")
            tabButton(index: 4, icon: "gearshape.fill", label: "Settings")
        }
        .frame(minHeight: 72)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(DesignSystem.SurfaceGlass)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.extraLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.extraLarge)
                .stroke(DesignSystem.BorderGlass, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private func tabButton(index: Int, icon: String, label: String) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: selectedTab == index ? .semibold : .medium))
                    .foregroundColor(selectedTab == index ? DesignSystem.SoftRed : DesignSystem.TextSecondary)

                Text(label)
                    .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? .white : DesignSystem.TextMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
    }

    private func navigateToTool(_ tool: String) {
        switch tool {
        case "Actions", "Split Actions", "Split Stems", "Stem Separation":
            activePath.append(NavigationDestination.actionsSplit)
        case "Import Audio", "Import Source":
            pendingProcessingOptions = .splits
            activePath.append(NavigationDestination.importSources)
        case "Studio Timeline", "Studio":
            activePath.append(NavigationDestination.studioTimeline)
        case "Studio Mixer", "Mixer":
            activePath.append(NavigationDestination.mixer)
        case "AI Analyzer":
            activePath.append(NavigationDestination.analyzer)
        case "Lyrics Viewer", "Lyrics Sync":
            activePath.append(NavigationDestination.lyrics)
        case "Record", "Recording", "Recorder", "Record Cover":
            activePath.append(NavigationDestination.recording)
        case "Loop Practice", "Practice Loop":
            activePath.append(NavigationDestination.loopPractice)
        case "Chords View", "Chords":
            activePath.append(NavigationDestination.chords)
        case "Audio Devices":
            activePath.append(NavigationDestination.audioDevices)
        case "Equalizer":
            activePath.append(NavigationDestination.equalizer)
        case "Export", "Export Mix":
            activePath.append(NavigationDestination.export)
        case "Settings":
            activePath.append(NavigationDestination.settings)
        case "Chord Lyrics", "Chord + Lyrics":
            activePath.append(NavigationDestination.chordLyrics)
        case "AI Jam Session":
            activePath.append(NavigationDestination.aiJam)
        case "Dual Camera Cover":
            activePath.append(NavigationDestination.dualCamera)
        case "Performance Mode":
            activePath.append(NavigationDestination.performanceMode)
        default:
            break
        }
    }

    private func reloadProjects(selecting id: UUID? = nil) {
        projects = ProjectStore.shared.listProjects()

        if let id, let project = projects.first(where: { $0.id == id }) {
            selectedProject = project
        } else if let selectedID = selectedProject?.id,
                  let refreshed = projects.first(where: { $0.id == selectedID }) {
            selectedProject = refreshed
        } else if selectedProject == nil {
            selectedProject = projects.first
        }

        AppRuntimeState.selectedProjectID = selectedProject?.id
    }

    private func popNavigation() {
        if activePath.count > 0 {
            activePath.removeLast()
        }
    }

    private func persistRuntimeState() {
        AppRuntimeState.selectedTab = selectedTab
        AppRuntimeState.activePath = activePath
        AppRuntimeState.selectedProjectID = selectedProject?.id
        AppRuntimeState.pendingInputURL = pendingInputURL
        AppRuntimeState.pendingProcessingOptions = pendingProcessingOptions
    }
}

enum NavigationDestination: Hashable {
    case actionsSplit
    case studioTimeline
    case importSources
    case processing
    case results
    case mixer
    case analyzer
    case lyrics
    case recording
    case recordCover
    case loopPractice
    case chords
    case audioDevices
    case equalizer
    case export
    case settings
    case chordLyrics
    case aiJam
    case dualCamera
    case performanceMode
    case legacyRecording
}

#Preview {
    AppRootView()
}
