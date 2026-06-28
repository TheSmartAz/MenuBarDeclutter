import AppKit

@MainActor
final class AppEnvironment {
    let settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    let appSupportPaths: AppSupportPaths
    let liveStatus: LiveDiagnosticsStatus
    let launchAtLoginService: LaunchAtLoginService
    let diagnosticsExporter: DiagnosticsExporter
    let safeModeService: SafeModeService
    let safeModeLaunchState: SafeModeLaunchState

    let screenGeometry: ScreenGeometryService
    let hidingService: HidingService
    let hotkeyManager: GlobalHotkeyManager
    let rehideController: RehideController
    let hoverRevealController: HoverRevealController
    private let shouldCollapseAfterStartupHealth: Bool
    private let reflectLaunchAtLoginOnStart: Bool

    lazy var accessibilityPermissionService = AccessibilityPermissionService(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var axMenuBarScanner = AXMenuBarScanner(
        diagnosticsLogger: diagnosticsLogger
    )

    lazy var menuBarScanCoordinator = MenuBarScanCoordinator(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        scanner: axMenuBarScanner,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        separatorFramesProvider: { [weak self] in
            MenuBarSeparatorFrames(
                primary: self?.primarySeparatorController.screenFrame,
                alwaysHidden: self?.alwaysHiddenSeparatorController.screenFrame
            )
        }
    )

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
        onSettingsChanged: { [weak self] in
            self?.refreshSearchSettings()
        },
        onOpenPrivacySettings: { [weak self] in
            self?.settingsWindowController.show(section: SettingsSection.privacy)
        }
    )

    private lazy var secondBarPositioningService = SecondBarPositioningService()

