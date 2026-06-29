import AppKit

@MainActor
struct AppHealthCoordinatorDependencies {
    let settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    let liveStatus: LiveDiagnosticsStatus
    let safeModeService: SafeModeService
    let safeModeLaunchState: SafeModeLaunchState
    let screenGeometry: ScreenGeometryService
    let statusBarController: StatusBarController
    let hotkeyManager: GlobalHotkeyManager
    let rehideController: RehideController
    let hoverRevealController: HoverRevealController
    let hidingService: HidingService
    let accessibilityPermissionService: AccessibilityPermissionService
    let menuBarScanCoordinator: MenuBarScanCoordinator
    let secondBarWindowController: SecondBarWindowController
}

@MainActor
struct AppHealthCoordinatorActions {
    let synchronizeLiveStatus: () -> Void
    let revealAllHiddenItems: () -> Void
    let resetAllSettings: () -> Void
    let refreshTriggerSettings: () -> Void

    init(
        synchronizeLiveStatus: @escaping () -> Void = {},
        revealAllHiddenItems: @escaping () -> Void = {},
        resetAllSettings: @escaping () -> Void = {},
        refreshTriggerSettings: @escaping () -> Void = {}
    ) {
        self.synchronizeLiveStatus = synchronizeLiveStatus
        self.revealAllHiddenItems = revealAllHiddenItems
        self.resetAllSettings = resetAllSettings
        self.refreshTriggerSettings = refreshTriggerSettings
    }
}

@MainActor
final class AppHealthCoordinator {
    private let dependencies: AppHealthCoordinatorDependencies
    private let externalActions: AppHealthCoordinatorActions

    private var healthService = HealthService()
    private var autoRehideTemporarilyDisabled = false
    private var hoverRevealTemporarilyDisabled = false

    private lazy var recoveryService = RecoveryService(
        actions: RecoveryActions(
            recreateMissingStatusItems: { [weak self] in
                self?.dependencies.statusBarController.ensureRequiredStatusItemsInstalled()
            },
            resetSeparatorLengths: { [weak self] in
                self?.resetSeparatorLengths()
            },
            expandAll: { [weak self] in
                self?.externalActions.revealAllHiddenItems()
            },
            disableAutoRehideTemporarily: { [weak self] in
                self?.disableAutoRehideTemporarily()
            },
            disableHoverRevealTemporarily: { [weak self] in
                self?.disableHoverRevealTemporarily()
            },
            resetMenuBarScanInterval: { [weak self] in
                self?.resetMenuBarScanInterval()
            },
            resetSecondBarPosition: { [weak self] in
                self?.resetSecondBarPosition()
            },
            refreshAccessibilityPermissionStatus: { [weak self] in
                self?.refreshAccessibilityPermissionStatus()
            },
            resetSettingsToDefaults: { [weak self] in
                self?.externalActions.resetAllSettings()
            },
            disableProMode: { [weak self] in
                self?.disableProMode()
            },
            enterSafeModeNextLaunch: { [weak self] in
                self?.requestSafeModeNextLaunch()
            }
        ),
        log: { [weak self] message in
            self?.dependencies.diagnosticsLogger.log(message)
        }
    )

    init(
        dependencies: AppHealthCoordinatorDependencies,
        actions: AppHealthCoordinatorActions
    ) {
        self.dependencies = dependencies
        self.externalActions = actions
    }

    var isAutoRehideSuppressed: Bool {
        dependencies.safeModeLaunchState.isSafeModeActive || autoRehideTemporarilyDisabled
    }

    var isHoverRevealSuppressed: Bool {
        dependencies.safeModeLaunchState.isSafeModeActive || hoverRevealTemporarilyDisabled
    }

    @discardableResult
    func runHealthCheck(reason: String) -> HealthReport {
        externalActions.synchronizeLiveStatus()
        let dogfoodRunID = dependencies.settingsStore.dogfoodModeEnabled
            ? dependencies.settingsStore.dogfoodRunID
            : nil
        let report = healthService.makeReport(snapshot: makeHealthSnapshot(), dogfoodRunID: dogfoodRunID)
        dependencies.liveStatus.healthReport = report

        dependencies.diagnosticsLogger.log(
            "Health check (\(reason)): \(report.status.displayName), \(report.issues.count) issue(s).",
            level: report.status == .ok ? .info : .warning
        )
        return report
    }

    func fixHealthIssues() {
        let report = runHealthCheck(reason: "manual repair")
        recover(report: report)
        _ = runHealthCheck(reason: "manual repair completed")
    }

    func recover(report: HealthReport) {
        recoveryService.recover(report: report)
    }

    func disableProMode() {
        dependencies.settingsStore.proModeEnabled = false
        dependencies.settingsStore.accessibilityDiscoveryEnabled = false
        dependencies.settingsStore.iconMovingEnabled = false
        dependencies.settingsStore.smartTriggersEnabled = false
        externalActions.refreshTriggerSettings()
        dependencies.liveStatus.scannedMenuBarItems = []
        dependencies.liveStatus.lastMenuBarScanTime = nil
        dependencies.liveStatus.menuBarScanFailuresCount = 0
        dependencies.diagnosticsLogger.log("Pro Mode disabled by health recovery.", level: .warning)
    }

