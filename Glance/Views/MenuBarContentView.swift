import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @Environment(\.dismiss) private var dismiss

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

