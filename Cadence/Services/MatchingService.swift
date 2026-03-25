import Foundation

@MainActor
@Observable
class MatchingService {
    // MARK: - State

    var isSearching: Bool = false
    var currentMatch: MatchingSession?
    var searchProgress: Double = 0
    var partnerDisconnected: Bool = false

    // MARK: - Private

    private var searchTask: Task<Void, Never>?
    private var availablePartners: [Partner] = Partner.mockPartners

    // MARK: - Matching

    func startSearching(focusMode: String, durationMinutes: Int) async {
        stopSearching()
        isSearching = true
        searchProgress = 0
        currentMatch = nil
        partnerDisconnected = false

        // Simulate search progress
        searchTask = Task { [weak self] in
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.searchProgress = Double(i) / 10.0
                }
            }
        }

        // Wait for search
        await searchTask?.value

        guard !Task.isCancelled else { return }

        // Find a partner
        let matchedPartner = findBestPartner(focusMode: focusMode)

        if let partner = matchedPartner {
            currentMatch = MatchingSession(
                partnerId: partner.id,
                partnerName: partner.name,
                durationMinutes: durationMinutes,
                focusMode: focusMode,
                status: .matched
            )
        } else {
            // No partner found — solo mode
            currentMatch = nil
        }

        isSearching = false
    }

    func stopSearching() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
        searchProgress = 0
    }

    func confirmMatch() {
        guard var match = currentMatch else { return }
        match.status = .inSession
        currentMatch = match
    }

    func disconnectPartner() {
        guard var match = currentMatch else { return }
        match.status = .disconnected
        currentMatch = match
        partnerDisconnected = true
    }

    func clearMatch() {
        currentMatch = nil
        partnerDisconnected = false
    }

    func continueSolo() {
        currentMatch = nil
        partnerDisconnected = false
    }

    // MARK: - Private

    private func findBestPartner(focusMode: String) -> Partner? {
        // Match by compatible focus mode and availability
        let compatible = availablePartners.filter { partner in
            partner.status == .available && (partner.focusMode == focusMode || partner.focusMode == nil)
        }
        return compatible.randomElement()
    }
}
