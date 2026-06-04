import Foundation

enum APIError: Error {
    case invalidURL
    case unauthorized
    case invalidResponse
    case server(String)
}

final class APIClient {
    static let shared = APIClient()

    private let siteURL = URL(string: "https://ai-pixel.online")!
    private let baseURL = URL(string: "https://ai-pixel.online/api/v1/")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 12
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    func login(email: String, password: String) async throws -> PixelCredentials {
        var body: [String: String] = [
            "email": email,
            "password": password
        ]
        if let agreementRevision = try await loginAgreementRevision() {
            body["login_agreement_revision"] = agreementRevision
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("auth/login"))
        request.httpMethod = "POST"
        applyBrowserLikeHeaders(to: &request, referer: "https://ai-pixel.online/login", hasJSONBody: true)
        request.setValue("https://ai-pixel.online", forHTTPHeaderField: "Origin")
        request.httpBody = try encoder.encode(body)

        let response: LoginResponse = try await send(request)
        guard response.code == 0, let data = response.data else {
            throw APIError.server(response.message ?? "登录失败")
        }
        return PixelCredentials(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            email: data.user?.email ?? email
        )
    }

    func refresh(_ credentials: PixelCredentials) async throws -> PixelCredentials {
        guard let refreshToken = credentials.refreshToken, !refreshToken.isEmpty else {
            throw APIError.unauthorized
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("auth/refresh"))
        request.httpMethod = "POST"
        applyBrowserLikeHeaders(to: &request, referer: "https://ai-pixel.online/dashboard", hasJSONBody: true)
        request.httpBody = try encoder.encode(["refresh_token": refreshToken])

        let response: LoginResponse = try await send(request)
        guard response.code == 0, let data = response.data else {
            throw APIError.unauthorized
        }
        return PixelCredentials(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken ?? refreshToken,
            email: data.user?.email ?? credentials.email
        )
    }

    func metrics(using credentials: PixelCredentials) async throws -> WidgetMetrics {
        async let me: MeResponse = authenticatedGet("auth/me?timezone=Asia%2FShanghai", credentials: credentials)
        async let stats: StatsResponse = authenticatedGet("usage/dashboard/stats?timezone=Asia%2FShanghai", credentials: credentials)

        let userResponse = try await me
        let statsResponse = try await stats

        guard userResponse.code == 0, statsResponse.code == 0 else {
            throw APIError.invalidResponse
        }

        let stat = statsResponse.data
        return WidgetMetrics(
            balance: userResponse.data?.balance ?? 0,
            todaySpend: stat?.todayActualCost ?? stat?.todayCost ?? 0,
            todayTokens: stat?.todayTokens ?? ((stat?.todayInputTokens ?? 0) + (stat?.todayOutputTokens ?? 0)),
            totalTokens: stat?.totalTokens ?? ((stat?.totalInputTokens ?? 0) + (stat?.totalOutputTokens ?? 0)),
            updatedAt: Date()
        )
    }

    private func authenticatedGet<T: Decodable>(_ path: String, credentials: PixelCredentials) async throws -> T {
        guard let url = endpointURL(path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyBrowserLikeHeaders(to: &request, referer: "https://ai-pixel.online/dashboard", hasJSONBody: false)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    private func endpointURL(_ path: String) -> URL? {
        URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

    private func loginAgreementRevision() async throws -> String? {
        let loginURL = siteURL.appendingPathComponent("login")
        var request = URLRequest(url: loginURL)
        request.httpMethod = "GET"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("zh", forHTTPHeaderField: "Accept-Language")
        request.setValue(Self.chromeUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }
        guard let html = String(data: data, encoding: .utf8) else {
            return nil
        }

        let pattern = #""login_agreement_revision"\s*:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return String(html[range])
    }

    private func applyBrowserLikeHeaders(to request: inout URLRequest, referer: String, hasJSONBody: Bool) {
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("zh", forHTTPHeaderField: "Accept-Language")
        if hasJSONBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue(Self.chromeUserAgent, forHTTPHeaderField: "User-Agent")
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server("HTTP \(http.statusCode)")
        }
        return try decoder.decode(T.self, from: data)
    }

    private static let chromeUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
}
