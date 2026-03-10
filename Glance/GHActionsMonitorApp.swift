import SwiftUI

@main
struct GHActionsMonitorApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Text("CI")
                if viewModel.hasNewActivity {
                    Circle()
                        .fill(.orange)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
