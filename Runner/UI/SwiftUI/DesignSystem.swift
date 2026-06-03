import SwiftUI

struct DesignSystem {
    // Colors
    static let BackgroundDark = Color(hex: "101926")
    static let BackgroundDeep = Color(hex: "08111D")
    static let SurfaceGlass = Color.white.opacity(0.08)
    static let SurfaceLightGlass = Color.white.opacity(0.18)
    static let SurfaceCard = Color(hex: "DDE4EA")
    static let PrimaryRed = Color(hex: "B00020")
    static let AccentRed = Color(hex: "D71920")
    static let SoftRed = Color(hex: "EF4444")
    static let TextPrimaryDark = Color.white
    static let TextPrimaryLight = Color(hex: "111827")
    static let TextSecondary = Color(hex: "94A3B8")
    static let TextMuted = Color(hex: "64748B")
    static let BorderGlass = Color.white.opacity(0.18)
    static let SuccessGreen = Color(hex: "22C55E")
    static let WarningYellow = Color(hex: "F59E0B")
    static let RecordRed = Color(hex: "EF233C")
    
    // Shapes & Corner Radii
    struct Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 22
        static let extraLarge: CGFloat = 28
    }
}

// Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
