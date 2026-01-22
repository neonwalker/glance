import SwiftUI

// MARK: - ViewModel

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var runs: [WorkflowRun] = []
    @Published var isLoading = false
    @Published var lastError: String?

    // Repo management
    @Published var monitoredRepos: [MonitoredRepo] = [] {
        didSet { saveRepos() }
    }

    // Settings (backed by UserDefaults)
    @AppStorage("githubToken") var githubToken: String = ""
    @AppStorage("pollInterval") var pollInterval: Double = 30

    private let service = GitHubService()
    private static let reposKey = "monitoredRepos"

    init() {
        loadRepos()
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
}
