import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var environment: AppEnvironment?
    private var launchKeepAliveStatusItem: NSStatusItem?
    private var uiTestingAccessibilityTrustOverride: UITestingAccessibilityTrustOverride?

    func applicationWillFinishLaunching(_ notification: Notification) {
        applyUITestingAppearanceOverride()
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("MenuBarDeclutter keeps menu bar status items active.")
        installLaunchKeepAliveStatusItem()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("MenuBarDeclutter keeps menu bar status items active.")

        let environment = makeEnvironment()
        self.environment = environment
        guard !isHostedUnitTestingLaunch else {
            environment.start()
            releaseLaunchKeepAliveStatusItemAfterStartup()
            return
        }

        seedRequestedUITestingPersistentStores(environment)
        environment.start()
        releaseLaunchKeepAliveStatusItemAfterStartup()
        applyPostStartupUITestingPermissionOverrides(environment)
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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func makeEnvironment() -> AppEnvironment {
        if isHostedUnitTestingLaunch {
            return makeHostedUnitTestingEnvironment()
        }

        guard launchArguments.contains("--ui-testing"),
              let defaults = UserDefaults(suiteName: "MenuBarDeclutterUITests") else {
            return AppEnvironment()
        }

        defaults.removePersistentDomain(forName: "MenuBarDeclutterUITests")

        let settingsStore = SettingsStore(defaults: defaults)
        let proDiscoveryEnabled = launchArguments.contains("--ui-testing-pro-discovery-enabled")
        let accessibilityGranted = launchArguments.contains("--ui-testing-accessibility-granted")
        let accurateIconsEnabled = launchArguments.contains("--ui-testing-accurate-icons-enabled")
        let screenCaptureGranted = launchArguments.contains("--ui-testing-screen-capture-granted")
        let secondBarPrimaryClickEnabled = launchArguments.contains("--ui-testing-second-bar-primary-click-enabled")
        let hideStatusShortcuts = launchArguments.contains("--ui-testing-hide-status-shortcuts")
        let useSystemAccessibility = launchArguments.contains("--ui-testing-use-system-accessibility")
        settingsStore.hasCompletedOnboarding = true
        settingsStore.hasSeenDragHint = true
        settingsStore.launchAtLoginEnabled = false
        settingsStore.proModeEnabled = false
        settingsStore.accessibilityDiscoveryEnabled = false
        settingsStore.secondBarPrimaryClickEnabled = false

        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("MenuBarDeclutterUITests", isDirectory: true)
        try? FileManager.default.removeItem(at: baseURL)

        let screenCapturePermissionService = ScreenCapturePermissionService(
            preflightAccess: { screenCaptureGranted },
            requestAccess: { screenCaptureGranted },
            systemSettingsOpener: { false }
        )
        let accessibilityTrustOverride = UITestingAccessibilityTrustOverride(isGranted: accessibilityGranted)
        uiTestingAccessibilityTrustOverride = accessibilityTrustOverride

        let environment: AppEnvironment
        if useSystemAccessibility {
            environment = AppEnvironment(
                settingsStore: settingsStore,
                appSupportPaths: AppSupportPaths(baseURL: baseURL),
                screenCapturePermissionService: screenCapturePermissionService,
                reflectLaunchAtLoginOnStart: false,
                presentMigrationNoticeOnStart: false
            )
        } else {
            environment = AppEnvironment(
                settingsStore: settingsStore,
                appSupportPaths: AppSupportPaths(baseURL: baseURL),
                screenCapturePermissionService: screenCapturePermissionService,
                reflectLaunchAtLoginOnStart: false,
                presentMigrationNoticeOnStart: false,
                accessibilityTrustProvider: { accessibilityTrustOverride.isGranted },
                accessibilityPromptTrustProvider: { accessibilityTrustOverride.isGranted },
                accessibilitySystemSettingsOpener: { false }
            )
        }

        if proDiscoveryEnabled {
            settingsStore.proModeEnabled = true
            settingsStore.accessibilityDiscoveryEnabled = true
        }
        if accurateIconsEnabled {
            settingsStore.renderedIconCaptureEnabled = true
        }
        if secondBarPrimaryClickEnabled {
            settingsStore.secondBarPrimaryClickEnabled = true
        }
        if hideStatusShortcuts {
            settingsStore.searchEnabled = false
            settingsStore.secondBarEnabled = false
            settingsStore.secondBarPrimaryClickEnabled = false
        }

        return environment
    }

    private func applyPostStartupUITestingPermissionOverrides(_ environment: AppEnvironment) {
        guard launchArguments.contains("--ui-testing-accessibility-revoked-after-launch"),
              let uiTestingAccessibilityTrustOverride else {
            return
        }

        uiTestingAccessibilityTrustOverride.isGranted = false
        environment.accessibilityPermissionService.markStale()
        environment.liveStatus.accessibilityPermissionStatus = environment.accessibilityPermissionService.refreshStatus()
    }

    private func applyUITestingAppearanceOverride() {
        guard launchArguments.contains("--ui-testing") else { return }

        if launchArguments.contains("--ui-testing-appearance-light") {
            NSApp.appearance = NSAppearance(named: .aqua)
        } else if launchArguments.contains("--ui-testing-appearance-dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func installLaunchKeepAliveStatusItem() {
        guard launchKeepAliveStatusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: 0)
        item.button?.toolTip = "MenuBarDeclutter"
        launchKeepAliveStatusItem = item
    }

    private func releaseLaunchKeepAliveStatusItemAfterStartup() {
        guard launchKeepAliveStatusItem != nil else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let statusItem = self.launchKeepAliveStatusItem else {
                return
            }
            NSStatusBar.system.removeStatusItem(statusItem)
            self.launchKeepAliveStatusItem = nil
        }
    }

    private func makeHostedUnitTestingEnvironment() -> AppEnvironment {
        let suiteName = "MenuBarDeclutterHostedUnitTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.hasCompletedOnboarding = true
        settingsStore.hasSeenDragHint = true
        settingsStore.launchAtLoginEnabled = false
        settingsStore.proModeEnabled = false
        settingsStore.accessibilityDiscoveryEnabled = false
        settingsStore.secondBarPrimaryClickEnabled = false

        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("MenuBarDeclutterHostedUnitTests-\(UUID().uuidString)", isDirectory: true)

        return AppEnvironment(
            settingsStore: settingsStore,
            appSupportPaths: AppSupportPaths(baseURL: baseURL),
            reflectLaunchAtLoginOnStart: false,
            presentMigrationNoticeOnStart: false,
            accessibilityTrustProvider: { false },
            accessibilityPromptTrustProvider: { false },
            accessibilitySystemSettingsOpener: { false }
        )
    }

    private func openRequestedUITestingSurface(_ environment: AppEnvironment) {
        guard launchArguments.contains("--ui-testing") else {
            return
        }

        let shouldSeedMenuBarItems = launchArguments.contains("--ui-testing-seed-menu-bar-items")
        let shouldSeedRenderedIcons = launchArguments.contains("--ui-testing-seed-rendered-icons")
        let shouldSeedPartialRenderedIcons = launchArguments.contains("--ui-testing-seed-partial-rendered-icons")
        let renderedIconSeedIDs: Set<MenuBarItemSnapshot.ID>
        if shouldSeedRenderedIcons {
            renderedIconSeedIDs = [
                "ui-test-calendar",
                "ui-test-sync"
            ]
        } else if shouldSeedPartialRenderedIcons {
            renderedIconSeedIDs = [
                "ui-test-calendar"
            ]
        } else {
            renderedIconSeedIDs = []
        }

        if launchArguments.contains("--ui-testing-show-onboarding-privacy") {
            environment.showOnboarding(stepID: "privacy")
        } else if launchArguments.contains("--ui-testing-show-onboarding") {
            environment.showOnboarding()
        } else if launchArguments.contains("--ui-testing-show-diagnostics") {
            environment.showDiagnostics()
        } else if launchArguments.contains("--ui-testing-show-settings-search-privacy") {
            environment.showSettings(section: .general, searchText: "privacy")
        } else if launchArguments.contains("--ui-testing-show-general") {
            environment.showSettings(section: .general)
        } else if launchArguments.contains("--ui-testing-show-hide-reveal") {
            environment.showSettings(section: .hideReveal)
        } else if launchArguments.contains("--ui-testing-show-arrange") {
            environment.showSettings(section: .arrange)
        } else if launchArguments.contains("--ui-testing-show-find-rescue") {
            environment.showSettings(section: .findRescue)
        } else if launchArguments.contains("--ui-testing-show-workspaces") {
            environment.showSettings(section: .workspacesPreview)
        } else if launchArguments.contains("--ui-testing-show-recovery") {
            environment.showSettings(section: .recovery)
        } else if launchArguments.contains("--ui-testing-show-behavior") {
            environment.showSettings(section: .behavior)
        } else if launchArguments.contains("--ui-testing-show-layout") {
            environment.showSettings(section: .layout)
        } else if launchArguments.contains("--ui-testing-show-search-settings") {
            environment.showSettings(section: .search)
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
            if shouldSeedMenuBarItems {
                seedMenuBarItemsUITestingSnapshot(environment)
            }
            environment.showSearch()
        } else if launchArguments.contains("--ui-testing-show-second-bar") {
            if shouldSeedMenuBarItems {
                seedMenuBarItemsUITestingSnapshot(environment)
            }
            environment.settingsStore.secondBarCloseOnOutsideClick = false
            environment.showSecondBar()
        } else if launchArguments.contains("--ui-testing-show-compact-second-bar") {
            if shouldSeedMenuBarItems {
                seedMenuBarItemsUITestingSnapshot(environment)
            }
            if !renderedIconSeedIDs.isEmpty {
                environment.seedRenderedIconsForUITesting(itemIDs: renderedIconSeedIDs)
            }
            environment.showCompactSecondBarForUITesting()
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
                if !renderedIconSeedIDs.isEmpty {
                    environment.seedRenderedIconsForUITesting(itemIDs: renderedIconSeedIDs)
                }
            }
        }
    }

    private func seedRequestedUITestingPersistentStores(_ environment: AppEnvironment) {
        guard launchArguments.contains("--ui-testing") else {
            return
        }

        if launchArguments.contains("--ui-testing-enable-workspace-panels") {
            environment.prepareWorkspacePanelUITestingState()
        }

        if launchArguments.contains("--ui-testing-seed-profiles") {
            seedProfilesUITestingStore(environment)
        }

        if launchArguments.contains("--ui-testing-seed-groups") {
            seedIconGroupsUITestingStore(environment)
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

    private func seedProfilesUITestingStore(_ environment: AppEnvironment) {
        let profiles = makeUITestingProfiles()
        let triggers = makeUITestingTriggers(profileIDs: profiles.map(\.id))

        do {
            try environment.appSupportPaths.ensureDirectoriesExist()

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            for profile in profiles {
                let url = environment.appSupportPaths.profilesDirectory
                    .appendingPathComponent("\(profile.id.uuidString).json")
                try encoder.encode(profile).write(to: url, options: .atomic)
            }

            let triggersURL = environment.appSupportPaths.profilesDirectory
                .appendingPathComponent(TriggerService.storageFilename)
            try encoder.encode(triggers).write(to: triggersURL, options: .atomic)

            environment.settingsStore.smartTriggersEnabled = true
            environment.settingsStore.automationPaused = false
            environment.diagnosticsLogger.log(
                "Seeded UI testing profile store with \(profiles.count) profiles and \(triggers.count) triggers."
            )
        } catch {
            environment.diagnosticsLogger.log(
                "Failed to seed UI testing profile store: \(error.localizedDescription)",
                level: .warning,
                category: .profile
            )
        }
    }

    private func makeUITestingProfiles() -> [ProfileModel] {
        let workUpdatedAt = Date(timeIntervalSince1970: 1_788_000_000)
        let focusUpdatedAt = Date(timeIntervalSince1970: 1_787_910_000)
        let presentationUpdatedAt = Date(timeIntervalSince1970: 1_787_820_000)

        return [
            ProfileModel(
                id: UUID(uuidString: "F6E1EFB7-A833-4F37-BB4D-38AA83F94B08") ?? UUID(),
                name: "Work Layout",
                createdAt: workUpdatedAt.addingTimeInterval(-172_800),
                updatedAt: workUpdatedAt,
                preferredVisibilityState: .expanded,
                showSecondBar: true,
                autoRehideEnabled: true,
                hoverRevealEnabled: true,
                targetZonesByBundleID: [
                    "com.flexibits.fantastical2.mac": .visible,
                    "com.getdropbox.dropbox": .hidden,
                    "io.tailscale.ipn.macos": .alwaysHidden
                ],
                notes: "Default weekday layout. Calendar stays visible, sync tools stay tucked away."
            ),
            ProfileModel(
                id: UUID(uuidString: "D97F8BC2-5E41-4189-A11B-6DE8B8D8E8A5") ?? UUID(),
                name: "Focus Writing",
                createdAt: focusUpdatedAt.addingTimeInterval(-86_400),
                updatedAt: focusUpdatedAt,
                preferredVisibilityState: .collapsed,
                showSecondBar: false,
                autoRehideEnabled: true,
                hoverRevealEnabled: false,
                targetZonesByBundleID: [
                    "com.apple.controlcenter": .visible,
                    "com.flexibits.fantastical2.mac": .hidden,
                    "com.getdropbox.dropbox": .alwaysHidden,
                    "io.tailscale.ipn.macos": .alwaysHidden
                ],
                notes: "Quiet mode for writing blocks and meeting prep."
            ),
            ProfileModel(
                id: UUID(uuidString: "615E82DE-BB48-4D8F-AE30-E1C7B74471AB") ?? UUID(),
                name: "Presentation",
                createdAt: presentationUpdatedAt.addingTimeInterval(-259_200),
                updatedAt: presentationUpdatedAt,
                preferredVisibilityState: .revealAll,
                showSecondBar: true,
                autoRehideEnabled: false,
                hoverRevealEnabled: true,
                targetZonesByBundleID: [
                    "com.apple.controlcenter": .visible,
                    "com.flexibits.fantastical2.mac": .visible,
                    "com.getdropbox.dropbox": .hidden,
                    "io.tailscale.ipn.macos": .hidden
                ],
                notes: "Reveal essentials before screen sharing; keep background utilities out of the way."
            )
        ]
    }

    private func makeUITestingTriggers(profileIDs: [UUID]) -> [TriggerModel] {
        guard profileIDs.count >= 3 else {
            return []
        }

        return [
            TriggerModel(
                id: UUID(uuidString: "DDE4E919-3176-42A2-9087-18557855FE14") ?? UUID(),
                name: "Desk Display",
                profileID: profileIDs[0],
                isEnabled: true,
                rule: .externalDisplayConnected(minimumDisplayCount: 2),
                debounceSeconds: 90,
                lastFiredAt: Date(timeIntervalSince1970: 1_788_020_000)
            ),
            TriggerModel(
                id: UUID(uuidString: "7BF71B5E-D3E6-48A3-ADBF-AB361D8D07C8") ?? UUID(),
                name: "Writing Block",
                profileID: profileIDs[1],
                isEnabled: true,
                rule: .timeOfDay(hour: 9, minute: 30),
                debounceSeconds: 120
            ),
            TriggerModel(
                id: UUID(uuidString: "4D1EE8B5-D00C-4C3C-9918-395C5B827861") ?? UUID(),
                name: "Low Battery",
                profileID: profileIDs[1],
                isEnabled: false,
                rule: .batteryLow(thresholdPercent: 20),
                debounceSeconds: 300
            ),
            TriggerModel(
                id: UUID(uuidString: "F53F52F5-C053-4956-A9E5-6E559F05B940") ?? UUID(),
                name: "Slides Frontmost",
                profileID: profileIDs[2],
                isEnabled: true,
                rule: .frontmostApp(bundleIdentifier: "com.apple.Keynote"),
                debounceSeconds: 75
            )
        ]
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
            name: "Pinned Tools",
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

    private var isHostedUnitTestingLaunch: Bool {
        guard !launchArguments.contains("--ui-testing") else {
            return false
        }

        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCInjectBundleInto"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }
}

private final class UITestingAccessibilityTrustOverride {
    var isGranted: Bool

    init(isGranted: Bool) {
        self.isGranted = isGranted
    }
}
