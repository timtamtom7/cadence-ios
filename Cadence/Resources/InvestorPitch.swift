import Foundation

// MARK: - Investor Pitch Deck
struct InvestorPitchDeck {
    let slides: [PitchSlide] = [
        PitchSlide(title: "The Problem", body: "In an age of constant distraction, deep focus is the superpower that separates high performers from everyone else. But 78% of workers report difficulty focusing.", imageAsset: nil),
        PitchSlide(title: "Our Solution", body: "Cadence is a focus intelligence platform that combines gamification, social accountability, and AI to help users achieve flow state.", imageAsset: nil),
        PitchSlide(title: "Market Opportunity", body: "$4.2B productivity app market growing at 13% CAGR. Focus/wellness segment is the fastest growing.", imageAsset: nil),
        PitchSlide(title: "Traction", body: "X daily active users, Y sessions completed, Z% week-over-week growth", imageAsset: nil),
        PitchSlide(title: "Business Model", body: "Freemium: Free (limited), Pro ($9.99/mo), Teams ($14.99/user/mo). B2B enterprise tier planned.", imageAsset: nil),
        PitchSlide(title: "Competition", body: "Forest, Focus@Will, Brain.fm — but none combine social accountability + AI + flow detection like Cadence.", imageAsset: nil),
        PitchSlide(title: "Team", body: "Solo founder, full-stack. Looking for engineering and sales co-founders.", imageAsset: nil),
        PitchSlide(title: "The Ask", body: "Raising $500K pre-seed to hire 2 engineers and reach $500K ARR.", imageAsset: nil)
    ]
}

struct PitchSlide {
    let title: String
    let body: String
    let imageAsset: String?
}

// MARK: - Financial Projections
struct FinancialProjections {
    // Year 1-3 projections
    static let year1 = YearProjection(
        year: 2024,
        arr: 50_000,
        activeSubscribers: 420,
        churnRate: 0.05,
        cac: 15,
        ltv: 180
    )
    
    static let year2 = YearProjection(
        year: 2025,
        arr: 200_000,
        activeSubscribers: 1700,
        churnRate: 0.04,
        cac: 12,
        ltv: 220
    )
    
    static let year3 = YearProjection(
        year: 2026,
        arr: 500_000,
        activeSubscribers: 4200,
        churnRate: 0.03,
        cac: 10,
        ltv: 280
    )
}

struct YearProjection {
    let year: Int
    let arr: Double
    let activeSubscribers: Int
    let churnRate: Double
    let cac: Double
    let ltv: Double
}

// MARK: - Hiring Plan
struct HiringPlan {
    static let positions: [HiringPosition] = [
        HiringPosition(role: "Senior iOS Engineer", timing: "Q1 2025", priority: .high, salaryRange: "$120-150K"),
        HiringPosition(role: "ML Engineer (Focus AI)", timing: "Q2 2025", priority: .high, salaryRange: "$130-160K"),
        HiringPosition(role: "Growth / Marketing", timing: "Q3 2025", priority: .medium, salaryRange: "$80-100K"),
        HiringPosition(role: "Customer Success", timing: "Q4 2025", priority: .medium, salaryRange: "$60-80K")
    ]
}

struct HiringPosition {
    let role: String
    let timing: String
    let priority: Priority
    let salaryRange: String
    
    enum Priority {
        case high, medium, low
    }
}

// MARK: - Company Policies
struct CompanyPolicies {
    static let remotePolicy = "Fully remote, async-first"
    static let meetingFreeDays = "No-meeting Wednesdays"
    static let focusTimePolicy = "4+ hours of deep work protected daily"
    static let sabbaticalPolicy = "3-month paid sabbatical after 4 years"
}
