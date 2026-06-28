import AppKit

@MainActor
final class MenuBarItemSurfaceCoordinator {
    private(set) lazy var secondBarWindowController = SecondBarWindowController(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        positioningService: secondBarPositioningService,
        diagnosticsLogger: diagnosticsLogger,
        onRefresh: { [weak self] in
            self?.refreshMenuBarItems()
        },
        onActivate: { [weak self] snapshot in
            self?.activateSecondBarItem(snapshot) ?? MenuItemActivationResult(
                outcome: .selectedWithoutHighlight,
                message: "Second Bar item selected."
            )
        },
        onMove: { [weak self] snapshot, command in
            guard let self else {
                return IconMoveResult.skipped(
                    command: command,
                    itemName: snapshot.owningApplicationName ?? snapshot.title ?? "Menu Bar Item",
                    error: .disabled
                )
            }
            return await self.moveIcon(snapshot, command: command)
        },
        onSettingsChanged: refreshSecondBarSettings,
        onOpenPrivacySettings: openPrivacySettings
    )

    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let safeModeLaunchState: SafeModeLaunchState
    private let hidingService: HidingService
    private let rehideController: RehideController
    private let hoverRevealController: HoverRevealController
    private let menuBarScanCoordinator: MenuBarScanCoordinator
    private let liveStatusSynchronizer: AppEnvironmentLiveStatusSynchronizer
    private let secondBarPositioningService: SecondBarPositioningService
    private let isHoverRevealSuppressed: () -> Bool

    private lazy var searchService = SearchService()

