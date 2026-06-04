import SwiftUI

struct HomeView: View {
    var projects: [StemProject]
    var onNavigateToTool: (String) -> Void
    var onProjectSelected: (StemProject) -> Void

    private let quickActionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerBar
                heroCard
                quickActions
                recentProjects
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Studio")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DesignSystem.AccentRed)
                    .tracking(1.5)

                Text("AI Music Studio")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            Button(action: { onNavigateToTool("AI Analyzer") }) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.SurfaceLightGlass)
                        .frame(width: 44, height: 44)

                    Image(systemName: "waveform")
                        .foregroundColor(DesignSystem.AccentRed)
                        .font(.system(size: 18))
                }
                .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))
            }
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.AccentRed.opacity(0.35),
                            DesignSystem.PrimaryRed.opacity(0.15),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), DesignSystem.AccentRed.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )

            VStack {
                Spacer()
                GlassWaveform(sampleCount: 34, isAnimated: true, highlightColor: DesignSystem.AccentRed)
                    .opacity(0.22)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 14)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("CREATE. ENHANCE. RELEASE.")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.AccentRed)
                    .tracking(2.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Next-Gen Audio Separation")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("Isolate vocals, drums, bass, and keys instantly with high-fidelity Neural separating engine.")
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.TextSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(minHeight: 168)
        .shadow(color: DesignSystem.AccentRed.opacity(0.2), radius: 15, x: 0, y: 8)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: quickActionColumns, spacing: 12) {
                quickActionCard(title: "New Project", icon: "plus.rectangle.on.folder", caption: "Split stems", isPrimary: true) {
                    onNavigateToTool("Import Source")
                }

                quickActionCard(title: "Studio Mixer", icon: "slider.horizontal.3", caption: "Mix tracks", isPrimary: false) {
                    onNavigateToTool("Studio Mixer")
                }

                quickActionCard(title: "AI Analyzer", icon: "waveform.path", caption: "Chords & BPM", isPrimary: false) {
                    onNavigateToTool("AI Analyzer")
                }

                quickActionCard(title: "Record Audio", icon: "mic.fill", caption: "Capture sound", isPrimary: false) {
                    onNavigateToTool("Record")
                }
            }
        }
    }

    private var recentProjects: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Projects")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { }) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.SoftRed)
                }
            }

            if projects.isEmpty {
                emptyRecentProjects
            } else {
                VStack(spacing: 10) {
                    ForEach(projects.prefix(3)) { project in
                    GlassListRow(action: {
                        onProjectSelected(project)
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                    .fill(
                                        LinearGradient(
                                            colors: [DesignSystem.AccentRed.opacity(0.4), DesignSystem.PrimaryRed.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)

                                Image(systemName: project.format == "WAV" ? "waveform" : "music.note")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(projectSummary(project))
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.TextMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.TextMuted)
                                .font(.system(size: 12))
                        }
                    }
                }
                }
            }
        }
    }

    private var emptyRecentProjects: some View {
        GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 16) {
            HStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DesignSystem.TextMuted)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))

                VStack(alignment: .leading, spacing: 3) {
                    Text("No projects yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Import or record audio to create your first real project.")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.TextMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }

    private func quickActionCard(
        title: String,
        icon: String,
        caption: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(isPrimary ? Color.white : DesignSystem.AccentRed.opacity(0.2))
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .foregroundColor(isPrimary ? DesignSystem.AccentRed : .white)
                        .font(.system(size: 16, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(caption)
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(isPrimary ?
                        LinearGradient(colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [DesignSystem.SurfaceGlass, Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(isPrimary ? DesignSystem.SoftRed.opacity(0.4) : DesignSystem.BorderGlass, lineWidth: 1)
            )
            .shadow(color: isPrimary ? DesignSystem.AccentRed.opacity(0.2) : Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
    }

    private func projectSummary(_ project: StemProject) -> String {
        "\(project.stemPaths.count) Stems - \(project.displayDuration) - \(formatDate(project.createdAt))"
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
        HomeView(projects: [], onNavigateToTool: { _ in }, onProjectSelected: { _ in })
    }
}
