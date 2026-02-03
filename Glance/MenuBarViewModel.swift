import SwiftUI
import UserNotifications
internal import Combine

// MARK: - ViewModel

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var runs: [WorkflowRun] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastRefresh: Date?
    @Published var rateLimitRemaining: Int?

    // Repo management
    @Published var monitoredRepos: [MonitoredRepo] = [] {
        didSet { saveRepos() }
    }

    // Settings (backed by UserDefaults)
    @AppStorage("githubToken") var githubToken: String = ""
    @AppStorage("pollInterval") var pollInterval: Double = 30

    private let service = GitHubService()
    private var pollingTask: Task<Void, Never>?
    private var previousStatuses: [String: BuildStatus] = []
    private static let reposKey = "monitoredRepos"

    init() {
        loadRepos()
        requestNotificationPermission()
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
                    perPage: 3
                )

                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                let mapped: [WorkflowRun] = apiRuns.map { run in
                    let updatedDate = iso.date(from: run.updatedAt)
                        ?? ISO8601DateFormatter().date(from: run.updatedAt)
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

                allRuns.append(contentsOf: mapped)
            } catch {
                print("Error fetching \(repo.fullName): \(error.localizedDescription)")
                lastError = error.localizedDescription
            }
        }

        // Sort: running/queued first, then by most recent
        allRuns.sort { a, b in
            let aPriority = (a.status == .running || a.status == .queued) ? 0 : 1
            let bPriority = (b.status == .running || b.status == .queued) ? 0 : 1
            if aPriority != bPriority { return aPriority < bPriority }
            return a.updatedAt > b.updatedAt
        }

        // Check for status changes → send notifications
        for run in allRuns {
            let key = "\(run.repo.fullName):\(run.workflowName):\(run.runNumber)"
            if let previous = previousStatuses[key], previous != run.status {
                sendNotification(run: run, previousStatus: previous)
            }
            previousStatuses[key] = run.status
        }

        if let rl = await service.rateLimit {
            rateLimitRemaining = rl.remaining
        }

        self.runs = allRuns
        self.lastRefresh = Date()
        self.isLoading = false
    }

    // MARK: - Repo Management

    func addRepo(owner: String, name: String) {
        let repo = MonitoredRepo(owner: owner.trimmingCharacters(in: .whitespaces),
                                  name: name.trimmingCharacters(in: .whitespaces))
        guard !monitoredRepos.contains(repo) else { return }
        monitoredRepos.append(repo)
    }

    func addRepo(fullName: String) {
        let parts = fullName.split(separator: "/")
        guard parts.count == 2 else { return }
        addRepo(owner: String(parts[0]), name: String(parts[1]))
    }

    func removeRepo(_ repo: MonitoredRepo) {
        monitoredRepos.removeAll { $0 == repo }
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
