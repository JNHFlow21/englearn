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
    @Environment(\.colorScheme) private var colorScheme
    let context: RootContext
    @State private var selectedSectionId: String? = AppSection.write.id

    private var selectedSection: AppSection {
        AppSection(rawValue: selectedSectionId ?? "") ?? .write
    }

    var body: some View {
        switch context {
        case .menuBar:
            ZStack {
                Theme.Colors.pageBackgroundView(colorScheme)
                    .ignoresSafeArea()

                TabView {
                    ComposeView()
                        .tabItem { Label("Write", systemImage: "square.and.pencil") }

                    HistoryView(layout: .menuBar)
                        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .frame(minWidth: 560, idealWidth: 600, minHeight: 640, idealHeight: 760)
                .padding(.top, 4)
            }

        case .window:
            ZStack {
                Theme.Colors.pageBackgroundView(colorScheme)
                    .ignoresSafeArea()

                NavigationSplitView {
                    List(selection: $selectedSectionId) {
                        ForEach(AppSection.allCases) { item in
                            Label(item.title, systemImage: item.systemImage)
                                .tag(item.id)
                        }
                    }
                    .navigationTitle("Englearn")
                    .frame(minWidth: 220)
                } detail: {
                    Group {
                        switch selectedSection {
                        case .write:
                            ComposeView()
                        case .history:
                            HistoryView(layout: .window)
                        case .settings:
                            SettingsView()
                        }
                    }
                    .navigationTitle(selectedSection.title)
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
    }
}
