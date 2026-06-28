import AppKit
import SwiftUI

@MainActor
final class SearchWindowController: NSWindowController, NSWindowDelegate {
    private let diagnosticsLogger: DiagnosticsLogger

    init(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        liveStatus: LiveDiagnosticsStatus,
        searchService: SearchService,
        menuItemActivator: MenuItemActivator,
        diagnosticsLogger: DiagnosticsLogger,
        onRefresh: @escaping () -> Void,
        onMove: @escaping @MainActor (MenuBarSearchResult, IconMoveCommand) async -> IconMoveResult,
        onSettingsChanged: @escaping () -> Void,
        onOpenPrivacySettings: @escaping () -> Void
    ) {
        self.diagnosticsLogger = diagnosticsLogger

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Find Icon"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .transient]
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: panel)

        let rootView = SearchRootView(
            settingsStore: settingsStore,
            permissionService: permissionService,
            liveStatus: liveStatus,
            searchService: searchService,
            onRefresh: onRefresh,
            onActivate: { result in
                menuItemActivator.activate(result)
            },
            onMove: onMove,
            onSettingsChanged: onSettingsChanged,
            onOpenPrivacySettings: onOpenPrivacySettings,
            onDismiss: { [weak panel] in
                panel?.close()
            }
        )

        panel.contentViewController = NSHostingController(rootView: rootView)
        panel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SearchWindowController does not support storyboards.")
    }

    func show() {
        if window?.isVisible != true {
            window?.center()
        }

        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        diagnosticsLogger.log("Find Icon panel opened.", level: .debug)
    }

    func windowWillClose(_ notification: Notification) {
        diagnosticsLogger.log("Find Icon panel closed.", level: .debug)
    }
}
