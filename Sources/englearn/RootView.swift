import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            ComposeView()
                .tabItem { Label("Write", systemImage: "square.and.pencil") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .frame(minWidth: 560, idealWidth: 600, minHeight: 640, idealHeight: 760)
    }
}
