import SwiftUI

struct ProfileView: View {
    @State private var hifiAudioEnabled = true
    @State private var selectedThemeIndex = 0
    private let themes = ["Dark Glass", "Red/White Accent", "Ultra Navy"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Profile Avatar Hero Card
                GlassCard(cornerRadius: DesignSystem.Radius.large, padding: 18) {
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [DesignSystem.AccentRed, DesignSystem.PrimaryRed],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 54, height: 54)
                            
                            Text("AS")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // User Info
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Artist Studio")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("studio.user@aimusic.io")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.TextSecondary)
                            
                            Text("Pro Studio Account")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(DesignSystem.SoftRed)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(DesignSystem.AccentRed.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.TextMuted)
                    }
                }
                .padding(.horizontal, 20)
                
                // Account Settings Group
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preferences")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .tracking(1.0)
                        .padding(.horizontal, 22)
                    
                    GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 12) {
                        VStack(spacing: 14) {
                            // Audio Quality
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.AccentRed.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "waveform.circle.fill")
                                        .foregroundColor(DesignSystem.SoftRed)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Hi-Fi Separating Mode")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Uncompressed 32-bit floating WAV")
                                        .font(.system(size: 11))
                                        .foregroundColor(DesignSystem.TextMuted)
                                }
                                Spacer()
                                Toggle("", isOn: $hifiAudioEnabled)
                                    .tint(DesignSystem.AccentRed)
                            }
                            
                            Divider().background(DesignSystem.BorderGlass)
                            
                            // Theme Settings
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundColor(.white)
                                }
                                
                                Text("Theme Select")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $selectedThemeIndex) {
                                    ForEach(0..<themes.count, id: \.self) { idx in
                                        Text(themes[idx]).tag(idx)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(DesignSystem.SoftRed)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // App Config Group
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Settings")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.TextSecondary)
                        .tracking(1.0)
                        .padding(.horizontal, 22)
                    
                    GlassCard(cornerRadius: DesignSystem.Radius.medium, padding: 12) {
                        VStack(spacing: 14) {
                            settingsRow(icon: "internaldrive.fill", title: "Storage Space", detail: "2.4 GB of 64 GB used")
                            Divider().background(DesignSystem.BorderGlass)
                            settingsRow(icon: "info.circle.fill", title: "About AI Music Studio", detail: "Version 1.0.0 (Build 18A)")
                            Divider().background(DesignSystem.BorderGlass)
                            settingsRow(icon: "questionmark.circle.fill", title: "Help & Support Center", detail: "Read documentation")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Logout/Reset Button
                Button(action: { /* Reset logic */ }) {
                    Text("Reset Studio Cache")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignSystem.SoftRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.AccentRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                .stroke(DesignSystem.AccentRed.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Bottom spacing for floating tab bar safety
                Spacer(minLength: 100)
            }
        }
    }
    
    // Config row helper
    private func settingsRow(icon: String, title: String, detail: String) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.TextMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.TextMuted)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProfileView()
    }
}
