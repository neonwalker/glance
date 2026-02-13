import Foundation

// MARK: - GitHub API Response Models (Codable)

nonisolated struct GitHubWorkflowRunsResponse: Codable {
    let totalCount: Int
    let workflowRuns: [GitHubWorkflowRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }
}

nonisolated struct GitHubWorkflowRun: Codable {
    let id: Int
    let name: String?
    let headBranch: String?
    let status: String?
    let conclusion: String?
    let htmlUrl: String
    let displayTitle: String?
    let updatedAt: String
    let runNumber: Int

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case headBranch = "head_branch"
        case htmlUrl = "html_url"
        case displayTitle = "display_title"
        case updatedAt = "updated_at"
        case runNumber = "run_number"
    }
}

// MARK: - Rate Limit Tracking

nonisolated struct GitHubRateLimit {
    let limit: Int
    let remaining: Int
    let resetDate: Date
}

// MARK: - Service Errors

enum GitHubServiceError: LocalizedError {
    case invalidToken
    case rateLimitExceeded(resetDate: Date)
    case networkError(Error)
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid or missing GitHub token. Check Settings."
        case .rateLimitExceeded(let date):
            let formatter = RelativeDateTimeFormatter()
            let relative = formatter.localizedString(for: date, relativeTo: Date())
            return "Rate limit exceeded. Resets \(relative)."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "GitHub API returned HTTP \(code)."
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

// MARK: - GitHub Service

actor GitHubService {

    private let session: URLSession
    private let baseURL = "https://api.github.com"
    private let apiVersion = "2022-11-28"
    private let decoder: JSONDecoder

    // ETag cache: keyed by request URL
    private var etagCache: [String: String] = [:]
    // Response cache: keyed by request URL — used when server returns 304
    private var responseCache: [String: GitHubWorkflowRunsResponse] = [:]

    // Rate limit info (updated from response headers)
    private(set) var rateLimit: GitHubRateLimit?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    func fetchWorkflowRuns(
        owner: String,
        repo: String,
        token: String,
        perPage: Int = 5
    ) async throws -> [GitHubWorkflowRun] {
        guard !token.isEmpty else {
            throw GitHubServiceError.invalidToken
        }

        // Check if we're already rate-limited
        if let rl = rateLimit, rl.remaining == 0, Date() < rl.resetDate {
            throw GitHubServiceError.rateLimitExceeded(resetDate: rl.resetDate)
        }

        let urlString = "\(baseURL)/repos/\(owner)/\(repo)/actions/runs?per_page=\(perPage)"

        guard let url = URL(string: urlString) else {
            throw GitHubServiceError.httpError(statusCode: 0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")

        if let etag = etagCache[urlString] {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GitHubServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubServiceError.httpError(statusCode: 0)
        }

        // Update rate limit from headers
        updateRateLimit(from: httpResponse)

        switch httpResponse.statusCode {
        case 200:
            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                etagCache[urlString] = etag
            }
            do {
                let decoded = try decoder.decode(GitHubWorkflowRunsResponse.self, from: data)
                responseCache[urlString] = decoded
                return decoded.workflowRuns
            } catch {
                throw GitHubServiceError.decodingError(error)
            }

        case 304:
            if let cached = responseCache[urlString] {
                return cached.workflowRuns
            }
            return []

        case 401:
            throw GitHubServiceError.invalidToken

        case 403:
            if let rl = rateLimit, rl.remaining == 0 {
                throw GitHubServiceError.rateLimitExceeded(resetDate: rl.resetDate)
            }
            throw GitHubServiceError.httpError(statusCode: 403)

        default:
            throw GitHubServiceError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Private Helpers

    private func updateRateLimit(from response: HTTPURLResponse) {
        guard
            let limitStr = response.value(forHTTPHeaderField: "X-RateLimit-Limit"),
            let limit = Int(limitStr),
            let remainingStr = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
            let remaining = Int(remainingStr),
            let resetStr = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
            let resetTimestamp = Double(resetStr)
        else {
            return
        }

        rateLimit = GitHubRateLimit(
            limit: limit,
            remaining: remaining,
            resetDate: Date(timeIntervalSince1970: resetTimestamp)
        )
    }
}
