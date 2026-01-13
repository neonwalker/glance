import SwiftUI

@main
struct GHActionsMonitorApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("Glance")
                .padding()
        } label: {
            Label("CI", systemImage: "hammer.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
