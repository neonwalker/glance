import SwiftUI
import UserNotifications
internal import Combine

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var runs: [WorkflowRun] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var rateLimitRemaining: Int?
    @Published var rateLimitResetDate: Date?

    @Published var monitoredRepos: [MonitoredRepo] = [] {
        didSet { saveRepos() }
    }

    @AppStorage("githubToken") var githubToken: String = ""
    @AppStorage("pollInterval") var pollInterval: Double = 30

    private let service = GitHubService()
    private var pollingTask: Task<Void, Never>?
    private var previousStatuses: [String: BuildStatus] = [:]
    private static let reposKey = "monitoredRepos"

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFormatterFallback = ISO8601DateFormatter()

    init() {
        loadRepos()
        requestNotificationPermission()
        startPolling()
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(pollInterval))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Refresh

    func refresh() async {
        guard !githubToken.isEmpty else {
            lastError = "No GitHub token configured. Open Settings."
            return
        }
        guard !monitoredRepos.isEmpty else {
            lastError = nil
            runs = []
            return
        }

        isLoading = true
        lastError = nil

        var allRuns: [WorkflowRun] = []

        for repo in monitoredRepos {
            do {
                let apiRuns = try await service.fetchWorkflowRuns(
                    owner: repo.owner,
                    repo: repo.name,
                    token: githubToken,
                    perPage: 10
                )
                allRuns.append(contentsOf: apiRuns.map { mapRun($0, for: repo) })
            } catch {
                print("Error fetching \(repo.fullName): \(error.localizedDescription)")
                lastError = error.localizedDescription
            }
        }

        allRuns.sort { a, b in
            let aPriority = (a.status == .running || a.status == .queued) ? 0 : 1
            let bPriority = (b.status == .running || b.status == .queued) ? 0 : 1
            if aPriority != bPriority { return aPriority < bPriority }
            return a.updatedAt > b.updatedAt
        }

        for run in allRuns {
            let key = "\(run.repo.fullName):\(run.workflowName):\(run.runNumber)"
            if let previous = previousStatuses[key], previous != run.status {
                sendNotification(run: run, previousStatus: previous)
            }
            previousStatuses[key] = run.status
        }

        if let rl = await service.rateLimit {
            rateLimitRemaining = rl.remaining
            rateLimitResetDate = rl.resetDate
        }

        self.runs = allRuns
        self.isLoading = false
    }

    private func mapRun(_ run: GitHubWorkflowRun, for repo: MonitoredRepo) -> WorkflowRun {
        let updatedDate = Self.isoFormatter.date(from: run.updatedAt)
            ?? Self.isoFormatterFallback.date(from: run.updatedAt)
            ?? Date()

        return WorkflowRun(
            id: run.id,
            repo: repo,
            workflowName: run.name ?? "Workflow",
            branch: run.headBranch ?? "unknown",
            status: BuildStatus.from(status: run.status, conclusion: run.conclusion),
            displayTitle: run.displayTitle ?? "Run #\(run.runNumber)",
            htmlUrl: run.htmlUrl,
            updatedAt: updatedDate,
            runNumber: run.runNumber
        )
    }

    // MARK: - Repo Management

    func addRepo(owner: String, name: String) {
        let repo = MonitoredRepo(owner: owner.trimmingCharacters(in: .whitespaces),
                                  name: name.trimmingCharacters(in: .whitespaces))
        guard !monitoredRepos.contains(repo) else { return }
        monitoredRepos.append(repo)
    }

    func addRepo(fullName: String) {
        let normalised = fullName
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = normalised.split(separator: "/")
        guard parts.count == 2 else { return }
        addRepo(owner: String(parts[0]), name: String(parts[1]))
    }

    func removeRepo(_ repo: MonitoredRepo) {
        monitoredRepos.removeAll { $0 == repo }
    }

    // MARK: - Overall Status (for menu bar icon)

    var overallStatus: BuildStatus? {
        guard !runs.isEmpty else { return nil }
        if runs.contains(where: { $0.status == .failure }) { return .failure }
        if runs.contains(where: { $0.status == .running }) { return .running }
        if runs.contains(where: { $0.status == .queued }) { return .queued }
        return .success
    }

    var overallStatusIcon: String {
        switch overallStatus {
        case .failure:  return "xmark.circle.fill"
        case .running:  return "arrow.triangle.2.circlepath"
        case .queued:   return "clock.fill"
        case .success:  return "checkmark.circle.fill"
        default:        return "circle.dashed"
        }
    }

    var overallStatusColor: Color {
        switch overallStatus {
        case .failure:  return .red
        case .running:  return .orange
        case nil:       return .secondary
        default:        return .green
        }
    }

    // MARK: - Persistence

    private func saveRepos() {
        if let data = try? JSONEncoder().encode(monitoredRepos) {
            UserDefaults.standard.set(data, forKey: Self.reposKey)
        }
    }

    private func loadRepos() {
        guard let data = UserDefaults.standard.data(forKey: Self.reposKey),
              let repos = try? JSONDecoder().decode([MonitoredRepo].self, from: data)
        else { return }
        self.monitoredRepos = repos
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(run: WorkflowRun, previousStatus: BuildStatus) {
        let content = UNMutableNotificationContent()

        switch run.status {
        case .success:
            content.title = "Build Passed"
            content.body = "\(run.repo.fullName) — \(run.workflowName) #\(run.runNumber)"
        case .failure:
            content.title = "Build Failed"
            content.body = "\(run.repo.fullName) — \(run.workflowName) #\(run.runNumber)"
            content.sound = .default
        default:
            return
        }

        let request = UNNotificationRequest(
            identifier: "run-\(run.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
