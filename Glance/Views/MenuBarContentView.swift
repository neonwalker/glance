import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("collapsedRepos") private var collapsedReposRaw: String = ""

    private var collapsedRepos: Set<String> {
        Set(collapsedReposRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func isExpanded(_ id: String) -> Bool {
        !collapsedRepos.contains(id)
    }

    private func toggle(_ id: String) {
        var set = collapsedRepos
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        collapsedReposRaw = set.joined(separator: ",")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            statusBarView
            Divider()
            errorBannerView
            contentView
            Divider()
            footerView
        }
        .frame(width: 360)
        .onAppear {
            viewModel.clearNewActivity()
        }
    }

    private var headerView: some View {
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
    }

    @ViewBuilder
    private var statusBarView: some View {
        if let remaining = viewModel.rateLimitRemaining {
            HStack(spacing: 4) {
                Spacer()
                Text("\(remaining) calls left")
                if let reset = viewModel.rateLimitResetDate {
                    Text("·")
                    Text("resets in \(reset, style: .relative)")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    @ViewBuilder
    private var errorBannerView: some View {
        if let error = viewModel.lastError {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(error)
                    .font(.caption)
                    .lineLimit(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.1))

            Divider()
        }
    }

    @ViewBuilder
    private var contentView: some View {
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
        } else if viewModel.runsByRepo.isEmpty && !viewModel.isLoading {
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
                VStack(spacing: 0) {
                    ForEach(viewModel.runsByRepo) { group in
                        Button {
                            toggle(group.id)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isExpanded(group.id) ? "chevron.down" : "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 12)
                                Text(group.repo.fullName)
                                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if let status = group.latestStatus {
                                    Image(systemName: status.icon)
                                        .foregroundStyle(status.color)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if isExpanded(group.id) {
                            ForEach(group.runs) { run in
                                RunRowView(run: run)
                            }
                        }

                        Divider()
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 400)
        }
    }

    private var footerView: some View {
        HStack {
            SettingsLink {
                Text("Settings...")
                    .foregroundStyle(.blue)
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { dismiss() })

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
}
