import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let navigationModel = SettingsNavigationModel()
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus?
    private let launchAtLoginService: LaunchAtLoginService?
    private let appSupportPaths: AppSupportPaths
    private let diagnosticsExporter: DiagnosticsExporter
    private let accessibilityPermissionService: AccessibilityPermissionService?
    private let menuBarScanCoordinator: MenuBarScanCoordinator?
    private let profileStore: ProfileStore?
    private let triggerService: TriggerService?

    private let onBehaviorChanged: (() -> Void)?
    private let onSearchChanged: (() -> Void)?
    private let onSecondBarChanged: (() -> Void)?
    private let onPrivacyChanged: (() -> Void)?
    private let onProfileDryRun: ((ProfileModel) -> ProfileApplicationDryRun)?
    private let onProfileApply: ((ProfileModel) -> ProfileApplicationDryRun)?
    private let onTriggersChanged: (() -> Void)?
    private let onResetLayout: (() -> Void)?
    private let onResetAllSettings: (() -> Void)?
    private let onResetMovingWarnings: (() -> Void)?
    private let onShowOnboarding: (() -> Void)?
    private let onRunHealthCheck: (() -> Void)?
    private let onFixHealthIssues: (() -> Void)?
    private let onResetBasicMode: (() -> Void)?
    private let onDisableProMode: (() -> Void)?
    private let onEnterSafeModeNextLaunch: (() -> Void)?

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus? = nil,
        launchAtLoginService: LaunchAtLoginService? = nil,
        appSupportPaths: AppSupportPaths = AppSupportPaths(),
        diagnosticsExporter: DiagnosticsExporter = DiagnosticsExporter(),
        accessibilityPermissionService: AccessibilityPermissionService? = nil,
        menuBarScanCoordinator: MenuBarScanCoordinator? = nil,
        profileStore: ProfileStore? = nil,
        triggerService: TriggerService? = nil,
        onBehaviorChanged: (() -> Void)? = nil,
        onSearchChanged: (() -> Void)? = nil,
        onSecondBarChanged: (() -> Void)? = nil,
        onPrivacyChanged: (() -> Void)? = nil,
        onProfileDryRun: ((ProfileModel) -> ProfileApplicationDryRun)? = nil,
        onProfileApply: ((ProfileModel) -> ProfileApplicationDryRun)? = nil,
        onTriggersChanged: (() -> Void)? = nil,
        onResetLayout: (() -> Void)? = nil,
        onResetAllSettings: (() -> Void)? = nil,
        onResetMovingWarnings: (() -> Void)? = nil,
        onShowOnboarding: (() -> Void)? = nil,
        onRunHealthCheck: (() -> Void)? = nil,
        onFixHealthIssues: (() -> Void)? = nil,
        onResetBasicMode: (() -> Void)? = nil,
        onDisableProMode: (() -> Void)? = nil,
        onEnterSafeModeNextLaunch: (() -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.launchAtLoginService = launchAtLoginService
        self.appSupportPaths = appSupportPaths
        self.diagnosticsExporter = diagnosticsExporter
        self.accessibilityPermissionService = accessibilityPermissionService
        self.menuBarScanCoordinator = menuBarScanCoordinator
        self.profileStore = profileStore
        self.triggerService = triggerService
        self.onBehaviorChanged = onBehaviorChanged
        self.onSearchChanged = onSearchChanged
        self.onSecondBarChanged = onSecondBarChanged
        self.onPrivacyChanged = onPrivacyChanged
        self.onProfileDryRun = onProfileDryRun
        self.onProfileApply = onProfileApply
        self.onTriggersChanged = onTriggersChanged
        self.onResetLayout = onResetLayout
        self.onResetAllSettings = onResetAllSettings
        self.onResetMovingWarnings = onResetMovingWarnings
        self.onShowOnboarding = onShowOnboarding
        self.onRunHealthCheck = onRunHealthCheck
        self.onFixHealthIssues = onFixHealthIssues
        self.onResetBasicMode = onResetBasicMode
        self.onDisableProMode = onDisableProMode
        self.onEnterSafeModeNextLaunch = onEnterSafeModeNextLaunch

        let contentView = SettingsRootView(
            navigationModel: navigationModel,
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
            onBehaviorChanged: onBehaviorChanged,
            onSearchChanged: onSearchChanged,
            onSecondBarChanged: onSecondBarChanged,
            onPrivacyChanged: onPrivacyChanged,
            onProfileDryRun: onProfileDryRun,
            onProfileApply: onProfileApply,
            onTriggersChanged: onTriggersChanged,
            onResetLayout: onResetLayout,
            onResetAllSettings: onResetAllSettings,
            onResetMovingWarnings: onResetMovingWarnings,
            onShowOnboarding: onShowOnboarding,
            onRunHealthCheck: onRunHealthCheck,
            onFixHealthIssues: onFixHealthIssues,
            onResetBasicMode: onResetBasicMode,
            onDisableProMode: onDisableProMode,
            onEnterSafeModeNextLaunch: onEnterSafeModeNextLaunch
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "\(AppConstants.displayName) Settings"
        window.contentViewController = NSHostingController(rootView: contentView)
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 680, height: 440)

        super.init(window: window)

        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SettingsWindowController does not support storyboards.")
    }

    func show(section: SettingsSection = .general) {
        navigationModel.selectedSection = section

        if window?.isVisible != true {
            window?.center()
        }

        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        diagnosticsLogger.log("Settings opened to \(section.title).", level: .debug)
    }
}
