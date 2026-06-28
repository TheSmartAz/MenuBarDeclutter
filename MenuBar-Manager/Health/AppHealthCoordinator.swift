import AppKit

@MainActor
final class AppHealthCoordinator {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let safeModeService: SafeModeService
    private let safeModeLaunchState: SafeModeLaunchState
    private let screenGeometry: ScreenGeometryService
    private let statusBarController: StatusBarController
    private let hotkeyManager: GlobalHotkeyManager
    private let rehideController: RehideController
    private let hoverRevealController: HoverRevealController
    private let hidingService: HidingService
    private let accessibilityPermissionService: AccessibilityPermissionService
    private let menuBarScanCoordinator: MenuBarScanCoordinator
    private let secondBarWindowController: SecondBarWindowController
    private let synchronizeLiveStatus: () -> Void
    private let revealAllHiddenItems: () -> Void
    private let resetSettingsToDefaults: () -> Void
    private let refreshTriggerSettings: () -> Void

    private var healthService = HealthService()
    private var autoRehideTemporarilyDisabled = false
    private var hoverRevealTemporarilyDisabled = false

    private lazy var recoveryService = RecoveryService(
        actions: RecoveryActions(
            recreateMissingStatusItems: { [weak self] in
                self?.statusBarController.ensureRequiredStatusItemsInstalled()
            },
            resetSeparatorLengths: { [weak self] in
                self?.resetSeparatorLengths()
            },
            expandAll: { [weak self] in
                self?.revealAllHiddenItems()
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
                self?.resetSettingsToDefaults()
            },
            disableProMode: { [weak self] in
                self?.disableProMode()
            },
            enterSafeModeNextLaunch: { [weak self] in
                self?.requestSafeModeNextLaunch()
            }
        ),
        log: { [weak self] message in
            self?.diagnosticsLogger.log(message)
        }
    )

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        safeModeService: SafeModeService,
        safeModeLaunchState: SafeModeLaunchState,
        screenGeometry: ScreenGeometryService,
        statusBarController: StatusBarController,
        hotkeyManager: GlobalHotkeyManager,
        rehideController: RehideController,
        hoverRevealController: HoverRevealController,
        hidingService: HidingService,
        accessibilityPermissionService: AccessibilityPermissionService,
        menuBarScanCoordinator: MenuBarScanCoordinator,
        secondBarWindowController: SecondBarWindowController,
        synchronizeLiveStatus: @escaping () -> Void,
        revealAllHiddenItems: @escaping () -> Void,
        resetSettingsToDefaults: @escaping () -> Void,
        refreshTriggerSettings: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.safeModeService = safeModeService
        self.safeModeLaunchState = safeModeLaunchState
        self.screenGeometry = screenGeometry
        self.statusBarController = statusBarController
        self.hotkeyManager = hotkeyManager
        self.rehideController = rehideController
        self.hoverRevealController = hoverRevealController
        self.hidingService = hidingService
        self.accessibilityPermissionService = accessibilityPermissionService
        self.menuBarScanCoordinator = menuBarScanCoordinator
        self.secondBarWindowController = secondBarWindowController
        self.synchronizeLiveStatus = synchronizeLiveStatus
        self.revealAllHiddenItems = revealAllHiddenItems
        self.resetSettingsToDefaults = resetSettingsToDefaults
        self.refreshTriggerSettings = refreshTriggerSettings
    }

    var isAutoRehideSuppressed: Bool {
        safeModeLaunchState.isSafeModeActive || autoRehideTemporarilyDisabled
    }

    var isHoverRevealSuppressed: Bool {
        safeModeLaunchState.isSafeModeActive || hoverRevealTemporarilyDisabled
    }

    @discardableResult
    func runHealthCheck(reason: String) -> HealthReport {
        synchronizeLiveStatus()
        let report = healthService.makeReport(snapshot: makeHealthSnapshot())
        liveStatus.healthReport = report

        diagnosticsLogger.log(
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
        settingsStore.proModeEnabled = false
        settingsStore.accessibilityDiscoveryEnabled = false
        settingsStore.iconMovingEnabled = false
        settingsStore.smartTriggersEnabled = false
        refreshTriggerSettings()
        liveStatus.scannedMenuBarItems = []
        liveStatus.lastMenuBarScanTime = nil
        liveStatus.menuBarScanFailuresCount = 0
        diagnosticsLogger.log("Pro Mode disabled by health recovery.", level: .warning)
    }

    func requestSafeModeNextLaunch() {
        do {
            try safeModeService.requestSafeModeOnNextLaunch()
            diagnosticsLogger.log("Safe Mode requested for next launch.", level: .warning)
        } catch {
            diagnosticsLogger.log("Could not request Safe Mode: \(error.localizedDescription)", level: .error)
        }
    }

    private func makeHealthSnapshot() -> HealthCheckSnapshot {
        HealthCheckSnapshot(
            controlItemExists: statusBarController.isControlItemInstalled,
            primarySeparatorExpected: true,
            primarySeparatorExists: statusBarController.isPrimarySeparatorInstalled,
            alwaysHiddenEnabled: settingsStore.alwaysHiddenEnabled,
            alwaysHiddenSeparatorExists: statusBarController.isAlwaysHiddenSeparatorInstalled,
            primarySeparatorLength: statusBarController.primarySeparatorLength,
            alwaysHiddenSeparatorLength: statusBarController.alwaysHiddenSeparatorLength,
            widestScreenWidth: screenGeometry.widestScreenWidth(),
            screenCount: NSScreen.screens.count,
            settingsIssues: HealthService.validateSettings(settingsStore),
            globalHotkeyEnabled: settingsStore.globalHotkeyEnabled && !safeModeLaunchState.isSafeModeActive,
            globalHotkeyRegistered: hotkeyManager.isRegistered(identifier: .visibilityToggle),
            searchHotkeyEnabled: settingsStore.searchEnabled
                && settingsStore.searchHotkeyEnabled
                && !safeModeLaunchState.isSafeModeActive,
            searchHotkeyRegistered: hotkeyManager.isRegistered(identifier: .findIcon),
            autoRehideEnabled: settingsStore.autoRehideEnabled && !isAutoRehideSuppressed,
            autoRehideScheduled: rehideController.isScheduled,
            visibilityState: hidingService.visibilityState,
            hoverRevealEnabled: settingsStore.hoverRevealEnabled && !isHoverRevealSuppressed,
            hoverRevealPollingActive: hoverRevealController.isPollingActive,
            proModeEnabled: settingsStore.proModeEnabled && !safeModeLaunchState.isSafeModeActive,
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled && !safeModeLaunchState.isSafeModeActive,
            accessibilityPermissionStatus: accessibilityPermissionService.refreshStatus(),
            lastMenuBarScanTime: liveStatus.lastMenuBarScanTime,
            menuBarScanFailuresCount: liveStatus.menuBarScanFailuresCount,
            axScanStaleThreshold: max(60, settingsStore.menuBarScanIntervalSeconds * 10)
        )
    }

    private func disableAutoRehideTemporarily() {
        autoRehideTemporarilyDisabled = true
        rehideController.cancel(reason: .cancelled)
        liveStatus.autoRehideScheduled = false
        diagnosticsLogger.log("Auto-rehide disabled temporarily by recovery.", level: .warning)
    }

    private func disableHoverRevealTemporarily() {
        hoverRevealTemporarilyDisabled = true
        hoverRevealController.stop()
        liveStatus.hoverPollingActive = false
        diagnosticsLogger.log("Hover reveal disabled temporarily by recovery.", level: .warning)
    }

    private func resetSeparatorLengths() {
        settingsStore.expandedSeparatorLength = AppConstants.defaultExpandedSeparatorLength
        settingsStore.collapsedSeparatorLengthOverride = nil
        statusBarController.resetSeparatorLength()
        statusBarController.reapplyCurrentVisibility()
        statusBarController.refreshSeparatorVisuals()
        diagnosticsLogger.log("Separator lengths reset by health recovery.", level: .warning)
    }

    private func resetMenuBarScanInterval() {
        settingsStore.menuBarScanIntervalSeconds = AppConstants.defaultMenuBarScanIntervalSeconds
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "health recovery")
        }
        diagnosticsLogger.log("Menu bar scan interval reset by health recovery.", level: .warning)
    }

    private func resetSecondBarPosition() {
        settingsStore.secondBarPositionModeRaw = SecondBarPositionMode.belowMenuBar.rawValue
        secondBarWindowController.refreshAfterSettingsChanged()
        diagnosticsLogger.log("Second Bar position reset by health recovery.", level: .warning)
    }

    private func refreshAccessibilityPermissionStatus() {
        liveStatus.accessibilityPermissionStatus = accessibilityPermissionService.refreshStatus()
        diagnosticsLogger.log("Accessibility permission status refreshed by health recovery.", level: .warning)
    }
}
