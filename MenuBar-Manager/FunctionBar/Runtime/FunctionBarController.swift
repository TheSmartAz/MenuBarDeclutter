import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class FunctionBarViewModel {
    var state: FunctionBarDisplayState = .closed
    var activeWorkspace: MenuBarWorkspace?
    var availableWorkspaces: [MenuBarWorkspace] = []
    var items: [FunctionBarItemModel] = []
    var feedbackMessage: String?
    var showsSetSwitcher = true
    var showsLabels = true
    var density = "regular"

    @ObservationIgnored var onActivateItem: ((FunctionBarItemModel) -> Void)?
    @ObservationIgnored var onPerformProxyAction: ((FunctionBarItemModel, FunctionBarProxyAction) -> Void)?
    @ObservationIgnored var onSwitchWorkspace: ((UUID) -> Void)?
    @ObservationIgnored var onHide: (() -> Void)?
    @ObservationIgnored var onOpenSettings: (() -> Void)?
    @ObservationIgnored var onHoverChanged: ((Bool) -> Void)?

    func activate(_ item: FunctionBarItemModel) {
        onActivateItem?(item)
    }

    func performProxyAction(_ action: FunctionBarProxyAction, for item: FunctionBarItemModel) {
        onPerformProxyAction?(item, action)
    }

    func switchWorkspace(id: UUID) {
        onSwitchWorkspace?(id)
    }

    func hide() {
        onHide?()
    }

    func hoverChanged(_ isHovering: Bool) {
        onHoverChanged?(isHovering)
    }
}

@MainActor
final class FunctionBarController: NSObject, NSWindowDelegate {
    private static let defaultPanelSize = NSSize(width: 720, height: 96)

    private let settingsStore: SettingsStore
    private let switchingService: WorkspaceSwitchingService
    private let resolver: FunctionBarItemResolver
    private let dispatcher: FunctionBarActionDispatcher
    private let placementService: FunctionBarPlacementService
    private let safeModeActive: () -> Bool
    private let statusItemAnchorProvider: () -> CGRect?
    private let diagnosticsLogger: DiagnosticsLogger?

    private var panel: NSPanel?
    private var lastPosition: CGPoint?
    private(set) var viewModel = FunctionBarViewModel()
    private(set) var displayState: FunctionBarDisplayState = .closed
    private(set) var lastPlacement: FunctionBarPlacement?
    private(set) var lastShowResult: String?
    var onHoverChanged: ((Bool) -> Void)?

    init(
        settingsStore: SettingsStore,
        switchingService: WorkspaceSwitchingService,
        resolver: FunctionBarItemResolver,
        dispatcher: FunctionBarActionDispatcher,
        placementService: FunctionBarPlacementService = FunctionBarPlacementService(),
        safeModeActive: @escaping () -> Bool,
        statusItemAnchorProvider: @escaping () -> CGRect? = { nil },
        diagnosticsLogger: DiagnosticsLogger? = nil
    ) {
        self.settingsStore = settingsStore
        self.switchingService = switchingService
        self.resolver = resolver
        self.dispatcher = dispatcher
        self.placementService = placementService
        self.safeModeActive = safeModeActive
        self.statusItemAnchorProvider = statusItemAnchorProvider
        self.diagnosticsLogger = diagnosticsLogger
        super.init()
        configureViewModel()
    }

    func start() {
        refresh(reason: .manual)
    }

    func stop() {
        hide(source: .commandCenter)
        panel = nil
    }

    func show(source: FunctionBarShowSource) {
        guard !safeModeActive() else {
            setState(.suspendedBySafeMode)
            lastShowResult = FunctionBarUnavailableReason.safeModeActive.rawValue
            return
        }
        guard settingsStore.workspacesPreviewEnabled else {
            setState(.unavailable(.settingsDisabled))
            lastShowResult = FunctionBarUnavailableReason.settingsDisabled.rawValue
            return
        }
        guard settingsStore.functionBarPreviewEnabled else {
            setState(.unavailable(.previewDisabled))
            lastShowResult = FunctionBarUnavailableReason.previewDisabled.rawValue
            return
        }

        let workspace = switchingService.activeWorkspace()
        applyDisplaySettings()
        viewModel.activeWorkspace = workspace
        viewModel.availableWorkspaces = switchingService.currentSnapshot().workspaces.filter { !$0.isArchived }
        viewModel.items = resolver.resolve(workspace: workspace)

        let panelSize = panel?.frame.size ?? Self.defaultPanelSize
        guard let placement = placement(for: panelSize) else {
            setState(.unavailable(.noDisplayAvailable))
            lastShowResult = FunctionBarUnavailableReason.noDisplayAvailable.rawValue
            return
        }

        let panel = panel ?? makePanel()
        self.panel = panel
        panel.hidesOnDeactivate = settingsStore.functionBarCloseOnOutsideClick
        apply(placement: placement, to: panel)
        setState(.visible(workspaceID: workspace.id))
        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        lastShowResult = "shown:\(source.rawValue)"
        diagnosticsLogger?.log("Function Bar shown.", level: .debug)
    }

