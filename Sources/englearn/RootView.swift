import SwiftUI

enum RootContext {
    case window
    case menuBar
}

private enum AppSection: String, CaseIterable, Identifiable {
    case write
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .write: "Write"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .write: "square.and.pencil"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let context: RootContext
    @State private var section: AppSection = .write

    var body: some View {
        switch context {
        case .menuBar:
            TabView {
                ComposeView()
                    .tabItem { Label("Write", systemImage: "square.and.pencil") }

                HistoryView()
                    .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
            .frame(minWidth: 560, idealWidth: 600, minHeight: 640, idealHeight: 760)
            .padding(.top, 4)

        case .window:
            NavigationSplitView {
                List(selection: $section) {
                    ForEach(AppSection.allCases) { item in
                        Label(item.title, systemImage: item.systemImage)
                            .tag(item)
                    }
                }
                .navigationTitle("Englearn")
                .frame(minWidth: 220)
            } detail: {
                Group {
                    switch section {
                    case .write:
                        ComposeView()
                    case .history:
                        HistoryView()
                    case .settings:
                        SettingsView()
                    }
                }
                .navigationTitle(section.title)
            }
            .navigationSplitViewStyle(.balanced)
        }
    }
}
