import AppKit
import Foundation
import SwiftUI

/// Owns the Basic Mode menu bar surface: a control toggle item plus the
/// primary and optional always-hidden separator items. Translates user input
/// into ``HidingService`` transitions and keeps the status item visuals in
/// sync with the visibility state.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let menuBuilder: StatusBarMenuBuilder
    private let diagnosticsLogger: DiagnosticsLogger
    private let factory: StatusItemFactory
    private let settingsStore: SettingsStore
    private let screenGeometry: ScreenGeometryService
    private let hidingService: HidingService
    private let primarySeparatorController: SeparatorController
    private let alwaysHiddenSeparatorController: SeparatorController
    private let rehideController: RehideController
    private let hoverRevealController: HoverRevealController
    private let hotkeyManager: GlobalHotkeyManager
    private let liveStatus: LiveDiagnosticsStatus
    private let statusItemMenuOpenDidChange: (Bool) -> Void
    private let autoRehideSuppressionProvider: () -> Bool
    private let hoverRevealSuppressionProvider: () -> Bool

    private var controlItem: NSStatusItem?
    private var didChangeScreenParametersObserver: NSObjectProtocol?
    private var dragHintPopover: NSPopover?
    private var isStatusItemMenuOpen = false

    // The menu target object holds @objc callbacks invoked from menu items and
    // from the control item button. It must outlive the controller.
    private let commandTarget: StatusBarCommandTarget

    init(
        menuBuilder: StatusBarMenuBuilder,
        diagnosticsLogger: DiagnosticsLogger,
        factory: StatusItemFactory,
        settingsStore: SettingsStore,
        screenGeometry: ScreenGeometryService,
        hidingService: HidingService,
        primarySeparatorController: SeparatorController,
        alwaysHiddenSeparatorController: SeparatorController,
        rehideController: RehideController,
        hoverRevealController: HoverRevealController,
        hotkeyManager: GlobalHotkeyManager,
        liveStatus: LiveDiagnosticsStatus,
        statusItemMenuOpenDidChange: @escaping (Bool) -> Void = { _ in },
        autoRehideSuppressionProvider: @escaping () -> Bool = { false },
        hoverRevealSuppressionProvider: @escaping () -> Bool = { false }
    ) {
        self.menuBuilder = menuBuilder
        self.diagnosticsLogger = diagnosticsLogger
        self.factory = factory
        self.settingsStore = settingsStore
        self.screenGeometry = screenGeometry
        self.hidingService = hidingService
        self.primarySeparatorController = primarySeparatorController
        self.alwaysHiddenSeparatorController = alwaysHiddenSeparatorController
        self.rehideController = rehideController
        self.hoverRevealController = hoverRevealController
        self.hotkeyManager = hotkeyManager
        self.liveStatus = liveStatus
        self.statusItemMenuOpenDidChange = statusItemMenuOpenDidChange
        self.autoRehideSuppressionProvider = autoRehideSuppressionProvider
        self.hoverRevealSuppressionProvider = hoverRevealSuppressionProvider
        self.commandTarget = StatusBarCommandTarget(
            hidingService: hidingService,
            settingsStore: settingsStore
        )
        super.init()
    }

    var isControlItemInstalled: Bool {
        controlItem != nil
    }

    var isPrimarySeparatorInstalled: Bool {
        primarySeparatorController.statusItem != nil
    }

    var isAlwaysHiddenSeparatorInstalled: Bool {
        alwaysHiddenSeparatorController.statusItem != nil
    }

    var primarySeparatorLength: Double {
        primarySeparatorController.currentLength
    }

    var alwaysHiddenSeparatorLength: Double {
        alwaysHiddenSeparatorController.currentLength
    }

    func installStatusItem() {
        guard controlItem == nil else { return }

        let control = factory.makeControlItem()
        controlItem = control

        if let button = control.button {
            button.action = #selector(StatusBarCommandTarget.controlItemClicked(_:))
            button.target = commandTarget
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        commandTarget.showMenu = { [weak self] button in
            self?.showMenu(from: button)
        }

        primarySeparatorController.install(enableItem: true)
        primarySeparatorController.refreshSymbol(state: hidingService.currentState)

        // The always-hidden separator is gated by `alwaysHiddenEnabled`.
        if settingsStore.alwaysHiddenEnabled {
            alwaysHiddenSeparatorController.install(enableItem: true)
            alwaysHiddenSeparatorController.refreshSymbol(state: hidingService.visibilityState.alwaysHiddenSeparatorState)
        }

        hidingService.onVisibilityChange = { [weak self] visibility in
            self?.handleVisibilityChange(visibility)
        }

        // Make sure the menu reflects the current state immediately so the
        // first click already shows the correct labels.
        menuBuilder.refresh(for: hidingService.visibilityState)

        observeScreenParameters()
        diagnosticsLogger.log("Status bar controller installed.")
        applyVisibility(hidingService.visibilityState)
        liveStatus.visibilityState = hidingService.visibilityState
    }

    func removeStatusItem() {
        if let control = controlItem {
            NSStatusBar.system.removeStatusItem(control)
            controlItem = nil
        }
        primarySeparatorController.remove()
        alwaysHiddenSeparatorController.remove()
        if let observer = didChangeScreenParametersObserver {
            NotificationCenter.default.removeObserver(observer)
            didChangeScreenParametersObserver = nil
        }
        rehideController.cancel()
        hoverRevealController.stop()
        hotkeyManager.unregister()
        setStatusItemMenuOpen(false)
        diagnosticsLogger.log("Status bar controller removed.")
    }

    // MARK: Public actions invoked by the menu target

    func expand() {
        hidingService.expand()
    }

    func collapse() {
        hidingService.collapse()
    }

    func toggle() {
        hidingService.toggle()
    }

    func revealAll() {
        hidingService.revealAll()
    }

    func toggleRevealAll() {
        hidingService.toggleRevealAll()
    }

    func resetSeparatorLength() {
        primarySeparatorController.resetOverride()
        alwaysHiddenSeparatorController.resetOverride()
        applyVisibility(hidingService.visibilityState)
        diagnosticsLogger.log("Separator override reset.")
    }

    func ensureRequiredStatusItemsInstalled() {
        if controlItem == nil {
            installStatusItem()
            return
        }

        if primarySeparatorController.statusItem == nil {
            primarySeparatorController.install(enableItem: true)
        }

        if settingsStore.alwaysHiddenEnabled && alwaysHiddenSeparatorController.statusItem == nil {
            alwaysHiddenSeparatorController.install(enableItem: true)
        }

        applyVisibility(hidingService.visibilityState)
        diagnosticsLogger.log("Required status items verified.")
    }

    func reapplyCurrentVisibility() {
        applyVisibility(hidingService.visibilityState)
    }

    func showDragHint() {
        diagnosticsLogger.log(AppConstants.dragHintMessage)
        showDragHintPopover()
    }

    // MARK: Settings-driven refresh

    /// Re-applies separator visuals (length / symbol) without changing
    /// underlying state. Called when `showSeparators` toggles.
    func refreshSeparatorVisuals() {
        primarySeparatorController.applyVisualMarkerEnabled(settingsStore.showSeparators)
        alwaysHiddenSeparatorController.applyVisualMarkerEnabled(settingsStore.showSeparators)
    }

    /// Installs or removes the always-hidden separator based on the latest
    /// `alwaysHiddenEnabled` value.
    func refreshAlwaysHiddenSeparator() {
        if settingsStore.alwaysHiddenEnabled {
            if alwaysHiddenSeparatorController.statusItem == nil {
                alwaysHiddenSeparatorController.install(enableItem: true)
                alwaysHiddenSeparatorController.apply(state: hidingService.visibilityState.alwaysHiddenSeparatorState)
            }
        } else {
            alwaysHiddenSeparatorController.remove()
        }
        liveStatus.alwaysHiddenSeparatorInstalled = alwaysHiddenSeparatorController.statusItem != nil
        applyVisibility(hidingService.visibilityState)
    }

    /// Restart the hover timer after the interval toggles.
    func refreshHoverReveal() {
        guard !hoverRevealSuppressionProvider() else {
            hoverRevealController.stop()
            liveStatus.hoverPollingActive = false
            return
        }
        hoverRevealController.restart()
        liveStatus.hoverPollingActive = hoverRevealController.isPollingActive
    }

    /// Re-arm the global hotkey after the enable/hotkey settings changes.
    func refreshGlobalHotkey() {
        if settingsStore.globalHotkeyEnabled {
            hotkeyManager.register(hotkey: settingsStore.effectiveGlobalHotkey())
        } else {
            hotkeyManager.register(hotkey: nil)
        }
        liveStatus.hotkeyRegistered = hotkeyManager.isRegistered(identifier: .visibilityToggle)
    }

    /// Cancels an in-flight auto-rehide when the setting is disabled, or
    /// re-arms an existing countdown after the delay changes.
    func refreshAutoRehide() {
        guard !autoRehideSuppressionProvider() else {
            rehideController.cancel()
            liveStatus.autoRehideScheduled = false
            liveStatus.lastRehideReason = rehideController.lastReason?.rawValue
            return
        }

        if settingsStore.autoRehideEnabled {
            if rehideController.isScheduled {
                rehideController.armAfterExpand(delay: settingsStore.autoRehideDelaySeconds)
            }
        } else {
            rehideController.cancel()
        }

        liveStatus.autoRehideScheduled = rehideController.isScheduled
        liveStatus.lastRehideReason = rehideController.lastReason?.rawValue
    }

    // MARK: Private

    private func observeScreenParameters() {
        guard didChangeScreenParametersObserver == nil else { return }
        didChangeScreenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.hidingService.handleScreenParametersChanged()
            }
        }
    }

    private func applyVisibility(_ visibility: HidingVisibilityState) {
        primarySeparatorController.apply(state: visibility.primarySeparatorState)
        alwaysHiddenSeparatorController.apply(state: visibility.alwaysHiddenSeparatorState)
        if let control = controlItem {
            factory.updateSymbol(for: control, kind: .control, state: visibility.primarySeparatorState)
        }
        menuBuilder.refresh(for: visibility)

        liveStatus.visibilityState = visibility
        liveStatus.primarySeparatorLength = primarySeparatorController.currentLength
        liveStatus.alwaysHiddenSeparatorLength = alwaysHiddenSeparatorController.currentLength
        liveStatus.alwaysHiddenSeparatorInstalled = alwaysHiddenSeparatorController.statusItem != nil
    }

    private func handleVisibilityChange(_ visibility: HidingVisibilityState) {
        applyVisibility(visibility)

        // Auto-rehide logic: when the user expands (or revealAlls), arm the
        // timer; when they collapse, cancel it.
        if visibility.isCollapsed {
            rehideController.markUserCollapsed()
            liveStatus.autoRehideScheduled = rehideController.isScheduled
            liveStatus.lastRehideReason = rehideController.lastReason?.rawValue
        } else if settingsStore.autoRehideEnabled && !autoRehideSuppressionProvider() {
            rehideController.armAfterExpand(delay: settingsStore.autoRehideDelaySeconds)
            liveStatus.autoRehideScheduled = rehideController.isScheduled
        } else {
            rehideController.cancel()
            liveStatus.autoRehideScheduled = false
        }
    }

    private func showMenu(from button: NSStatusBarButton) {
        let menu = menuBuilder.makeMenu()
        menu.delegate = self
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height),
            in: button
        )
    }

    func menuWillOpen(_ menu: NSMenu) {
        setStatusItemMenuOpen(true)
    }

    func menuDidClose(_ menu: NSMenu) {
        setStatusItemMenuOpen(false)
    }

    private func setStatusItemMenuOpen(_ isOpen: Bool) {
        guard isStatusItemMenuOpen != isOpen else { return }
        isStatusItemMenuOpen = isOpen
        statusItemMenuOpenDidChange(isOpen)
    }

    private func showDragHintPopover() {
        let anchorButton = primarySeparatorController.statusItem?.button ?? controlItem?.button
        guard let anchorButton else { return }

        dragHintPopover?.close()

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 104)
        popover.contentViewController = NSHostingController(rootView: DragHintPopoverView())
        popover.show(
            relativeTo: anchorButton.bounds,
            of: anchorButton,
            preferredEdge: .minY
        )
        dragHintPopover = popover
    }
}

/// @objc command sink owned by ``StatusBarController``. Kept private to this
/// file so the menu builder does not need to duplicate it.
@MainActor
private final class StatusBarCommandTarget: NSObject {
    private let hidingService: HidingService
    private let settingsStore: SettingsStore
    var showMenu: ((NSStatusBarButton) -> Void)?

    init(hidingService: HidingService, settingsStore: SettingsStore) {
        self.hidingService = hidingService
        self.settingsStore = settingsStore
    }

    @objc func controlItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu?(sender)
            return
        }

        let isOption = event?.modifierFlags.contains(.option) == true
        if isOption, settingsStore.revealAllOnOptionClick {
            hidingService.toggleRevealAll()
            return
        }

        hidingService.toggle()
    }
}

private struct DragHintPopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position the separator")
                .font(.headline)

            Text(AppConstants.dragHintMessage)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 320, alignment: .leading)
    }
}
