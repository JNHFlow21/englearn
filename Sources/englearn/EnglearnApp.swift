import SwiftUI

@main
struct EnglearnApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("Englearn") {
            RootView(context: .window)
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 720)
        }

        MenuBarExtra("Englearn", systemImage: "text.bubble") {
            RootView(context: .menuBar)
                .environmentObject(viewModel)
                .frame(minWidth: 560, minHeight: 640)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Open Englearn") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("o")
            }
            CommandGroup(replacing: .appTermination) {
                Button("Quit Englearn") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
    }
}
