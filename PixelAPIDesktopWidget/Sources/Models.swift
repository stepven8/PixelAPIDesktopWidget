import Foundation

struct PixelCredentials: Codable {
    let accessToken: String
    let refreshToken: String?
    let email: String?
}

struct LoginResponse: Decodable {
    let code: Int?
    let message: String?
    let data: LoginData?
}

struct LoginData: Decodable {
    let accessToken: String
    let refreshToken: String?
    let user: UserInfo?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct MeResponse: Decodable {
    let code: Int?
    let message: String?
    let data: UserInfo?
}

struct StatsResponse: Decodable {
    let code: Int?
    let message: String?
    let data: DashboardStats?
}

struct UserInfo: Decodable {
    let email: String?
    let balance: Double?
}

struct DashboardStats: Decodable {
    let todayActualCost: Double?
    let todayCost: Double?
    let totalActualCost: Double?
    let totalCost: Double?
    let todayTokens: Double?
    let todayInputTokens: Double?
    let todayOutputTokens: Double?
    let totalTokens: Double?
    let totalInputTokens: Double?
    let totalOutputTokens: Double?

    enum CodingKeys: String, CodingKey {
        case todayActualCost = "today_actual_cost"
        case todayCost = "today_cost"
        case totalActualCost = "total_actual_cost"
        case totalCost = "total_cost"
        case todayTokens = "today_tokens"
        case todayInputTokens = "today_input_tokens"
        case todayOutputTokens = "today_output_tokens"
        case totalTokens = "total_tokens"
        case totalInputTokens = "total_input_tokens"
        case totalOutputTokens = "total_output_tokens"
    }
}

struct WidgetMetrics {
    var balance: Double
    var todaySpend: Double
    var todayTokens: Double
    var totalTokens: Double
    var updatedAt: Date

    static let placeholder = WidgetMetrics(
        balance: 0,
        todaySpend: 0,
        todayTokens: 0,
        totalTokens: 0,
        updatedAt: Date()
    )
}

enum WidgetStatus {
    case signedOut
    case loading
    case ready
    case authExpired
    case networkError(String)

    var label: String {
        switch self {
        case .signedOut: return "需要登录"
        case .loading: return "同步中"
        case .ready: return "实时在线"
        case .authExpired: return "需要重新登录"
        case .networkError(let message): return message.isEmpty ? "网络异常" : message
        }
    }
}
