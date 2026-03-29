import SwiftUI

// MARK: - Shared Extensions (included by both iOS and macOS targets)

// MARK: - Color Palette

extension Color {
    static let appBackground = Color(hex: "0D1B1E")
    static let appSurface = Color(hex: "142328")
    static let appSurfaceElevated = Color(hex: "1A2E33")
    static let appPrimary = Color(hex: "00D4AA")
    static let appAccent = Color(hex: "00F5CC")
    static let appTextPrimary = Color(hex: "E8F7F3")
    static let appTextSecondary = Color(hex: "7AAEAA")
    static let appTextTertiary = Color(hex: "4A7A78")
    static let appTextQuaternary = Color(hex: "2A5A58")
    static let appError = Color(hex: "FF6B6B")
    static let appSuccess = Color(hex: "00D4AA")
    static let appWarning = Color(hex: "FFD93D")

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
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension ShapeStyle where Self == Color {
    static var appBackground: Color { Color.appBackground }
    static var appSurface: Color { Color.appSurface }
    static var appSurfaceElevated: Color { Color.appSurfaceElevated }
    static var appPrimary: Color { Color.appPrimary }
    static var appAccent: Color { Color.appAccent }
    static var appTextPrimary: Color { Color.appTextPrimary }
    static var appTextSecondary: Color { Color.appTextSecondary }
    static var appTextTertiary: Color { Color.appTextTertiary }
    static var appError: Color { Color.appError }
    static var appSuccess: Color { Color.appSuccess }
    static var appWarning: Color { Color.appWarning }
}

// MARK: - Font Extensions

extension Font {
    static let appDisplay = Font.system(size: 34, weight: .bold, design: .default)
    static let appHeading1 = Font.system(size: 28, weight: .semibold, design: .default)
    static let appHeading2 = Font.system(size: 20, weight: .medium, design: .default)
    static let appBody = Font.system(size: 17, weight: .regular, design: .default)
    static let appCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let appCaption2 = Font.system(size: 11, weight: .regular, design: .default)
    static let appMono = Font.system(size: 15, weight: .regular, design: .monospaced)
}

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
