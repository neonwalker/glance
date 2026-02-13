import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        Form {
            Section("GitHub Authentication") {
                SecureField("Token", text: $viewModel.githubToken)
                    .textFieldStyle(.roundedBorder)

                if !viewModel.githubToken.isEmpty {
                    HStack(spacing: 4) {
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

            Section {
                Picker("Check every", selection: $viewModel.pollInterval) {
                    Text("15 seconds").tag(15.0)
                    Text("30 seconds").tag(30.0)
                    Text("60 seconds").tag(60.0)
                    Text("2 minutes").tag(120.0)
                    Text("5 minutes").tag(300.0)
                }
            }
        }
        .padding(20)
    }
}
