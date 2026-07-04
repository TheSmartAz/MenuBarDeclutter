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
    private let dogfoodStore: DogfoodStore
    private let newItemInboxStore: NewMenuBarItemInboxStore?
    private let itemMemoryStore: MenuBarItemMemoryStore?
    private let placementPreferenceStore: PlacementItemPreferenceStore?
    private let accessibilityPermissionService: AccessibilityPermissionService?
    private let screenCapturePermissionService: ScreenCapturePermissionService?
    private let iconCaptureCoordinator: MenuBarIconCaptureCoordinator?
    private let menuBarScanCoordinator: MenuBarScanCoordinator?
    private let profileStore: ProfileStore?
    private let triggerService: TriggerService?
    private let layoutCoordinator: LayoutCoordinator?
    private let groupStore: IconGroupStore?
    private let hotkeyBindingStore: HotkeyBindingStore?
    private let privateAccessCoordinator: PrivateAccessCoordinator?
    private let workspaceSwitchingService: WorkspaceSwitchingService?
    private let setBuilderViewModel: SetBuilderViewModel?
    private let functionBarController: FunctionBarController?
    private let infoStripController: InfoStripController?
    private let actions: SettingsActions

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus? = nil,
        launchAtLoginService: LaunchAtLoginService? = nil,
        appSupportPaths: AppSupportPaths = AppSupportPaths(),
        diagnosticsExporter: DiagnosticsExporter = DiagnosticsExporter(),
        dogfoodStore: DogfoodStore? = nil,
        newItemInboxStore: NewMenuBarItemInboxStore? = nil,
        itemMemoryStore: MenuBarItemMemoryStore? = nil,
        placementPreferenceStore: PlacementItemPreferenceStore? = nil,
        accessibilityPermissionService: AccessibilityPermissionService? = nil,
        screenCapturePermissionService: ScreenCapturePermissionService? = nil,
        iconCaptureCoordinator: MenuBarIconCaptureCoordinator? = nil,
        menuBarScanCoordinator: MenuBarScanCoordinator? = nil,
        profileStore: ProfileStore? = nil,
        triggerService: TriggerService? = nil,
        layoutCoordinator: LayoutCoordinator? = nil,
        groupStore: IconGroupStore? = nil,
        hotkeyBindingStore: HotkeyBindingStore? = nil,
        privateAccessCoordinator: PrivateAccessCoordinator? = nil,
        workspaceSwitchingService: WorkspaceSwitchingService? = nil,
        setBuilderViewModel: SetBuilderViewModel? = nil,
        functionBarController: FunctionBarController? = nil,
        infoStripController: InfoStripController? = nil,
        actions: SettingsActions = .empty
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.launchAtLoginService = launchAtLoginService
        self.appSupportPaths = appSupportPaths
        self.diagnosticsExporter = diagnosticsExporter
        self.dogfoodStore = dogfoodStore ?? DogfoodStore(appSupportPaths: appSupportPaths)
        self.newItemInboxStore = newItemInboxStore
        self.itemMemoryStore = itemMemoryStore
        self.placementPreferenceStore = placementPreferenceStore
        self.accessibilityPermissionService = accessibilityPermissionService
        self.screenCapturePermissionService = screenCapturePermissionService
        self.iconCaptureCoordinator = iconCaptureCoordinator
        self.menuBarScanCoordinator = menuBarScanCoordinator
        self.profileStore = profileStore
        self.triggerService = triggerService
        self.layoutCoordinator = layoutCoordinator
        self.groupStore = groupStore
        self.hotkeyBindingStore = hotkeyBindingStore
        self.privateAccessCoordinator = privateAccessCoordinator
        self.workspaceSwitchingService = workspaceSwitchingService
        self.setBuilderViewModel = setBuilderViewModel
        self.functionBarController = functionBarController
        self.infoStripController = infoStripController
        self.actions = actions

        let contentView = SettingsRootView(
            navigationModel: navigationModel,
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            launchAtLoginService: launchAtLoginService,
            appSupportPaths: appSupportPaths,
            diagnosticsExporter: diagnosticsExporter,
            dogfoodStore: self.dogfoodStore,
            newItemInboxStore: newItemInboxStore,
            itemMemoryStore: itemMemoryStore,
            placementPreferenceStore: placementPreferenceStore,
            accessibilityPermissionService: accessibilityPermissionService,
            screenCapturePermissionService: screenCapturePermissionService,
            iconCaptureCoordinator: iconCaptureCoordinator,
            menuBarScanCoordinator: menuBarScanCoordinator,
            profileStore: profileStore,
            triggerService: triggerService,
            layoutCoordinator: layoutCoordinator,
            groupStore: groupStore,
            hotkeyBindingStore: hotkeyBindingStore,
            privateAccessCoordinator: privateAccessCoordinator,
            workspaceSwitchingService: workspaceSwitchingService,
            setBuilderViewModel: setBuilderViewModel,
            functionBarController: functionBarController,
            infoStripController: infoStripController,
            actions: actions
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "\(AppConstants.displayName) Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified
        window.contentViewController = NSHostingController(rootView: contentView)
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 820, height: 620)

        super.init(window: window)

        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SettingsWindowController does not support storyboards.")
    }

    func show(section: SettingsSection = .general, searchText: String? = nil) {
        navigationModel.selectedSection = section
        if let searchText {
            navigationModel.searchText = searchText
        }

        if window?.isVisible != true {
            window?.center()
        }

        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        diagnosticsLogger.log("Settings opened to \(section.title).", level: .debug)
    }
}
