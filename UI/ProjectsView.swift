import SwiftUI

struct ProjectsView: View {
    var onProjectSelected: (String) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedFilterIndex: Int = 0
    private let filters = ["All", "Songs", "Sessions", "Imported"]
    
    var filteredProjects: [StemProject] {
        var list = PreviewData.projects
        
        if selectedFilterIndex == 1 { // Songs
            list = list.filter { $0.stemPaths.count > 2 }
        } else if selectedFilterIndex == 2 { // Sessions
            list = list.filter { $0.name.contains("Session") || $0.name.contains("Track") }
        } else if selectedFilterIndex == 3 { // Imported
            list = list.filter { $0.status == .imported }
        }
        
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return list
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LIBRARY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignSystem.AccentRed)
                        .tracking(2.0)
                    Text("Projects")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    onProjectSelected("New Custom Session")
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(DesignSystem.AccentRed)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Library Hero Card (matching Home page styling)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.AccentRed.opacity(0.25),
                                DesignSystem.PrimaryRed.opacity(0.1),
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), DesignSystem.AccentRed.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Background waveform
                VStack {
                    Spacer()
                    GlassWaveform(sampleCount: 22, isAnimated: false, highlightColor: DesignSystem.AccentRed)
                        .opacity(0.15)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                }
                .frame(height: 100)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIVE SESSION")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(DesignSystem.AccentRed)
                            .tracking(1.5)
                        
                        Text("Ocean Waves")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Ready to mix · 6 stems separated")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                    
                    Spacer()
                    
                    // Wave graphic/icon
                    ZStack {
                        Circle()
                            .fill(DesignSystem.AccentRed.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "waveform.path")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))
                }
                .padding(16)
            }
            .frame(height: 100)
            .padding(.horizontal, 20)
            
            // Search Bar
            GlassSearchBar(text: $searchText, placeholder: "Search projects...")
                .padding(.horizontal, 20)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedFilterIndex = index
                            }
                        }) {
                            Text(filters[index])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedFilterIndex == index ? .white : DesignSystem.TextSecondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedFilterIndex == index ? 
                                            DesignSystem.AccentRed : 
                                            DesignSystem.SurfaceGlass)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedFilterIndex == index ? DesignSystem.SoftRed.opacity(0.4) : DesignSystem.BorderGlass, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Project List
            if filteredProjects.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.TextMuted)
                    Text("No projects found")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("Try clearing your filters or search query.")
                        .font(.system(size: 13))
                        .foregroundColor(DesignSystem.TextMuted)
                    Spacer()
                }
                .padding(.bottom, 60)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(filteredProjects) { project in
                            GlassListRow(action: {
                                onProjectSelected(project.name)
                            }) {
                                HStack(spacing: 16) {
                                    // Artwork/Icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                            .fill(
                                                LinearGradient(
                                                    colors: [DesignSystem.AccentRed.opacity(0.35), DesignSystem.PrimaryRed.opacity(0.08)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: project.format == "WAV" ? "waveform" : "music.note")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                            .stroke(DesignSystem.BorderGlass, lineWidth: 1)
                                    )
                                    
                                    // Title & Stems Info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 8) {
                                            Text("\(project.stemPaths.count) Stems")
                                                .foregroundColor(DesignSystem.SoftRed)
                                                .font(.system(size: 12, weight: .medium))
                                            
                                            Text("•")
                                                .foregroundColor(DesignSystem.TextMuted)
                                            
                                            Text(project.displayDuration)
                                                .foregroundColor(DesignSystem.TextMuted)
                                            
                                            Text("•")
                                                .foregroundColor(DesignSystem.TextMuted)
                                            
                                            Text(formatDate(project.createdAt))
                                                .foregroundColor(DesignSystem.TextMuted)
                                        }
                                        .font(.system(size: 12))
                                    }
                                    
                                    Spacer()
                                    
                                    // Actions Menu Button
                                    Button(action: { }) {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(DesignSystem.TextSecondary)
                                            .frame(width: 32, height: 32)
                                            .background(DesignSystem.SurfaceGlass)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProjectsView(onProjectSelected: { _ in })
    }
}