    func requestSafeModeNextLaunch() {
        do {
            try dependencies.safeModeService.requestSafeModeOnNextLaunch()
            dependencies.diagnosticsLogger.log("Safe Mode requested for next launch.", level: .warning)
        } catch {
            dependencies.diagnosticsLogger.log("Could not request Safe Mode: \(error.localizedDescription)", level: .error)
        }
    }

    private func makeHealthSnapshot() -> HealthCheckSnapshot {
        HealthCheckSnapshot(
            controlItemExists: dependencies.statusBarController.isControlItemInstalled,
            primarySeparatorExpected: true,
            primarySeparatorExists: dependencies.statusBarController.isPrimarySeparatorInstalled,
            alwaysHiddenEnabled: dependencies.settingsStore.alwaysHiddenEnabled,
            alwaysHiddenSeparatorExists: dependencies.statusBarController.isAlwaysHiddenSeparatorInstalled,
            primarySeparatorLength: dependencies.statusBarController.primarySeparatorLength,
            alwaysHiddenSeparatorLength: dependencies.statusBarController.alwaysHiddenSeparatorLength,
            widestScreenWidth: dependencies.screenGeometry.widestScreenWidth(),
            screenCount: NSScreen.screens.count,
            settingsIssues: HealthService.validateSettings(dependencies.settingsStore),
            globalHotkeyEnabled: dependencies.settingsStore.globalHotkeyEnabled
                && !dependencies.safeModeLaunchState.isSafeModeActive,
            globalHotkeyRegistered: dependencies.hotkeyManager.isRegistered(identifier: .visibilityToggle),
            searchHotkeyEnabled: dependencies.settingsStore.searchEnabled
                && dependencies.settingsStore.searchHotkeyEnabled
                && !dependencies.safeModeLaunchState.isSafeModeActive,
            searchHotkeyRegistered: dependencies.hotkeyManager.isRegistered(identifier: .findIcon),
            autoRehideEnabled: dependencies.settingsStore.autoRehideEnabled && !isAutoRehideSuppressed,
            autoRehideScheduled: dependencies.rehideController.isScheduled,
            visibilityState: dependencies.hidingService.visibilityState,
            hoverRevealEnabled: dependencies.settingsStore.hoverRevealEnabled && !isHoverRevealSuppressed,
            hoverRevealPollingActive: dependencies.hoverRevealController.isPollingActive,
            proModeEnabled: dependencies.settingsStore.proModeEnabled
                && !dependencies.safeModeLaunchState.isSafeModeActive,
            accessibilityDiscoveryEnabled: dependencies.settingsStore.accessibilityDiscoveryEnabled
                && !dependencies.safeModeLaunchState.isSafeModeActive,
            accessibilityPermissionStatus: dependencies.accessibilityPermissionService.refreshStatus(),
            lastMenuBarScanTime: dependencies.liveStatus.lastMenuBarScanTime,
            menuBarScanFailuresCount: dependencies.liveStatus.menuBarScanFailuresCount,
            axScanStaleThreshold: max(60, dependencies.settingsStore.menuBarScanIntervalSeconds * 10)
        )
    }

    private func disableAutoRehideTemporarily() {
        autoRehideTemporarilyDisabled = true
        dependencies.rehideController.cancel(reason: .cancelled)
        dependencies.liveStatus.autoRehideScheduled = false
        dependencies.diagnosticsLogger.log("Auto-rehide disabled temporarily by recovery.", level: .warning)
    }

    private func disableHoverRevealTemporarily() {
        hoverRevealTemporarilyDisabled = true
        dependencies.hoverRevealController.stop()
        dependencies.liveStatus.hoverPollingActive = false
        dependencies.diagnosticsLogger.log("Hover reveal disabled temporarily by recovery.", level: .warning)
    }

    private func resetSeparatorLengths() {
        dependencies.settingsStore.expandedSeparatorLength = AppConstants.defaultExpandedSeparatorLength
        dependencies.settingsStore.collapsedSeparatorLengthOverride = nil
        dependencies.statusBarController.resetSeparatorLength()
        dependencies.statusBarController.reapplyCurrentVisibility()
        dependencies.statusBarController.refreshSeparatorVisuals()
        dependencies.diagnosticsLogger.log("Separator lengths reset by health recovery.", level: .warning)
    }

    private func resetMenuBarScanInterval() {
        dependencies.settingsStore.menuBarScanIntervalSeconds = AppConstants.defaultMenuBarScanIntervalSeconds
        if !dependencies.safeModeLaunchState.isSafeModeActive {
            dependencies.menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "health recovery")
        }
        dependencies.diagnosticsLogger.log("Menu bar scan interval reset by health recovery.", level: .warning)
    }

    private func resetSecondBarPosition() {
        dependencies.settingsStore.secondBarPositionModeRaw = SecondBarPositionMode.belowMenuBar.rawValue
        dependencies.secondBarWindowController.refreshAfterSettingsChanged()
        dependencies.diagnosticsLogger.log("Second Bar position reset by health recovery.", level: .warning)
    }

    private func refreshAccessibilityPermissionStatus() {
        dependencies.liveStatus.accessibilityPermissionStatus = dependencies.accessibilityPermissionService.refreshStatus()
        dependencies.diagnosticsLogger.log("Accessibility permission status refreshed by health recovery.", level: .warning)
    }
}
