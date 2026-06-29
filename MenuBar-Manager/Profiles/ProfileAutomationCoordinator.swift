import Foundation

@MainActor
final class ProfileAutomationCoordinator {
    let profileStore: ProfileStore
    let triggerService: TriggerService

    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let accessibilityPermissionService: AccessibilityPermissionService
    private let profileApplicationService: ProfileApplicationService
    private let refreshAfterProfileApply: () -> Void
    private let routeCommand: (MenuBarCommand) -> MenuBarCommandResult

    private lazy var automationURLHandler = AutomationURLHandler(
        diagnosticsLogger: diagnosticsLogger,
        routeCommand: routeCommand
    )

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        appSupportPaths: AppSupportPaths,
        liveStatus: LiveDiagnosticsStatus,
        accessibilityPermissionService: AccessibilityPermissionService,
        setVisibility: @escaping (HidingVisibilityState) -> Void,
        refreshAfterProfileApply: @escaping () -> Void,
        enterFullMenuBarMode: @escaping () -> Void = {},
        exitFullMenuBarMode: @escaping () -> Void = {},
        refreshGroups: @escaping () -> Void = {},
        routeCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.accessibilityPermissionService = accessibilityPermissionService
        self.refreshAfterProfileApply = refreshAfterProfileApply
        self.routeCommand = routeCommand

        let profileStore = ProfileStore(appSupportPaths: appSupportPaths)
        let profileApplicationService = ProfileApplicationService(
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            setVisibility: setVisibility,
            enterFullMenuBarMode: enterFullMenuBarMode,
            exitFullMenuBarMode: exitFullMenuBarMode,
            refreshGroups: refreshGroups
        )

        self.profileStore = profileStore
        self.profileApplicationService = profileApplicationService
        self.triggerService = TriggerService(
            settingsStore: settingsStore,
            profileStore: profileStore,
            profileApplicationService: profileApplicationService,
            appSupportPaths: appSupportPaths,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus
        )
    }

    func start() {
        profileStore.load()
        triggerService.load()
        automationURLHandler.install()
    }

    func stop() {
        triggerService.stop()
        automationURLHandler.uninstall()
    }

    func dryRunProfile(_ profile: ProfileModel) -> ProfileApplicationDryRun {
        profileApplicationService.dryRun(
            profile: profile,
            snapshots: liveStatus.scannedMenuBarItems,
            accessibilityStatus: accessibilityPermissionService.refreshStatus(),
            allowProMoves: false
        )
    }

    func applyProfile(_ profile: ProfileModel) -> ProfileApplicationDryRun {
        let summary = profileApplicationService.applyBasicSettings(
            profile: profile,
            snapshots: liveStatus.scannedMenuBarItems,
            accessibilityStatus: accessibilityPermissionService.refreshStatus(),
            allowProMoves: false
        )
        refreshAfterProfileApply()
        return summary
    }

    func applyProfile(named name: String) -> Bool {
        profileStore.load()
        guard let profile = profileStore.profile(named: name) else {
            return false
        }
        _ = applyProfile(profile)
        return true
    }
}
