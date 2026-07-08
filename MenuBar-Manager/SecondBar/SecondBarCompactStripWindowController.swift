import AppKit
import SwiftUI

@MainActor
final class SecondBarCompactStripWindowController: NSWindowController, NSWindowDelegate {
    private enum VisibleContent {
        case compact(snapshots: [MenuBarItemSnapshot], accurateIconReadyIDs: Set<String>)
        case requirements(ProSecondBarReadinessState)

        var isCompact: Bool {
            if case .compact = self {
                return true
            }
            return false
        }
    }

    private let settingsStore: SettingsStore
    private let liveStatus: LiveDiagnosticsStatus
    private let positioningService: SecondBarPositioningService
    private let diagnosticsLogger: DiagnosticsLogger
    private let onActivate: (MenuBarItemSnapshot) -> Bool
    private let onOpenManage: () -> Void
    private let onOpenSettings: () -> Void

    private var visibleContent: VisibleContent?
    private var lastAnchorFrame: CGRect?
    private var activationFeedback: SecondBarCompactStripActivationFeedback?

    /// Reused across renders: rebuilding a fresh `NSHostingController` on every
    /// `renderAndPosition()` (twice per open + every reposition) is a visible
    /// hitch (H2). Created lazily once, then its `rootView` is updated in place.
    private var hostingController: NSHostingController<AnyView>?

    var isShowingCompactStrip: Bool {
        window?.isVisible == true && visibleContent?.isCompact == true
    }

    @ObservationIgnored nonisolated(unsafe) private var displayParametersObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var activeSpaceObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var screensWakeObserver: NSObjectProtocol?

