import SwiftUI

@main
struct GHActionsMonitorApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.startPolling()
                }
                .onDisappear {
                    // Keep polling even when popover is closed
                }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.overallStatusIcon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(viewModel.overallStatusColor)
                Text("CI")
                    .font(.caption)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
