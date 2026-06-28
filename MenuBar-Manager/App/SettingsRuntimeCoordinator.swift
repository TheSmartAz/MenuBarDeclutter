import Foundation

@MainActor
final class SettingsRuntimeCoordinator {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let safeModeLaunchState: SafeModeLaunchState
    private let launchAtLoginService: LaunchAtLoginService
    private let statusBarController: StatusBarController
    private let hotkeyManager: GlobalHotkeyManager
    private let hoverRevealController: HoverRevealController
    private let menuBarScanCoordinator: MenuBarScanCoordinator
    private let secondBarWindowController: SecondBarWindowController
    private let triggerService: TriggerService
    private let liveStatusSynchronizer: AppEnvironmentLiveStatusSynchronizer
    private let isHoverRevealSuppressed: () -> Bool
    private let runHealthCheck: (String) -> Void
    private let showSearch: () -> Void

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        safeModeLaunchState: SafeModeLaunchState,
        launchAtLoginService: LaunchAtLoginService,
        statusBarController: StatusBarController,
        hotkeyManager: GlobalHotkeyManager,
        hoverRevealController: HoverRevealController,
        menuBarScanCoordinator: MenuBarScanCoordinator,
        secondBarWindowController: SecondBarWindowController,
        triggerService: TriggerService,
        liveStatusSynchronizer: AppEnvironmentLiveStatusSynchronizer,
        isHoverRevealSuppressed: @escaping () -> Bool,
        runHealthCheck: @escaping (String) -> Void,
        showSearch: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.safeModeLaunchState = safeModeLaunchState
        self.launchAtLoginService = launchAtLoginService
        self.statusBarController = statusBarController
        self.hotkeyManager = hotkeyManager
        self.hoverRevealController = hoverRevealController
        self.menuBarScanCoordinator = menuBarScanCoordinator
        self.secondBarWindowController = secondBarWindowController
        self.triggerService = triggerService
        self.liveStatusSynchronizer = liveStatusSynchronizer
        self.isHoverRevealSuppressed = isHoverRevealSuppressed
        self.runHealthCheck = runHealthCheck
        self.showSearch = showSearch
    }

    /// Called by Settings views when any Phase 2 behavior checkbox changes.
    func refreshBehaviorSettings() {
        statusBarController.refreshAlwaysHiddenSeparator()
        statusBarController.refreshHoverReveal()
        if safeModeLaunchState.isSafeModeActive {
            hotkeyManager.unregister(identifier: .visibilityToggle)
        } else {
            statusBarController.refreshGlobalHotkey()
        }
        statusBarController.refreshSeparatorVisuals()
        statusBarController.refreshAutoRehide()
        liveStatusSynchronizer.synchronize()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.scanIfAllowed(reason: "behavior settings changed")
        }
        runHealthCheck("behavior settings changed")
    }

    func refreshSearchSettings() {
        refreshSearchHotkeyRegistration()
        liveStatusSynchronizer.refreshSearchIndexItemCount()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "search settings changed")
        }
        runHealthCheck("search settings changed")
    }

    func refreshSecondBarSettings() {
        secondBarWindowController.refreshAfterSettingsChanged()
        liveStatusSynchronizer.refreshSecondBarItemCount()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "second bar settings changed")
        }
        runHealthCheck("second bar settings changed")
    }

    func refreshPrivacySettings() {
        guard !safeModeLaunchState.isSafeModeActive else {
            diagnosticsLogger.log("Safe Mode skipped Pro privacy refresh.", level: .warning)
            return
        }
        menuBarScanCoordinator.refreshAfterSettingsChanged()
        runHealthCheck("privacy settings changed")
    }

    func refreshTriggerSettings() {
        if safeModeLaunchState.isSafeModeActive {
            triggerService.stop()
            diagnosticsLogger.log("Safe Mode disabled smart triggers.", level: .warning)
        } else if settingsStore.smartTriggersEnabled {
            triggerService.start()
        } else {
            triggerService.stop()
        }
    }

    func applyInitialBehaviorSettings() {
        if safeModeLaunchState.isSafeModeActive {
            hotkeyManager.unregister()
        } else {
            statusBarController.refreshGlobalHotkey()
        }
        refreshSearchHotkeyRegistration()
        if settingsStore.hoverRevealEnabled && !isHoverRevealSuppressed() {
            hoverRevealController.start()
            liveStatus.hoverPollingActive = hoverRevealController.isPollingActive
        } else {
            hoverRevealController.stop()
            liveStatus.hoverPollingActive = false
        }
        liveStatusSynchronizer.synchronize()
    }

    /// Resets the menu bar layout to the recommended collapsed separator length
    /// for the widest screen, clearing any user-override.
    func resetAppLayout() {
        settingsStore.collapsedSeparatorLengthOverride = nil
        statusBarController.resetSeparatorLength()
        statusBarController.refreshSeparatorVisuals()
        diagnosticsLogger.log("App layout reset to recommended separator length.")
    }

    /// Resets all settings to defaults, then re-applies live behavior so the
    /// user does not have to relaunch.
    func resetAllSettings() {
        settingsStore.restoreDefaults()

        // Re-run the launch-at-login reflection against the new (false) value.
        launchAtLoginService.apply(enabled: false)

        // Re-apply live behavior.
        statusBarController.refreshAlwaysHiddenSeparator()
        statusBarController.refreshHoverReveal()
        if safeModeLaunchState.isSafeModeActive {
            hotkeyManager.unregister(identifier: .visibilityToggle)
        } else {
            statusBarController.refreshGlobalHotkey()
        }
        refreshSearchHotkeyRegistration()
        statusBarController.refreshSeparatorVisuals()
        statusBarController.refreshAutoRehide()
        secondBarWindowController.refreshAfterSettingsChanged()
        refreshTriggerSettings()
        statusBarController.resetSeparatorLength()

        liveStatusSynchronizer.synchronize()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "settings reset")
        }
        runHealthCheck("settings reset")

        diagnosticsLogger.log("All settings reset to defaults.")
    }

    func toggleProMode() {
        if settingsStore.proModeEnabled {
            settingsStore.proModeEnabled = false
            settingsStore.accessibilityDiscoveryEnabled = false
            diagnosticsLogger.log("Pro Mode disabled from status menu.")
        } else {
            settingsStore.proModeEnabled = true
            settingsStore.accessibilityDiscoveryEnabled = true
            diagnosticsLogger.log("Pro Mode enabled from status menu.")
        }

        refreshPrivacySettings()
        refreshSearchSettings()
    }

    private func refreshSearchHotkeyRegistration() {
        guard !safeModeLaunchState.isSafeModeActive else {
            hotkeyManager.unregister(identifier: .findIcon)
            liveStatus.searchHotkeyRegistered = false
            return
        }

        if settingsStore.searchEnabled && settingsStore.searchHotkeyEnabled {
            hotkeyManager.register(
                identifier: .findIcon,
                hotkey: settingsStore.effectiveSearchHotkey()
            ) { [weak self] in
                self?.showSearch()
            }
        } else {
            hotkeyManager.unregister(identifier: .findIcon)
        }

        liveStatus.searchHotkeyRegistered = hotkeyManager.isRegistered(identifier: .findIcon)
    }
}