    private lazy var highlightOverlayWindow = HighlightOverlayWindow(
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var menuItemActivator = MenuItemActivator(
        settingsStore: settingsStore,
        hidingService: hidingService,
        highlightOverlay: highlightOverlayWindow,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var searchWindowController = SearchWindowController(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        searchService: searchService,
        menuItemActivator: menuItemActivator,
        diagnosticsLogger: diagnosticsLogger,
        onRefresh: { [weak self] in
            self?.refreshMenuBarItems()
        },
        onMove: { [weak self] result, command in
            guard let self else {
                return IconMoveResult.skipped(
                    command: command,
                    itemName: result.displayTitle,
                    error: .disabled
                )
            }
            return await self.moveIcon(result.snapshot, command: command)
        },
        onSettingsChanged: refreshSearchSettings,
        onOpenPrivacySettings: openPrivacySettings
    )

    private lazy var iconMoveService = IconMoveService(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        diagnosticsLogger: diagnosticsLogger,
        separatorFramesProvider: separatorFramesProvider,
        currentVisibilityProvider: { [weak self] in
            self?.hidingService.visibilityState ?? .expanded
        },
        setVisibility: { [weak self] state in
            self?.hidingService.setVisibility(state)
        },
        refreshSnapshots: { [weak self] in
            self?.refreshMenuBarItems()
            return self?.liveStatus.scannedMenuBarItems ?? []
        },
        suspendRuntimeBehaviors: { [weak self] in
            self?.suspendRuntimeForIconMove()
        },
        resumeRuntimeBehaviors: { [weak self] in
            self?.resumeRuntimeAfterIconMove()
        }
    )

    private let accessibilityPermissionService: AccessibilityPermissionService
    private let separatorFramesProvider: () -> MenuBarSeparatorFrames
    private let refreshSearchSettings: () -> Void
    private let refreshSecondBarSettings: () -> Void
    private let openPrivacySettings: () -> Void

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        safeModeLaunchState: SafeModeLaunchState,
        hidingService: HidingService,
        rehideController: RehideController,
        hoverRevealController: HoverRevealController,
        accessibilityPermissionService: AccessibilityPermissionService,
        menuBarScanCoordinator: MenuBarScanCoordinator,
        liveStatusSynchronizer: AppEnvironmentLiveStatusSynchronizer,
        secondBarPositioningService: SecondBarPositioningService = SecondBarPositioningService(),
        separatorFramesProvider: @escaping () -> MenuBarSeparatorFrames,
        isHoverRevealSuppressed: @escaping () -> Bool,
        refreshSearchSettings: @escaping () -> Void,
        refreshSecondBarSettings: @escaping () -> Void,
        openPrivacySettings: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.safeModeLaunchState = safeModeLaunchState
        self.hidingService = hidingService
        self.rehideController = rehideController
        self.hoverRevealController = hoverRevealController
        self.accessibilityPermissionService = accessibilityPermissionService
        self.menuBarScanCoordinator = menuBarScanCoordinator
        self.liveStatusSynchronizer = liveStatusSynchronizer
        self.secondBarPositioningService = secondBarPositioningService
        self.separatorFramesProvider = separatorFramesProvider
        self.isHoverRevealSuppressed = isHoverRevealSuppressed
        self.refreshSearchSettings = refreshSearchSettings
        self.refreshSecondBarSettings = refreshSecondBarSettings
        self.openPrivacySettings = openPrivacySettings
    }

    func showSearch() {
        refreshMenuBarItems()
        searchWindowController.show()
    }

    func showSecondBar() {
        settingsStore.secondBarEnabled = true
        refreshSecondBarSettings()
        refreshMenuBarItems()
        secondBarWindowController.show()
    }

    func hideSecondBar() {
        secondBarWindowController.hide()
    }

    func toggleSecondBar() {
        if !settingsStore.secondBarEnabled {
            settingsStore.secondBarEnabled = true
            refreshSecondBarSettings()
        }
        refreshMenuBarItems()
        secondBarWindowController.toggle()
    }

    func refreshSecondBarAfterSettingsChanged() {
        secondBarWindowController.refreshAfterSettingsChanged()
    }

    func refreshMenuBarItems() {
        if safeModeLaunchState.isSafeModeActive {
            diagnosticsLogger.log("Safe Mode skipped manual Pro scan.", level: .warning)
        } else {
            menuBarScanCoordinator.requestManualRefresh()
        }
        liveStatusSynchronizer.refreshSearchAndSecondBarItemCounts()
    }

    func resetMovingWarnings() {
        iconMoveService.resetWarnings()
    }

    private func activateSecondBarItem(_ snapshot: MenuBarItemSnapshot) -> MenuItemActivationResult {
        let result = menuItemActivator.activate(
            MenuBarSearchResult(
                snapshot: snapshot,
                score: 0,
                matchReason: .recent
            )
        )

        if settingsStore.secondBarActivateOwningAppOnSelection,
           let processIdentifier = snapshot.owningProcessIdentifier {
            NSRunningApplication(processIdentifier: processIdentifier)?
                .activate(options: [])
        }

        diagnosticsLogger.log("Second Bar activation: \(result.message)")
        return result
    }

    private func moveIcon(_ snapshot: MenuBarItemSnapshot, command: IconMoveCommand) async -> IconMoveResult {
        guard !safeModeLaunchState.isSafeModeActive else {
            return IconMoveResult.skipped(
                command: command,
                itemName: snapshot.owningApplicationName ?? snapshot.title ?? "Menu Bar Item",
                error: .disabled
            )
        }
        return await iconMoveService.move(snapshot, command: command)
    }

    private func suspendRuntimeForIconMove() {
        rehideController.cancel(reason: .cancelled)
        hoverRevealController.stop()
        liveStatus.autoRehideScheduled = false
        liveStatus.hoverPollingActive = false
        diagnosticsLogger.log("Runtime reveal behaviors suspended for icon move.", level: .debug)
    }

    private func resumeRuntimeAfterIconMove() {
        if settingsStore.hoverRevealEnabled && !isHoverRevealSuppressed() {
            hoverRevealController.start()
        }
        liveStatus.hoverPollingActive = hoverRevealController.isPollingActive
        diagnosticsLogger.log("Runtime reveal behaviors resumed after icon move.", level: .debug)
    }
}
