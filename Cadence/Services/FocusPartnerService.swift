import Foundation

// MARK: - Focus Goal

struct FocusGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var category: GoalCategory
    var targetMinutesPerDay: Int

    enum GoalCategory: String, Codable, CaseIterable {
        case deepWork = "Deep Work"
        case creative = "Creative"
        case study = "Study"
        case coding = "Coding"
        case writing = "Writing"
        case reading = "Reading"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        category: GoalCategory,
        targetMinutesPerDay: Int = 120
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.targetMinutesPerDay = targetMinutesPerDay
    }
}

// MARK: - Focus Partner

struct FocusPartner: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let goal: String
    let streak: Int
    var status: PartnerStatus
    var currentSessionType: String?
    var joinedAt: Date

    enum PartnerStatus: String, Codable {
        case focusing
        case onBreak = "on_break"
        case available

        var displayText: String {
            switch self {
            case .focusing: return "Focusing"
            case .onBreak: return "On Break"
            case .available: return "Available"
            }
        }

        var icon: String {
            switch self {
            case .focusing: return "brain.head.profile"
            case .onBreak: return "cup.and.saucer"
            case .available: return "checkmark.circle"
            }
        }
    }
}

// MARK: - Focus Partner Service

final class FocusPartnerService: @unchecked Sendable {
    static let shared = FocusPartnerService()

    private let storageKey = "focusPartnerData"

    private init() {}

    // MARK: - Find Partner

    func findPartner(matching goal: FocusGoal) async throws -> FocusPartner? {
        // Simulate network delay for partner matching
        try await Task.sleep(nanoseconds: 800_000_000)

        let candidates = buildCandidatePartners()
        return candidates.first { partner in
            partner.goal.lowercased().contains(goal.category.rawValue.lowercased()) ||
            partner.goal.lowercased().contains(goal.name.lowercased())
        } ?? candidates.randomElement()
    }

    // MARK: - Start Focus Together

    func startFocusTogether(partnerId: UUID) async {
        // Record that we started a shared session with this partner
        var data = loadPartnerData()
        if !data.activePartnerIds.contains(partnerId.uuidString) {
            data.activePartnerIds.append(partnerId.uuidString)
            data.sessionStartMap[partnerId.uuidString] = Date()
            savePartnerData(data)
        }
    }

    // MARK: - Send Check-In

    func sendCheckIn(message: String) {
        // In a real app, this would send to a server
        // For now, just persist as a recent check-in
        var data = loadPartnerData()
        let checkIn = CheckIn(message: message, sentAt: Date())
        data.recentCheckIns.append(checkIn)
        if data.recentCheckIns.count > 20 {
            data.recentCheckIns.removeFirst()
        }
        savePartnerData(data)
    }

    // MARK: - Get Active Partner Session

    func getActivePartnerSession(partnerId: UUID) -> PartnerSession? {
        let data = loadPartnerData()
        guard let startDate = data.sessionStartMap[partnerId.uuidString] else {
            return nil
        }
        return PartnerSession(
            partnerId: partnerId,
            startedAt: startDate,
            elapsedMinutes: Int(Date().timeIntervalSince(startDate) / 60)
        )
    }

    // MARK: - Persistence

    private struct PartnerData: Codable {
        var activePartnerIds: [String] = []
        var sessionStartMap: [String: Date] = [:]
        var recentCheckIns: [CheckIn] = []
    }

    private struct CheckIn: Codable {
        let message: String
        let sentAt: Date
    }

    private func loadPartnerData() -> PartnerData {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let partnerData = try? JSONDecoder().decode(PartnerData.self, from: data) else {
            return PartnerData()
        }
        return partnerData
    }

    private func savePartnerData(_ data: PartnerData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Demo Data

    private func buildCandidatePartners() -> [FocusPartner] {
        [
            FocusPartner(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Taylor S",
                goal: "Deep Work & Coding",
                streak: 14,
                status: .focusing,
                currentSessionType: "Coding",
                joinedAt: Date().addingTimeInterval(-86400 * 5)
            ),
            FocusPartner(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Morgan L",
                goal: "Study & Reading",
                streak: 7,
                status: .available,
                currentSessionType: nil,
                joinedAt: Date().addingTimeInterval(-86400 * 12)
            ),
            FocusPartner(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Jordan R",
                goal: "Creative Writing",
                streak: 21,
                status: .onBreak,
                currentSessionType: "Writing",
                joinedAt: Date().addingTimeInterval(-86400 * 20)
            ),
            FocusPartner(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                name: "Alex K",
                goal: "Deep Work",
                streak: 3,
                status: .focusing,
                currentSessionType: "Deep Work",
                joinedAt: Date().addingTimeInterval(-86400 * 2)
            ),
            FocusPartner(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                name: "Casey M",
                goal: "Study",
                streak: 10,
                status: .available,
                currentSessionType: nil,
                joinedAt: Date().addingTimeInterval(-86400 * 8)
            )
        ]
    }
}

// MARK: - Partner Session

struct PartnerSession: Identifiable, Codable {
    var id: UUID { partnerId }
    let partnerId: UUID
    let startedAt: Date
    let elapsedMinutes: Int

    var formattedTime: String {
        let h = elapsedMinutes / 60
        let m = elapsedMinutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}
