import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let environment = makeEnvironment()
        self.environment = environment
        environment.start()
        openRequestedUITestingSurface(environment)
    }

    func applicationWillTerminate(_ notification: Notification) {
        environment?.diagnosticsLogger.log("Application will terminate.")
        environment?.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        environment?.showSettings()
        return false
    }

    private func makeEnvironment() -> AppEnvironment {
        guard launchArguments.contains("--ui-testing"),
              let defaults = UserDefaults(suiteName: "MenuBarDeclutterUITests") else {
            return AppEnvironment()
        }

        defaults.removePersistentDomain(forName: "MenuBarDeclutterUITests")

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.hasCompletedOnboarding = true
        settingsStore.hasSeenDragHint = true
        settingsStore.launchAtLoginEnabled = false
        settingsStore.proModeEnabled = false
        settingsStore.accessibilityDiscoveryEnabled = false

        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("MenuBarDeclutterUITests", isDirectory: true)
        try? FileManager.default.removeItem(at: baseURL)

        return AppEnvironment(
            settingsStore: settingsStore,
            appSupportPaths: AppSupportPaths(baseURL: baseURL),
            reflectLaunchAtLoginOnStart: false,
            presentMigrationNoticeOnStart: false
        )
    }

    private func openRequestedUITestingSurface(_ environment: AppEnvironment) {
        guard launchArguments.contains("--ui-testing") else {
            return
        }

        if launchArguments.contains("--ui-testing-show-diagnostics") {
            environment.showDiagnostics()
        } else if launchArguments.contains("--ui-testing-show-privacy") {
            environment.showSettings(section: .privacy)
        } else if launchArguments.contains("--ui-testing-show-second-bar-settings") {
            environment.showSettings(section: .secondBar)
        } else if launchArguments.contains("--ui-testing-show-search") {
            environment.showSearch()
        } else if launchArguments.contains("--ui-testing-show-second-bar") {
            environment.showSecondBar()
        } else if launchArguments.contains("--ui-testing-show-settings") {
            environment.showSettings()
        }
    }

    private var launchArguments: Set<String> {
        Set(ProcessInfo.processInfo.arguments)
    }
}
