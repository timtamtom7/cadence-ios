import SwiftUI

// MARK: - Brand Guidelines (Cadence 3.0)

// Brand tiers
extension Color {
    static let brandFree = Color.appTextSecondary
    static let brandPro = Color(hex: "FFD700")      // Gold
    static let brandTeams = Color(hex: "9B59B6")    // Purple

    // Awards
    static let awardGold = Color(hex: "FFD700")
    static let awardSilver = Color(hex: "C0C0C0")
}

extension Font {
    static let brandDisplay = Font.system(size: 48, weight: .bold, design: .default)
    static let brandTitle = Font.system(size: 32, weight: .semibold, design: .default)
    static let brandHeadline = Font.system(size: 20, weight: .medium, design: .default)
    static let brandBody = Font.system(size: 17, weight: .regular, design: .default)
    static let brandCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let brandMono = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// MARK: - Press Kit Info

struct PressKit {
    let appName = "Cadence"
    let tagline = "Deep focus in a distracted world"
    let description = """
    Cadence is a focus timer app that combines gamification, social accountability, \
    and AI-powered insights to help users achieve flow state.
    """
    let keyFeatures = [
        "Focus sessions with ambient soundscapes",
        "Social focus with partner matching",
        "AI-powered focus predictions",
        "Teams and challenges for accountability",
        "Flow state detection (Cadence 3.0)"
    ]
    let awards = [
        "Apple Design Awards submission 2024",
        "Productivity App of the Year — Tech Awards"
    ]
    let contact = "press@cadence.app"
}

// MARK: - Brand Usage Guidelines

struct BrandGuidelines {
    static let useCapitalizedName = "Cadence"
    static let useTagline = "Deep focus in a distracted world"
    static let primaryColor = Color.appPrimary
    static let backgroundColor = Color.appBackground

    static let doNot = [
        "Use lowercase 'cadence'",
        "Use the app name as a verb",
        "Modify the brand green color",
        "Use competitor app names in marketing"
    ]
}
