import SwiftUI

struct Theme {
    static let primary = Color(hex: "#1E3A5F")
    static let onPrimary = Color.white
    static let secondary = Color(hex: "#2563EB")
    static let background = Color(hex: "#F8FAFC")
    static let surface = Color.white
    static let onBackground = Color(hex: "#0F172A")
    static let error = Color(hex: "#DC2626")
    static let errorContainer = Color(hex: "#FEE2E2")
    static let textSecondary = Color(hex: "#64748B")
    static let divider = Color(hex: "#E2E8F0")

    static func statusColor(_ status: AssetStatus) -> Color {
        switch status {
        case .available: return Color(hex: "#16A34A")
        case .inUse: return Color(hex: "#2563EB")
        case .maintenance: return Color(hex: "#D97706")
        case .retired: return Color(hex: "#6B7280")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
