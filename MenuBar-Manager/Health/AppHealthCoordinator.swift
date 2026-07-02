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
    let layoutCoordinator: LayoutCoordinator
    let groupStore: IconGroupStore
    let groupStatusItemController: IconGroupStatusItemController
    let hotkeyBindingStore: HotkeyBindingStore
    let dynamicHotkeyRegistrationService: DynamicHotkeyRegistrationService
    let privateAccessCoordinator: PrivateAccessCoordinator
    var workspaceDiagnostics: () -> WorkspaceDiagnosticsSnapshot? = { nil }
    var functionBarVisible: () -> Bool = { false }
    var infoStripVisible: () -> Bool = { false }
    var infoStripSelectedTileProviderCount: () -> Int = { 0 }
    var infoStripAvailableSelectedTileProviderCount: () -> Int = { 0 }
    var infoStripInvalidProviderIDCount: () -> Int = { 0 }
    var infoStripRotationResult: () -> String? = { nil }
    var infoStripPlacementFailed: () -> Bool = { false }
    var infoStripTimingInvalid: () -> Bool = { false }
}

@MainActor
struct AppHealthCoordinatorActions {
    let synchronizeLiveStatus: () -> Void
    let revealAllHiddenItems: () -> Void
    let resetAllSettings: () -> Void
    let refreshTriggerSettings: () -> Void
    let resetWorkspacesToDefaults: () -> Void
    let resetCurrentWorkspaceLayout: () -> Void
    let removeMissingWorkspaceGroupReferences: () -> Void
    let discardSetBuilderDraft: () -> Void
    let hideFunctionBar: () -> Void
    let disableFunctionBarPreview: () -> Void
    let disableSetBuilderPreview: () -> Void
    let hideInfoStrip: () -> Void
    let showFunctionBar: () -> Void
    let disableInfoStripPreview: () -> Void
    let resetInfoStripSettings: () -> Void
    let resetInfoStripPlacement: () -> Void
    let clearInvalidInfoStripProviders: () -> Void
    let showFunctionBarInstead: () -> Void

