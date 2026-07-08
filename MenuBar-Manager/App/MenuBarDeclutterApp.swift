import SwiftUI

@main
struct MenuBarDeclutterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.showSettingsFromAppMenu()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
