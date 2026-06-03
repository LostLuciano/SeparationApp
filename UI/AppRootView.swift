import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = 0
    @State private var showImportSheet: Bool = false
    @State private var activePath = NavigationPath()
    
    // Shared state to allow flow transitions (UI only)
    @State private var showProcessingView: Bool = false
    @State private var showResultsView: Bool = false
    @State private var selectedProjectName: String = "Ocean Waves"
    
    var body: some View {
        NavigationStack(path: $activePath) {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [DesignSystem.BackgroundDark, DesignSystem.BackgroundDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content Switcher
                VStack(spacing: 0) {
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
                            ProjectsView(onProjectSelected: { projName in
                                selectedProjectName = projName
                                activePath.append(NavigationDestination.results)
                            })
                        case 2:
                            ToolsHubView(onNavigateToTool: { tool in
                                navigateToTool(tool)
                            })
                        case 3:
                            ProfileView()
                        default:
                            HomeView(onNavigateToTool: { _ in }, onProjectSelected: { _ in })
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                    
                    // Floating Custom Glass Tab Bar (Pushed slightly up to float)
                    customTabBar
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .importSources:
                    ImportSourceView(onImportSelected: {
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
                        activePath.append(NavigationDestination.processing)
                    })
                }
            }
        }
    }
    
    // Custom Glass Tab Bar View
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
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Routing helpers
    private func navigateToTool(_ tool: String) {
        switch tool {
        case "Import Audio", "Import Source":
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
