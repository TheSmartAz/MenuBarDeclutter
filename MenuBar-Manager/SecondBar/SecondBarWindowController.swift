import AppKit
import SwiftUI

@MainActor
final class SecondBarWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore: SettingsStore
    private let permissionService: AccessibilityPermissionService
    private let liveStatus: LiveDiagnosticsStatus
    private let positioningService: SecondBarPositioningService
    private let diagnosticsLogger: DiagnosticsLogger

    private var lastPosition: CGPoint?

    /// Observer for `NSApplication.didChangeScreenParametersNotification`. The second
    /// bar panel is positioned in screen-relative coordinates, so any display
    /// connect/disconnect/reorder can leave it stranded off-screen or above the
    /// notch height on a new main display. When notified while visible, we clear
    /// unreachable remembered positions and re-invoke `positionPanel()` so the
    /// panel recovers to the current display.
    ///
    /// Marked `nonisolated(unsafe)` so the observer can be released from
    /// `deinit` (which on Apple platforms runs on whatever thread releases the last
    /// reference). The observer is registered on `.main` and only removed here, so
    /// concurrent access from another thread does not occur in practice.
    @ObservationIgnored nonisolated(unsafe) private var displayParametersObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var activeSpaceObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var screensWakeObserver: NSObjectProtocol?

    init(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        liveStatus: LiveDiagnosticsStatus,
        itemMemoryStore: MenuBarItemMemoryStore,
        positioningService: SecondBarPositioningService,
        diagnosticsLogger: DiagnosticsLogger,
        onRefresh: @escaping () -> Void,
        onCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult,
        onMove: @escaping @MainActor (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult,
        groupsProvider: @escaping () -> [IconGroup],
        onSettingsChanged: @escaping () -> Void,
        onOpenPrivacySettings: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.permissionService = permissionService
        self.liveStatus = liveStatus
        self.positioningService = positioningService
        self.diagnosticsLogger = diagnosticsLogger

        let panel = SecondBarPanel(
            contentRect: NSRect(
                origin: .zero,
                size: Self.contentSize(
                    showLabels: settingsStore.secondBarShowLabels,
                    showsUnavailableState: Self.showsUnavailableState(
                        settingsStore: settingsStore,
                        permissionService: permissionService,
                        liveStatus: liveStatus
                    )
                )
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.applyMenuBarDeclutterFloatingPanelStyle(title: "Second Bar")
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.minSize = NSSize(width: 620, height: 210)

        super.init(window: panel)

        let rootView = SecondBarRootView(
            settingsStore: settingsStore,
            permissionService: permissionService,
            liveStatus: liveStatus,
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
        updatePanelBehaviorFromSettings()
        observeScreenParameters()
        observeWorkspaceGeometryChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SecondBarWindowController does not support storyboards.")
    }

    deinit {
        if let displayParametersObserver {
            NotificationCenter.default.removeObserver(displayParametersObserver)
        }
        if let activeSpaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
        }
        if let screensWakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(screensWakeObserver)
        }
    }

    /// Registers a `.main`-queue observer for screen geometry changes so the
    /// panel re-positions (or closes, when unreachable) instead of becoming
    /// stranded off-screen after a display change.
    private func observeScreenParameters() {
        guard displayParametersObserver == nil else { return }
        displayParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleScreenParametersChanged()
            }
        }
    }

    private func observeWorkspaceGeometryChanges() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        if activeSpaceObserver == nil {
            activeSpaceObserver = workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.handleWorkspaceGeometryChanged(reason: "active Space changed")
                }
            }
        }

        if screensWakeObserver == nil {
            screensWakeObserver = workspaceCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.handleWorkspaceGeometryChanged(reason: "screens woke")
                }
            }
        }
    }

    @MainActor
    private func handleScreenParametersChanged() {
        positioningService.invalidateCurrentScreenSnapshots()
        guard window?.isVisible == true else { return }

        if let lastPosition {
            let stillInsideScreen = positioningService.currentScreenSnapshots().contains { screen in
                screen.visibleFrame.contains(lastPosition)
            }
            if !stillInsideScreen {
                diagnosticsLogger.log(
                    "Second Bar recovered: previous position no longer inside any current display.",
                    level: .debug
                )
                self.lastPosition = nil
            }
        }

        positionPanel()
    }

    @MainActor
    private func handleWorkspaceGeometryChanged(reason: String) {
        positioningService.invalidateCurrentScreenSnapshots()
        guard window?.isVisible == true else { return }

        positionPanel()
        diagnosticsLogger.log("Second Bar repositioned after \(reason).", level: .debug)
    }

    func show() {
        positionPanel()
        updatePanelBehaviorFromSettings()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        liveStatus.secondBarVisible = true
        diagnosticsLogger.log("Second Bar shown.", level: .debug)
    }

    func hide() {
        window?.close()
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func refreshAfterSettingsChanged() {
        updatePanelBehaviorFromSettings()
        if window?.isVisible == true {
            positionPanel()
        }
    }

    func windowWillClose(_ notification: Notification) {
        if let frame = window?.frame {
            lastPosition = frame.origin
            liveStatus.secondBarLastPosition = frameSummary(frame)
        }
        liveStatus.secondBarVisible = false
        diagnosticsLogger.log("Second Bar hidden.", level: .debug)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard settingsStore.secondBarCloseOnOutsideClick,
              window?.isVisible == true else {
            return
        }
        window?.close()
    }

    private func positionPanel() {
        guard let window else { return }
        let targetSize = targetPanelSize
        let placement = positioningService.placement(
            panelSize: targetSize,
            mode: settingsStore.effectiveSecondBarPositionMode(),
            lastPosition: lastPosition
        )

        window.setFrame(placement.frame, display: true)
        liveStatus.secondBarCurrentScreen = placement.screenID
        liveStatus.secondBarLastPosition = frameSummary(placement.frame)
        if placement.avoidedNotch {
            diagnosticsLogger.log("Second Bar adjusted to avoid the notch area.", level: .debug)
        }
    }

    private var targetPanelSize: CGSize {
        guard let window else {
            return Self.contentSize(
                showLabels: settingsStore.secondBarShowLabels,
                showsUnavailableState: Self.showsUnavailableState(
                    settingsStore: settingsStore,
                    permissionService: permissionService,
                    liveStatus: liveStatus
                )
            )
        }
        let contentRect = NSRect(origin: .zero, size: Self.contentSize(
            showLabels: settingsStore.secondBarShowLabels,
            showsUnavailableState: Self.showsUnavailableState(
                settingsStore: settingsStore,
                permissionService: permissionService,
                liveStatus: liveStatus
            )
        ))
        return window.frameRect(forContentRect: contentRect).size
    }

    private static func contentSize(showLabels: Bool, showsUnavailableState: Bool) -> CGSize {
        let height: CGFloat = showsUnavailableState ? 274 : (showLabels ? 274 : 228)
        let width: CGFloat = showsUnavailableState ? 660 : 760
        let unavailableHeight: CGFloat = 238
        return CGSize(width: width, height: showsUnavailableState ? unavailableHeight : height)
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

    private func updatePanelBehaviorFromSettings() {
        guard let panel = window as? NSPanel else { return }
        panel.hidesOnDeactivate = false
    }

    private func frameSummary(_ frame: CGRect) -> String {
        "x \(Int(frame.minX)), y \(Int(frame.minY)), \(Int(frame.width)) x \(Int(frame.height))"
    }
}

private final class SecondBarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
