import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = 0
    @State private var activePath = NavigationPath()

    @State private var projects: [StemProject] = []
    @State private var selectedProject: StemProject?
    @State private var pendingInputURL: URL?

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
                reloadProjects()
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .importSources:
                    ImportSourceView(onImportSelected: { importedURL in
                        pendingInputURL = importedURL
                        activePath.append(NavigationDestination.processing)
                    })
                case .processing:
                    if let inputURL = pendingInputURL {
                        ProcessingView(
                            audioURL: inputURL,
                            onComplete: { project in
                                selectedProject = project
                                pendingInputURL = nil
                                reloadProjects(selecting: project.id)
                                activePath.append(NavigationDestination.results)
                            },
                            onCancel: {
                                pendingInputURL = nil
                                popNavigation()
                            }
                        )
                    } else {
                        MissingProjectView(
                            title: "No audio selected",
                            message: "Choose an audio file or finish a recording before processing.",
                            actionTitle: "Import Audio",
                            action: { activePath.append(NavigationDestination.importSources) }
                        )
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
                        noProjectSelectedView
                    }
                case .mixer:
                    if let project = selectedProject {
                        StudioMixerView(project: project)
                    } else {
                        noProjectSelectedView
                    }
                case .analyzer:
                    AIAnalyzerView(project: selectedProject)
                case .lyrics:
                    LyricsViewerView(project: selectedProject)
                case .recording:
                    RecordingView(onRecordFinished: { recordedURL in
                        pendingInputURL = recordedURL
                        activePath.append(NavigationDestination.processing)
                    })
                }
            }
        }
    }

    private var currentTabView: some View {
        Group {
            switch selectedTab {
            case 0:
                HomeView(
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
                ProjectsView(
                    projects: projects,
                    onCreateProject: {
                        activePath.append(NavigationDestination.importSources)
                    },
                    onProjectSelected: { project in
                        selectedProject = project
                        activePath.append(NavigationDestination.results)
                    }
                )
            case 2:
                ToolsHubView(onNavigateToTool: { tool in
                    navigateToTool(tool)
                })
            case 3:
                ProfileView()
            default:
                EmptyView()
            }
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, icon: "house.fill", label: "Home")
            tabButton(index: 1, icon: "music.note.list", label: "Projects")

            Button(action: {
                activePath.append(NavigationDestination.importSources)
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

            tabButton(index: 2, icon: "slider.horizontal.3", label: "Tools")
            tabButton(index: 3, icon: "person.fill", label: "Profile")
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

    private var noProjectSelectedView: some View {
        MissingProjectView(
            title: "No project selected",
            message: "Import or record audio first, then open the project tools from Results.",
            actionTitle: "Import Audio",
            action: { activePath.append(NavigationDestination.importSources) }
        )
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
        case "Import Audio", "Import Source", "Stem Separation":
            activePath.append(NavigationDestination.importSources)
        case "Studio Mixer":
            activePath.append(NavigationDestination.mixer)
        case "AI Analyzer":
            activePath.append(NavigationDestination.analyzer)
        case "Lyrics Viewer":
            activePath.append(NavigationDestination.lyrics)
        case "Record", "Recording":
            activePath.append(NavigationDestination.recording)
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
    }

    private func popNavigation() {
        if activePath.count > 0 {
            activePath.removeLast()
        }
    }
}

struct MissingProjectView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(DesignSystem.TextMuted)

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.TextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                GlassButton(title: actionTitle, icon: "plus", isAccented: true, action: action)
                    .padding(.horizontal, 36)
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

enum NavigationDestination: Hashable {
    case importSources
    case processing
    case results
    case mixer
    case analyzer
    case lyrics
    case recording
}

#Preview {
    AppRootView()
}
