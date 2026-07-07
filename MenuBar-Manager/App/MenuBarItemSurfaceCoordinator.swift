import AppKit

@MainActor
final class MenuBarItemSurfaceCoordinator {
    private(set) lazy var secondBarCompactStripWindowController = SecondBarCompactStripWindowController(
        settingsStore: settingsStore,
        liveStatus: liveStatus,
        positioningService: secondBarPositioningService,
        diagnosticsLogger: diagnosticsLogger,
        onActivate: { [weak self] snapshot in
            self?.activateCompactStripItem(snapshot) == true
        },
        onOpenManage: { [weak self] in
            _ = self?.routeCommand(MenuBarCommand(
                action: .showSecondBar,
                target: .secondBar,
                source: .secondBar
            ))
        },
        onOpenSettings: openPrivacySettings
    )

    private(set) lazy var secondBarWindowController = SecondBarWindowController(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        itemMemoryStore: menuBarItemMemoryStore,
        positioningService: secondBarPositioningService,
        diagnosticsLogger: diagnosticsLogger,
        onRefresh: { [weak self] in
            self?.refreshMenuBarItems()
        },
        onCommand: { [weak self] command in
            self?.routeCommand(command) ?? MenuBarCommandResult.stopped(
                command,
                status: .failed,
                message: "Command router is unavailable.",
                diagnosticReason: "routerUnavailable"
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
        groupsProvider: { [weak self] in
            self?.availableGroups() ?? []
        },
        onSettingsChanged: refreshSecondBarSettings,
        onOpenPrivacySettings: openPrivacySettings
    )

    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let menuBarItemMemoryStore: MenuBarItemMemoryStore
    private let moveOutcomeRecorder: (any MoveOutcomeRecording)?
    private let newItemInboxStore: NewMenuBarItemInboxStore?
    private let groupStore: IconGroupStore
    private let safeModeLaunchState: SafeModeLaunchState
    private let hidingService: HidingService
    private let rehideController: RehideController
    private let hoverRevealController: HoverRevealController
    private let screenGeometry: ScreenGeometryService
    private let menuBarScanCoordinator: MenuBarScanCoordinator
    private let iconCaptureCoordinator: MenuBarIconCaptureCoordinator?
    private let renderedIconCache: MenuBarRenderedIconCache
    private let liveStatusSynchronizer: AppEnvironmentLiveStatusSynchronizer
    private let secondBarPositioningService: SecondBarPositioningService
    private let isHoverRevealSuppressed: () -> Bool

    private lazy var searchService = SearchService()

    private lazy var searchWindowController = SearchWindowController(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        searchService: searchService,
        itemMemoryStore: menuBarItemMemoryStore,
        diagnosticsLogger: diagnosticsLogger,
        newItemStorageKeysProvider: { [weak self] in
            Set(self?.newItemInboxStore?.inbox.items.map(\.id) ?? [])
        },
        workspaceUsageProvider: { [weak self] in
            self?.workspaceUsageProvider()
        },
        onRefresh: { [weak self] in
            self?.refreshMenuBarItems()
        },
        onCommand: { [weak self] command in
            self?.routeCommand(command) ?? MenuBarCommandResult.stopped(
                command,
                status: .failed,
                message: "Command router is unavailable.",
                diagnosticReason: "routerUnavailable"
            )
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
        groupsProvider: { [weak self] in
            self?.availableGroups() ?? []
        },
        onSettingsChanged: refreshSearchSettings,
        onOpenPrivacySettings: openPrivacySettings
    )

    private lazy var iconMoveService = IconMoveService(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        diagnosticsLogger: diagnosticsLogger,
        screenGeometry: screenGeometry,
        separatorFramesProvider: separatorFramesProvider,
        currentVisibilityProvider: { [weak self] in
            self?.hidingService.visibilityState ?? .expanded
        },
        setVisibility: { [weak self] state in
            self?.hidingService.setVisibility(state)
        },
        refreshSnapshots: { [weak self] in
            await self?.refreshMenuBarItemsForMoveVerification() ?? []
        },
        suspendRuntimeBehaviors: { [weak self] in
            self?.suspendRuntimeForIconMove()
        },
        resumeRuntimeBehaviors: { [weak self] in
            self?.resumeRuntimeAfterIconMove()
        },
        moveOutcomeRecorder: moveOutcomeRecorder
    )

    private let accessibilityPermissionService: AccessibilityPermissionService
    private let separatorFramesProvider: () -> MenuBarSeparatorFrames
    private let refreshSearchSettings: () -> Void
    private let refreshSecondBarSettings: () -> Void
    private let workspaceUsageProvider: () -> WorkspaceUsageIndexSnapshot?
    private let openPrivacySettings: () -> Void
    private let routeCommand: (MenuBarCommand) -> MenuBarCommandResult

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        itemMemoryStore: MenuBarItemMemoryStore,
        newItemInboxStore: NewMenuBarItemInboxStore? = nil,
        groupStore: IconGroupStore,
        safeModeLaunchState: SafeModeLaunchState,
        hidingService: HidingService,
        rehideController: RehideController,
        hoverRevealController: HoverRevealController,
        screenGeometry: ScreenGeometryService,
        accessibilityPermissionService: AccessibilityPermissionService,
        menuBarScanCoordinator: MenuBarScanCoordinator,
        iconCaptureCoordinator: MenuBarIconCaptureCoordinator? = nil,
        renderedIconCache: MenuBarRenderedIconCache = .shared,
        liveStatusSynchronizer: AppEnvironmentLiveStatusSynchronizer,
        secondBarPositioningService: SecondBarPositioningService = SecondBarPositioningService(),
        separatorFramesProvider: @escaping () -> MenuBarSeparatorFrames,
        isHoverRevealSuppressed: @escaping () -> Bool,
        refreshSearchSettings: @escaping () -> Void,
        refreshSecondBarSettings: @escaping () -> Void,
        workspaceUsageProvider: @escaping () -> WorkspaceUsageIndexSnapshot? = { nil },
        openPrivacySettings: @escaping () -> Void,
        moveOutcomeRecorder: (any MoveOutcomeRecording)? = nil,
        routeCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.menuBarItemMemoryStore = itemMemoryStore
        self.newItemInboxStore = newItemInboxStore
        self.groupStore = groupStore
        self.safeModeLaunchState = safeModeLaunchState
        self.hidingService = hidingService
        self.rehideController = rehideController
        self.hoverRevealController = hoverRevealController
        self.screenGeometry = screenGeometry
        self.accessibilityPermissionService = accessibilityPermissionService
        self.menuBarScanCoordinator = menuBarScanCoordinator
        self.iconCaptureCoordinator = iconCaptureCoordinator
        self.renderedIconCache = renderedIconCache
        self.liveStatusSynchronizer = liveStatusSynchronizer
        self.secondBarPositioningService = secondBarPositioningService
        self.separatorFramesProvider = separatorFramesProvider
        self.isHoverRevealSuppressed = isHoverRevealSuppressed
        self.refreshSearchSettings = refreshSearchSettings
        self.refreshSecondBarSettings = refreshSecondBarSettings
        self.workspaceUsageProvider = workspaceUsageProvider
        self.openPrivacySettings = openPrivacySettings
        self.moveOutcomeRecorder = moveOutcomeRecorder
        self.routeCommand = routeCommand
    }

    func showSearch() {
        refreshMenuBarItems()
        searchWindowController.show()
    }

    func showSecondBar() {
        secondBarCompactStripWindowController.hide()
        refreshMenuBarItems()
        secondBarWindowController.show()
    }

    func hideSecondBar() {
        secondBarCompactStripWindowController.hide()
        secondBarWindowController.hide()
    }

    func toggleSecondBar() {
        secondBarCompactStripWindowController.hide()
        refreshMenuBarItems()
        secondBarWindowController.toggle()
    }

    func toggleCompactSecondBar(anchorFrame: CGRect?) {
        secondBarWindowController.hide()
        let snapshots = compactStripSnapshots()
        secondBarCompactStripWindowController.toggleCompactStrip(
            snapshots: snapshots,
            accurateIconReadyIDs: accurateIconReadyIDs(for: snapshots),
            anchorFrame: anchorFrame
        )
    }

    func showSecondBarRequirements(
        _ readiness: ProSecondBarReadinessState,
        anchorFrame: CGRect?
    ) {
        secondBarWindowController.hide()
        secondBarCompactStripWindowController.showRequirements(
            readiness,
            anchorFrame: anchorFrame
        )
    }

    func refreshSecondBarAfterSettingsChanged() {
        secondBarWindowController.refreshAfterSettingsChanged()
    }

    func refreshMenuBarItems() {
        let usesSeededMenuBarItems = FloatingPanelSearchUITestingArguments.usesSeededMenuBarItems
        if safeModeLaunchState.isSafeModeActive {
            diagnosticsLogger.log("Safe Mode skipped manual Pro scan.", level: .warning)
        } else if usesSeededMenuBarItems {
            diagnosticsLogger.log("UI testing seeded menu bar items retained; skipped live manual Pro scan.", level: .debug)
        } else {
            menuBarScanCoordinator.requestManualRefresh()
        }
        liveStatusSynchronizer.refreshSearchAndSecondBarItemCounts()
        if usesSeededMenuBarItems {
            diagnosticsLogger.log("UI testing seeded menu bar items retained; skipped rendered icon refresh.", level: .debug)
        } else {
            iconCaptureCoordinator?.refreshHiddenIconsViaRevealSweepIfAllowed(reason: "surface refresh")
        }
    }

    func refreshMenuBarItemsForMoveVerification() async -> [MenuBarItemSnapshot] {
        guard !safeModeLaunchState.isSafeModeActive else {
            diagnosticsLogger.log("Safe Mode skipped Assisted Move verification scan.", level: .warning)
            liveStatusSynchronizer.refreshSearchAndSecondBarItemCounts()
            return liveStatus.scannedMenuBarItems
        }

        let result = await menuBarScanCoordinator.requestManualRefreshAndWait(
            reason: "assisted move verification"
        )
        liveStatusSynchronizer.refreshSearchAndSecondBarItemCounts()
        return result?.snapshots ?? liveStatus.scannedMenuBarItems
    }

    func resetMovingWarnings() {
        iconMoveService.resetWarnings()
    }

    func performAssistedMove(
        _ snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand
    ) async -> IconMoveResult {
        guard !safeModeLaunchState.isSafeModeActive else {
            return IconMoveResult.skipped(
                command: command,
                itemName: snapshot.owningApplicationName ?? snapshot.title ?? "Menu Bar Item",
                error: .disabled
            )
        }
        return await iconMoveService.moveAfterExternalConfirmation(snapshot, command: command)
    }

    private func availableGroups() -> [IconGroup] {
        IconGroupSort.sort(groupStore.groups).filter(\.isEnabled)
    }

    private func compactStripSnapshots() -> [MenuBarItemSnapshot] {
        liveStatus.scannedMenuBarItems.filter { snapshot in
            !isMenuBarDeclutterStatusItem(snapshot)
        }
    }

    private func accurateIconReadyIDs(for snapshots: [MenuBarItemSnapshot]) -> Set<String> {
        Set(snapshots.compactMap { snapshot in
            renderedIconCache.resolvedImage(for: snapshot) == nil ? nil : snapshot.id
        })
    }

    private func isMenuBarDeclutterStatusItem(_ snapshot: MenuBarItemSnapshot) -> Bool {
        if let bundleIdentifier = snapshot.bundleIdentifier,
           bundleIdentifier == Bundle.main.bundleIdentifier {
            return true
        }
        return snapshot.owningApplicationName == "MenuBarDeclutter"
    }

    @discardableResult
    private func activateCompactStripItem(_ snapshot: MenuBarItemSnapshot) -> Bool {
        let result = routeCommand(MenuBarCommand(
            action: .activateItem,
            target: .menuBarItem(id: snapshot.id),
            source: .secondBar
        ))
        return result.didRun
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

enum FloatingPanelSearchUITestingArguments {
    enum Surface {
        case findIcon
        case secondBar
        case groupPanel

        var queryArgumentName: String {
            switch self {
            case .findIcon:
                "--ui-testing-find-icon-query"
            case .secondBar:
                "--ui-testing-second-bar-query"
            case .groupPanel:
                "--ui-testing-group-panel-query"
            }
        }
    }

    static func query(for surface: Surface) -> String {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--ui-testing") else { return "" }
        return value(for: surface.queryArgumentName, in: arguments)
            ?? value(for: "--ui-testing-floating-panel-query", in: arguments)
            ?? ""
    }

    static var usesSeededMenuBarItems: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--ui-testing")
            && arguments.contains("--ui-testing-seed-menu-bar-items")
    }

    private static func value(for argumentName: String, in arguments: [String]) -> String? {
        let assignmentPrefix = "\(argumentName)="
        if let assignedValue = arguments.first(where: { $0.hasPrefix(assignmentPrefix) }) {
            return String(assignedValue.dropFirst(assignmentPrefix.count)).removingPercentEncoding
        }

        guard let argumentIndex = arguments.firstIndex(of: argumentName),
              arguments.indices.contains(argumentIndex + 1) else {
            return nil
        }

        return arguments[argumentIndex + 1].removingPercentEncoding
    }
}
