import Foundation

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
