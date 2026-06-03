import SwiftUI

struct ImportSourceView: View {
    var onImportSelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let sources = [
        (title: "Import Audio", subtitle: "WAV, MP3, M4A, AIFF, CAF", icon: "music.note", detail: "Import from library or downloads"),
        (title: "Import Video", subtitle: "Extract audio from video", icon: "video.fill", detail: "Extract high quality audio tracks from MOV/MP4"),
        (title: "Browse Files", subtitle: "Choose from local files", icon: "folder.fill", detail: "Select audio tracks directly from Device storage"),
        (title: "From iCloud Drive", subtitle: "Import from iCloud", icon: "icloud.fill", detail: "Browse shared files in iCloud folders")
    ]
    
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
                    
                    Text("Import Source")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40) // Balance back button
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Description Label
                VStack(alignment: .leading, spacing: 6) {
                    Text("CHOOSE AUDIO SOURCE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignSystem.AccentRed)
                        .tracking(1.5)
                    
                    Text("Select the audio input you want to split into high-fidelity stems.")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.TextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                // List of sources
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(sources, id: \.title) { source in
                            GlassListRow(action: onImportSelected) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.AccentRed.opacity(0.18))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: source.icon)
                                            .foregroundColor(DesignSystem.SoftRed)
                                            .font(.system(size: 18))
                                    }
                                    .overlay(Circle().stroke(DesignSystem.BorderGlass, lineWidth: 1))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(source.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(source.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(DesignSystem.TextSecondary)
                                        
                                        Text(source.detail)
                                            .font(.system(size: 10))
                                            .foregroundColor(DesignSystem.TextMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(DesignSystem.TextMuted)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Supported Formats Card Footer
                GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 14) {
                    VStack(spacing: 6) {
                        Text("Supported Formats")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("WAV, MP3, M4A, AIFF, CAF, MOV, MP4")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.TextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ImportSourceView(onImportSelected: {})
}
