import AppKit
import SwiftUI

@MainActor
final class SecondBarWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore: SettingsStore
    private let liveStatus: LiveDiagnosticsStatus
    private let positioningService: SecondBarPositioningService
    private let diagnosticsLogger: DiagnosticsLogger

    private var lastPosition: CGPoint?

    /// Observer for `NSApplication.didChangeScreenParametersNotification`. The second
    /// bar panel is positioned in screen-relative coordinates, so any display
    /// connect/disconnect/reorder can leave it stranded off-screen or above the
    /// notch height on a new main display. When notified while visible, we re-invoke
    /// `positionPanel()`; if the previously-saved position is no longer inside any
    /// current `NSScreen.visibleFrame`, the panel is closed to ensure the user can
    /// re-invoke it from a known-good state rather than clicking into empty space.
    ///
    /// Marked `nonisolated(unsafe)` so the observer can be released from
    /// `deinit` (which on Apple platforms runs on whatever thread releases the last
    /// reference). The observer is registered on `.main` and only removed here, so
    /// concurrent access from another thread does not occur in practice.
    @ObservationIgnored nonisolated(unsafe) private var displayParametersObserver: NSObjectProtocol?

    init(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        liveStatus: LiveDiagnosticsStatus,
        positioningService: SecondBarPositioningService,
        diagnosticsLogger: DiagnosticsLogger,
        onRefresh: @escaping () -> Void,
        onCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult,
        onMove: @escaping @MainActor (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult,
        onSettingsChanged: @escaping () -> Void,
        onOpenPrivacySettings: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.liveStatus = liveStatus
        self.positioningService = positioningService
        self.diagnosticsLogger = diagnosticsLogger

        let panel = SecondBarPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 190),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Second Bar"
        panel.isFloatingPanel = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow

        super.init(window: panel)

        let rootView = SecondBarRootView(
            settingsStore: settingsStore,
            permissionService: permissionService,
            liveStatus: liveStatus,
            onRefresh: onRefresh,
            onCommand: onCommand,
            onMove: onMove,
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
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SecondBarWindowController does not support storyboards.")
    }

    deinit {
        if let displayParametersObserver {
            NotificationCenter.default.removeObserver(displayParametersObserver)
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

    @MainActor
    private func handleScreenParametersChanged() {
        positioningService.invalidateCurrentScreenSnapshots()
        guard window?.isVisible == true else { return }

        // If the last-saved position no longer falls inside any current screen, close
        // the panel rather than repositioning blindly — re-opening from settings
        // will pick a sensible default again.
        if let lastPosition {
            let stillInsideScreen = positioningService.currentScreenSnapshots().contains { screen in
                screen.visibleFrame.contains(lastPosition)
            }
            if !stillInsideScreen {
                diagnosticsLogger.log(
                    "Second Bar closed: previous position no longer inside any current display.",
                    level: .debug
                )
                window?.close()
                return
            }
        }

        positionPanel()
    }

    func show() {
        guard settingsStore.secondBarEnabled else {
            diagnosticsLogger.log("Second Bar show requested while disabled.", level: .debug)
            return
        }

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
        CGSize(
            width: 640,
            height: settingsStore.secondBarShowLabels ? 190 : 132
        )
    }

    private func updatePanelBehaviorFromSettings() {
        guard let panel = window as? NSPanel else { return }
        panel.hidesOnDeactivate = settingsStore.secondBarCloseOnOutsideClick
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
