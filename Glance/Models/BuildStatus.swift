import SwiftUI

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