    private lazy var iconMoveService = IconMoveService(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        liveStatus: liveStatus,
        diagnosticsLogger: diagnosticsLogger,
        separatorFramesProvider: { [weak self] in
            MenuBarSeparatorFrames(
                primary: self?.primarySeparatorController.screenFrame,
                alwaysHidden: self?.alwaysHiddenSeparatorController.screenFrame
            )
        },
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

    private lazy var secondBarWindowController = SecondBarWindowController(
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
        onSettingsChanged: { [weak self] in
            self?.refreshSecondBarSettings()
        },
        onOpenPrivacySettings: { [weak self] in
            self?.settingsWindowController.show(section: SettingsSection.privacy)
        }
    )

    private lazy var profileStore = ProfileStore(appSupportPaths: appSupportPaths)

    private lazy var profileApplicationService = ProfileApplicationService(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        setVisibility: { [weak self] state in
            self?.hidingService.setVisibility(state)
        }
    )

    private lazy var triggerService = TriggerService(
        settingsStore: settingsStore,
        profileStore: profileStore,
        profileApplicationService: profileApplicationService,
        appSupportPaths: appSupportPaths,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus
    )

    private lazy var automationURLHandler = AutomationURLHandler(
        diagnosticsLogger: diagnosticsLogger,
        expand: { [weak self] in self?.expandHiddenItems() },
        collapse: { [weak self] in self?.collapseHiddenItems() },
        revealAll: { [weak self] in self?.revealAllHiddenItems() },
        showSecondBar: { [weak self] in self?.showSecondBar() },
        applyProfileNamed: { [weak self] name in
            self?.applyProfile(named: name) == true
        }
    )

    private var statusItemMenuOpen = false

    private lazy var systemRecoveryCoordinator = AppEnvironmentSystemRecoveryCoordinator(
        recoverAfterSystemChange: { [weak self] reason in
            self?.recoverAfterSystemChange(reason: reason)
        }
    )

    private lazy var settingsWindowController = SettingsWindowController(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        launchAtLoginService: launchAtLoginService,
        appSupportPaths: appSupportPaths,
        diagnosticsExporter: diagnosticsExporter,
        accessibilityPermissionService: accessibilityPermissionService,
        menuBarScanCoordinator: menuBarScanCoordinator,
        profileStore: profileStore,
        triggerService: triggerService,
        onBehaviorChanged: { [weak self] in
            self?.refreshBehaviorSettings()
        },
        onSearchChanged: { [weak self] in
            self?.refreshSearchSettings()
        },
        onSecondBarChanged: { [weak self] in
            self?.refreshSecondBarSettings()
        },
        onPrivacyChanged: { [weak self] in
            self?.refreshPrivacySettings()
        },
        onProfileDryRun: { [weak self] profile in
            self?.dryRunProfile(profile) ?? ProfileApplicationDryRun(
                itemsToReveal: [],
                itemsToMove: [],
                unavailableItems: [],
                permissionRequirements: ["Profile service unavailable."]
            )
        },
        onProfileApply: { [weak self] profile in
            self?.applyProfile(profile) ?? ProfileApplicationDryRun(
                itemsToReveal: [],
                itemsToMove: [],
                unavailableItems: [],
                permissionRequirements: ["Profile service unavailable."]
            )
        },
        onTriggersChanged: { [weak self] in
            self?.refreshTriggerSettings()
        },
        onResetLayout: { [weak self] in
            self?.resetAppLayout()
        },
        onResetAllSettings: { [weak self] in
            self?.resetAllSettings()
        },
        onResetMovingWarnings: { [weak self] in
            self?.iconMoveService.resetWarnings()
        },
        onShowOnboarding: { [weak self] in
            self?.showOnboarding()
        },
        onRunHealthCheck: { [weak self] in
            _ = self?.runHealthCheck(reason: "manual diagnostics refresh")
        },
        onFixHealthIssues: { [weak self] in
            self?.fixHealthIssues()
        },
        onResetBasicMode: { [weak self] in
            self?.resetAllSettings()
        },
        onDisableProMode: { [weak self] in
            self?.disableProModeForDiagnostics()
        },
        onEnterSafeModeNextLaunch: { [weak self] in
            self?.requestSafeModeNextLaunchForDiagnostics()
        }
    )

    private lazy var onboardingWindowController = OnboardingWindowController(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        onComplete: { [weak self] in
            self?.refreshAfterOnboarding()
        }
    )

    private lazy var statusItemFactory = StatusItemFactory(diagnosticsLogger: diagnosticsLogger)

    private lazy var primarySeparatorController = SeparatorController(
        kind: .primarySeparator,
        factory: statusItemFactory,
        settingsStore: settingsStore,
        screenGeometry: screenGeometry,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var alwaysHiddenSeparatorController = SeparatorController(
        kind: .alwaysHiddenSeparator,
        factory: statusItemFactory,
        settingsStore: settingsStore,
        screenGeometry: screenGeometry,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var menuBuilder = StatusBarMenuBuilder(
        actions: .init(
            expand: { [weak self] in self?.expandHiddenItems() },
            collapse: { [weak self] in self?.collapseHiddenItems() },
            toggle: { [weak self] in self?.toggleHiddenItems() },
            revealAll: { [weak self] in self?.revealAllHiddenItems() },
            toggleRevealAll: { [weak self] in self?.toggleRevealAll() },
            findIcon: { [weak self] in self?.showSearch() },
            showSecondBar: { [weak self] in self?.showSecondBar() },
            hideSecondBar: { [weak self] in self?.hideSecondBar() },
            toggleSecondBar: { [weak self] in self?.toggleSecondBar() },
            refreshMenuBarItems: { [weak self] in self?.refreshMenuBarItems() },
            toggleProMode: { [weak self] in self?.toggleProMode() },
            proModeTitle: { [weak self] in
                self?.settingsStore.proModeEnabled == true ? "Disable Pro Mode" : "Enable Pro Mode"
            },
            canRefreshMenuBarItems: { [weak self] in
                self?.menuBarScanCoordinator.isManualRefreshAvailable == true
            },
            resetSeparatorLength: { [weak self] in self?.resetSeparatorLength() },
            showDragHint: { [weak self] in self?.showDragHint() },
            openSettings: { [weak self] in self?.showSettings() },
            showDiagnostics: { [weak self] in self?.showDiagnostics() },
            showAbout: { [weak self] in self?.showAbout() },
            quit: { [weak self] in self?.quit() }
        )
    )

    private lazy var statusBarController = StatusBarController(
        menuBuilder: menuBuilder,
        diagnosticsLogger: diagnosticsLogger,
        factory: statusItemFactory,
        settingsStore: settingsStore,
        screenGeometry: screenGeometry,
        hidingService: hidingService,
        primarySeparatorController: primarySeparatorController,
        alwaysHiddenSeparatorController: alwaysHiddenSeparatorController,
        rehideController: rehideController,
        hoverRevealController: hoverRevealController,
        hotkeyManager: hotkeyManager,
        liveStatus: liveStatus,
        statusItemMenuOpenDidChange: { [weak self] isOpen in
            self?.statusItemMenuOpen = isOpen
        },
        autoRehideSuppressionProvider: { [weak self] in
            self?.isAutoRehideSuppressed == true
        },
        hoverRevealSuppressionProvider: { [weak self] in
            self?.isHoverRevealSuppressed == true
        }
    )

    private lazy var liveStatusSynchronizer = AppEnvironmentLiveStatusSynchronizer(
        liveStatus: liveStatus,
        settingsStore: settingsStore,
        hidingService: hidingService,
        primarySeparatorController: primarySeparatorController,
        alwaysHiddenSeparatorController: alwaysHiddenSeparatorController,
        hotkeyManager: hotkeyManager,
        hoverRevealController: hoverRevealController,
        rehideController: rehideController,
        accessibilityPermissionService: accessibilityPermissionService
    )

    private lazy var healthCoordinator = AppHealthCoordinator(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        safeModeService: safeModeService,
        safeModeLaunchState: safeModeLaunchState,
        screenGeometry: screenGeometry,
        statusBarController: statusBarController,
        hotkeyManager: hotkeyManager,
        rehideController: rehideController,
        hoverRevealController: hoverRevealController,
        hidingService: hidingService,
        accessibilityPermissionService: accessibilityPermissionService,
        menuBarScanCoordinator: menuBarScanCoordinator,
        secondBarWindowController: secondBarWindowController,
        synchronizeLiveStatus: { [weak self] in
            self?.updateLiveStatusFromServices()
        },
        revealAllHiddenItems: { [weak self] in
            self?.revealAllHiddenItems()
        },
        resetSettingsToDefaults: { [weak self] in
            self?.resetAllSettings()
        },
        refreshTriggerSettings: { [weak self] in
            self?.refreshTriggerSettings()
        }
    )

    init(
        settingsStore: SettingsStore = SettingsStore(),
        diagnosticsLogger: DiagnosticsLogger = DiagnosticsLogger(),
        appSupportPaths: AppSupportPaths = AppSupportPaths(),
        screenGeometry: ScreenGeometryService = ScreenGeometryService(),
        launchAtLoginService: LaunchAtLoginService? = nil,
        reflectLaunchAtLoginOnStart: Bool = true
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.appSupportPaths = appSupportPaths
        self.screenGeometry = screenGeometry
        self.reflectLaunchAtLoginOnStart = reflectLaunchAtLoginOnStart
        self.liveStatus = LiveDiagnosticsStatus()
        let safeModeService = SafeModeService(appSupportPaths: appSupportPaths)
        let safeModeLaunchState = safeModeService.detectLaunchState()
        self.safeModeService = safeModeService
        self.safeModeLaunchState = safeModeLaunchState

        let requestedCollapsedLaunch = settingsStore.startCollapsed || settingsStore.isCollapsed
        self.shouldCollapseAfterStartupHealth = requestedCollapsedLaunch && !safeModeLaunchState.shouldStartExpanded

        // Phase 9: always start expanded until status items pass health checks.
        settingsStore.isCollapsed = false

        self.hidingService = HidingService(
            settingsStore: settingsStore,
            screenGeometry: screenGeometry,
            diagnosticsLogger: diagnosticsLogger
        )
        self.hotkeyManager = GlobalHotkeyManager(diagnosticsLogger: diagnosticsLogger)
        self.rehideController = RehideController(diagnosticsLogger: diagnosticsLogger)
        self.hoverRevealController = HoverRevealController(
            settingsStore: settingsStore,
            screenGeometry: screenGeometry,
            diagnosticsLogger: diagnosticsLogger
        )

        if let launchAtLoginService {
            self.launchAtLoginService = launchAtLoginService
        } else {
            self.launchAtLoginService = LaunchAtLoginService(
                diagnosticsLogger: diagnosticsLogger
            )
        }

        self.diagnosticsExporter = DiagnosticsExporter()
        liveStatus.safeModeActive = safeModeLaunchState.isSafeModeActive
        liveStatus.safeModeReasonSummary = safeModeLaunchState.displaySummary

        // Wire RehideController: when it fires, collapse and update live status.
        rehideController.onRehide = { [weak self] in
            self?.collapseAfterRehide()
        }
        rehideController.autoRehideDelayProvider = { [weak self] in
            self?.settingsStore.autoRehideDelaySeconds ?? AppConstants.defaultAutoRehideDelaySeconds
        }
        rehideController.autoRehideEnabledProvider = { [weak self] in
            guard let self else { return false }
            return self.settingsStore.autoRehideEnabled && !self.isAutoRehideSuppressed
        }
        rehideController.conditionsProvider = { [weak self] in
            self?.currentRehideConditions() ?? RehidePostponementConditions()
        }
        rehideController.onStatusChange = { [weak self] in
            self?.updateLiveStatusFromServices()
        }

        // Wire HoverRevealController: reveal on enter, re-arm rehide on leave.
        hoverRevealController.isCollapsedProvider = { [weak self] in
            self?.hidingService.currentState.isCollapsed ?? false
        }
        hoverRevealController.autoRehideEnabledProvider = { [weak self] in
            guard let self else { return false }
            return self.settingsStore.autoRehideEnabled && !self.isAutoRehideSuppressed
        }
        hoverRevealController.onReveal = { [weak self] in
            self?.expandHiddenItems()
        }
        hoverRevealController.onLeave = { [weak self] in
            self?.armRehide()
        }

        // Wire hotkey: toggle visibility.
        hotkeyManager.onTrigger = { [weak self] in
            self?.toggleHiddenItems()
        }
    }

    func start() {
        // Best-effort: ensure App Support directories exist on launch so the
        // diagnostics export save panel has a default location.
        do {
            try appSupportPaths.ensureDirectoriesExist()
        } catch {
            diagnosticsLogger.log("Could not create App Support directories: \(error.localizedDescription)", level: .warning)
        }
        do {
            try safeModeService.writeRunningMarker()
        } catch {
            diagnosticsLogger.log("Could not write crash marker: \(error.localizedDescription)", level: .warning)
        }

        if safeModeLaunchState.isSafeModeActive {
            diagnosticsLogger.log("Safe Mode active: \(safeModeLaunchState.displaySummary).", level: .warning)
        }

        profileStore.load()
        triggerService.load()
        automationURLHandler.install()

        settingsStore.lastKnownAppVersion = AppConstants.appVersion
        statusBarController.installStatusItem()
        updateLiveStatusFromServices()
        applyInitialBehaviorSettings()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.start()
        } else {
            diagnosticsLogger.log("Safe Mode skipped Pro Mode Accessibility scans.", level: .warning)
        }
        refreshTriggerSettings()
        systemRecoveryCoordinator.startObserving()

        let startupReport = runHealthCheck(reason: "launch")
        let recoveredAtStartup = !startupReport.isHealthy
        if !startupReport.isHealthy {
            healthCoordinator.recover(report: startupReport)
            _ = runHealthCheck(reason: "startup recovery")
        }

        if shouldCollapseAfterStartupHealth,
           liveStatus.healthReport?.status == .ok {
            collapseHiddenItems()
        } else if safeModeLaunchState.shouldStartExpanded || recoveredAtStartup {
            revealAllHiddenItems()
        } else {
            expandHiddenItems()
        }

        // Phase 3: reflect the persisted Launch at Login preference. This only
        // enables the login item when the user previously opted in.
        if reflectLaunchAtLoginOnStart {
            launchAtLoginService.apply(enabled: settingsStore.launchAtLoginEnabled)
        }

        if !settingsStore.hasSeenDragHint {
            showDragHint()
        }

        // Phase 3: present onboarding on first launch (or skip if already completed).
        if !settingsStore.hasCompletedOnboarding {
            onboardingWindowController.show()
        }

        diagnosticsLogger.log("Application environment started in \(settingsStore.appMode.displayName) mode.")
    }

    func stop() {
        secondBarWindowController.hide()
        triggerService.stop()
        automationURLHandler.uninstall()
        systemRecoveryCoordinator.stopObserving()
        menuBarScanCoordinator.stop()
        statusBarController.removeStatusItem()
        do {
            try safeModeService.clearRunningMarker()
        } catch {
            diagnosticsLogger.log("Could not clear crash marker: \(error.localizedDescription)", level: .warning)
        }
    }

    // MARK: Hiding actions

    func expandHiddenItems() {
        statusBarController.expand()
    }

    func collapseHiddenItems() {
        statusBarController.collapse()
    }

    func toggleHiddenItems() {
        statusBarController.toggle()
    }

    func revealAllHiddenItems() {
        statusBarController.revealAll()
    }

    func toggleRevealAll() {
        statusBarController.toggleRevealAll()
    }

    func resetSeparatorLength() {
        statusBarController.resetSeparatorLength()
    }

    func showDragHint() {
        statusBarController.showDragHint()
        settingsStore.hasSeenDragHint = true
    }

    // MARK: Settings-driven refresh

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
        _ = runHealthCheck(reason: "behavior settings changed")
    }

    func refreshSearchSettings() {
        refreshSearchHotkeyRegistration()
        liveStatusSynchronizer.refreshSearchIndexItemCount()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "search settings changed")
        }
        _ = runHealthCheck(reason: "search settings changed")
    }

    func refreshSecondBarSettings() {
        secondBarWindowController.refreshAfterSettingsChanged()
        liveStatusSynchronizer.refreshSecondBarItemCount()
        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.refreshAfterSettingsChanged(reason: "second bar settings changed")
        }
        _ = runHealthCheck(reason: "second bar settings changed")
    }

    func refreshPrivacySettings() {
        guard !safeModeLaunchState.isSafeModeActive else {
            diagnosticsLogger.log("Safe Mode skipped Pro privacy refresh.", level: .warning)
            return
        }
        menuBarScanCoordinator.refreshAfterSettingsChanged()
        _ = runHealthCheck(reason: "privacy settings changed")
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
        if settingsStore.hoverRevealEnabled && !isHoverRevealSuppressed {
            hoverRevealController.start()
            liveStatus.hoverPollingActive = hoverRevealController.isPollingActive
        } else {
            hoverRevealController.stop()
            liveStatus.hoverPollingActive = false
        }
        liveStatusSynchronizer.synchronize()
    }

    // MARK: Phase 3 resets and onboarding

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
        _ = runHealthCheck(reason: "settings reset")

        diagnosticsLogger.log("All settings reset to defaults.")
    }

    func showOnboarding() {
        onboardingWindowController.show()
    }

    private func refreshAfterOnboarding() {
        // Currently a no-op beyond logging; kept as a hook so future phases can
        // react when the user first completes onboarding (e.g. show drag hint).
        diagnosticsLogger.log("Post-onboarding refresh applied.")
    }

    // MARK: Health and recovery

    @discardableResult
    func runHealthCheck(reason: String) -> HealthReport {
        healthCoordinator.runHealthCheck(reason: reason)
    }

    func fixHealthIssues() {
        healthCoordinator.fixHealthIssues()
    }

    private func disableProModeForDiagnostics() {
        healthCoordinator.disableProMode()
    }

    private func requestSafeModeNextLaunchForDiagnostics() {
        healthCoordinator.requestSafeModeNextLaunch()
    }

    private var isAutoRehideSuppressed: Bool {
        healthCoordinator.isAutoRehideSuppressed
    }

    private var isHoverRevealSuppressed: Bool {
        healthCoordinator.isHoverRevealSuppressed
    }

    private func recoverAfterSystemChange(reason: String) {
        rehideController.cancel(reason: .cancelled)
        liveStatus.autoRehideScheduled = false
        hidingService.handleScreenParametersChanged()
        statusBarController.ensureRequiredStatusItemsInstalled()
        statusBarController.reapplyCurrentVisibility()
        secondBarWindowController.refreshAfterSettingsChanged()

        if !safeModeLaunchState.isSafeModeActive {
            menuBarScanCoordinator.scanIfAllowed(reason: reason, force: true)
        }

        _ = runHealthCheck(reason: reason)
        diagnosticsLogger.log("Wake/display recovery completed: \(reason).")
    }

    // MARK: Private helpers

    private func collapseAfterRehide() {
        statusBarController.collapse()
        rehideController.markRehideFired()
        liveStatus.autoRehideScheduled = false
        liveStatus.lastRehideReason = rehideController.lastReason?.rawValue
    }

    private func armRehide() {
        guard settingsStore.autoRehideEnabled, !isAutoRehideSuppressed else { return }
        rehideController.startCountdown(delay: settingsStore.autoRehideDelaySeconds)
        liveStatus.autoRehideScheduled = rehideController.isScheduled
    }

    private func currentRehideConditions() -> RehidePostponementConditions {
        var conditions = RehidePostponementConditions()

        // Mouse in menu bar band — check via screen geometry against
        // NSEvent.mouseLocation. No permissions required.
        let mouse = NSEvent.mouseLocation
        conditions.mouseInMenuBarBand = screenGeometry.isPointInAnyMenuBarBand(mouse)

        // Settings window key check.
        conditions.settingsWindowKey = settingsWindowController.window?.isKeyWindow == true

        conditions.statusItemMenuOpen = statusItemMenuOpen

        return conditions
    }

    private func updateLiveStatusFromServices() {
        liveStatusSynchronizer.synchronize()
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
        if settingsStore.hoverRevealEnabled && !isHoverRevealSuppressed {
            hoverRevealController.start()
        }
        liveStatus.hoverPollingActive = hoverRevealController.isPollingActive
        diagnosticsLogger.log("Runtime reveal behaviors resumed after icon move.", level: .debug)
    }

    private func dryRunProfile(_ profile: ProfileModel) -> ProfileApplicationDryRun {
        profileApplicationService.dryRun(
            profile: profile,
            snapshots: liveStatus.scannedMenuBarItems,
            accessibilityStatus: accessibilityPermissionService.refreshStatus(),
            allowProMoves: false
        )
    }

    private func applyProfile(_ profile: ProfileModel) -> ProfileApplicationDryRun {
        let summary = profileApplicationService.applyBasicSettings(
            profile: profile,
            snapshots: liveStatus.scannedMenuBarItems,
            accessibilityStatus: accessibilityPermissionService.refreshStatus(),
            allowProMoves: false
        )
        refreshBehaviorSettings()
        refreshSecondBarSettings()
        refreshTriggerSettings()
        return summary
    }

    private func applyProfile(named name: String) -> Bool {
        profileStore.load()
        guard let profile = profileStore.profile(named: name) else {
            return false
        }
        _ = applyProfile(profile)
        return true
    }

    // MARK: UI surfaces

    func showSettings(section: SettingsSection = .general) {
        settingsWindowController.show(section: section)
    }

    func showDiagnostics() {
        showSettings(section: .diagnostics)
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

    func refreshMenuBarItems() {
        if safeModeLaunchState.isSafeModeActive {
            diagnosticsLogger.log("Safe Mode skipped manual Pro scan.", level: .warning)
        } else {
            menuBarScanCoordinator.requestManualRefresh()
        }
        liveStatusSynchronizer.refreshSearchAndSecondBarItemCounts()
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

    func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: AppConstants.displayName,
            .version: AppConstants.appVersion
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApp.terminate(nil)
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
