import Foundation
import HealthKit

// MARK: - Flow State Detection
struct FlowState: Codable {
    let timestamp: Date
    let duration: Int // seconds
    let intensity: Double // 0-1
    let indicators: [FlowIndicator]
    let sessionId: UUID?
}

enum FlowIndicator: String, Codable, CaseIterable {
    case sustainedAttention = "Sustained Attention"
    case reducedSelfAwareness = "Reduced Self-Awareness"
    case timeDistortion = "Time Distortion"
    case effortlessControl = "Effortless Control"
    case completeAbsorption = "Complete Absorption"
}

@MainActor
class FlowStateService: ObservableObject {
    @Published var currentFlowState: FlowState?
    @Published var flowHistory: [FlowState] = []
    @Published var isFlowStateActive = false
    
    private let healthStore = HKHealthStore()
    
    /// Detect flow state based on session characteristics
    func detectFlowState(session: Session, userReportsHighFocus: Bool) -> FlowState {
        var indicators: [FlowIndicator] = []
        var intensity: Double = 0
        
        // High focus score indicates sustained attention
        if session.focusScore >= 85 {
            indicators.append(.sustainedAttention)
            intensity += 0.3
        }
        
        // Longer sessions (>30 min) can indicate time distortion
        if session.durationMinutes >= 30 {
            indicators.append(.timeDistortion)
            intensity += 0.2
        }
        
        // User-reported high focus
        if userReportsHighFocus {
            indicators.append(.completeAbsorption)
            intensity += 0.3
        }
        
        // High focus score + long duration = likely effortless control
        if session.focusScore >= 90 && session.durationMinutes >= 45 {
            indicators.append(.effortlessControl)
            intensity += 0.2
        }
        
        return FlowState(
            timestamp: session.completedAt,
            duration: session.duration,
            intensity: min(1.0, intensity),
            indicators: indicators,
            sessionId: session.id
        )
    }
    
    /// Start monitoring for flow state
    func startMonitoring() async {
        // HealthKit biometric monitoring placeholder
        // In production: monitor heart rate variability during sessions
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        currentFlowState = nil
        isFlowStateActive = false
    }
}

// MARK: - Biometric Feedback
struct BiometricReading: Codable {
    let timestamp: Date
    let heartRate: Double?
    let hrv: Double? // heart rate variability
    let galvanicSkin: Double?
    let motionIntensity: Double?
}

class BiometricFeedbackService: @unchecked Sendable {
    static let shared = BiometricFeedbackService()
    
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    /// Request HealthKit authorization
    @MainActor
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        
        var typesToRead: Set<HKObjectType> = []
        if let hrt = heartRateType { typesToRead.insert(hrt) }
        if let hrvt = hrvType { typesToRead.insert(hrvt) }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            return false
        }
    }
    
    /// Get current heart rate
    func fetchCurrentHeartRate() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            healthStore.execute(query)
        }
    }
}
