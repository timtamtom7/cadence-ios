import Foundation

// MARK: - REST API Service
actor APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.cadence.app/v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Session Endpoints
    
    struct SessionResponse: Codable {
        let id: UUID
        let duration: Int
        let focusScore: Int
        let completedAt: Date
    }
    
    func fetchSessions(token: String, limit: Int = 50) async throws -> [SessionResponse] {
        let url = URL(string: "\(baseURL)/sessions?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return try decoder.decode([SessionResponse].self, from: data)
    }
    
    func postSession(_ session: Session, token: String) async throws -> SessionResponse {
        let url = URL(string: "\(baseURL)/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = try encoder.encode(session)
        request.httpBody = payload
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.requestFailed
        }
        
        return try decoder.decode(SessionResponse.self, from: data)
    }
    
    // MARK: - Analytics Endpoints
    
    struct AnalyticsResponse: Codable {
        let totalSessions: Int
        let totalMinutes: Int
        let averageFocusScore: Double
        let streakDays: Int
        let flowStateProbability: Double
    }
    
    func fetchAnalytics(token: String) async throws -> AnalyticsResponse {
        let url = URL(string: "\(baseURL)/analytics")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return try decoder.decode(AnalyticsResponse.self, from: data)
    }
    
    // MARK: - Task Manager Integration
    
    enum TaskManager: String, CaseIterable {
        case todoist = "Todoist"
        case things = "Things 3"
        case omnifocus = "OmniFocus"
        case notion = "Notion"
        case linear = "Linear"
        
        var icon: String {
            switch self {
            case .todoist: return "checklist"
            case .things: return "checkmark.circle"
            case .omnifocus: return "target"
            case .notion: return "doc.text"
            case .linear: return "chart.bar"
            }
        }
    }
    
    struct TaskManagerConnection: Codable {
        let manager: String
        let connected: Bool
        let lastSync: Date?
    }
    
    func getTaskManagerConnections(token: String) async throws -> [TaskManagerConnection] {
        let url = URL(string: "\(baseURL)/integrations")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return try decoder.decode([TaskManagerConnection].self, from: data)
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case requestFailed
    case unauthorized
    case serverError
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Request failed. Please try again."
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError: return "Server error. Please try again later."
        case .decodingFailed: return "Failed to process server response."
        }
    }
}

// MARK: - Webhook Events
struct WebhookEvent: Codable {
    let event: String
    let timestamp: Date
    let data: [String: String]
}

enum WebhookEventType: String {
    case sessionCompleted = "session.completed"
    case challengeJoined = "challenge.joined"
    case teamSessionStarted = "team.session.started"
    case streakMilestone = "streak.milestone"
    case flowStateDetected = "flow_state.detected"
}
