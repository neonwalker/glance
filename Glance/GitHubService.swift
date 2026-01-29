import Foundation

// MARK: - GitHub API Response Models (Codable)

struct GitHubWorkflowRunsResponse: Codable {
    let totalCount: Int
    let workflowRuns: [GitHubWorkflowRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }
}

struct GitHubWorkflowRun: Codable {
    let id: Int
    let name: String?
    let headBranch: String?
    let headSha: String
    let status: String?
    let conclusion: String?
    let htmlUrl: String
    let displayTitle: String?
    let event: String?
    let createdAt: String
    let updatedAt: String
    let runNumber: Int

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion, event
        case headBranch = "head_branch"
        case headSha = "head_sha"
        case htmlUrl = "html_url"
        case displayTitle = "display_title"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case runNumber = "run_number"
    }
}

// MARK: - Rate Limit Tracking

struct GitHubRateLimit {
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

        let urlString = "\(baseURL)/repos/\(owner)/\(repo)/actions/runs?per_page=\(perPage)"

        guard let url = URL(string: urlString) else {
            throw GitHubServiceError.httpError(statusCode: 0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")

        // Attach ETag for conditional request (saves rate limit if unchanged)
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
            // Not Modified — return cached response
            if let cached = responseCache[urlString] {
                return cached.workflowRuns
            }
            return []

        case 401:
            throw GitHubServiceError.invalidToken

        default:
            throw GitHubServiceError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
