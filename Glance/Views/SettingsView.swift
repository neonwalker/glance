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
