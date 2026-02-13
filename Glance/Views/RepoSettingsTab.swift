import SwiftUI

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
            inputError = "Use the format: owner/repo (e.g. neonwalker/glance)"
            return
        }

        inputError = nil
        viewModel.addRepo(fullName: newRepoInput)
        newRepoInput = ""
    }
}
