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
        } label: {
            Label("CI", systemImage: "hammer.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
