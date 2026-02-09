import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        TabView {
            GeneralSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            RepoSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("Repositories", systemImage: "folder")
                }
        }
        .frame(width: 480, height: 340)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        Form {
            Section("GitHub Authentication") {
                SecureField("Personal Access Token", text: $viewModel.githubToken)
                    .textFieldStyle(.roundedBorder)

                Text("Generate a fine-grained token at github.com/settings/tokens with **Actions (read)** permission on your repos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !viewModel.githubToken.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Token configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let remaining = viewModel.rateLimitRemaining {
                            Text("· \(remaining) calls remaining")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if let reset = viewModel.rateLimitResetDate {
                            Text("· resets \(reset, style: .relative)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Polling") {
                Picker("Check every", selection: $viewModel.pollInterval) {
                    Text("15 seconds").tag(15.0)
                    Text("30 seconds").tag(30.0)
                    Text("60 seconds").tag(60.0)
                    Text("2 minutes").tag(120.0)
                    Text("5 minutes").tag(300.0)
                }

                Text("Uses conditional requests (ETag) so unchanged responses don't count against your rate limit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Notifications") {
                Text("You'll get a macOS notification when a build changes to **Passed** or **Failed**.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
}

// MARK: - Repos Tab

struct RepoSettingsTab: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var newRepoInput = ""
    @State private var inputError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monitored Repositories")
                .font(.headline)

            HStack {
                TextField("owner/repo", text: $newRepoInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addRepo() }

                Button("Add") { addRepo() }
                    .disabled(newRepoInput.isEmpty)
            }

            if let error = inputError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.monitoredRepos.isEmpty {
                VStack(spacing: 6) {
                    Text("No repositories added yet.")
                        .foregroundStyle(.secondary)
                    Text("Enter a repo in owner/repo format above.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.monitoredRepos) { repo in
                        HStack {
                            Image(systemName: "book.closed")
                                .foregroundStyle(.secondary)
                            Text(repo.fullName)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button {
                                viewModel.removeRepo(repo)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(20)
    }

    private func addRepo() {
        let parts = newRepoInput
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/")

        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            inputError = "Use the format: owner/repo (e.g. stuxf/gh-monitor)"
            return
        }

        inputError = nil
        viewModel.addRepo(fullName: newRepoInput)
        newRepoInput = ""
    }
}
