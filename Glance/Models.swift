import SwiftUI

// MARK: - Domain Models

enum BuildStatus: String, CaseIterable {
    case success
    case failure
    case running
    case queued
    case cancelled
    case unknown

    var icon: String {
        switch self {
        case .success:    return "checkmark.circle.fill"
        case .failure:    return "xmark.circle.fill"
        case .running:    return "arrow.triangle.2.circlepath"
        case .queued:     return "clock.fill"
        case .cancelled:  return "minus.circle.fill"
        case .unknown:    return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success:    return .green
        case .failure:    return .red
        case .running:    return .orange
        case .queued:     return .gray
        case .cancelled:  return .gray
        case .unknown:    return .secondary
        }
    }

    var label: String {
        switch self {
        case .success:    return "Passed"
        case .failure:    return "Failed"
        case .running:    return "Running"
        case .queued:     return "Queued"
        case .cancelled:  return "Cancelled"
        case .unknown:    return "Unknown"
        }
    }

    /// Map GitHub API status + conclusion to our domain model
    static func from(status: String?, conclusion: String?) -> BuildStatus {
        switch status {
        case "queued", "waiting", "requested", "pending":
            return .queued
        case "in_progress":
            return .running
        case "completed":
            switch conclusion {
            case "success":
                return .success
            case "failure", "timed_out", "action_required":
                return .failure
            case "cancelled", "skipped", "stale", "neutral":
                return .cancelled
            default:
                return .unknown
            }
        default:
            return .unknown
        }
    }
}

/// A monitored repository (user-configured)
struct MonitoredRepo: Identifiable, Codable, Equatable {
    var id: String { "\(owner)/\(name)" }
    let owner: String
    let name: String

    var fullName: String { "\(owner)/\(name)" }
}

/// A workflow run as displayed in the UI
struct WorkflowRun: Identifiable {
    let id: Int
    let repo: MonitoredRepo
    let workflowName: String
    let branch: String
    let status: BuildStatus
    let displayTitle: String
    let htmlUrl: String
    let updatedAt: Date
    let runNumber: Int

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}
