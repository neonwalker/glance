import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(.secondary)
                Text("GH Actions Monitor")
                    .font(.headline)
                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Status bar
            HStack(spacing: 8) {
                Spacer()
                if let remaining = viewModel.rateLimitRemaining {
                    Text("\(remaining) API calls left")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            Divider()

            // Content
            if viewModel.monitoredRepos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No repos monitored")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("Add repos in Settings")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else if viewModel.runs.isEmpty && !viewModel.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No recent runs")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.runs) { run in
                            RunRowView(run: run)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 360)
            }

            Divider()

            // Footer
            HStack {
                SettingsLink {
                    Text("Settings...")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 360)
    }
}

// MARK: - Single workflow run row

struct RunRowView: View {
    let run: WorkflowRun
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: run.status.icon)
                .font(.system(size: 16))
                .foregroundStyle(run.status.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.repo.fullName)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(run.branch, systemImage: "arrow.branch")
                    Text("·")
                    Text(run.workflowName)
                    Text("·")
                    Text(run.timeAgo)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if !run.displayTitle.isEmpty {
                    Text(run.displayTitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(run.status.label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(run.status.color.opacity(0.15))
                .foregroundStyle(run.status.color)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if let url = URL(string: run.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
