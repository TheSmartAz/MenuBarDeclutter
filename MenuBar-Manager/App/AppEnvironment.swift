import AppKit
import ApplicationServices

private let appEnvironmentAccessibilityPromptOptionKey = "AXTrustedCheckOptionPrompt"

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
    let screenCapturePermissionService: ScreenCapturePermissionService

    let screenGeometry: ScreenGeometryService
    let hidingService: HidingService
    let hotkeyManager: GlobalHotkeyManager
    let rehideController: RehideController
    let hoverRevealController: HoverRevealController
    private let shouldCollapseAfterStartupHealth: Bool
    private let reflectLaunchAtLoginOnStart: Bool
    private let presentMigrationNoticeOnStart: Bool
    private let accessibilityTrustProvider: AccessibilityPermissionService.TrustProvider
    private let accessibilityPromptTrustProvider: AccessibilityPermissionService.TrustProvider
    private let accessibilitySystemSettingsOpener: AccessibilityPermissionService.SystemSettingsOpener

    lazy var accessibilityPermissionService = AccessibilityPermissionService(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        trustProvider: accessibilityTrustProvider,
        promptTrustProvider: accessibilityPromptTrustProvider,
        systemSettingsOpener: accessibilitySystemSettingsOpener
    )

    private lazy var menuBarRenderedIconCache: MenuBarRenderedIconCache = {
        let cache = MenuBarRenderedIconCache.shared
        cache.configure(directoryURL: appSupportPaths.renderedIconCacheDirectory)
        return cache
    }()

    private lazy var menuBarIconCaptureCoordinator: MenuBarIconCaptureCoordinator = MenuBarIconCaptureCoordinator(
        settingsStore: settingsStore,
        permissionService: screenCapturePermissionService,
        diagnosticsLogger: diagnosticsLogger,
        cache: menuBarRenderedIconCache,
        currentVisibilityProvider: { [weak self] in
            self?.hidingService.visibilityState ?? .expanded
        },
        setVisibility: { [weak self] state in
            self?.hidingService.setVisibility(state)
        },
        refreshSnapshots: { [weak self] in
            guard let self else { return [] }
            let result = await self.menuBarScanCoordinator.requestManualRefreshAndWait(
                reason: "rendered icon reveal sweep"
            )
            return result?.snapshots ?? self.liveStatus.scannedMenuBarItems
        },
        secondBarWarmUpStatusHandler: { [weak self] inProgress, refreshedCount in
            let result = refreshedCount.map { "Refreshed \($0) thumbnail(s)" }
            self?.liveStatus.updateSecondBarIconWarmUp(
                inProgress: inProgress,
                result: result
            )
        }
    )

    private lazy var axMenuBarScanner = AXMenuBarScanner(
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var menuBarItemDirectActivationService = MenuBarItemDirectActivationService(
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var newMenuBarItemInboxStore = NewMenuBarItemInboxStore(
        fileURL: appSupportPaths.newMenuBarItemInboxFileURL
    )

    private lazy var menuBarItemMemoryStore = MenuBarItemMemoryStore(
        fileURL: appSupportPaths.menuBarItemMemoryFileURL
    )

    /// Local-only collector of per-attempt assisted-move outcomes; feeds the
    /// measured success rate that gates the Level-2 Workspaces work.
    private lazy var moveOutcomeStore = MoveOutcomeStore(appSupportPaths: appSupportPaths)

    private lazy var placementItemPreferenceStore = PlacementItemPreferenceStore(
        fileURL: appSupportPaths.placementItemPreferencesFileURL
    )

    lazy var menuBarScanCoordinator: MenuBarScanCoordinator = MenuBarScanCoordinator(
        settingsStore: settingsStore,
        permissionService: accessibilityPermissionService,
        scanner: axMenuBarScanner,
        diagnosticsLogger: diagnosticsLogger,
        liveStatus: liveStatus,
        newItemInboxStore: newMenuBarItemInboxStore,
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
        },
        exportDiagnostics: ProcessInfo.processInfo.arguments.contains("--qa-diagnostics-url-export-enabled") ? { [weak self] url in
            self?.exportDiagnosticsJSON(to: url) == true
        } : nil,
        showCompactSecondBar: ProcessInfo.processInfo.arguments.contains("--qa-diagnostics-url-export-enabled") ? { [weak self] in
            self?.showCompactSecondBarFromQAURL() == true
        } : nil
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
        newItemInboxStore: newMenuBarItemInboxStore,
        itemMemoryStore: menuBarItemMemoryStore,
        placementPreferenceStore: placementItemPreferenceStore,
        accessibilityPermissionService: accessibilityPermissionService,
        screenCapturePermissionService: screenCapturePermissionService,
        iconCaptureCoordinator: menuBarIconCaptureCoordinator,
        menuBarScanCoordinator: menuBarScanCoordinator,
        profileStore: profileAutomationCoordinator.profileStore,
        triggerService: profileAutomationCoordinator.triggerService,
        layoutCoordinator: layoutCoordinator,
        groupStore: groupStore,
        hotkeyBindingStore: hotkeyBindingStore,
        privateAccessCoordinator: privateAccessCoordinator,
        workspaceSwitchingService: workspaceSwitchingService,
        setBuilderViewModel: setBuilderViewModel,
        functionBarController: functionBarController,
        infoStripController: infoStripController,
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
            commandAvailability: { [weak self] command in
                self?.commandRouter.availability(for: command)
                    ?? MenuBarCommandAvailability.unavailable(
                        status: .failed,
                        message: "Command router is unavailable.",
                        diagnosticReason: "routerUnavailable",
                        failedGate: .targetAvailable
                    )
            },
            routeCommand: { [weak self] command in
                guard let self else {
                    return MenuBarCommandResult.stopped(
                        command,
                        status: .failed,
                        message: "Command router is unavailable.",
                        diagnosticReason: "routerUnavailable"
                    )
                }
                return self.commandRouter.route(command)
            },
            executeAssistedMove: { [weak self] snapshot, command in
                guard let self else {
                    return IconMoveResult.skipped(
                        command: command,
                        itemName: snapshot.owningApplicationName ?? snapshot.title ?? "Menu Bar Item",
                        error: .disabled
                    )
                }
                return await self.executeAssistedMoveFromSettings(snapshot, command: command)
            },
            applyWorkspaceLayout: { [weak self] in
                await self?.applyActiveWorkspaceLayout() ?? nil
            },
            isWorkspaceLayoutApplyEnabled: { [weak self] in
                guard let self else { return false }
                return self.settingsStore.iconMovingEnabled
                    && self.settingsStore.proModeEnabled
                    && self.accessibilityPermissionService.status == .granted
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
            showDragHint: { [weak self] in
                self?.showDragHint()
            },
            runHealthCheck: { [weak self] in
                _ = self?.runHealthCheck(reason: "manual diagnostics refresh")
            },
            fixHealthIssues: { [weak self] in
                self?.fixHealthIssues()
            },
            expand: { [weak self] in
                self?.expandHiddenItems()
            },
            revealAll: { [weak self] in
                self?.revealAllHiddenItems()
            },
            recreateStatusItems: { [weak self] in
                self?.performRecoveryAction(.recreateStatusItems)
            },
            disableAutoRehideTemporarily: { [weak self] in
                self?.performRecoveryAction(.disableAutoRehideTemporarily)
            },
            disableHoverRevealTemporarily: { [weak self] in
                self?.performRecoveryAction(.disableHoverRevealTemporarily)
            },
            resetCurrentWorkspaceLayout: { [weak self] in
                self?.performRecoveryAction(.resetCurrentWorkspaceLayout)
            },
            removeMissingWorkspaceGroupReferences: { [weak self] in
                self?.performRecoveryAction(.removeMissingWorkspaceGroupReferences)
            },
            discardSetBuilderDraft: { [weak self] in
                self?.performRecoveryAction(.discardSetBuilderDraft)
            },
            disableFunctionBarPreview: { [weak self] in
                self?.performRecoveryAction(.disableFunctionBarPreview)
            },
            disableInfoStripPreview: { [weak self] in
                self?.performRecoveryAction(.disableInfoStripPreview)
            },
            disableSetBuilderPreview: { [weak self] in
                self?.performRecoveryAction(.disableSetBuilderPreview)
            },
            resetBasicMode: { [weak self] in
                self?.resetAllSettings()
            },
            disableProMode: { [weak self] in
                self?.disableProModeForDiagnostics()
            },
            enterSafeModeNextLaunch: { [weak self] in
                self?.requestSafeModeNextLaunchForDiagnostics()
            },
            openTroubleshootingGuide: { [weak self] in
                self?.openTroubleshootingGuide()
            }
        )
    )

    private lazy var onboardingWindowController = OnboardingWindowController(
        settingsStore: settingsStore,
        diagnosticsLogger: diagnosticsLogger,
        onComplete: { [weak self] in
            self?.refreshAfterOnboarding()
        },
        onOpenSettings: { [weak self] in
            self?.showSettings()
        },
        onOpenArrange: { [weak self] in
            self?.showSettings(section: .arrange)
        },
        onOpenWorkspaces: { [weak self] in
            self?.showSettings(section: .workspacesPreview)
        },
        onCreateSampleWorkspace: { [weak self] in
            self?.createSampleWorkspaceFromOnboarding()
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
            revealAll: { [weak self] in self?.revealAllFromStatusMenu() },
            toggleRevealAll: { [weak self] in self?.toggleRevealAllFromStatusMenu() },
            emergencyRevealAndResetSeparators: { [weak self] in self?.emergencyRevealAndResetSeparators() },
            findIcon: { [weak self] in self?.showSearch() },
            showSecondBar: { [weak self] in self?.showSecondBar() },
            hideSecondBar: { [weak self] in self?.hideSecondBar() },
            toggleSecondBar: { [weak self] in self?.toggleSecondBar() },
            refreshMenuBarItems: { [weak self] in self?.refreshMenuBarItems() },
            toggleProMode: { [weak self] in self?.toggleProMode() },
            proModeTitle: { [weak self] in
                self?.settingsStore.proModeEnabled == true ? "Disable Optional Pro" : "Enable Optional Pro"
            },
            toggleAutomationPaused: { [weak self] in self?.toggleAutomationPaused() },
            automationPausedTitle: { [weak self] in
                self?.settingsStore.automationPaused == true ? "Resume Automation" : "Pause Automation"
            },
            automationPaused: { [weak self] in
                self?.settingsStore.automationPaused == true
            },
            secondBarVisible: { [weak self] in
                self?.liveStatus.secondBarVisible == true
            },
            findIconStatusMenuEnabled: { [weak self] in
                self?.settingsStore.searchEnabled == true
            },
            secondBarStatusMenuEnabled: { [weak self] in
                self?.settingsStore.secondBarEnabled == true
            },
            safeModeActive: { [weak self] in
                self?.safeModeLaunchState.isSafeModeActive == true
            },
            advancedMenuRelevant: { [weak self] in
                guard let self else { return false }
                return StatusMenuAdvancedVisibility(
                    proModeEnabled: self.settingsStore.proModeEnabled,
                    automationPaused: self.settingsStore.automationPaused,
                    iconMovingEnabled: self.settingsStore.iconMovingEnabled,
                    menuBarSpacingLabsEnabled: self.settingsStore.menuBarSpacingLabsEnabled,
                    dogfoodModeEnabled: self.settingsStore.dogfoodModeEnabled,
                    workspacesPreviewEnabled: self.settingsStore.workspacesPreviewEnabled,
                    functionBarPreviewEnabled: self.settingsStore.functionBarPreviewEnabled,
                    infoStripPreviewEnabled: self.settingsStore.infoStripPreviewEnabled
                ).isRelevant
            },
            canShowNewMenuBarItems: { [weak self] in
                self?.canShowNewMenuBarItems == true
            },
            newMenuBarItemReviewCount: { [weak self] in
                self?.liveStatus.newMenuBarItemReviewCount ?? 0
            },
            commandAvailability: { [weak self] command in
                self?.commandRouter.availability(for: command)
                    ?? MenuBarCommandAvailability.unavailable(
                        status: .failed,
                        message: "Command router is unavailable.",
                        diagnosticReason: "routerUnavailable",
                        failedGate: .targetAvailable
                    )
            },
            routeCommand: { [weak self] command in
                self?.routeStatusMenuCommand(command)
            },
            dogfoodModeEnabled: { [weak self] in
                self?.settingsStore.dogfoodModeEnabled == true
            },
            canRefreshMenuBarItems: { [weak self] in
                self?.menuBarScanCoordinator.isManualRefreshAvailable == true
            },
            resetSeparatorLength: { [weak self] in self?.resetSeparatorLength() },
            resetLayout: { [weak self] in self?.resetAppLayout() },
            showDragHint: { [weak self] in self?.showDragHint() },
            openArrangeSettings: { [weak self] in self?.showSettings(section: .arrange) },
            openNewMenuBarItems: { [weak self] in self?.showSettings(section: .findRescue) },
            openRecoverySettings: { [weak self] in self?.showSettings(section: .recovery) },
            openSettings: { [weak self] in self?.showSettings() },
            showDiagnostics: { [weak self] in self?.showDiagnostics() },
            showAbout: { [weak self] in self?.showAbout() },
            quit: { [weak self] in self?.quit() },
            openProfilesSettings: { [weak self] in self?.showSettings(section: .profiles) },
            enterFullMenuBarMode: { [weak self] in self?.enterFullMenuBarMode() },
            exitFullMenuBarMode: { [weak self] in self?.exitFullMenuBarMode() },
            fullMenuBarModeIsActive: { [weak self] in
                self?.layoutCoordinator.fullMenuBarModeService.isActive == true
            },
            showLayoutSuggestions: { [weak self] in self?.showLayoutSuggestions() },
            openLayoutSettings: { [weak self] in self?.showSettings(section: .layout) },
            openAdvancedSettings: { [weak self] in self?.showSettings(section: .advanced) },
            openWorkspacesPreview: { [weak self] in self?.showWorkspacePreview() },
            workspacesPreviewEnabled: { [weak self] in
                self?.settingsStore.workspacesPreviewEnabled == true
            },
            functionBarPreviewEnabled: { [weak self] in
                self?.settingsStore.functionBarPreviewEnabled == true
            },
            infoStripPreviewEnabled: { [weak self] in
                self?.settingsStore.infoStripPreviewEnabled == true
            },
            functionBarVisible: { [weak self] in
                self?.functionBarController.displayState.isVisible == true
            },
            infoStripVisible: { [weak self] in
                if let state = self?.infoStripController.displayState,
                   case .visible = state {
                    return true
                }
                return false
            },
            showFunctionBarPreview: { [weak self] in
                _ = self?.commandRouter.route(MenuBarCommand(action: .showFunctionBar, target: .functionBar, source: .statusMenu))
            },
            hideFunctionBarPreview: { [weak self] in
                _ = self?.commandRouter.route(MenuBarCommand(action: .hideFunctionBar, target: .functionBar, source: .statusMenu))
            },
            showInfoStripPreview: { [weak self] in
                _ = self?.commandRouter.route(MenuBarCommand(action: .showInfoStrip, target: .infoStrip, source: .statusMenu))
            },
            hideInfoStripPreview: { [weak self] in
                _ = self?.commandRouter.route(MenuBarCommand(action: .hideInfoStrip, target: .infoStrip, source: .statusMenu))
            },
            previewSpacingPreset: { [weak self] in self?.showSettings(section: .layout) },
            showAssistedMoveGuide: { [weak self] in self?.showSettings(section: .arrange) },
            addSpacerDivider: { [weak self] in
                self?.layoutCoordinator.spacerController.add(type: SpacerItemType.divider)
            },
            addSpacer: { [weak self] in
                self?.layoutCoordinator.spacerController.add(type: SpacerItemType.thinSpacer)
            },
            toggleSpacerMarkers: { [weak self] in
                guard let self else { return }
                self.layoutCoordinator.spacerController.setMarkersVisible(!self.settingsStore.showSpacerMarkers)
            },
            revealInlineAnyway: { [weak self] in
                _ = self?.layoutCoordinator.crowdedRevealRescueService.revealInlineAnyway()
                self?.revealAllHiddenItemsInline()
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
        },
        primaryClickAction: { [weak self] button in
            guard let self else { return false }
            return self.handleStatusItemPrimaryClick(anchorFrame: button.menuBarDeclutterScreenFrame)
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
        itemMemoryStore: menuBarItemMemoryStore,
        newItemInboxStore: newMenuBarItemInboxStore,
        groupStore: groupStore,
        safeModeLaunchState: safeModeLaunchState,
        hidingService: hidingService,
        rehideController: rehideController,
        hoverRevealController: hoverRevealController,
        screenGeometry: screenGeometry,
        accessibilityPermissionService: accessibilityPermissionService,
        menuBarScanCoordinator: menuBarScanCoordinator,
        iconCaptureCoordinator: menuBarIconCaptureCoordinator,
        renderedIconCache: menuBarRenderedIconCache,
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
        workspaceUsageProvider: { [weak self] in
            guard let self else { return nil }
            return WorkspaceUsageIndex().rebuild(
                snapshot: self.workspaceSwitchingService.currentSnapshot(),
                groups: self.groupStore.groups,
                discoveredSnapshots: self.liveStatus.scannedMenuBarItems
            )
        },
        openPrivacySettings: { [weak self] in
            self?.settingsWindowController.show(section: SettingsSection.privacy)
        },
        moveOutcomeRecorder: moveOutcomeStore,
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

    /// Level-2 layout coordinator (inert until UI drives it). The apply gate
    /// reuses the Assisted Move opt-in conditions.
    private lazy var workspaceLayoutCoordinator = menuBarItemSurfaceCoordinator.makeWorkspaceLayoutCoordinator(
        isApplyEnabled: { [weak self] in
            guard let self else { return false }
            return self.settingsStore.iconMovingEnabled
                && self.settingsStore.proModeEnabled
                && self.accessibilityPermissionService.status == .granted
        }
    )

    /// Entry point for a future "apply layout on switch" control: applies the
    /// active workspace's target layout to the real bar iff the apply gate is on.
    func applyActiveWorkspaceLayout() async -> WorkspaceLayoutApplyResult? {
        let workspace = workspaceSwitchingService.activeWorkspace()
        return await workspaceLayoutCoordinator.applyLayoutIfEnabled(for: workspace)
    }

    /// Entry point for a future "Save current layout to workspace" control.
    func captureLayoutIntoActiveWorkspace() async {
        let workspace = workspaceSwitchingService.activeWorkspace()
        let updated = await workspaceLayoutCoordinator.captureCurrentLayout(into: workspace)
        _ = workspaceSwitchingService.updateWorkspace(updated)
    }

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
            privateAccessCoordinator: privateAccessCoordinator,
            workspaceDiagnostics: { [weak self] in
                guard let self else { return nil }
                return WorkspaceDiagnosticsSnapshot.make(
                    settingsStore: self.settingsStore,
                    snapshot: self.workspaceSwitchingService.currentSnapshot(),
                    validationIssues: self.workspaceStore.lastValidationIssues,
                    lastLoadStatus: self.workspaceStore.lastLoadStatus,
                    knownGroupIDs: Set(self.groupStore.groups.map(\.id)),
                    protectedGroupIDs: Set(self.groupStore.groups.filter(\.isProtected).map(\.id)),
                    knownProfileIDs: Set(self.profileAutomationCoordinator.profileStore.profiles.map(\.id)),
                    availableMenuBarItemHashes: self.availableMenuBarItemHashesForWorkspaceDiagnostics()
                )
            },
            functionBarVisible: { [weak self] in
                self?.functionBarController.activeState().isVisible == true
            },
            infoStripVisible: { [weak self] in
                guard let state = self?.infoStripController.displayState else { return false }
                if case .visible = state { return true }
                return false
            },
            infoStripSelectedTileProviderCount: { [weak self] in
                self?.activeInfoStripConfigForHealth().selectedTileProviderIDs.count ?? 0
            },
            infoStripAvailableSelectedTileProviderCount: { [weak self] in
                self?.availableSelectedInfoTileProviderCountForHealth() ?? 0
            },
            infoStripInvalidProviderIDCount: { [weak self] in
                self?.invalidInfoTileProviderIDCountForHealth() ?? 0
            },
            infoStripRotationResult: { [weak self] in
                self?.infoStripController.lastRotationResult
            },
            infoStripPlacementFailed: { [weak self] in
                self?.infoStripController.lastPlacementFailed == true
            },
            infoStripTimingInvalid: { [weak self] in
                self?.infoStripTimingInvalidForHealth() == true
            }
        ),
        actions: AppHealthCoordinatorActions(
            synchronizeLiveStatus: { [weak self] in
                self?.updateLiveStatusFromServices()
            },
            revealAllHiddenItems: { [weak self] in
                self?.revealAllHiddenItemsInline()
            },
            resetAllSettings: { [weak self] in
                self?.resetAllSettings()
            },
            refreshTriggerSettings: { [weak self] in
                self?.refreshTriggerSettings()
            },
            resetWorkspacesToDefaults: { [weak self] in
                _ = self?.workspaceSwitchingService.resetWorkspacesToDefaults()
                self?.refreshWorkspacePreviewRuntime()
            },
            resetCurrentWorkspaceLayout: { [weak self] in
                self?.resetCurrentWorkspaceLayoutForRecovery()
            },
            removeMissingWorkspaceGroupReferences: { [weak self] in
                self?.removeMissingWorkspaceGroupReferencesForRecovery()
            },
            discardSetBuilderDraft: { [weak self] in
                self?.discardSetBuilderDraftForRecovery()
            },
            hideFunctionBar: { [weak self] in
                self?.hideFunctionBarPreview(source: .settings)
            },
            disableFunctionBarPreview: { [weak self] in
                self?.disableFunctionBarPreviewForRecovery()
            },
            disableSetBuilderPreview: { [weak self] in
                self?.disableSetBuilderPreviewForRecovery()
            },
            hideInfoStrip: { [weak self] in
                self?.hideInfoStripPreview()
            },
            showFunctionBar: { [weak self] in
                self?.showFunctionBarPreview(source: .settings)
            },
            disableInfoStripPreview: { [weak self] in
                self?.disableInfoStripPreviewForRecovery()
            },
            resetInfoStripSettings: { [weak self] in
                self?.resetInfoStripSettingsForRecovery()
            },
            resetInfoStripPlacement: { [weak self] in
                self?.resetInfoStripPlacementForRecovery()
            },
            clearInvalidInfoStripProviders: { [weak self] in
                self?.clearInvalidInfoStripProvidersForRecovery()
            },
            showFunctionBarInstead: { [weak self] in
                self?.showFunctionBarInsteadForRecovery()
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
            self?.revealAllHiddenItemsInline()
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
            self?.routeCrowdedRescueCommand(
                action: .showSecondBar,
                target: .secondBar
            )
        },
        openFunctionBar: { [weak self] in
            self?.showFunctionBarPreview(source: .commandCenter)
        },
        enterFullMenuBarMode: { [weak self] in
            self?.enterFullMenuBarMode()
        },
        showLayoutSuggestions: { [weak self] in
            self?.showLayoutSuggestions()
        }
    )

    private lazy var groupStore = IconGroupStore(
        directory: appSupportPaths.applicationSupportDirectory.appendingPathComponent("Groups", isDirectory: true),
        backupsDirectory: appSupportPaths.backupsDirectory,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var workspaceStore = WorkspaceStore(
        fileURL: appSupportPaths.workspaceStoreFileURL,
        backupsDirectory: appSupportPaths.workspaceBackupsDirectory,
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var initialWorkspaceSnapshot: WorkspaceStoreSnapshot = {
        do {
            return try workspaceStore.load()
        } catch {
            diagnosticsLogger.log(
                "Workspace store failed to load; using in-memory defaults: \(error.localizedDescription)",
                level: .warning,
                category: .recovery
            )
            return WorkspaceStoreSnapshot.defaults()
        }
    }()

    private lazy var workspaceSwitchingService = WorkspaceSwitchingService(
        store: workspaceStore,
        initialSnapshot: initialWorkspaceSnapshot,
        safeModeActive: { [weak self] in
            self?.safeModeLaunchState.isSafeModeActive == true
        }
    )

    private lazy var functionBarItemResolver = FunctionBarItemResolver(
        groupsProvider: { [weak self] in
            self?.groupStore.groups ?? []
        },
        snapshotsProvider: { [weak self] in
            self?.liveStatus.scannedMenuBarItems ?? []
        },
        proDiscoveryAvailable: { [weak self] in
            guard let self else { return false }
            return self.settingsStore.isProDiscoveryAvailable
        },
        accessibilityAvailable: { [weak self] in
            self?.accessibilityPermissionService.status == .granted
        }
    )

    private lazy var functionBarActionDispatcher = FunctionBarActionDispatcher(
        routeCommand: { [weak self] command in
            self?.commandRouter.route(command)
                ?? MenuBarCommandResult.stopped(
                    command,
                    status: .failed,
                    message: "Command router is unavailable.",
                    diagnosticReason: "routerUnavailable"
                )
        },
        openSettings: { [weak self] in self?.showSettings() },
        openRecovery: { [weak self] in self?.showSettings(section: .recovery) },
        openWorkspacePreview: { [weak self] in self?.showSettings(section: .workspacesPreview) },
        showFunctionBar: { [weak self] in self?.showFunctionBarPreview(source: .commandCenter) },
        hideFunctionBar: { [weak self] in self?.hideFunctionBarPreview(source: .commandCenter) },
        showInfoStrip: { [weak self] in self?.showInfoStripPreview() },
        hideInfoStrip: { [weak self] in self?.hideInfoStripPreview() }
    )

    private lazy var functionBarController = FunctionBarController(
        settingsStore: settingsStore,
        switchingService: workspaceSwitchingService,
        resolver: functionBarItemResolver,
        dispatcher: functionBarActionDispatcher,
        safeModeActive: { [weak self] in
            self?.safeModeLaunchState.isSafeModeActive == true
        },
        statusItemAnchorProvider: { [weak self] in
            self?.currentSeparatorFrames().primary
        },
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var infoStripController = InfoStripController(
        settingsStore: settingsStore,
        switchingService: workspaceSwitchingService,
        safeModeActive: { [weak self] in
            self?.safeModeLaunchState.isSafeModeActive == true
        },
        statusItemAnchorProvider: { [weak self] in
            self?.currentSeparatorFrames().primary
        },
        contextBuilder: { [weak self] in
            self?.currentInfoTileContext() ?? InfoTileContext.empty
        },
        actionDispatcher: { [weak self] action in
            self?.dispatchInfoTileAction(action)
        },
        showFunctionBar: { [weak self] in
            self?.showFunctionBarPreview(source: .workspaceDisplay)
        },
        diagnosticsLogger: diagnosticsLogger
    )

    private lazy var workspaceDisplayCoordinator = WorkspaceDisplayCoordinator(
        functionBarController: functionBarController,
        infoStripController: infoStripController,
        switchingService: workspaceSwitchingService,
        safeModeActive: { [weak self] in
            self?.safeModeLaunchState.isSafeModeActive == true
        },
        infoStripAutoShowEnabled: { [weak self] in
            self?.settingsStore.infoStripAutoShowEnabled == true
        }
    )

    private lazy var setBuilderViewModel: SetBuilderViewModel = {
        let model = SetBuilderViewModel(
            switchingService: workspaceSwitchingService,
            groupStore: groupStore,
            newItemInboxStore: newMenuBarItemInboxStore,
            snapshotsProvider: { [weak self] in
                self?.liveStatus.scannedMenuBarItems ?? []
            },
            settingsStore: settingsStore
        )
        model.onCommitted = { [weak self] in
            self?.refreshWorkspacePreviewRuntime()
        }
        model.onPreviewFunctionBar = { [weak self] in
            self?.showFunctionBarPreview(source: .settings)
        }
        return model
    }()

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
        diagnosticsLogger: diagnosticsLogger,
        expandHiddenItems: { [weak self] in
            self?.performCrowdedReveal(intent: .revealItem) {
                self?.expandHiddenItemsInline()
            }
        },
        revealAllItems: { [weak self] in
            self?.performCrowdedReveal(intent: .revealItem) {
                self?.revealAllHiddenItemsInline()
            }
        }
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
        screenCaptureStatus: { [weak self] in
            self?.screenCapturePermissionService.refreshStatus() ?? .unknown
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
            self?.routeStatusMenuCommand(MenuBarCommand(
                action: .showGroupPanel,
                target: .group(group.id),
                source: .statusMenu
            ))
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
        screenCapturePermissionService: ScreenCapturePermissionService? = nil,
        launchAtLoginService: LaunchAtLoginService? = nil,
        reflectLaunchAtLoginOnStart: Bool = true,
        presentMigrationNoticeOnStart: Bool = true,
        accessibilityTrustProvider: @escaping AccessibilityPermissionService.TrustProvider = {
            AXIsProcessTrustedWithOptions([
                appEnvironmentAccessibilityPromptOptionKey: false
            ] as CFDictionary)
        },
        accessibilityPromptTrustProvider: @escaping AccessibilityPermissionService.TrustProvider = {
            AXIsProcessTrustedWithOptions([
                appEnvironmentAccessibilityPromptOptionKey: true
            ] as CFDictionary)
        },
        accessibilitySystemSettingsOpener: @escaping AccessibilityPermissionService.SystemSettingsOpener = {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
                return false
            }
            return NSWorkspace.shared.open(url)
        }
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.appSupportPaths = appSupportPaths
        self.screenGeometry = screenGeometry
        self.screenCapturePermissionService = screenCapturePermissionService ?? ScreenCapturePermissionService(
            settingsStore: settingsStore
        )
        self.reflectLaunchAtLoginOnStart = reflectLaunchAtLoginOnStart
        self.presentMigrationNoticeOnStart = presentMigrationNoticeOnStart
        self.accessibilityTrustProvider = accessibilityTrustProvider
        self.accessibilityPromptTrustProvider = accessibilityPromptTrustProvider
        self.accessibilitySystemSettingsOpener = accessibilitySystemSettingsOpener
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
        liveStatus.updateNewMenuBarItemReviewCount(newMenuBarItemInboxStore.inbox.reviewCount)
        statusBarController.installStatusItem()
        updateLiveStatusFromServices()
        applyInitialBehaviorSettings()
        startMenuBarScanningIfAllowed()
        refreshTriggerSettings()
        systemRecoveryCoordinator.startObserving()
        layoutCoordinator.start()
        groupStore.load()
        hotkeyBindingStore.load()
        _ = workspaceSwitchingService.currentSnapshot()
        functionBarController.start()
        setBuilderViewModel.refresh()
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
            diagnosticsLogger.log("Safe Mode skipped Optional Pro Accessibility scans.", level: .warning)
            return
        }
        guard !FloatingPanelSearchUITestingArguments.usesSeededMenuBarItems else {
            diagnosticsLogger.log("UI testing seeded menu bar items retained; skipped startup AX scan.", level: .debug)
            return
        }
        menuBarScanCoordinator.scanCompleted = { [weak self] result in
            self?.menuBarIconCaptureCoordinator.refreshVisibleIconsIfAllowed(
                snapshots: result.snapshots,
                reason: "AX scan"
            )
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
        Labs automation, icon moving, Optional Pro discovery, auto-rehide, hover reveal, hotkeys, and Launch at Login were reset to conservative defaults. Your profiles were left in place.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func stop() {
        infoStripController.hide()
        functionBarController.stop()
        dynamicHotkeyRegistrationService.unregisterAll()
        groupStatusItemController.removeAll()
        layoutCoordinator.stop()
        AppEnvironment.shared = nil
        menuBarItemSurfaceCoordinator.hideSecondBar()
        profileAutomationCoordinator.stop()
        systemRecoveryCoordinator.stopObserving()
        menuBarIconCaptureCoordinator.stop()
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
        performCrowdedReveal(intent: .expand) { [weak self] in
            self?.expandHiddenItemsInline()
        }
    }

    func collapseHiddenItems() {
        statusBarController.collapse()
    }

    func toggleHiddenItems() {
        if hidingService.visibilityState.isCollapsed {
            expandHiddenItems()
        } else {
            statusBarController.toggle()
        }
    }

    func revealAllHiddenItems() {
        performCrowdedReveal(intent: .revealAll) { [weak self] in
            self?.revealAllHiddenItemsInline()
        }
    }

    private func expandHiddenItemsInline() {
        statusBarController.expand()
    }

    private func revealAllHiddenItemsInline() {
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
        if hidingService.visibilityState.isRevealAll {
            statusBarController.toggleRevealAll()
        } else {
            revealAllHiddenItems()
        }
    }

    private func revealAllFromStatusMenu() {
        guard shouldProtectAlwaysHiddenReveal else {
            revealAllHiddenItems()
            return
        }

        routeStatusMenuCommand(MenuBarCommand(
            action: .revealAlwaysHiddenZone,
            target: .globalVisibility,
            source: .statusMenu
        ))
    }

    private func toggleRevealAllFromStatusMenu() {
        guard !hidingService.visibilityState.isRevealAll else {
            toggleRevealAll()
            return
        }

        guard shouldProtectAlwaysHiddenReveal else {
            toggleRevealAll()
            return
        }

        routeStatusMenuCommand(MenuBarCommand(
            action: .revealAlwaysHiddenZone,
            target: .globalVisibility,
            source: .statusMenu
        ))
    }

    private var shouldProtectAlwaysHiddenReveal: Bool {
        settingsStore.alwaysHiddenEnabled && privateAccessCoordinator.isProtected(.alwaysHiddenZone)
    }

    private func routeStatusMenuCommand(_ command: MenuBarCommand) {
        guard let resource = command.action.privateAccessResource(for: command.target),
              !protectedActionGate.canAccessWithoutPrompt(resource) else {
            _ = commandRouter.route(command)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            var didRoute = false
            let didUnlockAndRun = await self.protectedActionGate.execute(
                resource: resource,
                reason: self.statusMenuUnlockReason(for: command)
            ) {
                didRoute = true
                _ = self.commandRouter.route(command)
            }

            guard !didUnlockAndRun, !didRoute else { return }
            let result = MenuBarCommandResult.stopped(
                command,
                status: .requiresUnlock,
                message: "This command requires Private Access unlock.",
                diagnosticReason: "privateAccessLocked"
            )
            self.diagnosticsLogger.log(
                "Status menu command did not run because Private Access unlock was not completed.",
                level: .info,
                category: .privacy,
                metadata: MenuBarCommandDiagnostics.metadata(for: result, source: command.source)
            )
        }
    }

    private func statusMenuUnlockReason(for command: MenuBarCommand) -> String {
        switch command.action {
        case .revealAlwaysHiddenZone:
            "Unlock to reveal always-hidden menu bar items."
        case .showFindIcon:
            "Unlock to open Find Icon."
        case .showSecondBar, .showIconPanel, .showItemInSecondBar, .activateItem:
            "Unlock to open Second Bar."
        case .showGroupPanel:
            "Unlock to open this protected group."
        case .revealGroup:
            "Unlock to reveal this protected group."
        case .applyProfile:
            "Unlock to apply this profile."
        case .spacingPresetApply:
            "Unlock to apply Menu Bar Spacing Labs changes."
        case .experimentalActivateItem:
            "Unlock to move this menu bar item."
        default:
            "Unlock to run this protected command."
        }
    }

    // MARK: Phase 10 Layout actions

    func enterFullMenuBarMode() {
        layoutCoordinator.enterFullMenuBarMode()
    }

    func exitFullMenuBarMode() {
        layoutCoordinator.exitFullMenuBarMode()
    }

    func showLayoutSuggestions() {
        showSettings(section: .arrange)
    }

    private var canShowNewMenuBarItems: Bool {
        settingsStore.proModeEnabled
            && settingsStore.accessibilityDiscoveryEnabled
            && accessibilityPermissionService.status == .granted
            && !safeModeLaunchState.isSafeModeActive
    }

    private func performCrowdedReveal(
        intent: CrowdedRevealIntent,
        inlineAction: () -> Void
    ) {
        let estimate = layoutCoordinator.currentCapacityEstimate()
        let result = layoutCoordinator.crowdedRevealRescueService.evaluate(
            intent: intent,
            currentVisibility: hidingService.visibilityState,
            estimate: estimate,
            secondBarAvailable: crowdedRescueCommandAvailable(
                action: .showSecondBar,
                target: .secondBar
            ),
            functionBarAvailable: settingsStore.workspacesPreviewEnabled
                && settingsStore.functionBarPreviewEnabled
                && !safeModeLaunchState.isSafeModeActive,
            fullMenuBarModeAvailable: crowdedRescueCommandAvailable(
                action: .enterFullMenuBarMode,
                target: .fullMenuBarMode
            ),
            layoutSuggestionsAvailable: crowdedRescueCommandAvailable(
                action: .showLayoutSuggestions,
                target: .layoutSuggestions
            ),
            safeModeActive: safeModeLaunchState.isSafeModeActive
        )

        switch result {
        case .proceedInline, .inlineOverride:
            inlineAction()
        case .openedSecondBar, .openedFunctionBar, .enteredFullMenuBarMode, .suggestedOnly, .noOp:
            break
        }
    }

    private func crowdedRescueCommandAvailable(
        action: MenuBarCommandAction,
        target: MenuBarCommandTarget
    ) -> Bool {
        commandRouter.availability(for: MenuBarCommand(
            action: action,
            target: target,
            source: .crowdedRescue
        ))
        .isAvailable
    }

    @discardableResult
    private func routeCrowdedRescueCommand(
        action: MenuBarCommandAction,
        target: MenuBarCommandTarget
    ) -> MenuBarCommandResult {
        commandRouter.route(MenuBarCommand(
            action: action,
            target: target,
            source: .crowdedRescue
        ))
    }

    private func restoreVisibilityState(_ state: HidingVisibilityState) {
        switch state {
        case .collapsed:
            collapseHiddenItems()
        case .expanded:
            expandHiddenItemsInline()
        case .revealAll:
            revealAllHiddenItemsInline()
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

    func showOnboarding(stepID: String? = nil) {
        onboardingWindowController.show(stepID: stepID)
    }

    private func refreshAfterOnboarding() {
        // Currently a no-op beyond logging; kept as a hook so future phases can
        // react when the user first completes onboarding (e.g. show drag hint).
        diagnosticsLogger.log("Post-onboarding refresh applied.")
    }

    private func createSampleWorkspaceFromOnboarding() {
        let snapshot = workspaceSwitchingService.currentSnapshot()
        if let existing = snapshot.workspaces.first(where: { !$0.isArchived && $0.name == "Focus" }) {
            _ = workspaceSwitchingService.switchWorkspace(id: existing.id, source: .settings)
            refreshWorkspacePreviewRuntime()
            showSettings(section: .workspacesPreview)
            diagnosticsLogger.log("Onboarding sample Workspace already exists; opened Workspaces.", level: .info)
            return
        }

        let result = workspaceSwitchingService.createWorkspace(WorkspaceDraft(name: "Focus", iconName: "moon"))
        guard result.status == .success,
              let workspaceID = result.activeWorkspaceID,
              var workspace = workspaceSwitchingService.currentSnapshot().workspaces.first(where: { $0.id == workspaceID }) else {
            diagnosticsLogger.log("Onboarding sample Workspace could not be created: \(result.message)", level: .warning)
            showSettings(section: .workspacesPreview)
            return
        }

        let now = Date()
        workspace.functionItems = [
            .command(.findIcon, now: now),
            .command(.showSecondBar, now: now),
            .divider(now: now),
            .command(.revealAll, now: now),
            .command(.openRecovery, now: now)
        ]
        workspace.updatedAt = now
        _ = workspaceSwitchingService.updateWorkspace(workspace)
        refreshWorkspacePreviewRuntime()
        showSettings(section: .workspacesPreview)
        diagnosticsLogger.log("Onboarding created a local sample Workspace with safe commands only.", level: .info)
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

    private func performRecoveryAction(_ action: HealthRecoveryAction) {
        healthCoordinator.performRecoveryAction(action)
        updateLiveStatusFromServices()
    }

    private func openTroubleshootingGuide() {
        if let guideURL = recoveryGuideURL() {
            NSWorkspace.shared.open(guideURL)
            return
        }

        do {
            let generatedURL = try writeLocalRecoveryGuide()
            NSWorkspace.shared.open(generatedURL)
        } catch {
            diagnosticsLogger.log("Failed to open recovery guide: \(error.localizedDescription)", level: .error)
        }
    }

    private func recoveryGuideURL() -> URL? {
        let fileManager = FileManager.default
        let candidates = [
            Bundle.main.url(
                forResource: "i-cant-find-my-icons",
                withExtension: "md",
                subdirectory: "docs/support"
            ),
            sourceCheckoutRecoveryGuideURL()
        ]

        return candidates.compactMap(\.self).first { fileManager.fileExists(atPath: $0.path) }
    }

    private func sourceCheckoutRecoveryGuideURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/support/i-cant-find-my-icons.md")
    }

    private func writeLocalRecoveryGuide() throws -> URL {
        let guideURL = appSupportPaths.localLostIconsGuideURL
        try FileManager.default.createDirectory(
            at: appSupportPaths.supportDirectory,
            withIntermediateDirectories: true
        )

        try Self.localRecoveryGuideText.write(to: guideURL, atomically: true, encoding: .utf8)
        return guideURL
    }

    private static let localRecoveryGuideText = """
    # I can't find my icons

    1. Choose Reveal All from the MenuBarDeclutter status menu.
    2. Open Settings > Recovery and use Expand or Reveal All.
    3. Use Reset Layout if separators or hidden zones look wrong.
    4. Use Safe Mode on next launch if optional behavior is getting in the way.

    Safe Mode starts expanded and disables optional behaviors. Basic Mode does not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
    """

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
        let command = MenuBarCommand(
            action: .applyProfile,
            target: .profileID(profile.id),
            source: .settings
        )
        let availability = commandRouter.availability(for: command)
        guard availability.isAvailable else {
            diagnosticsLogger.log(
                "Profile apply blocked by Command Center gate.",
                level: .info,
                category: .profile,
                metadata: [
                    "status": availability.status.rawValue,
                    "reason": availability.diagnosticReason
                ]
            )
            return ProfileApplicationDryRun(
                itemsToReveal: [],
                itemsToMove: [],
                unavailableItems: [],
                permissionRequirements: [availability.message]
            )
        }

        return profileAutomationCoordinator.applyProfile(profile)
    }

    @discardableResult
    func applyProfileNamed(_ name: String) -> Bool {
        profileAutomationCoordinator.applyProfile(named: name)
    }

    // MARK: UI surfaces

    func showSettings(section: SettingsSection = .general, searchText: String? = nil) {
        settingsWindowController.show(section: section, searchText: searchText)
    }

    func showDiagnostics() {
        showSettings(section: .diagnostics)
    }

    @discardableResult
    func exportDiagnosticsJSON(to url: URL) -> Bool {
        do {
            _ = try appSupportPaths.ensureDirectoriesExist()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let snapshot = diagnosticsExporter.makeSnapshot(
                settingsStore: settingsStore,
                logger: diagnosticsLogger,
                secondBarReadiness: makeSecondBarReadinessDiagnosticsSnapshot(),
                secondBarRuntime: makeSecondBarRuntimeDiagnosticsSnapshot(),
                workspacePreview: nil,
                events: diagnosticsLogger.events
            )
            let data = try diagnosticsExporter.serialize(
                snapshot,
                format: .json,
                includeAppSupportPath: false,
                appSupportPath: nil
            )
            try data.write(to: url, options: .atomic)
            diagnosticsLogger.log(
                "Diagnostics JSON exported to \(url.lastPathComponent).",
                level: .info,
                category: .urlAutomation
            )
            return true
        } catch {
            diagnosticsLogger.log(
                "Diagnostics JSON export failed: \(error.localizedDescription)",
                level: .error,
                category: .urlAutomation
            )
            return false
        }
    }

    func showSearch() {
        menuBarItemSurfaceCoordinator.showSearch()
    }

    func showSecondBar() {
        guard openSecondBarIfReady(anchorFrame: nil) else {
            return
        }
        menuBarItemSurfaceCoordinator.showSecondBar()
    }

    func showCompactSecondBarForUITesting() {
        guard ProcessInfo.processInfo.arguments.contains("--ui-testing") else {
            return
        }

        _ = handleStatusItemPrimaryClick(anchorFrame: compactSecondBarUITestingAnchorFrame())
    }

    @discardableResult
    private func showCompactSecondBarFromQAURL() -> Bool {
        handleStatusItemPrimaryClick(anchorFrame: nil)
    }

    private func compactSecondBarUITestingAnchorFrame() -> CGRect {
        let screen = SecondBarPositioningService.currentScreens().first { $0.isMain }
            ?? SecondBarPositioningService.fallbackScreen
        return CGRect(
            x: screen.frame.maxX - 56,
            y: screen.frame.minY + 4,
            width: 24,
            height: 24
        )
    }

    func seedRenderedIconsForUITesting(itemIDs: Set<MenuBarItemSnapshot.ID>) {
        guard ProcessInfo.processInfo.arguments.contains("--ui-testing") else {
            return
        }

        let resolver = MenuBarIconAppearanceResolver()
        for snapshot in liveStatus.scannedMenuBarItems where itemIDs.contains(snapshot.id) {
            guard let frame = snapshot.frame,
                  let cacheKey = resolver.cacheKey(for: snapshot),
                  let image = Self.makeUITestingRenderedIconImage(seed: snapshot.id) else {
                continue
            }

            menuBarRenderedIconCache.cache(MenuBarIconSnapshot(
                identity: MenuBarIconIdentity(snapshot: snapshot),
                image: image,
                frameInScreenPoints: frame,
                scale: NSScreen.main?.backingScaleFactor ?? 2,
                cacheKey: cacheKey,
                source: .renderedCapture,
                capturedAt: Date()
            ))
        }
    }

    private static func makeUITestingRenderedIconImage(seed: String) -> CGImage? {
        let size = 24
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let hash = UInt(bitPattern: seed.hashValue)
        let red = CGFloat((hash & 0xFF0000) >> 16) / 255
        let green = CGFloat((hash & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hash & 0x0000FF) / 255
        context.setFillColor(NSColor(red: red, green: green, blue: blue, alpha: 1).cgColor)
        context.fillEllipse(in: CGRect(x: 4, y: 4, width: 16, height: 16))
        return context.makeImage()
    }

    func showWorkspacePreview() {
        showSettings(section: .workspacesPreview)
    }

    func prepareWorkspacePanelUITestingState() {
        settingsStore.workspacesPreviewEnabled = true
        settingsStore.functionBarPreviewEnabled = true
        settingsStore.infoStripPreviewEnabled = true
        settingsStore.functionBarCloseOnOutsideClick = false
        settingsStore.infoStripCloseOnOutsideClick = false

        var activeWorkspace = workspaceSwitchingService.activeWorkspace()
        activeWorkspace.infoStripConfig.isEnabled = true
        _ = workspaceSwitchingService.updateWorkspace(activeWorkspace)

        setBuilderViewModel.refresh()
        refreshWorkspacePreviewRuntime()
    }

    @discardableResult
    func switchWorkspace(id: UUID) -> Bool {
        let result = workspaceSwitchingService.switchWorkspace(id: id, source: .settings)
        setBuilderViewModel.refresh()
        refreshWorkspacePreviewRuntime()
        diagnosticsLogger.log(
            "Workspace switch result: \(result.status.rawValue).",
            level: result.status == .success || result.status == .noChange ? .info : .warning,
            category: .layout
        )
        return result.status == .success || result.status == .noChange
    }

    func showFunctionBarPreview(source: FunctionBarShowSource) {
        _ = source
        workspaceDisplayCoordinator.showFunctionBar()
    }

    func hideFunctionBarPreview(source: FunctionBarHideSource) {
        _ = source
        workspaceDisplayCoordinator.hideFunctionBar()
    }

    func toggleFunctionBarPreview(source: FunctionBarShowSource) {
        _ = source
        workspaceDisplayCoordinator.toggleFunctionBar()
    }

    @discardableResult
    private func showFunctionBarFromPrimaryClick() -> Bool {
        let result = commandRouter.route(MenuBarCommand(
            action: .showFunctionBar,
            target: .functionBar,
            source: .statusMenu
        ))
        return result.didRun
    }

    @discardableResult
    private func handleStatusItemPrimaryClick(anchorFrame: CGRect?) -> Bool {
        let safeModeActive = safeModeLaunchState.isSafeModeActive
        let readinessState: ProSecondBarReadinessState = safeModeActive
            ? .missingEntitlement
            : currentProSecondBarReadiness().state
        switch StatusBarPrimaryClickRouter.route(
            entitlement: safeModeActive ? .basic : currentProEntitlementState(),
            readiness: readinessState,
            primaryClickOptIn: settingsStore.secondBarPrimaryClickEnabled,
            safeModeActive: safeModeActive
        ) {
        case .toggleCompactStrip:
            menuBarItemSurfaceCoordinator.toggleCompactSecondBar(anchorFrame: anchorFrame)
            return true
        case .showSecondBarRequirements:
            menuBarItemSurfaceCoordinator.showSecondBarRequirements(
                readinessState,
                anchorFrame: anchorFrame
            )
            return true
        case .toggleInlineVisibility:
            guard settingsStore.functionBarPrimaryClickEnabled else {
                return false
            }
            return showFunctionBarFromPrimaryClick()
        }
    }

    private func currentProEntitlementState() -> ProEntitlementState {
        guard settingsStore.proModeEnabled else {
            return .basic
        }
        return .licensed
    }

    private func currentProSecondBarReadiness() -> ProSecondBarReadinessResult {
        ProSecondBarReadiness.evaluate(ProSecondBarReadinessInput(
            entitlement: currentProEntitlementState(),
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityPermission: accessibilityPermissionService.currentStatus,
            accurateIconsEnabled: settingsStore.renderedIconCaptureEnabled,
            screenCapturePermission: screenCapturePermissionService.refreshStatus()
        ))
    }

    private func makeSecondBarReadinessDiagnosticsSnapshot() -> DiagnosticsExporter.SecondBarReadinessDiagnosticsSnapshot {
        let input = ProSecondBarReadinessInput(
            entitlement: currentProEntitlementState(),
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityPermission: accessibilityPermissionService.currentStatus,
            accurateIconsEnabled: settingsStore.renderedIconCaptureEnabled,
            screenCapturePermission: screenCapturePermissionService.refreshStatus()
        )
        return DiagnosticsExporter.SecondBarReadinessDiagnosticsSnapshot(
            input: input,
            readiness: ProSecondBarReadiness.evaluate(input),
            primaryClickOptIn: settingsStore.secondBarPrimaryClickEnabled,
            safeModeActive: safeModeLaunchState.isSafeModeActive
        )
    }

    private func makeSecondBarRuntimeDiagnosticsSnapshot() -> DiagnosticsExporter.SecondBarRuntimeDiagnosticsSnapshot {
        DiagnosticsExporter.SecondBarRuntimeDiagnosticsSnapshot(
            visible: liveStatus.secondBarVisible,
            itemCount: liveStatus.secondBarItemCount,
            currentScreen: liveStatus.secondBarCurrentScreen,
            lastPosition: liveStatus.secondBarLastPosition,
            iconWarmUpInProgress: liveStatus.secondBarIconWarmUpInProgress,
            lastIconWarmUpResult: liveStatus.secondBarLastIconWarmUpResult,
            lastCompactVisibleItemCount: liveStatus.secondBarLastCompactVisibleItemCount,
            lastCompactOverflowItemCount: liveStatus.secondBarLastCompactOverflowItemCount,
            lastCompactFallbackIconCount: liveStatus.secondBarLastCompactFallbackIconCount,
            lastCompactScanState: liveStatus.secondBarLastCompactScanState,
            lastCompactAvoidedNotch: liveStatus.secondBarLastCompactAvoidedNotch,
            lastActivationResult: liveStatus.secondBarLastActivationResult,
            lastActivationMatrixResult: liveStatus.secondBarLastActivationMatrixResult,
            lastActivationTargetZone: liveStatus.secondBarLastActivationTargetZone,
            lastActivationVisitedElementCount: liveStatus.secondBarLastActivationVisitedElementCount,
            lastActivationAXError: liveStatus.secondBarLastActivationAXError
        )
    }

    private func openSecondBarIfReady(anchorFrame: CGRect?) -> Bool {
        let readiness = currentProSecondBarReadiness()
        guard readiness.isReady else {
            menuBarItemSurfaceCoordinator.showSecondBarRequirements(
                readiness.state,
                anchorFrame: anchorFrame
            )
            return false
        }
        return true
    }

    func showInfoStripPreview() {
        workspaceDisplayCoordinator.showInfoStrip()
    }

    func hideInfoStripPreview() {
        workspaceDisplayCoordinator.hideInfoStrip()
    }

    func toggleInfoStripPreview() {
        workspaceDisplayCoordinator.toggleInfoStrip()
    }

    func advanceInfoStripTile() {
        infoStripController.advanceTile()
    }

    private func resetCurrentWorkspaceLayoutForRecovery() {
        let result = workspaceSwitchingService.resetActiveWorkspaceLayoutToDefaults()
        setBuilderViewModel.refresh()
        refreshWorkspacePreviewRuntime()
        diagnosticsLogger.log(
            "Current Workspace layout reset by health recovery: \(result.status.rawValue).",
            level: result.status == .success ? .warning : .error,
            category: .layout
        )
    }

    private func removeMissingWorkspaceGroupReferencesForRecovery() {
        let knownGroupIDs = Set(groupStore.groups.map(\.id))
        let result = workspaceSwitchingService.removeMissingGroupReferences(knownGroupIDs: knownGroupIDs)
        setBuilderViewModel.refresh()
        refreshWorkspacePreviewRuntime()
        diagnosticsLogger.log(
            "Missing Workspace group references removed by health recovery: \(result.status.rawValue).",
            level: result.status == .success ? .warning : .info,
            category: .layout
        )
    }

    private func discardSetBuilderDraftForRecovery() {
        setBuilderViewModel.revertDraft()
        setBuilderViewModel.refresh()
        diagnosticsLogger.log("Set Builder draft discarded by health recovery.", level: .warning, category: .layout)
    }

    private func disableFunctionBarPreviewForRecovery() {
        settingsStore.functionBarPreviewEnabled = false
        settingsStore.functionBarPrimaryClickEnabled = false
        hideFunctionBarPreview(source: .settings)
        diagnosticsLogger.log("Function Bar Preview disabled by health recovery.", level: .warning, category: .layout)
    }

    private func disableSetBuilderPreviewForRecovery() {
        settingsStore.setBuilderPreviewEnabled = false
        discardSetBuilderDraftForRecovery()
        diagnosticsLogger.log("Set Builder Preview disabled by health recovery.", level: .warning, category: .layout)
    }

    private func disableInfoStripPreviewForRecovery() {
        settingsStore.infoStripPreviewEnabled = false
        settingsStore.infoStripAutoShowEnabled = false
        hideInfoStripPreview()
        diagnosticsLogger.log("Info Strip Preview disabled by health recovery.", level: .warning, category: .layout)
    }

    private func resetInfoStripSettingsForRecovery() {
        var workspace = workspaceSwitchingService.activeWorkspace()
        workspace.infoStripConfig = .default
        let result = workspaceSwitchingService.updateWorkspace(workspace)
        setBuilderViewModel.refresh()
        hideInfoStripPreview()
        refreshWorkspacePreviewRuntime()
        diagnosticsLogger.log(
            "Info Strip settings reset by health recovery: \(result.status.rawValue).",
            level: result.status == .success ? .warning : .error,
            category: .layout
        )
    }

    private func resetInfoStripPlacementForRecovery() {
        infoStripController.resetPlacement()
        diagnosticsLogger.log("Info Strip placement reset by health recovery.", level: .warning, category: .layout)
    }

    private func clearInvalidInfoStripProvidersForRecovery() {
        var workspace = workspaceSwitchingService.activeWorkspace()
        let originalProviderIDs = workspace.infoStripConfig.selectedTileProviderIDs
        let registry = InfoTileProviderRegistry()
        var validProviderIDs = originalProviderIDs.filter { registry.provider(id: $0) != nil }

        if validProviderIDs.isEmpty, !originalProviderIDs.isEmpty {
            validProviderIDs = WorkspaceInfoStripConfig.defaultTileProviderIDs
        }

        guard validProviderIDs != originalProviderIDs else {
            diagnosticsLogger.log("Info Strip provider cleanup skipped; no invalid providers found.", level: .info, category: .layout)
            return
        }

        workspace.infoStripConfig.selectedTileProviderIDs = validProviderIDs
        let result = workspaceSwitchingService.updateWorkspace(workspace)
        setBuilderViewModel.refresh()
        infoStripController.refresh()
        diagnosticsLogger.log(
            "Invalid Info Strip providers cleared by health recovery: \(result.status.rawValue).",
            level: result.status == .success ? .warning : .error,
            category: .layout
        )
    }

    private func showFunctionBarInsteadForRecovery() {
        hideInfoStripPreview()
        settingsStore.workspacesPreviewEnabled = true
        settingsStore.functionBarPreviewEnabled = true
        showFunctionBarPreview(source: .settings)
        diagnosticsLogger.log("Function Bar shown instead of Info Strip by health recovery.", level: .warning, category: .layout)
    }

    private func activeInfoStripConfigForHealth() -> WorkspaceInfoStripConfig {
        workspaceSwitchingService.activeWorkspace().infoStripConfig
    }

    private func availableSelectedInfoTileProviderCountForHealth() -> Int {
        let config = activeInfoStripConfigForHealth()
        return InfoTileProviderRegistry()
            .snapshots(for: config.selectedTileProviderIDs, context: currentInfoTileContext())
            .count
    }

    private func invalidInfoTileProviderIDCountForHealth() -> Int {
        let registry = InfoTileProviderRegistry()
        return activeInfoStripConfigForHealth().selectedTileProviderIDs
            .filter { registry.provider(id: $0) == nil }
            .count
    }

    private func availableMenuBarItemHashesForWorkspaceDiagnostics() -> Set<String>? {
        guard settingsStore.proModeEnabled,
              settingsStore.accessibilityDiscoveryEnabled,
              accessibilityPermissionService.status == .granted,
              liveStatus.lastMenuBarScanTime != nil else {
            return nil
        }
        return Set(liveStatus.scannedMenuBarItems.map(\.id))
    }

    private func infoStripTimingInvalidForHealth() -> Bool {
        let config = activeInfoStripConfigForHealth()
        return config.idleDelaySeconds < WorkspaceValidationConstants.minIdleDelaySeconds
            || config.idleDelaySeconds > WorkspaceValidationConstants.maxIdleDelaySeconds
            || config.rotationIntervalSeconds < WorkspaceValidationConstants.minRotationIntervalSeconds
            || config.rotationIntervalSeconds > WorkspaceValidationConstants.maxRotationIntervalSeconds
    }

    private func refreshWorkspacePreviewRuntime() {
        functionBarController.refresh(reason: .workspaceChanged)
        if settingsStore.infoStripAutoShowEnabled {
            infoStripController.refresh()
        }
    }

    private func currentInfoTileContext() -> InfoTileContext {
        let latestScanAge = liveStatus.lastMenuBarScanTime.map {
            max(0, Int(Date().timeIntervalSince($0)))
        }
        return InfoTileContext(
            activeWorkspace: workspaceSwitchingService.activeWorkspace(),
            functionBarVisible: functionBarController.displayState.isVisible,
            hiddenItemCount: liveStatus.menuBarScanHiddenCount,
            alwaysHiddenItemCount: liveStatus.menuBarScanAlwaysHiddenCount,
            newItemCount: liveStatus.newMenuBarItemReviewCount,
            healthWarningCount: liveStatus.healthReport?.issues.count ?? 0,
            latestScanAgeSeconds: latestScanAge,
            proDiscoveryAvailable: settingsStore.isProDiscoveryAvailable,
            safeModeActive: safeModeLaunchState.isSafeModeActive,
            currentDate: Date()
        )
    }

    private func dispatchInfoTileAction(_ action: InfoTileAction) {
        switch action.commandID {
        case WorkspaceCommandReference.showWorkspacePreview.actionID:
            _ = commandRouter.route(MenuBarCommand(action: .showWorkspacePreview, source: .settings))
        case WorkspaceCommandReference.openRecovery.actionID:
            showSettings(section: .recovery)
        case WorkspaceCommandReference.revealAll.actionID:
            _ = commandRouter.route(MenuBarCommand(action: .revealAll, source: .settings))
        case WorkspaceCommandReference.showFunctionBar.actionID:
            _ = commandRouter.route(MenuBarCommand(action: .showFunctionBar, target: .functionBar, source: .settings))
        case WorkspaceCommandReference.nextInfoStripTile.actionID:
            _ = commandRouter.route(MenuBarCommand(action: .nextInfoStripTile, target: .infoStrip, source: .settings))
        case WorkspaceCommandReference.openInfoStripSettings.actionID:
            _ = commandRouter.route(MenuBarCommand(action: .openInfoStripSettings, target: .infoStrip, source: .settings))
        case WorkspaceCommandReference.showFunctionBarFromInfoStrip.actionID:
            _ = commandRouter.route(MenuBarCommand(action: .showFunctionBarFromInfoStrip, target: .infoStrip, source: .settings))
        default:
            diagnosticsLogger.log("Info Strip action is unavailable: \(action.commandID)", level: .warning, category: .layout)
        }
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
        if liveStatus.secondBarVisible {
            menuBarItemSurfaceCoordinator.hideSecondBar()
        } else {
            showSecondBar()
        }
    }

    func refreshMenuBarItems() {
        menuBarItemSurfaceCoordinator.refreshMenuBarItems()
    }

    func resetMovingWarnings() {
        menuBarItemSurfaceCoordinator.resetMovingWarnings()
    }

    func executeAssistedMoveFromSettings(
        _ snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand
    ) async -> IconMoveResult {
        await menuBarItemSurfaceCoordinator.performAssistedMove(snapshot, command: command)
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
        handlers.showWorkspacePreview = { [weak self] in self?.showWorkspacePreview() }
        handlers.switchWorkspace = { [weak self] id in
            self?.switchWorkspace(id: id) == true
        }
        handlers.showFunctionBar = { [weak self] in self?.showFunctionBarPreview(source: .commandCenter) }
        handlers.hideFunctionBar = { [weak self] in self?.hideFunctionBarPreview(source: .commandCenter) }
        handlers.toggleFunctionBar = { [weak self] in self?.toggleFunctionBarPreview(source: .commandCenter) }
        handlers.showInfoStrip = { [weak self] in self?.showInfoStripPreview() }
        handlers.hideInfoStrip = { [weak self] in self?.hideInfoStripPreview() }
        handlers.toggleInfoStrip = { [weak self] in self?.toggleInfoStripPreview() }
        handlers.nextInfoStripTile = { [weak self] in self?.advanceInfoStripTile() }
        handlers.openInfoStripSettings = { [weak self] in self?.showSettings(section: .workspacesPreview) }
        handlers.showFunctionBarFromInfoStrip = { [weak self] in self?.showFunctionBarPreview(source: .workspaceDisplay) }
        handlers.showLayoutSuggestions = { [weak self] in self?.showLayoutSuggestions() }
        handlers.enterFullMenuBarMode = { [weak self] in self?.enterFullMenuBarMode() }
        handlers.exitFullMenuBarMode = { [weak self] in self?.exitFullMenuBarMode() }
        handlers.previewSpacingPreset = { [weak self] _ in
            guard let self else { return false }
            self.showSettings(section: .layout)
            return true
        }
        handlers.showAssistedMoveGuide = { [weak self] in
            guard let self else { return false }
            self.showSettings(section: .arrange)
            return true
        }
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
        handlers.highlightItem = { [weak self] itemID in
            self?.highlightMenuBarItem(id: itemID) == true
        }
        handlers.openOwningApp = { [weak self] itemID in
            self?.openOwningAppForMenuBarItem(id: itemID) == true
        }
        handlers.showItemInSecondBar = { [weak self] itemID in
            self?.showMenuBarItemInSecondBar(id: itemID) == true
        }
        handlers.activateItem = { [weak self] itemID in
            self?.activateMenuBarItem(id: itemID) == true
        }
        handlers.showGroupPanel = { [weak self] groupID in
            self?.showGroupPanel(id: groupID) == true
        }
        handlers.revealGroup = { [weak self] groupID in
            self?.revealGroup(id: groupID) == true
        }
        handlers.createGroupFromItem = { [weak self] itemID in
            self?.createGroupFromMenuBarItem(id: itemID) == true
        }
        handlers.addItemToGroup = { [weak self] groupID, itemID in
            self?.addMenuBarItem(id: itemID, toGroup: groupID) == true
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
        case .revealGroup(let groupID):
            return commandRouter.route(MenuBarCommand(
                action: .revealGroup,
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

    private func highlightMenuBarItem(id: String) -> Bool {
        refreshMenuBarItems()
        guard let snapshot = liveStatus.scannedMenuBarItems.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Command Center item highlight target unavailable.", level: .warning, category: .layout)
            return false
        }

        let result = groupMenuItemActivator.highlight(snapshot)
        diagnosticsLogger.log("Command Center item highlight: \(result.message)", level: .debug, category: .layout)
        return result.outcome != .missingFrame
    }

    private func openOwningAppForMenuBarItem(id: String) -> Bool {
        refreshMenuBarItems()
        guard let snapshot = liveStatus.scannedMenuBarItems.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Command Center owning app target unavailable.", level: .warning, category: .layout)
            return false
        }

        guard let processIdentifier = snapshot.owningProcessIdentifier,
              let application = NSRunningApplication(processIdentifier: processIdentifier) else {
            diagnosticsLogger.log("Command Center owning app is unavailable.", level: .warning, category: .layout)
            return false
        }

        return application.activate(options: [])
    }

    private func showMenuBarItemInSecondBar(id: String) -> Bool {
        guard liveStatus.scannedMenuBarItems.contains(where: { $0.id == id }) else {
            diagnosticsLogger.log("Dynamic hotkey Second Bar item target unavailable.", level: .warning, category: .hotkey)
            return false
        }
        showSecondBar()
        return true
    }

    private func activateMenuBarItem(id: String) -> Bool {
        guard let snapshot = liveStatus.scannedMenuBarItems.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Second Bar activation target unavailable.", level: .warning, category: .layout)
            return false
        }

        let result = menuBarItemDirectActivationService.activate(snapshot: snapshot)
        liveStatus.updateSecondBarDirectActivation(
            result: result,
            targetZone: snapshot.zone
        )
        diagnosticsLogger.log(
            "Second Bar activation result: \(result.status.rawValue).",
            level: result.didActivate ? .debug : .warning,
            category: .layout,
            metadata: [
                "targetID": snapshot.id,
                "targetZone": snapshot.zone.rawValue,
                "matrixResult": result.matrixOutcome.rawValue,
                "visitedElementCount": "\(result.visitedElementCount)",
                "axError": result.axErrorDescription ?? "none",
                "message": result.message
            ]
        )
        return result.didActivate
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

    private func revealGroup(id: UUID) -> Bool {
        groupStore.load()
        guard let group = groupStore.groups.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Group reveal target unavailable.", level: .warning, category: .layout)
            return false
        }

        refreshMenuBarItems()
        let resolver = IconGroupSnapshotResolver()
        let plan = resolver.revealPlan(for: group, snapshots: liveStatus.scannedMenuBarItems)

        switch plan {
        case .noMatchingItems:
            diagnosticsLogger.log("Group reveal had no matching menu bar items.", level: .warning, category: .layout)
            return false
        case .noRevealNeeded:
            diagnosticsLogger.log("Group reveal did not need visibility changes.", category: .layout)
            return true
        case .expandHiddenZone:
            performCrowdedReveal(intent: .revealGroup) { [weak self] in
                self?.expandHiddenItemsInline()
            }
            diagnosticsLogger.log("Group reveal expanded hidden menu bar items.", category: .layout)
            return true
        case .revealAllHiddenItems:
            performCrowdedReveal(intent: .revealGroup) { [weak self] in
                self?.revealAllHiddenItemsInline()
            }
            diagnosticsLogger.log("Group reveal revealed all hidden menu bar items.", category: .layout)
            return true
        }
    }

    private func createGroupFromMenuBarItem(id: String) -> Bool {
        refreshMenuBarItems()
        guard let snapshot = liveStatus.scannedMenuBarItems.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Group creation item target unavailable.", level: .warning, category: .layout)
            return false
        }

        groupStore.load()
        let groupName = IconGroupItemActionPlanner.defaultGroupName(
            for: snapshot,
            existingGroups: groupStore.groups
        )
        let created = groupStore.createGroup(name: groupName)
        groupStore.updateGroup(id: created.id) { group in
            group.symbolName = "folder"
            group.showInSecondBar = true
            group.showAsStatusItem = false
            group.itemRefs = [IconGroupItemActionPlanner.itemRef(from: snapshot)]
        }
        refreshGroupSettings()
        diagnosticsLogger.log("Created group from menu bar item.", category: .layout)
        return true
    }

    private func addMenuBarItem(id: String, toGroup groupID: UUID) -> Bool {
        refreshMenuBarItems()
        guard let snapshot = liveStatus.scannedMenuBarItems.first(where: { $0.id == id }) else {
            diagnosticsLogger.log("Group add item target unavailable.", level: .warning, category: .layout)
            return false
        }

        groupStore.load()
        guard groupStore.groups.contains(where: { $0.id == groupID }) else {
            diagnosticsLogger.log("Group add target unavailable.", level: .warning, category: .layout)
            return false
        }

        var didAdd = false
        groupStore.updateGroup(id: groupID) { group in
            let result = IconGroupItemActionPlanner.adding(snapshot: snapshot, to: group)
            group = result.group
            didAdd = result.didAdd
        }
        refreshGroupSettings()
        diagnosticsLogger.log(
            didAdd ? "Added menu bar item to group." : "Menu bar item already exists in group.",
            category: .layout
        )
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

private extension NSView {
    var menuBarDeclutterScreenFrame: CGRect? {
        guard let window else { return nil }
        return window.convertToScreen(convert(bounds, to: nil))
    }
}
