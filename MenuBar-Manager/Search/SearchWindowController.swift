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
        itemMemoryStore: MenuBarItemMemoryStore,
        diagnosticsLogger: DiagnosticsLogger,
        onRefresh: @escaping () -> Void,
        onCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult,
        onMove: @escaping @MainActor (MenuBarSearchResult, IconMoveCommand) async -> IconMoveResult,
        groupsProvider: @escaping () -> [IconGroup],
        onSettingsChanged: @escaping () -> Void,
        onOpenPrivacySettings: @escaping () -> Void
    ) {
        self.diagnosticsLogger = diagnosticsLogger

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 440),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Find Icon"
        panel.titleVisibility = .visible
        panel.titlebarAppearsTransparent = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.backgroundColor = .windowBackgroundColor
        panel.isOpaque = true
        panel.hasShadow = true
        panel.minSize = NSSize(width: 560, height: 380)
        panel.collectionBehavior = [.moveToActiveSpace, .transient]
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: panel)

        let rootView = SearchRootView(
            settingsStore: settingsStore,
            permissionService: permissionService,
            liveStatus: liveStatus,
            searchService: searchService,
            itemMemoryStore: itemMemoryStore,
            onRefresh: onRefresh,
            onCommand: onCommand,
            onMove: onMove,
            groupsProvider: groupsProvider,
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