    func hide(source: FunctionBarHideSource) {
        panel?.close()
        setState(.closed)
        lastShowResult = "hidden:\(source.rawValue)"
    }

    func toggle(source: FunctionBarShowSource) {
        if panel?.isVisible == true {
            hide(source: .commandCenter)
        } else {
            show(source: source)
        }
    }

    func refresh(reason: FunctionBarRefreshReason) {
        applyDisplaySettings()
        if safeModeActive() {
            if panel?.isVisible == true {
                hide(source: .safeMode)
            }
            setState(.suspendedBySafeMode)
            lastShowResult = FunctionBarUnavailableReason.safeModeActive.rawValue
            return
        }
        if !settingsStore.workspacesPreviewEnabled {
            if panel?.isVisible == true {
                hide(source: .commandCenter)
                lastShowResult = FunctionBarUnavailableReason.settingsDisabled.rawValue
            }
            return
        }
        if !settingsStore.functionBarPreviewEnabled {
            if panel?.isVisible == true {
                hide(source: .commandCenter)
                lastShowResult = FunctionBarUnavailableReason.previewDisabled.rawValue
            }
            return
        }

        let snapshot = switchingService.currentSnapshot()
        viewModel.availableWorkspaces = snapshot.workspaces.filter { !$0.isArchived }
        let active = switchingService.activeWorkspace()
        viewModel.activeWorkspace = active
        viewModel.items = resolver.resolve(workspace: active)
        if panel?.isVisible == true {
            setState(.visible(workspaceID: active.id))
            guard let panel, let placement = placement(for: panel.frame.size) else {
                setState(.unavailable(.noDisplayAvailable))
                lastShowResult = FunctionBarUnavailableReason.noDisplayAvailable.rawValue
                return
            }
            apply(placement: placement, to: panel)
        }
        diagnosticsLogger?.log("Function Bar refreshed for \(reason.rawValue).", level: .debug)
    }

    func activeState() -> FunctionBarDisplayState {
        displayState
    }

    func showSetSwitcher() {
        show(source: .setSwitcher)
    }

    func windowWillClose(_ notification: Notification) {
        if let frame = panel?.frame {
            lastPosition = frame.origin
        }
        setState(.closed)
    }

    private func configureViewModel() {
        viewModel.onActivateItem = { [weak self] item in
            guard let self else { return }
            let result = self.dispatcher.activate(item)
            self.viewModel.feedbackMessage = result.message
        }
        viewModel.onPerformProxyAction = { [weak self] item, action in
            guard let self else { return }
            let result = self.dispatcher.activate(item, proxyAction: action)
            self.viewModel.feedbackMessage = result.message
        }
        viewModel.onSwitchWorkspace = { [weak self] id in
            guard let self else { return }
            let result = self.switchingService.switchWorkspace(id: id, source: .functionBar)
            self.viewModel.feedbackMessage = result.message
            self.refresh(reason: .workspaceChanged)
        }
        viewModel.onHide = { [weak self] in
            self?.hide(source: .closeButton)
        }
        viewModel.onOpenSettings = { [weak self] in
            self?.dispatcher.openWorkspacePreview()
        }
        viewModel.onHoverChanged = { [weak self] isHovering in
            self?.onHoverChanged?(isHovering)
        }
    }

    private func applyDisplaySettings() {
        viewModel.showsSetSwitcher = settingsStore.functionBarShowSetSwitcher
        viewModel.showsLabels = settingsStore.functionBarShowLabels
        viewModel.density = settingsStore.functionBarDensity
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.defaultPanelSize),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Function Bar Preview"
        panel.titleVisibility = .visible
        panel.isFloatingPanel = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = settingsStore.functionBarCloseOnOutsideClick
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.backgroundColor = .windowBackgroundColor
        panel.isOpaque = true
        panel.hasShadow = true
        panel.minSize = NSSize(width: 420, height: 92)
        panel.contentViewController = NSHostingController(rootView: FunctionBarView(viewModel: viewModel))
        panel.delegate = self
        return panel
    }

    private func placement(for panelSize: NSSize) -> FunctionBarPlacement? {
        placementService.placement(
            panelSize: panelSize,
            preference: settingsStore.effectiveFunctionBarPlacementPreference(),
            statusItemAnchor: statusItemAnchorProvider(),
            lastPosition: lastPosition
        )
    }

    private func apply(placement: FunctionBarPlacement, to panel: NSPanel) {
        lastPlacement = placement
        panel.setFrameOrigin(placement.origin)
    }

    private func setState(_ state: FunctionBarDisplayState) {
        displayState = state
        viewModel.state = state
    }
}

struct FunctionBarStateMachine {
    private(set) var state: FunctionBarDisplayState = .closed

    mutating func show(workspaceID: UUID, previewEnabled: Bool, safeModeActive: Bool) -> FunctionBarDisplayState {
        if safeModeActive {
            state = .suspendedBySafeMode
        } else if !previewEnabled {
            state = .unavailable(.previewDisabled)
        } else {
            state = .visible(workspaceID: workspaceID)
        }
        return state
    }

    mutating func hide() -> FunctionBarDisplayState {
        state = .closed
        return state
    }
}
