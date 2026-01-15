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
