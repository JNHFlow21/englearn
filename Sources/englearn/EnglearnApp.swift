import SwiftUI

@main
struct Thought2EnglishApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("Thought2English") {
            RootView(context: .window)
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 720)
        }

        MenuBarExtra("Thought2English", systemImage: "text.bubble") {
            RootView(context: .menuBar)
                .environmentObject(viewModel)
                .frame(minWidth: 560, minHeight: 640)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Open Thought2English") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("o")
            }
            CommandGroup(replacing: .appTermination) {
                Button("Quit Thought2English") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
    }
}
