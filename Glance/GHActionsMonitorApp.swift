import SwiftUI

@main
struct GHActionsMonitorApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
        } label: {
            if viewModel.hasNewActivity {
                Image(systemName: "hammer.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.primary, .orange)
            } else {
                Image(systemName: "hammer")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
