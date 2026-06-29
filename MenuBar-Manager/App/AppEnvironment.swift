import AppKit

@MainActor
final class AppEnvironment {
    /// Shared instance for App Intents access.
    static var shared: AppEnvironment?

    let settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    let appSupportPaths: AppSupportPaths
    let liveStatus: LiveDiagnosticsStatus
    let launchAtLoginService: LaunchAtLoginService
    let diagnosticsExporter: DiagnosticsExporter
    let dogfoodStore: DogfoodStore
    let safeModeService: SafeModeService
    let safeModeLaunchState: SafeModeLaunchState
    let settingsMigrationResult: SettingsMigrationResult

    let screenGeometry: ScreenGeometryService
    let hidingService: HidingService
    let hotkeyManager: GlobalHotkeyManager
    let rehideController: RehideController
    let hoverRevealController: HoverRevealController
    private let shouldCollapseAfterStartupHealth: Bool
    private let reflectLaunchAtLoginOnStart: Bool
    private let presentMigrationNoticeOnStart: Bool

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
            self?.currentSeparatorFrames() ?? AppEnvironment.emptySeparatorFrames
        }
    )

    private lazy var profileAutomationCoordinator = ProfileAutomationCoordinator(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        appSupportPaths: appSupportPaths,
        liveStatus: liveStatus,
        accessibilityPermissionService: accessibilityPermissionService,
        setVisibility: { [weak self] state in
            self?.hidingService.setVisibility(state)
        },
        refreshAfterProfileApply: { [weak self] in
            self?.refreshRuntimeAfterProfileApply()
        },
        enterFullMenuBarMode: { [weak self] in
            self?.enterFullMenuBarMode()
        },
        exitFullMenuBarMode: { [weak self] in
            self?.exitFullMenuBarMode()
        },
        refreshGroups: { [weak self] in
            self?.refreshGroupSettings()
        },
        routeCommand: { [weak self] command in
            self?.commandRouter.route(command)
                ?? MenuBarCommandResult.stopped(
                    command,
                    status: .failed,
                    message: "Command router is unavailable.",
                    diagnosticReason: "routerUnavailable"
                )
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
        dogfoodStore: dogfoodStore,
        accessibilityPermissionService: accessibilityPermissionService,
        menuBarScanCoordinator: menuBarScanCoordinator,
        profileStore: profileAutomationCoordinator.profileStore,
        triggerService: profileAutomationCoordinator.triggerService,
        layoutCoordinator: layoutCoordinator,
        groupStore: groupStore,
        hotkeyBindingStore: hotkeyBindingStore,
        privateAccessCoordinator: privateAccessCoordinator,
        actions: SettingsActions(
            behaviorChanged: { [weak self] in
                self?.refreshBehaviorSettings()
            },
            searchChanged: { [weak self] in
                self?.refreshSearchSettings()
            },
            secondBarChanged: { [weak self] in
                self?.refreshSecondBarSettings()
            },
            privacyChanged: { [weak self] in
                self?.refreshPrivacySettings()
            },
            groupsChanged: { [weak self] in
                self?.refreshGroupSettings()
            },
            dynamicHotkeysChanged: { [weak self] in
                self?.refreshDynamicHotkeys()
            },
            automationSettingsChanged: { [weak self] in
                self?.refreshAutomationSettings()
            },
            profile: SettingsProfileActions(
                dryRun: { [weak self] profile in
                    self?.dryRunProfile(profile) ?? ProfileApplicationDryRun(
                        itemsToReveal: [],
                        itemsToMove: [],
                        unavailableItems: [],
                        permissionRequirements: ["Profile service unavailable."]
                    )
                },
                apply: { [weak self] profile in
                    self?.applyProfile(profile) ?? ProfileApplicationDryRun(
                        itemsToReveal: [],
                        itemsToMove: [],
                        unavailableItems: [],
                        permissionRequirements: ["Profile service unavailable."]
                    )
                }
            ),
            triggersChanged: { [weak self] in
                self?.refreshTriggerSettings()
            },
            resetLayout: { [weak self] in
                self?.resetAppLayout()
            },
            resetAllSettings: { [weak self] in
                self?.resetAllSettings()
            },
            resetMovingWarnings: { [weak self] in
                self?.resetMovingWarnings()
            },
            showOnboarding: { [weak self] in
                self?.showOnboarding()
            },
            runHealthCheck: { [weak self] in
                _ = self?.runHealthCheck(reason: "manual diagnostics refresh")
            },
            fixHealthIssues: { [weak self] in
                self?.fixHealthIssues()
            },
            resetBasicMode: { [weak self] in
                self?.resetAllSettings()
            },
            disableProMode: { [weak self] in
                self?.disableProModeForDiagnostics()
            },
            enterSafeModeNextLaunch: { [weak self] in
                self?.requestSafeModeNextLaunchForDiagnostics()
            }
        )
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
            emergencyRevealAndResetSeparators: { [weak self] in self?.emergencyRevealAndResetSeparators() },
            findIcon: { [weak self] in self?.showSearch() },
            showSecondBar: { [weak self] in self?.showSecondBar() },
            hideSecondBar: { [weak self] in self?.hideSecondBar() },
            toggleSecondBar: { [weak self] in self?.toggleSecondBar() },
            refreshMenuBarItems: { [weak self] in self?.refreshMenuBarItems() },
            toggleProMode: { [weak self] in self?.toggleProMode() },
            proModeTitle: { [weak self] in
                self?.settingsStore.proModeEnabled == true ? "Disable Pro Mode" : "Enable Pro Mode"
            },
            toggleAutomationPaused: { [weak self] in self?.toggleAutomationPaused() },
            automationPausedTitle: { [weak self] in
                self?.settingsStore.automationPaused == true ? "Resume Automation" : "Pause Automation"
            },
            canRefreshMenuBarItems: { [weak self] in
                self?.menuBarScanCoordinator.isManualRefreshAvailable == true
            },
            resetSeparatorLength: { [weak self] in self?.resetSeparatorLength() },
            showDragHint: { [weak self] in self?.showDragHint() },
            openSettings: { [weak self] in self?.showSettings() },
            showDiagnostics: { [weak self] in self?.showDiagnostics() },
            showAbout: { [weak self] in self?.showAbout() },
            quit: { [weak self] in self?.quit() },
            enterFullMenuBarMode: { [weak self] in self?.enterFullMenuBarMode() },
            exitFullMenuBarMode: { [weak self] in self?.exitFullMenuBarMode() },
            fullMenuBarModeIsActive: { [weak self] in
                self?.layoutCoordinator.fullMenuBarModeService.isActive == true
            },
            showLayoutSuggestions: { [weak self] in self?.showLayoutSuggestions() },
            openLayoutSettings: { [weak self] in self?.showSettings(section: .layout) },
            addSpacerDivider: { [weak self] in
                self?.layoutCoordinator.spacerController.add(type: .divider)
            },
            addSpacer: { [weak self] in
                self?.layoutCoordinator.spacerController.add(type: .thinSpacer)
            },
            toggleSpacerMarkers: { [weak self] in
                guard let self else { return }
                self.layoutCoordinator.spacerController.setMarkersVisible(!self.settingsStore.showSpacerMarkers)
            },
            revealInlineAnyway: { [weak self] in
                _ = self?.layoutCoordinator.crowdedRevealRescueService.revealInlineAnyway()
            },
            crowdedRevealIntercepted: { [weak self] in
                self?.layoutCoordinator.crowdedRevealRescueService.lastRevealIntercepted == true
            }
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
            self?.isHoverRevealCurrentlySuppressed() == true
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

    private lazy var menuBarItemSurfaceCoordinator = MenuBarItemSurfaceCoordinator(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        safeModeLaunchState: safeModeLaunchState,
        hidingService: hidingService,
        rehideController: rehideController,
        hoverRevealController: hoverRevealController,
        screenGeometry: screenGeometry,
        accessibilityPermissionService: accessibilityPermissionService,
        menuBarScanCoordinator: menuBarScanCoordinator,
        liveStatusSynchronizer: liveStatusSynchronizer,
        separatorFramesProvider: { [weak self] in
            self?.currentSeparatorFrames() ?? AppEnvironment.emptySeparatorFrames
        },
        isHoverRevealSuppressed: { [weak self] in
            self?.isHoverRevealCurrentlySuppressed() == true
        },
        refreshSearchSettings: { [weak self] in
            self?.refreshSearchSettings()
        },
        refreshSecondBarSettings: { [weak self] in
            self?.refreshSecondBarSettings()
        },
        openPrivacySettings: { [weak self] in
            self?.settingsWindowController.show(section: SettingsSection.privacy)
        }
    )

    private lazy var healthCoordinator = AppHealthCoordinator(
        dependencies: AppHealthCoordinatorDependencies(
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
            secondBarWindowController: menuBarItemSurfaceCoordinator.secondBarWindowController,
            layoutCoordinator: layoutCoordinator,
            groupStore: groupStore,
            groupStatusItemController: groupStatusItemController,
            hotkeyBindingStore: hotkeyBindingStore,
            dynamicHotkeyRegistrationService: dynamicHotkeyRegistrationService,
            privateAccessCoordinator: privateAccessCoordinator
        ),
        actions: AppHealthCoordinatorActions(
            synchronizeLiveStatus: { [weak self] in
                self?.updateLiveStatusFromServices()
            },
            revealAllHiddenItems: { [weak self] in
                self?.revealAllHiddenItems()
            },
            resetAllSettings: { [weak self] in
                self?.resetAllSettings()
            },
            refreshTriggerSettings: { [weak self] in
                self?.refreshTriggerSettings()
            }
        )
    )

    private lazy var settingsRuntimeCoordinator = SettingsRuntimeCoordinator(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        safeModeLaunchState: safeModeLaunchState,
        launchAtLoginService: launchAtLoginService,
        statusBarController: statusBarController,
        hotkeyManager: hotkeyManager,
        hoverRevealController: hoverRevealController,
        menuBarScanCoordinator: menuBarScanCoordinator,
        secondBarWindowController: menuBarItemSurfaceCoordinator.secondBarWindowController,
        triggerService: profileAutomationCoordinator.triggerService,
        liveStatusSynchronizer: liveStatusSynchronizer,
        isHoverRevealSuppressed: { [weak self] in
            self?.isHoverRevealCurrentlySuppressed() == true
        },
        runHealthCheck: { [weak self] reason in
            _ = self?.runHealthCheck(reason: reason)
        },
        showSearch: { [weak self] in
            self?.showSearch()
        }
    )

    private lazy var layoutCoordinator = LayoutCoordinator(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        appSupportPaths: appSupportPaths,
        screenGeometry: screenGeometry,
        hidingService: hidingService,
        scanResultProvider: { [weak self] in
            self?.menuBarScanCoordinator.lastResult
        },
        revealAll: { [weak self] in
            self?.revealAllHiddenItems()
        },
        restoreVisibility: { [weak self] state in
            self?.restoreVisibilityState(state)
        },
        suspendAutoRehide: { [weak self] in
            self?.suspendAutoRehide()
        },
        resumeAutoRehide: { [weak self] in
            self?.resumeAutoRehide()
        },
        showSpacerMarkers: { [weak self] visible in
            self?.settingsStore.showSpacerMarkers = visible
        },
        openSecondBar: { [weak self] in
            self?.showSecondBar()
        },
        enterFullMenuBarMode: { [weak self] in
            self?.enterFullMenuBarMode()
        }
    )

    private lazy var groupStore = IconGroupStore(
        directory: appSupportPaths.applicationSupportDirectory.appendingPathComponent("Groups", isDirectory: true),
        backupsDirectory: appSupportPaths.backupsDirectory,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var privateAccessCoordinator = PrivateAccessCoordinator(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        authService: LocalAuthenticationService(
            allowPasswordFallback: { [weak self] in
                self?.settingsStore.privateAccessAllowDevicePasswordFallback ?? true
            }
        )
    )

    lazy var protectedActionGate = ProtectedActionGate(coordinator: privateAccessCoordinator)

    private lazy var hotkeyBindingStore = HotkeyBindingStore(
        directory: appSupportPaths.applicationSupportDirectory.appendingPathComponent("Hotkeys", isDirectory: true),
        backupsDirectory: appSupportPaths.backupsDirectory,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var groupHighlightOverlayWindow = HighlightOverlayWindow(
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var groupMenuItemActivator = MenuItemActivator(
        settingsStore: settingsStore,
        hidingService: hidingService,
        highlightOverlay: groupHighlightOverlayWindow,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var groupActivationService = IconGroupActivationService(
        activator: groupMenuItemActivator,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var commandRouter = MenuBarCommandRouter(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        safeModeActive: { [weak self] in
            self?.safeModeLaunchState.isSafeModeActive == true
        },
        accessibilityStatus: { [weak self] in
            self?.accessibilityPermissionService.status ?? .notRequested
        },
        privateAccess: protectedActionGate,
        handlers: makeCommandHandlers()
    )

    private lazy var groupPanelWindowController = IconGroupPanelWindowController(
        diagnosticsLogger: diagnosticsLogger,
        activationService: groupActivationService,
        protectedActionGate: protectedActionGate
    )

    private lazy var groupStatusItemController = IconGroupStatusItemController(
        settingsStore: settingsStore,
        groupStore: groupStore,
        factory: IconGroupStatusItemFactory(diagnosticsLogger: diagnosticsLogger),
        diagnosticsLogger: diagnosticsLogger,
        openGroup: { [weak self] group in
            self?.showGroupPanel(group)
        },
        editGroup: { [weak self] _ in
            self?.showSettings(section: .groups)
        }
    )

    private lazy var dynamicHotkeyRegistrationService = DynamicHotkeyRegistrationService(
        settingsStore: settingsStore,
        bindingStore: hotkeyBindingStore,
        hotkeyManager: hotkeyManager,
        protectedActionGate: protectedActionGate,
        diagnosticsLogger: diagnosticsLogger,
        routeAction: { [weak self] action in
            self?.routeDynamicHotkeyAction(action)
                ?? MenuBarCommandResult.stopped(
                    MenuBarCommand(action: .toggle, source: .dynamicHotkey),
                    status: .failed,
                    message: "Command router is unavailable.",
                    diagnosticReason: "routerUnavailable"
                )
        }
    )

    lazy var intentExecutionService = AppIntentExecutionService(commandRouter: commandRouter)

    init(
        settingsStore: SettingsStore = SettingsStore(),
        diagnosticsLogger: DiagnosticsLogger = DiagnosticsLogger(),
        appSupportPaths: AppSupportPaths = AppSupportPaths(),
        screenGeometry: ScreenGeometryService = ScreenGeometryService(),
        launchAtLoginService: LaunchAtLoginService? = nil,
        reflectLaunchAtLoginOnStart: Bool = true,
        presentMigrationNoticeOnStart: Bool = true
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.appSupportPaths = appSupportPaths
        self.screenGeometry = screenGeometry
        self.reflectLaunchAtLoginOnStart = reflectLaunchAtLoginOnStart
        self.presentMigrationNoticeOnStart = presentMigrationNoticeOnStart
        self.liveStatus = LiveDiagnosticsStatus()
        self.settingsMigrationResult = SettingsMigrationService(
            settingsStore: settingsStore,
            appSupportPaths: appSupportPaths,
            diagnosticsLogger: diagnosticsLogger
        ).migrateIfNeeded()
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
        self.dogfoodStore = DogfoodStore(appSupportPaths: appSupportPaths)
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
        AppEnvironment.shared = self
        prepareLaunchStorage()
        dogfoodStore.loadRun(id: settingsStore.dogfoodRunID)
        logSafeModeStatusIfNeeded()
        startRuntimeServices()

        let recoveredAtStartup = runStartupHealthCheckAndRecoveryIfNeeded()
        applyInitialVisibility(recoveredAtStartup: recoveredAtStartup)

        reflectLaunchAtLoginPreferenceIfNeeded()
        presentFirstRunSurfacesIfNeeded()
        presentMigrationNoticeIfNeeded()

        diagnosticsLogger.log("Application environment started in \(settingsStore.appMode.displayName) mode.")
    }

    private func prepareLaunchStorage() {
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
    }

    private func logSafeModeStatusIfNeeded() {
        if safeModeLaunchState.isSafeModeActive {
            diagnosticsLogger.log("Safe Mode active: \(safeModeLaunchState.displaySummary).", level: .warning)
        }
    }

    private func startRuntimeServices() {
        profileAutomationCoordinator.start()

        settingsStore.lastKnownAppVersion = AppConstants.appVersion
        statusBarController.installStatusItem()
        updateLiveStatusFromServices()
        applyInitialBehaviorSettings()
        startMenuBarScanningIfAllowed()
        refreshTriggerSettings()
        systemRecoveryCoordinator.startObserving()
        layoutCoordinator.start()
        groupStore.load()
        hotkeyBindingStore.load()
        if safeModeLaunchState.isSafeModeActive {
            layoutCoordinator.enterSafeMode()
            groupStatusItemController.enterSafeMode()
            dynamicHotkeyRegistrationService.unregisterAll()
        } else {
            groupStatusItemController.refresh()
            dynamicHotkeyRegistrationService.refreshRegistrations()
        }
    }

    private func startMenuBarScanningIfAllowed() {
        guard !safeModeLaunchState.isSafeModeActive else {
            diagnosticsLogger.log("Safe Mode skipped Pro Mode Accessibility scans.", level: .warning)
            return
        }
        menuBarScanCoordinator.start()
    }

    private func runStartupHealthCheckAndRecoveryIfNeeded() -> Bool {
        let startupReport = runHealthCheck(reason: "launch")
        guard !startupReport.isHealthy else {
            return false
        }

        healthCoordinator.recover(report: startupReport)

        // Intentional second check: recovery can recreate status items, reset
        // settings, or refresh permission state. The refreshed report drives
        // the initial collapse/expand decision below.
        _ = runHealthCheck(reason: "startup recovery")
        return true
    }

    private func applyInitialVisibility(recoveredAtStartup: Bool) {
        if shouldCollapseAfterStartupHealth,
           liveStatus.healthReport?.status == .ok {
            collapseHiddenItems()
        } else if safeModeLaunchState.shouldStartExpanded || recoveredAtStartup {
            revealAllHiddenItems()
        } else {
            expandHiddenItems()
        }
    }

    private func reflectLaunchAtLoginPreferenceIfNeeded() {
        guard reflectLaunchAtLoginOnStart else { return }
        launchAtLoginService.apply(enabled: settingsStore.launchAtLoginEnabled)
    }

    private func presentFirstRunSurfacesIfNeeded() {
        if !settingsStore.hasSeenDragHint {
            showDragHint()
        }

        if !settingsStore.hasCompletedOnboarding {
            onboardingWindowController.show()
        }
    }

    private func presentMigrationNoticeIfNeeded() {
        guard presentMigrationNoticeOnStart,
              settingsStore.v01SafeDefaultsNoticePending else {
            return
        }
        settingsStore.v01SafeDefaultsNoticePending = false

        let alert = NSAlert()
        alert.messageText = "Updated to v0.1 safe defaults"
        alert.informativeText = """
        Experimental automation, icon moving, Pro discovery, auto-rehide, hover reveal, hotkeys, and Launch at Login were reset to conservative defaults. Your profiles were left in place.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func stop() {
        dynamicHotkeyRegistrationService.unregisterAll()
        groupStatusItemController.removeAll()
        layoutCoordinator.stop()
        AppEnvironment.shared = nil
        menuBarItemSurfaceCoordinator.hideSecondBar()
        profileAutomationCoordinator.stop()
        systemRecoveryCoordinator.stopObserving()
        menuBarScanCoordinator.stop()
        hotkeyManager.invalidate()
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

    func emergencyRevealAndResetSeparators() {
        statusBarController.revealAll()
        statusBarController.resetSeparatorLength()
        statusBarController.refreshSeparatorVisuals()
        diagnosticsLogger.log(
            "Emergency recovery applied: reveal all and reset separators.",
            level: .warning,
            category: .recovery
        )
        updateLiveStatusFromServices()
    }

    func toggleRevealAll() {
        statusBarController.toggleRevealAll()
    }

    // MARK: Phase 10 Layout actions

    func enterFullMenuBarMode() {
        layoutCoordinator.enterFullMenuBarMode()
    }

    func exitFullMenuBarMode() {
        layoutCoordinator.exitFullMenuBarMode()
    }

    func showLayoutSuggestions() {
        showSettings(section: .layout)
    }

    private func restoreVisibilityState(_ state: HidingVisibilityState) {
        switch state {
        case .collapsed:
            collapseHiddenItems()
        case .expanded:
            expandHiddenItems()
        case .revealAll:
            revealAllHiddenItems()
        }
    }

    private func suspendAutoRehide() {
        rehideController.cancel(reason: .cancelled)
        liveStatus.autoRehideScheduled = false
    }

    private func resumeAutoRehide() {
        // Re-arm rehide if auto-rehide is enabled and currently expanded.
        guard settingsStore.autoRehideEnabled else { return }
        armRehide()
    }

    func resetSeparatorLength() {
        statusBarController.resetSeparatorLength()
    }

    func showDragHint() {
        statusBarController.showDragHint()
        settingsStore.hasSeenDragHint = true
    }

    // MARK: Settings-driven refresh

    func refreshBehaviorSettings() {
        settingsRuntimeCoordinator.refreshBehaviorSettings()
    }

    func refreshSearchSettings() {
        settingsRuntimeCoordinator.refreshSearchSettings()
    }

    func refreshSecondBarSettings() {
        settingsRuntimeCoordinator.refreshSecondBarSettings()
    }

    func refreshPrivacySettings() {
        settingsRuntimeCoordinator.refreshPrivacySettings()
    }

    func refreshGroupSettings() {
        groupStore.load()
        if safeModeLaunchState.isSafeModeActive {
            groupStatusItemController.enterSafeMode()
        } else {
            groupStatusItemController.refresh()
        }
        updateLiveStatusFromServices()
    }

    func refreshDynamicHotkeys() {
        hotkeyBindingStore.load()
        if safeModeLaunchState.isSafeModeActive {
            dynamicHotkeyRegistrationService.unregisterAll()
        } else {
            dynamicHotkeyRegistrationService.refreshRegistrations()
        }
        updateLiveStatusFromServices()
    }

    func refreshAutomationSettings() {
        diagnosticsLogger.log("Automation settings refreshed.", level: .debug, category: .urlAutomation)
    }

    func refreshTriggerSettings() {
        settingsRuntimeCoordinator.refreshTriggerSettings()
    }

    func toggleAutomationPaused() {
        settingsStore.automationPaused.toggle()
        refreshTriggerSettings()
        updateLiveStatusFromServices()
        diagnosticsLogger.log(
            settingsStore.automationPaused ? "Automation paused from status menu." : "Automation resumed from status menu.",
            level: .info,
            category: .trigger
        )
    }

    func applyInitialBehaviorSettings() {
        settingsRuntimeCoordinator.applyInitialBehaviorSettings()
    }

    // MARK: Phase 3 resets and onboarding

    func resetAppLayout() {
        settingsRuntimeCoordinator.resetAppLayout()
    }

    func resetAllSettings() {
        settingsRuntimeCoordinator.resetAllSettings()
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
        menuBarItemSurfaceCoordinator.refreshSecondBarAfterSettingsChanged()

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

    private static let emptySeparatorFrames = MenuBarSeparatorFrames(
        primary: nil,
        alwaysHidden: nil
    )

    private func currentSeparatorFrames() -> MenuBarSeparatorFrames {
        MenuBarSeparatorFrames(
            primary: primarySeparatorController.screenFrame,
            alwaysHidden: alwaysHiddenSeparatorController.screenFrame
        )
    }

    private func isHoverRevealCurrentlySuppressed() -> Bool {
        isHoverRevealSuppressed
    }

    private func refreshRuntimeAfterProfileApply() {
        refreshBehaviorSettings()
        refreshSecondBarSettings()
        refreshTriggerSettings()
    }

    private func dryRunProfile(_ profile: ProfileModel) -> ProfileApplicationDryRun {
        profileAutomationCoordinator.dryRunProfile(profile)
    }

    private func applyProfile(_ profile: ProfileModel) -> ProfileApplicationDryRun {
        profileAutomationCoordinator.applyProfile(profile)
    }

    @discardableResult
    func applyProfileNamed(_ name: String) -> Bool {
        profileAutomationCoordinator.applyProfile(named: name)
    }

    // MARK: UI surfaces

    func showSettings(section: SettingsSection = .general) {
        settingsWindowController.show(section: section)
    }

    func showDiagnostics() {
        showSettings(section: .diagnostics)
    }

    func showSearch() {
        menuBarItemSurfaceCoordinator.showSearch()
    }

    func showSecondBar() {
        menuBarItemSurfaceCoordinator.showSecondBar()
    }

    func showGroupPanel(_ group: IconGroup) {
        let snapshots = liveStatus.scannedMenuBarItems
        let openPanel = { [weak self] in
            self?.groupPanelWindowController.show(group: group, snapshots: snapshots)
        }

        if group.isProtected {
            Task { @MainActor in
                await protectedActionGate.execute(
                    resource: .protectedGroup(group.id),
                    reason: "Unlock to open \(group.name)."
                ) {
                    openPanel()
                }
            }
        } else {
            openPanel()
        }
    }

    func hideSecondBar() {
        menuBarItemSurfaceCoordinator.hideSecondBar()
    }

    func toggleSecondBar() {
        menuBarItemSurfaceCoordinator.toggleSecondBar()
    }

    func refreshMenuBarItems() {
        menuBarItemSurfaceCoordinator.refreshMenuBarItems()
    }

    func resetMovingWarnings() {
        menuBarItemSurfaceCoordinator.resetMovingWarnings()
    }

    func toggleProMode() {
        settingsRuntimeCoordinator.toggleProMode()
    }

    private func makeCommandHandlers() -> MenuBarCommandHandlers {
        var handlers = MenuBarCommandHandlers()
        handlers.expand = { [weak self] in self?.expandHiddenItems() }
        handlers.collapse = { [weak self] in self?.collapseHiddenItems() }
        handlers.toggle = { [weak self] in self?.toggleHiddenItems() }
        handlers.revealAll = { [weak self] in self?.revealAllHiddenItems() }
        handlers.showFindIcon = { [weak self] in self?.showSearch() }
        handlers.showSecondBar = { [weak self] in self?.showSecondBar() }
        handlers.hideSecondBar = { [weak self] in self?.hideSecondBar() }
        handlers.showIconPanel = { [weak self] in self?.showSecondBar() }
        handlers.showLayoutSuggestions = { [weak self] in self?.showLayoutSuggestions() }
        handlers.enterFullMenuBarMode = { [weak self] in self?.enterFullMenuBarMode() }
        handlers.exitFullMenuBarMode = { [weak self] in self?.exitFullMenuBarMode() }
        handlers.pauseAutomation = { [weak self] in
            self?.settingsStore.automationPaused = true
            self?.refreshTriggerSettings()
        }
        handlers.resumeAutomation = { [weak self] in
            self?.settingsStore.automationPaused = false
            self?.refreshTriggerSettings()
        }
        handlers.revealItem = { [weak self] itemID in
            self?.revealMenuBarItem(id: itemID) == true
        }
        handlers.showItemInSecondBar = { [weak self] itemID in
            self?.showMenuBarItemInSecondBar(id: itemID) == true
        }
        handlers.showGroupPanel = { [weak self] groupID in
            self?.showGroupPanel(id: groupID) == true
        }
        handlers.applyProfileNamed = { [weak self] name in
            self?.applyProfileNamed(name) ?? false
        }
        handlers.applyProfileID = { [weak self] id in
            self?.applyProfile(id: id) == true
        }
        handlers.dryRunProfileID = { [weak self] id in
            self?.dryRunProfile(id: id) == true
        }
        handlers.dryRunProfileNamed = { [weak self] name in
            self?.dryRunProfile(named: name) == true
        }
        return handlers
    }

    private func routeDynamicHotkeyAction(_ action: HotkeyAction) -> MenuBarCommandResult {
        switch action {
        case .revealAndHighlightItem(let itemID):
            return commandRouter.route(MenuBarCommand(
                action: .revealItem,
                target: .menuBarItem(id: itemID),
                source: .dynamicHotkey
            ))
        case .openGroup(let groupID):
            return commandRouter.route(MenuBarCommand(
                action: .showGroupPanel,
                target: .group(groupID),
                source: .dynamicHotkey
            ))
        case .openSecondBarFilteredToGroup(let groupID):
            let secondBarResult = commandRouter.route(MenuBarCommand(
                action: .showSecondBar,
                target: .secondBar,
                source: .dynamicHotkey
            ))
            guard secondBarResult.didRun else { return secondBarResult }
            return commandRouter.route(MenuBarCommand(
                action: .showGroupPanel,
                target: .group(groupID),
                source: .dynamicHotkey
            ))
        case .openSecondBarFilteredToItem(let itemID):
            return commandRouter.route(MenuBarCommand(
                action: .showItemInSecondBar,
                target: .menuBarItem(id: itemID),
                source: .dynamicHotkey
            ))
        case .applyProfile(let profileID):
            return commandRouter.route(MenuBarCommand(
                action: .applyProfile,
                target: .profileID(profileID),
                source: .dynamicHotkey
            ))
        case .enterFullMenuBarMode:
            return commandRouter.route(MenuBarCommand(
                action: .enterFullMenuBarMode,
                target: .fullMenuBarMode,
                source: .dynamicHotkey
            ))
        case .exitFullMenuBarMode:
            return commandRouter.route(MenuBarCommand(
                action: .exitFullMenuBarMode,
                target: .fullMenuBarMode,
                source: .dynamicHotkey
            ))
        case .pauseAutomation:
            return commandRouter.route(MenuBarCommand(
                action: .pauseAutomation,
                target: .automation,
                source: .dynamicHotkey
            ))
        case .resumeAutomation:
            return commandRouter.route(MenuBarCommand(
                action: .resumeAutomation,
                target: .automation,
                source: .dynamicHotkey
            ))
        }
    }

    private func revealMenuBarItem(id: String) -> Bool {
        refreshMenuBarItems()
        guard let snapshot = liveStatus.scannedMenuBarItems.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Dynamic hotkey item target unavailable.", level: .warning, category: .hotkey)
            return false
        }
        _ = groupActivationService.activate(snapshot: snapshot)
        return true
    }

    private func showMenuBarItemInSecondBar(id: String) -> Bool {
        guard liveStatus.scannedMenuBarItems.contains(where: { $0.id == id }) else {
            diagnosticsLogger.log("Dynamic hotkey Second Bar item target unavailable.", level: .warning, category: .hotkey)
            return false
        }
        showSecondBar()
        return true
    }

    private func showGroupPanel(id: UUID) -> Bool {
        groupStore.load()
        guard let group = groupStore.groups.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Dynamic hotkey group target unavailable.", level: .warning, category: .hotkey)
            return false
        }
        showGroupPanel(group)
        return true
    }

    private func applyProfile(id: UUID) -> Bool {
        profileAutomationCoordinator.profileStore.load()
        guard let profile = profileAutomationCoordinator.profileStore.profiles.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Dynamic hotkey profile target unavailable.", level: .warning, category: .hotkey)
            return false
        }
        _ = applyProfile(profile)
        return true
    }

    private func dryRunProfile(id: UUID) -> Bool {
        profileAutomationCoordinator.profileStore.load()
        guard let profile = profileAutomationCoordinator.profileStore.profiles.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Dynamic hotkey profile dry-run target unavailable.", level: .warning, category: .hotkey)
            return false
        }
        _ = dryRunProfile(profile)
        return true
    }

    private func dryRunProfile(named name: String) -> Bool {
        profileAutomationCoordinator.profileStore.load()
        guard let profile = profileAutomationCoordinator.profileStore.profile(named: name) else {
            diagnosticsLogger.log("Profile dry-run target unavailable.", level: .warning, category: .profile)
            return false
        }
        _ = dryRunProfile(profile)
        return true
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
}
