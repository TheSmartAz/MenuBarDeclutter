import AppKit
import SwiftUI

@MainActor
final class SearchWindowController: NSWindowController, NSWindowDelegate {
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus

    init(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        liveStatus: LiveDiagnosticsStatus,
        searchService: SearchService,
        itemMemoryStore: MenuBarItemMemoryStore,
        diagnosticsLogger: DiagnosticsLogger,
        newItemStorageKeysProvider: @escaping () -> Set<String>,
        workspaceUsageProvider: @escaping () -> WorkspaceUsageIndexSnapshot? = { nil },
        onRefresh: @escaping () -> Void,
        onCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult,
        onMove: @escaping @MainActor (MenuBarSearchResult, IconMoveCommand) async -> IconMoveResult,
        groupsProvider: @escaping () -> [IconGroup],
        onSettingsChanged: @escaping () -> Void,
        onOpenPrivacySettings: @escaping () -> Void
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus

        let showsUnavailableState = Self.showsUnavailableState(
            settingsStore: settingsStore,
            permissionService: permissionService,
            liveStatus: liveStatus
        )
        let panel = SearchPanel(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 440),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.applyMenuBarDeclutterFloatingPanelStyle(title: "Find Icon")
        panel.setContentSize(Self.contentSize(showsUnavailableState: showsUnavailableState))
        panel.minSize = NSSize(width: 520, height: 340)
        panel.collectionBehavior = [.moveToActiveSpace, .transient]

        super.init(window: panel)

        let rootView = SearchRootView(
            settingsStore: settingsStore,
            permissionService: permissionService,
            liveStatus: liveStatus,
            searchService: searchService,
            itemMemoryStore: itemMemoryStore,
            diagnosticsLogger: diagnosticsLogger,
            newItemStorageKeysProvider: newItemStorageKeysProvider,
            workspaceUsageProvider: workspaceUsageProvider,
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
        let start = Date()
        if window?.isVisible != true {
            window?.center()
        }

        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        let durationMilliseconds = Date().timeIntervalSince(start) * 1000
        liveStatus.updateSearchPanelOpenDuration(milliseconds: durationMilliseconds)
        diagnosticsLogger.log(
            "Find Icon panel opened.",
            level: .debug,
            metadata: ["panelOpenMilliseconds": Self.formattedMilliseconds(durationMilliseconds)]
        )
    }

    func windowWillClose(_ notification: Notification) {
        diagnosticsLogger.log("Find Icon panel closed.", level: .debug)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard window?.isVisible == true else { return }
        window?.close()
    }

    private static func formattedMilliseconds(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private static func contentSize(showsUnavailableState: Bool) -> CGSize {
        showsUnavailableState
            ? CGSize(width: 560, height: 340)
            : CGSize(width: 600, height: 400)
    }

    private static func showsUnavailableState(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        liveStatus: LiveDiagnosticsStatus
    ) -> Bool {
        liveStatus.safeModeActive
            || !settingsStore.proModeEnabled
            || !settingsStore.accessibilityDiscoveryEnabled
            || permissionService.status != .granted
    }
}

private final class SearchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
