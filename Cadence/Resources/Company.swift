import Foundation

// MARK: - Company Structure
struct Company {
    let name = "Cadence Technologies, Inc."
    let founded = "2023"
    let website = "cadence.app"
    let structure = CompanyStructure()
}

struct CompanyStructure {
    let type = "C-Corp (Delaware)"
    let founded = "2023"
    let employees = 1
    let stage = "Bootstrapped / Pre-seed"
}

// MARK: - Team Roles
struct CompanyTeamMember: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let responsibilities: [String]
}

enum CompanyRole: String, CaseIterable {
    case founder = "Founder / CEO"
    case engineer = "Engineer"
    case designer = "Designer"
    case marketing = "Marketing"
    case ops = "Operations"
}

// MARK: - Financial Metrics
struct FinancialMetrics {
    var monthlyRecurringRevenue: Double = 0
    var activeSubscribers: Int = 0
    var averageRevenuePerUser: Double = 0
    var churnRate: Double = 0
    var lifetimeValue: Double = 0
    var customerAcquisitionCost: Double = 0
    
    var arr: Double {
        monthlyRecurringRevenue * 12
    }
    
    var arrTarget500K: Double { 500_000 }
    var progressToTarget: Double {
        min(1.0, arr / arrTarget500K)
    }
}

// MARK: - Investment Readiness Checklist
struct InvestmentReadinessChecklist {
    let items: [ChecklistItem] = [
        ChecklistItem(title: "Business Plan", completed: true, notes: "Platform expansion strategy"),
        ChecklistItem(title: "Financial Model", completed: true, notes: "ARR projections to $500K"),
        ChecklistItem(title: "Cap Table", completed: false, notes: "Pending legal setup"),
        ChecklistItem(title: "Pitch Deck", completed: false, notes: "Draft complete, needs polish"),
        ChecklistItem(title: "Unit Economics", completed: true, notes: "LTV:CAC > 3x"),
        ChecklistItem(title: "Traction Metrics", completed: true, notes: "Active user growth tracked"),
        ChecklistItem(title: "Legal Review", completed: false, notes: "Terms of service updated"),
        ChecklistItem(title: "IP Protection", completed: false, notes: "Trademark filed")
    ]
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    var completed: Bool
    var notes: String?
}
