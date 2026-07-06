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

        let placement = positioningService.compactStripPlacement(
            contentSize: Self.defaultContentSize,
            anchorFrame: lastAnchorFrame
        )
        let plan = plan(for: visibleContent, availableWidth: placement.frame.width)
        let rootContent: SecondBarCompactStripRootView.Content
        switch visibleContent {
        case .compact:
            rootContent = .ready(plan: plan)
        case .requirements(let readiness):
            rootContent = .requirements(readiness)
        }

        window.setFrame(placement.frame, display: true)
        window.contentViewController = NSHostingController(rootView: SecondBarCompactStripRootView(
            content: rootContent,
            activationFeedback: activationFeedback,
            onActivate: { [weak self] snapshot in
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
        ))
        liveStatus.secondBarCurrentScreen = placement.screenID
        liveStatus.secondBarLastPosition = frameSummary(placement.frame)
    }

    private func plan(
        for content: VisibleContent,
        availableWidth: CGFloat
    ) -> SecondBarCompactStripPlan {
        guard case .compact(let snapshots, let accurateIconReadyIDs) = content else {
            return SecondBarCompactStripPlan(
                visibleItems: [],
                hiddenOverflowCount: 0,
                needsAccurateIconCount: 0
            )
        }

        return SecondBarCompactStripPlanner.plan(
            snapshots: snapshots,
            accurateIconReadyIDs: accurateIconReadyIDs,
            maxVisibleItems: maxVisibleItems(for: availableWidth)
        )
    }

    private func maxVisibleItems(for availableWidth: CGFloat) -> Int {
        let reservedControlWidth: CGFloat = 142
        let itemSlotWidth: CGFloat = 36
        let availableItemWidth = max(0, availableWidth - reservedControlWidth)
        return min(18, max(0, Int(availableItemWidth / itemSlotWidth)))
    }

    private func activate(_ snapshot: MenuBarItemSnapshot) {
        guard onActivate(snapshot) else {
            activationFeedback = SecondBarCompactStripActivationFeedback(
                message: "Could not activate",
                tone: .warning
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

    private static let defaultContentSize = CGSize(width: 560, height: 42)
}

private final class SecondBarCompactStripPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
