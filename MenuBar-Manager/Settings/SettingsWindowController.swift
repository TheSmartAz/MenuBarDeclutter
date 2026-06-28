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
    private let actions: SettingsActions

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
        actions: SettingsActions = .empty
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
        self.actions = actions

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
            actions: actions
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