    init(
        settingsStore: SettingsStore,
        liveStatus: LiveDiagnosticsStatus,
        positioningService: SecondBarPositioningService,
        diagnosticsLogger: DiagnosticsLogger,
        onActivate: @escaping (MenuBarItemSnapshot) -> Bool,
        onOpenManage: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.liveStatus = liveStatus
        self.positioningService = positioningService
        self.diagnosticsLogger = diagnosticsLogger
        self.onActivate = onActivate
        self.onOpenManage = onOpenManage
        self.onOpenSettings = onOpenSettings

        let panel = SecondBarCompactStripPanel(
            contentRect: NSRect(origin: .zero, size: Self.defaultContentSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.applyMenuBarDeclutterFloatingPanelStyle(title: "Second Bar Compact Strip")
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.minSize = NSSize(width: 220, height: Self.defaultContentSize.height)

        super.init(window: panel)

        panel.delegate = self
        observeScreenParameters()
        observeWorkspaceGeometryChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SecondBarCompactStripWindowController does not support storyboards.")
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

    func showCompactStrip(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<String>,
        anchorFrame: CGRect?
    ) {
        visibleContent = .compact(
            snapshots: snapshots,
            accurateIconReadyIDs: accurateIconReadyIDs
        )
        activationFeedback = nil
        showCurrentContent(anchorFrame: anchorFrame)
        diagnosticsLogger.log("Second Bar compact strip shown.", level: .debug)
    }

    func refreshCompactStrip(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<String>,
        anchorFrame: CGRect?
    ) {
        guard window?.isVisible == true,
              visibleContent?.isCompact == true else {
            return
        }

        visibleContent = .compact(
            snapshots: snapshots,
            accurateIconReadyIDs: accurateIconReadyIDs
        )
        if let anchorFrame {
            lastAnchorFrame = anchorFrame
        }
        renderAndPosition()
        diagnosticsLogger.log("Second Bar compact strip refreshed.", level: .debug)
    }

    func toggleCompactStrip(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<String>,
        anchorFrame: CGRect?
    ) {
        if window?.isVisible == true,
           visibleContent?.isCompact == true {
            hide()
            return
        }

        showCompactStrip(
            snapshots: snapshots,
            accurateIconReadyIDs: accurateIconReadyIDs,
            anchorFrame: anchorFrame
        )
    }

    func showRequirements(
        _ readiness: ProSecondBarReadinessState,
        anchorFrame: CGRect?
    ) {
        visibleContent = .requirements(readiness)
        activationFeedback = nil
        showCurrentContent(anchorFrame: anchorFrame)
        diagnosticsLogger.log(
            "Second Bar compact requirements shown: \(readiness.displayTitle).",
            level: .debug
        )
    }

    func hide() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        if let frame = window?.frame {
            liveStatus.secondBarLastPosition = frameSummary(frame)
        }
        visibleContent = nil
        activationFeedback = nil
        liveStatus.secondBarVisible = false
        diagnosticsLogger.log("Second Bar compact strip hidden.", level: .debug)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard settingsStore.secondBarCloseOnOutsideClick,
              window?.isVisible == true else {
            return
        }
        window?.close()
    }

    private func showCurrentContent(anchorFrame: CGRect?) {
        lastAnchorFrame = anchorFrame
        renderAndPosition()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        liveStatus.secondBarVisible = true
    }

    private func renderAndPosition() {
        guard let window,
              let visibleContent else {
            return
        }

        let screens = positioningService.currentScreenSnapshots()
        let placement = positioningService.compactStripPlacement(
            contentSize: Self.defaultContentSize,
            anchorFrame: lastAnchorFrame,
            mouseLocation: positioningService.mouseLocationProvider(),
            screens: screens
        )
        let targetScreen = screens.first { $0.id == placement.screenID }
            ?? SecondBarPositioningService.fallbackScreen
        let plan = plan(
            for: visibleContent,
            availableWidth: placement.frame.width,
            screen: targetScreen
        )
        let rootContent: SecondBarCompactStripRootView.Content
        switch visibleContent {
        case .compact:
            rootContent = .ready(plan: plan)
            liveStatus.updateSecondBarCompactStrip(plan: plan)
        case .requirements(let readiness):
            rootContent = .requirements(readiness)
        }

        let rootView = SecondBarCompactStripRootView(
            content: rootContent,
            activationFeedback: activationFeedback,
            onActivate: { [weak self] snapshot in
                self?.activate(snapshot)
            },
            onRetryActivation: { [weak self] snapshot in
                self?.activate(snapshot)
            },
            onOpenManage: { [weak self] in
                self?.openManage()
            },
            onOpenSettings: { [weak self] in
                self?.onOpenSettings()
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )
        .frame(width: placement.frame.width, height: placement.frame.height)

        let erasedRootView = AnyView(rootView)
        if let hostingController {
            hostingController.rootView = erasedRootView
        } else {
            let controller = NSHostingController(rootView: erasedRootView)
            hostingController = controller
            window.contentViewController = controller
        }
        window.setFrame(placement.frame, display: true)
        liveStatus.secondBarCurrentScreen = placement.screenID
        liveStatus.secondBarLastPosition = frameSummary(placement.frame)
        liveStatus.updateSecondBarCompactPlacement(avoidedNotch: placement.avoidedNotch)
    }

    private func plan(
        for content: VisibleContent,
        availableWidth: CGFloat,
        screen: SecondBarScreenSnapshot
    ) -> SecondBarCompactStripPlan {
        guard case .compact(let snapshots, let accurateIconReadyIDs) = content else {
            return SecondBarCompactStripPlan(
                visibleItems: [],
                hiddenOverflowCount: 0,
                needsAccurateIconCount: 0,
                scanState: .noScan
            )
        }

        return SecondBarCompactStripPlanner.plan(
            snapshots: snapshots,
            accurateIconReadyIDs: accurateIconReadyIDs,
            availableItemWidth: availableItemWidth(for: availableWidth),
            screen: screen,
            lastScanTime: liveStatus.lastMenuBarScanTime
        )
    }

    private func availableItemWidth(for availableWidth: CGFloat) -> CGFloat {
        let horizontalContentInset: CGFloat = 12
        let overflowReserve: CGFloat = 40
        return max(0, availableWidth - horizontalContentInset - overflowReserve)
    }

    private func activate(_ snapshot: MenuBarItemSnapshot) {
        guard onActivate(snapshot) else {
            activationFeedback = SecondBarCompactStripActivationFeedback(
                message: "Could not activate",
                tone: .warning,
                retrySnapshot: snapshot
            )
            renderAndPosition()
            diagnosticsLogger.log("Second Bar compact activation failed for \(snapshot.id).", level: .warning)
            return
        }

        hide()
    }

    private func openManage() {
        hide()
        onOpenManage()
    }

    private func observeScreenParameters() {
        guard displayParametersObserver == nil else { return }
        displayParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleWorkspaceGeometryChanged(reason: "display parameters changed")
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

    private func handleWorkspaceGeometryChanged(reason: String) {
        positioningService.invalidateCurrentScreenSnapshots()
        guard window?.isVisible == true else { return }
        renderAndPosition()
        diagnosticsLogger.log("Second Bar compact strip repositioned after \(reason).", level: .debug)
    }

    private func frameSummary(_ frame: CGRect) -> String {
        "x \(Int(frame.minX)), y \(Int(frame.minY)), \(Int(frame.width)) x \(Int(frame.height))"
    }

    private static let defaultContentSize = CGSize(width: 560, height: 34)
}

private final class SecondBarCompactStripPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