    init(
        synchronizeLiveStatus: @escaping () -> Void = {},
        revealAllHiddenItems: @escaping () -> Void = {},
        resetAllSettings: @escaping () -> Void = {},
        refreshTriggerSettings: @escaping () -> Void = {},
        resetWorkspacesToDefaults: @escaping () -> Void = {},
        resetCurrentWorkspaceLayout: @escaping () -> Void = {},
        removeMissingWorkspaceGroupReferences: @escaping () -> Void = {},
        discardSetBuilderDraft: @escaping () -> Void = {},
        hideFunctionBar: @escaping () -> Void = {},
        disableFunctionBarPreview: @escaping () -> Void = {},
        disableSetBuilderPreview: @escaping () -> Void = {},
        hideInfoStrip: @escaping () -> Void = {},
        showFunctionBar: @escaping () -> Void = {},
        disableInfoStripPreview: @escaping () -> Void = {},
        resetInfoStripSettings: @escaping () -> Void = {},
        resetInfoStripPlacement: @escaping () -> Void = {},
        clearInvalidInfoStripProviders: @escaping () -> Void = {},
        showFunctionBarInstead: @escaping () -> Void = {}
    ) {
        self.synchronizeLiveStatus = synchronizeLiveStatus
        self.revealAllHiddenItems = revealAllHiddenItems
        self.resetAllSettings = resetAllSettings
        self.refreshTriggerSettings = refreshTriggerSettings
        self.resetWorkspacesToDefaults = resetWorkspacesToDefaults
        self.resetCurrentWorkspaceLayout = resetCurrentWorkspaceLayout
        self.removeMissingWorkspaceGroupReferences = removeMissingWorkspaceGroupReferences
        self.discardSetBuilderDraft = discardSetBuilderDraft
        self.hideFunctionBar = hideFunctionBar
        self.disableFunctionBarPreview = disableFunctionBarPreview
        self.disableSetBuilderPreview = disableSetBuilderPreview
        self.hideInfoStrip = hideInfoStrip
        self.showFunctionBar = showFunctionBar
        self.disableInfoStripPreview = disableInfoStripPreview
        self.resetInfoStripSettings = resetInfoStripSettings
        self.resetInfoStripPlacement = resetInfoStripPlacement
        self.clearInvalidInfoStripProviders = clearInvalidInfoStripProviders
        self.showFunctionBarInstead = showFunctionBarInstead
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
            },
            exitFullMenuBarMode: { [weak self] in
                self?.dependencies.layoutCoordinator.exitFullMenuBarMode()
            },
            hideOptionalSpacerItems: { [weak self] in
                self?.dependencies.layoutCoordinator.spacerController.hideAllOptional()
            },
            disableDynamicHotkeys: { [weak self] in
                guard let self else { return }
                self.dependencies.settingsStore.dynamicHotkeysEnabled = false
                self.dependencies.dynamicHotkeyRegistrationService.unregisterAll()
            },
            disableGroupStatusItems: { [weak self] in
                guard let self else { return }
                self.dependencies.settingsStore.groupStatusItemsEnabled = false
                self.dependencies.groupStatusItemController.removeAll()
            },
            clearPrivateAccessUnlock: { [weak self] in
                self?.dependencies.privateAccessCoordinator.clearUnlock()
            },
            resetWorkspacesToDefaults: { [weak self] in
                self?.externalActions.resetWorkspacesToDefaults()
            },
            resetCurrentWorkspaceLayout: { [weak self] in
                self?.externalActions.resetCurrentWorkspaceLayout()
            },
            removeMissingWorkspaceGroupReferences: { [weak self] in
                self?.externalActions.removeMissingWorkspaceGroupReferences()
            },
            discardSetBuilderDraft: { [weak self] in
                self?.externalActions.discardSetBuilderDraft()
            },
            hideFunctionBar: { [weak self] in
                self?.externalActions.hideFunctionBar()
            },
            disableFunctionBarPreview: { [weak self] in
                self?.externalActions.disableFunctionBarPreview()
            },
            disableSetBuilderPreview: { [weak self] in
                self?.externalActions.disableSetBuilderPreview()
            },
            hideInfoStrip: { [weak self] in
                self?.externalActions.hideInfoStrip()
            },
            disableInfoStripPreview: { [weak self] in
                self?.externalActions.disableInfoStripPreview()
            },
            resetInfoStripSettings: { [weak self] in
                self?.externalActions.resetInfoStripSettings()
            },
            resetInfoStripPlacement: { [weak self] in
                self?.externalActions.resetInfoStripPlacement()
            },
            clearInvalidInfoStripProviders: { [weak self] in
                self?.externalActions.clearInvalidInfoStripProviders()
            },
            showFunctionBarInstead: { [weak self] in
                self?.externalActions.showFunctionBarInstead()
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

    func performRecoveryAction(_ action: HealthRecoveryAction) {
        recoveryService.perform(action)
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
        let workspaceDiagnostics = dependencies.workspaceDiagnostics()
        return HealthCheckSnapshot(
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
            axScanStaleThreshold: max(60, dependencies.settingsStore.menuBarScanIntervalSeconds * 10),
            layoutFeaturesEnabled: dependencies.settingsStore.layoutFeaturesEnabled,
            fullMenuBarModeActive: dependencies.layoutCoordinator.fullMenuBarModeService.isActive,
            spacerItemsEnabled: dependencies.settingsStore.spacerItemsEnabled,
            spacerItemCount: dependencies.layoutCoordinator.spacerStore.itemCount,
            visibleSpacerItemCount: dependencies.layoutCoordinator.spacerController.visibleItemCount,
            groupsEnabled: dependencies.settingsStore.groupsEnabled,
            groupCount: dependencies.groupStore.groupCount,
            protectedGroupCount: dependencies.groupStore.protectedGroupCount,
            duplicateGroupNames: IconGroupValidation.validate(dependencies.groupStore.groups).contains(.duplicateName),
            groupStatusItemsEnabled: dependencies.settingsStore.groupStatusItemsEnabled,
            groupStatusItemCount: dependencies.groupStatusItemController.visibleCount,
            dynamicHotkeysEnabled: dependencies.settingsStore.dynamicHotkeysEnabled,
            dynamicHotkeyBindingCount: dependencies.hotkeyBindingStore.count,
            dynamicHotkeyRegisteredCount: dependencies.dynamicHotkeyRegistrationService.lastSnapshot.registeredCount,
            dynamicHotkeyConflictCount: HotkeyConflictDetector.conflictCount(in: dependencies.hotkeyBindingStore.bindings),
            privateAccessEnabled: dependencies.settingsStore.privateAccessEnabled,
            privateAccessUnlockActive: dependencies.privateAccessCoordinator.isUnlocked,
            appIntentsEnabled: dependencies.settingsStore.appIntentsEnabled,
            safeModeActive: dependencies.safeModeLaunchState.isSafeModeActive,
            functionBarPreviewEnabled: dependencies.settingsStore.workspacesPreviewEnabled
                && dependencies.settingsStore.functionBarPreviewEnabled,
            functionBarVisible: dependencies.functionBarVisible(),
            infoStripPreviewEnabled: dependencies.settingsStore.workspacesPreviewEnabled
                && dependencies.settingsStore.infoStripPreviewEnabled,
            infoStripVisible: dependencies.infoStripVisible(),
            infoStripSelectedTileProviderCount: dependencies.infoStripSelectedTileProviderCount(),
            infoStripAvailableSelectedTileProviderCount: dependencies.infoStripAvailableSelectedTileProviderCount(),
            infoStripInvalidProviderIDCount: dependencies.infoStripInvalidProviderIDCount(),
            infoStripRotationResult: dependencies.infoStripRotationResult(),
            infoStripPlacementFailed: dependencies.infoStripPlacementFailed(),
            infoStripTimingInvalid: dependencies.infoStripTimingInvalid(),
            workspaceStoreLoadStatus: workspaceDiagnostics?.lastLoadStatus ?? .notLoaded,
            workspaceValidationIssueCount: workspaceDiagnostics?.validationIssueCount ?? 0,
            workspaceMissingGroupReferenceCount: workspaceDiagnostics?.missingGroupReferenceCount ?? 0,
            workspaceDetachedSourceGroupMissingCount: workspaceDiagnostics?.detachedSourceGroupMissingCount ?? 0,
            workspaceUnresolvedMenuBarProxyReferenceCount: workspaceDiagnostics?.unresolvedMenuBarItemReferenceCount ?? 0,
            workspaceMissingProfileBindingCount: workspaceDiagnostics?.missingProfileBindingCount ?? 0
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
