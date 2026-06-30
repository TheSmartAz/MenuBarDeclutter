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

        let shouldSeedMenuBarItems = launchArguments.contains("--ui-testing-seed-menu-bar-items")
        let shouldSeedGroups = launchArguments.contains("--ui-testing-seed-groups")

        if shouldSeedGroups {
            seedIconGroupsUITestingStore(environment)
        }

        if launchArguments.contains("--ui-testing-show-diagnostics") {
            environment.showDiagnostics()
        } else if launchArguments.contains("--ui-testing-show-general") {
            environment.showSettings(section: .general)
        } else if launchArguments.contains("--ui-testing-show-behavior") {
            environment.showSettings(section: .behavior)
        } else if launchArguments.contains("--ui-testing-show-layout") {
            environment.showSettings(section: .layout)
        } else if launchArguments.contains("--ui-testing-show-privacy") {
            environment.showSettings(section: .privacy)
        } else if launchArguments.contains("--ui-testing-show-private-access") {
            environment.showSettings(section: .privateAccess)
        } else if launchArguments.contains("--ui-testing-show-menu-bar-items") {
            environment.showSettings(section: .menuBarItems)
        } else if launchArguments.contains("--ui-testing-show-second-bar-settings") {
            environment.showSettings(section: .secondBar)
        } else if launchArguments.contains("--ui-testing-show-groups") {
            environment.showSettings(section: .groups)
        } else if launchArguments.contains("--ui-testing-show-hotkeys") {
            environment.showSettings(section: .hotkeys)
        } else if launchArguments.contains("--ui-testing-show-profiles") {
            environment.showSettings(section: .profiles)
        } else if launchArguments.contains("--ui-testing-show-automation") {
            environment.showSettings(section: .automation)
        } else if launchArguments.contains("--ui-testing-show-import-export") {
            environment.showSettings(section: .importExport)
        } else if launchArguments.contains("--ui-testing-show-advanced") {
            environment.showSettings(section: .advanced)
        } else if launchArguments.contains("--ui-testing-show-search") {
            environment.showSearch()
        } else if launchArguments.contains("--ui-testing-show-second-bar") {
            environment.settingsStore.secondBarCloseOnOutsideClick = false
            environment.showSecondBar()
        } else if launchArguments.contains("--ui-testing-show-group-panel") {
            seedMenuBarItemsUITestingSnapshot(environment)
            environment.showGroupPanel(makeUITestingIconGroup())
        } else if launchArguments.contains("--ui-testing-show-settings") {
            environment.showSettings()
        }

        if shouldSeedMenuBarItems {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                seedMenuBarItemsUITestingSnapshot(environment)
            }
        }
    }

    private func seedMenuBarItemsUITestingSnapshot(_ environment: AppEnvironment) {
        let scanTimestamp = Date()
        let snapshots = [
            MenuBarItemSnapshot(
                id: "ui-test-control-center",
                title: "Control Center",
                role: "AXMenuBarItem",
                subrole: nil,
                frame: CGRect(x: 1466, y: 0, width: 26, height: 24),
                owningProcessIdentifier: 101,
                owningApplicationName: "Control Center",
                bundleIdentifier: "com.apple.controlcenter",
                zone: .visible,
                isLikelySystemItem: true,
                scanTimestamp: scanTimestamp
            ),
            MenuBarItemSnapshot(
                id: "ui-test-wifi",
                title: "Wi-Fi",
                role: "AXMenuBarItem",
                subrole: nil,
                frame: CGRect(x: 1432, y: 0, width: 28, height: 24),
                owningProcessIdentifier: 101,
                owningApplicationName: "Control Center",
                bundleIdentifier: "com.apple.controlcenter",
                zone: .visible,
                isLikelySystemItem: true,
                scanTimestamp: scanTimestamp
            ),
            MenuBarItemSnapshot(
                id: "ui-test-calendar",
                title: "Calendar",
                role: "AXMenuBarItem",
                subrole: nil,
                frame: CGRect(x: 1344, y: 0, width: 31, height: 24),
                owningProcessIdentifier: 502,
                owningApplicationName: "Fantastical",
                bundleIdentifier: "com.flexibits.fantastical2.mac",
                zone: .hidden,
                isLikelySystemItem: false,
                scanTimestamp: scanTimestamp
            ),
            MenuBarItemSnapshot(
                id: "ui-test-sync",
                title: "Sync",
                role: "AXMenuBarItem",
                subrole: "AXUnknown",
                frame: CGRect(x: 1296, y: 0, width: 29, height: 24),
                owningProcessIdentifier: 744,
                owningApplicationName: "Dropbox",
                bundleIdentifier: "com.getdropbox.dropbox",
                zone: .hidden,
                isLikelySystemItem: false,
                scanTimestamp: scanTimestamp
            ),
            MenuBarItemSnapshot(
                id: "ui-test-vpn",
                title: "VPN",
                role: "AXMenuBarItem",
                subrole: nil,
                frame: CGRect(x: 1238, y: 0, width: 26, height: 24),
                owningProcessIdentifier: 881,
                owningApplicationName: "Tailscale",
                bundleIdentifier: "io.tailscale.ipn.macos",
                zone: .alwaysHidden,
                isLikelySystemItem: false,
                scanTimestamp: scanTimestamp
            ),
            MenuBarItemSnapshot(
                id: "ui-test-unknown",
                title: nil,
                role: "AXMenuBarItem",
                subrole: nil,
                frame: nil,
                owningProcessIdentifier: nil,
                owningApplicationName: nil,
                bundleIdentifier: nil,
                zone: .unknown,
                isLikelySystemItem: false,
                scanTimestamp: scanTimestamp
            )
        ]
        let result = MenuBarScanResult(
            snapshots: snapshots,
            scanTimestamp: scanTimestamp,
            axFailuresCount: 0
        )

        environment.liveStatus.accessibilityPermissionStatus = .granted
        environment.liveStatus.scannedMenuBarItems = result.snapshots
        environment.liveStatus.lastMenuBarScanTime = result.scanTimestamp
        environment.liveStatus.menuBarScanFailuresCount = result.axFailuresCount
        environment.liveStatus.menuBarScanVisibleCount = result.visibleCount
        environment.liveStatus.menuBarScanHiddenCount = result.hiddenCount
        environment.liveStatus.menuBarScanAlwaysHiddenCount = result.alwaysHiddenCount
        environment.liveStatus.menuBarScanUnknownCount = result.unknownCount
        environment.liveStatus.searchIndexItemCount = result.snapshots.count
        environment.diagnosticsLogger.log(
            "Seeded UI testing menu bar item snapshot with \(result.snapshots.count) items."
        )
    }

    private func seedIconGroupsUITestingStore(_ environment: AppEnvironment) {
        let directory = environment.appSupportPaths.applicationSupportDirectory
            .appendingPathComponent("Groups", isDirectory: true)
        let fileURL = directory.appendingPathComponent("groups.json")
        let groups = makeUITestingIconGroups()

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let container = IconGroupContainer(
                schemaVersion: IconGroupStore.schemaVersion,
                groups: groups
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(container).write(to: fileURL, options: .atomic)

            environment.diagnosticsLogger.log(
                "Seeded UI testing group store with \(groups.count) groups."
            )
        } catch {
            environment.diagnosticsLogger.log(
                "Failed to seed UI testing group store: \(error.localizedDescription)",
                level: .warning,
                category: .layout
            )
        }
    }

    private func makeUITestingIconGroups() -> [IconGroup] {
        var focusApps = makeUITestingIconGroup()
        focusApps.colorName = "blue"
        focusApps.showAsStatusItem = true

        let systemItems = IconGroup(
            id: UUID(uuidString: "63FE86A1-6551-4A83-A2E4-8F1B7B2D6A3F") ?? UUID(),
            name: "System Essentials",
            symbolName: "switch.2",
            colorName: "green",
            isProtected: true,
            showInSecondBar: false,
            itemRefs: [
                IconGroupItemRef(
                    bundleIdentifier: "com.apple.controlcenter",
                    appName: "Control Center",
                    titleContains: "Wi-Fi",
                    manualLabel: "Wi-Fi"
                ),
                IconGroupItemRef(
                    bundleIdentifier: "com.apple.controlcenter",
                    appName: "Control Center",
                    titleContains: "Control Center",
                    manualLabel: "Control Center"
                )
            ]
        )

        let quietSync = IconGroup(
            id: UUID(uuidString: "F4098F79-721F-4F8D-BC52-B83A5DCE29F4") ?? UUID(),
            name: "Quiet Sync",
            symbolName: "arrow.triangle.2.circlepath",
            colorName: "orange",
            isEnabled: false,
            itemRefs: [
                IconGroupItemRef(
                    bundleIdentifier: "com.getdropbox.dropbox",
                    appName: "Dropbox",
                    manualLabel: "Dropbox Sync"
                ),
                IconGroupItemRef(
                    bundleIdentifier: "com.example.missing",
                    manualLabel: "Missing Helper"
                )
            ]
        )

        return [focusApps, systemItems, quietSync]
    }

    private func makeUITestingIconGroup() -> IconGroup {
        IconGroup(
            id: UUID(uuidString: "8C5B7B19-9E0A-46C9-A1A7-E7B4D9E8A114") ?? UUID(),
            name: "Focus Apps",
            symbolName: "folder",
            itemRefs: [
                IconGroupItemRef(
                    bundleIdentifier: "com.flexibits.fantastical2.mac",
                    manualLabel: "Calendar"
                ),
                IconGroupItemRef(
                    bundleIdentifier: "com.getdropbox.dropbox",
                    manualLabel: "Sync"
                ),
                IconGroupItemRef(
                    bundleIdentifier: "io.tailscale.ipn.macos",
                    manualLabel: "VPN"
                )
            ]
        )
    }

    private var launchArguments: Set<String> {
        Set(ProcessInfo.processInfo.arguments)
    }
}
