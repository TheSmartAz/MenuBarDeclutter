import Foundation

@MainActor
final class ProfileAutomationCoordinator {
    let profileStore: ProfileStore
    let triggerService: TriggerService

    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let accessibilityPermissionService: AccessibilityPermissionService
    private let profileApplicationService: ProfileApplicationService
    private let settingsStore: SettingsStore
    private let refreshAfterProfileApply: () -> Void
    private let expand: () -> Void
    private let collapse: () -> Void
    private let revealAll: () -> Void
    private let showSecondBar: () -> Void

    private lazy var automationURLHandler = AutomationURLHandler(
        diagnosticsLogger: diagnosticsLogger,
        expand: expand,
        collapse: collapse,
        revealAll: revealAll,
        showSecondBar: showSecondBar,
        applyProfileNamed: { [weak self] name in
            self?.applyProfile(named: name) == true
        },
        isAutomationEnabled: { [weak self] in
            self?.settingsStore.automationPaused == false
        }
    )

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        appSupportPaths: AppSupportPaths,
        liveStatus: LiveDiagnosticsStatus,
        accessibilityPermissionService: AccessibilityPermissionService,
        setVisibility: @escaping (HidingVisibilityState) -> Void,
        refreshAfterProfileApply: @escaping () -> Void,
        expand: @escaping () -> Void,
        collapse: @escaping () -> Void,
        revealAll: @escaping () -> Void,
        showSecondBar: @escaping () -> Void
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.accessibilityPermissionService = accessibilityPermissionService
        self.settingsStore = settingsStore
        self.refreshAfterProfileApply = refreshAfterProfileApply
        self.expand = expand
        self.collapse = collapse
        self.revealAll = revealAll
        self.showSecondBar = showSecondBar

        let profileStore = ProfileStore(appSupportPaths: appSupportPaths)
        let profileApplicationService = ProfileApplicationService(
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            setVisibility: setVisibility
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
