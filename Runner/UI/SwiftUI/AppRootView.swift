import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = 0
    @State private var activePath = NavigationPath()

    @State private var selectedProjectName: String = "Ocean Waves"
    
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
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .importSources:
                    ImportSourceView(onImportSelected: { importedURL in
                        selectedProjectName = importedURL.deletingPathExtension().lastPathComponent
                        activePath.append(NavigationDestination.processing)
                    })
                case .processing:
                    ProcessingView(onComplete: {
                        activePath.append(NavigationDestination.results)
                    }, onCancel: {
                        activePath.removeLast()
                    })
                case .results:
                    ResultsView(projectName: selectedProjectName, onOpenMixer: {
                        activePath.append(NavigationDestination.mixer)
                    }, onOpenAnalyzer: {
                        activePath.append(NavigationDestination.analyzer)
                    })
                case .mixer:
                    StudioMixerView(projectName: selectedProjectName)
                case .analyzer:
                    AIAnalyzerView()
                case .lyrics:
                    LyricsViewerView()
                case .recording:
                    RecordingView(onRecordFinished: {
                        selectedProjectName = "Recorded Session"
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
                    onNavigateToTool: { tool in
                        navigateToTool(tool)
                    },
                    onProjectSelected: { projName in
                        selectedProjectName = projName
                        activePath.append(NavigationDestination.results)
                    }
                )
            case 1:
                ProjectsView(
                    onCreateProject: {
                        activePath.append(NavigationDestination.importSources)
                    },
                    onProjectSelected: { projName in
                        selectedProjectName = projName
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
            
            // Central Red Button for New Project / Import
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
    
    // Routing helpers
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
}

// Navigation Enum for SwiftUI Destination Binding
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
