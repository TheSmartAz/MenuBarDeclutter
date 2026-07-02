import AppKit
import Observation
import SwiftUI

@MainActor
protocol InfoTileContextProviding {
    func infoTileContext() -> InfoTileContext
}

@MainActor
@Observable
final class InfoStripViewModel {
    var state: InfoStripDisplayState = .closed
    var currentTile: InfoTileSnapshot?
    var activeWorkspace: MenuBarWorkspace?
    var unavailableMessage: String?
    var showFunctionBarOnHover = true

    @ObservationIgnored var onAction: ((InfoTileAction) -> Void)?
    @ObservationIgnored var onShowFunctionBar: (() -> Void)?
    @ObservationIgnored var onNextTile: (() -> Void)?
    @ObservationIgnored var onClose: (() -> Void)?

    func performAction() {
        if let action = currentTile?.action {
            onAction?(action)
        }
    }
}

@MainActor
final class InfoStripRotationService {
    private let registry: InfoTileProviderRegistry
    private var timer: Timer?
    private var providerIDs: [String] = []
    private var contextProvider: (any InfoTileContextProviding)?
    private var index = 0
    private var isPaused = false
    private(set) var current: InfoTileSnapshot?
    private(set) var lastRotationResult: String?
    var onSnapshotChanged: ((InfoTileSnapshot?) -> Void)?

    init(registry: InfoTileProviderRegistry) {
        self.registry = registry
    }

    func start(configuration: WorkspaceInfoStripConfig, contextProvider: any InfoTileContextProviding) {
        stop()
        self.contextProvider = contextProvider
        providerIDs = configuration.selectedTileProviderIDs
        index = 0
        rotate()
        let interval = TimeInterval(max(configuration.rotationIntervalSeconds, WorkspaceValidationConstants.minRotationIntervalSeconds))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceIfRunning()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        current = nil
        contextProvider = nil
        lastRotationResult = "stopped"
        onSnapshotChanged?(nil)
    }

    func pause(reason: InfoStripPauseReason) {
        isPaused = true
        lastRotationResult = "paused:\(reason.rawValue)"
    }

    func resume(reason: InfoStripResumeReason) {
        isPaused = false
        lastRotationResult = "resumed:\(reason.rawValue)"
    }

    func currentSnapshot() -> InfoTileSnapshot? {
        current
    }

    func advanceManually() {
        advanceIfRunning()
    }

    private func advanceIfRunning() {
        guard !isPaused else { return }
        index += 1
        rotate()
    }

    private func rotate() {
        guard let contextProvider else { return }
        let context = contextProvider.infoTileContext()
        guard !context.safeModeActive else {
            current = nil
            lastRotationResult = "safeMode"
            onSnapshotChanged?(nil)
            return
        }
        let snapshots = registry.snapshots(for: providerIDs, context: context)
        guard !snapshots.isEmpty else {
            current = nil
            lastRotationResult = "empty"
            onSnapshotChanged?(nil)
            return
        }
        current = snapshots[index % snapshots.count]
        lastRotationResult = "rotated"
        onSnapshotChanged?(current)
    }
}

nonisolated enum InfoStripPauseReason: String, Equatable, Sendable {
    case functionBarPinned
    case userPaused
    case appInactive
}

nonisolated enum InfoStripResumeReason: String, Equatable, Sendable {
    case functionBarClosed
    case userResumed
    case manual
}

@MainActor
final class InfoStripController: NSObject, NSWindowDelegate, InfoTileContextProviding {
    private let settingsStore: SettingsStore
    private let switchingService: WorkspaceSwitchingService
    private let registry: InfoTileProviderRegistry
    private let rotationService: InfoStripRotationService
    private let placementService: InfoStripPlacementService
    private let safeModeActive: () -> Bool
    private let contextBuilder: () -> InfoTileContext
    private let actionDispatcher: (InfoTileAction) -> Void
    private let showFunctionBar: () -> Void
    private let diagnosticsLogger: DiagnosticsLogger?

    private var panel: NSPanel?
    private var lastPosition: CGPoint?
    private(set) var viewModel = InfoStripViewModel()
    private(set) var displayState: InfoStripDisplayState = .closed
    private(set) var lastPlacement: InfoStripPlacement?
    private(set) var lastPlacementFailed = false
    private(set) var lastShowResult: String?
    var lastRotationResult: String? {
        rotationService.lastRotationResult
    }

    init(
        settingsStore: SettingsStore,
        switchingService: WorkspaceSwitchingService,
        registry: InfoTileProviderRegistry = InfoTileProviderRegistry(),
        placementService: InfoStripPlacementService = InfoStripPlacementService(),
        safeModeActive: @escaping () -> Bool,
        contextBuilder: @escaping () -> InfoTileContext,
        actionDispatcher: @escaping (InfoTileAction) -> Void,
        showFunctionBar: @escaping () -> Void,
        diagnosticsLogger: DiagnosticsLogger? = nil
    ) {
        self.settingsStore = settingsStore
        self.switchingService = switchingService
        self.registry = registry
        self.rotationService = InfoStripRotationService(registry: registry)
        self.placementService = placementService
        self.safeModeActive = safeModeActive
        self.contextBuilder = contextBuilder
        self.actionDispatcher = actionDispatcher
        self.showFunctionBar = showFunctionBar
        self.diagnosticsLogger = diagnosticsLogger
        super.init()
        configureViewModel()
    }

    func show() {
        guard !safeModeActive() else {
            setState(.suspendedBySafeMode)
            lastShowResult = InfoStripUnavailableReason.safeModeActive.rawValue
            return
        }
        guard settingsStore.workspacesPreviewEnabled, settingsStore.infoStripPreviewEnabled else {
            setState(.unavailable(.previewDisabled))
            lastShowResult = InfoStripUnavailableReason.previewDisabled.rawValue
            return
        }
        let workspace = switchingService.activeWorkspace()
        guard workspace.infoStripConfig.isEnabled else {
            setState(.unavailable(.workspaceDisabled))
            lastShowResult = InfoStripUnavailableReason.workspaceDisabled.rawValue
            return
        }

        viewModel.activeWorkspace = workspace
        viewModel.showFunctionBarOnHover = InfoStripHoverPolicy.shouldShowFunctionBar(
            globalEnabled: settingsStore.infoStripHoverToFunctionBarEnabled,
            workspaceBehavior: workspace.infoStripConfig.hoverBehavior
        )
        rotationService.onSnapshotChanged = { [weak self] snapshot in
            self?.viewModel.currentTile = snapshot
            self?.viewModel.unavailableMessage = snapshot == nil ? "Info Strip has no available tiles." : nil
        }
        rotationService.start(configuration: workspace.infoStripConfig, contextProvider: self)

        let panel = panel ?? makePanel()
        self.panel = panel
        panel.hidesOnDeactivate = settingsStore.infoStripCloseOnOutsideClick
        guard position(panel: panel) else {
            rotationService.stop()
            lastShowResult = InfoStripUnavailableReason.noDisplayAvailable.rawValue
            return
        }
        setState(.visible(workspaceID: workspace.id, tileProviderID: viewModel.currentTile?.providerID))
        panel.orderFrontRegardless()
        lastShowResult = "shown"
        diagnosticsLogger?.log("Info Strip shown.", level: .debug)
    }

    func hide() {
        rotationService.stop()
        panel?.close()
        setState(.closed)
        lastShowResult = "hidden"
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func refresh() {
        if panel?.isVisible == true {
            show()
        }
    }

    func advanceTile() {
        rotationService.advanceManually()
    }

    func resetPlacement() {
        lastPosition = nil
        lastPlacement = nil
        lastPlacementFailed = false
        if panel?.isVisible == true {
            _ = position(panel: panel)
        }
    }

    func infoTileContext() -> InfoTileContext {
        contextBuilder()
    }

    func windowWillClose(_ notification: Notification) {
        if let frame = panel?.frame {
            lastPosition = frame.origin
        }
        rotationService.stop()
        setState(.closed)
    }

    private func configureViewModel() {
        viewModel.onAction = { [weak self] action in self?.actionDispatcher(action) }
        viewModel.onShowFunctionBar = { [weak self] in
            self?.actionDispatcher(InfoTileAction(commandID: WorkspaceCommandReference.showFunctionBarFromInfoStrip.actionID, label: "Show Function Bar"))
        }
        viewModel.onNextTile = { [weak self] in
            self?.actionDispatcher(InfoTileAction(commandID: WorkspaceCommandReference.nextInfoStripTile.actionID, label: "Next Tile"))
        }
        viewModel.onClose = { [weak self] in self?.hide() }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 74),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Info Strip Preview"
        panel.isFloatingPanel = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = settingsStore.infoStripCloseOnOutsideClick
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.backgroundColor = .windowBackgroundColor
        panel.isOpaque = true
        panel.hasShadow = true
        panel.contentViewController = NSHostingController(rootView: InfoStripView(viewModel: viewModel))
        panel.delegate = self
        return panel
    }

    @discardableResult
    private func position(panel: NSPanel?) -> Bool {
        guard let panel else {
            lastPlacementFailed = true
            return false
        }
        guard let placement = placementService.placement(panelSize: panel.frame.size, preference: .alignWithFunctionBar, lastPosition: lastPosition) else {
            setState(.unavailable(.noDisplayAvailable))
            lastPlacementFailed = true
            lastPlacement = nil
            return false
        }
        lastPlacement = placement
        lastPlacementFailed = false
        panel.setFrameOrigin(placement.origin)
        return true
    }

    private func setState(_ state: InfoStripDisplayState) {
        displayState = state
        viewModel.state = state
    }
}

nonisolated enum InfoStripHoverPolicy {
    static func shouldShowFunctionBar(
        globalEnabled: Bool,
        workspaceBehavior: WorkspaceInfoStripHoverBehavior
    ) -> Bool {
        globalEnabled && workspaceBehavior == .showFunctionBar
    }
}

@MainActor
final class WorkspaceDisplayCoordinator {
    private let functionBarController: FunctionBarController
    private let infoStripController: InfoStripController
    private let switchingService: WorkspaceSwitchingService
    private let safeModeActive: () -> Bool
    private let infoStripAutoShowEnabled: () -> Bool
    private var idleTask: Task<Void, Never>?
    private(set) var state: WorkspaceDisplayState = .closed

    init(
        functionBarController: FunctionBarController,
        infoStripController: InfoStripController,
        switchingService: WorkspaceSwitchingService,
        safeModeActive: @escaping () -> Bool,
        infoStripAutoShowEnabled: @escaping () -> Bool
    ) {
        self.functionBarController = functionBarController
        self.infoStripController = infoStripController
        self.switchingService = switchingService
        self.safeModeActive = safeModeActive
        self.infoStripAutoShowEnabled = infoStripAutoShowEnabled
        self.functionBarController.onHoverChanged = { [weak self] isHovering in
            self?.functionBarHoverChanged(isHovering)
        }
    }

    func showFunctionBar() {
        guard !safeModeActive() else {
            state = .suspendedBySafeMode
            return
        }
        infoStripController.hide()
        functionBarController.show(source: .workspaceDisplay)
        switch functionBarController.displayState {
        case .visible(let workspaceID):
            state = .functionBarVisible(workspaceID: workspaceID)
        case .suspendedBySafeMode:
            state = .suspendedBySafeMode
        default:
            state = .closed
        }
        idleTask?.cancel()
    }

    func hideFunctionBar() {
        idleTask?.cancel()
        functionBarController.hide(source: .workspaceDisplay)
        if case .functionBarVisible = state {
            state = .closed
        }
    }

    func toggleFunctionBar() {
        if functionBarController.displayState.isVisible {
            hideFunctionBar()
        } else {
            showFunctionBar()
        }
    }

    func showInfoStrip() {
        guard !safeModeActive() else {
            state = .suspendedBySafeMode
            return
        }
        idleTask?.cancel()
        functionBarController.hide(source: .workspaceDisplay)
        infoStripController.show()
        switch infoStripController.displayState {
        case .visible(let workspaceID, let tileProviderID):
            state = .infoStripVisible(workspaceID: workspaceID, tileID: tileProviderID)
        case .suspendedBySafeMode:
            state = .suspendedBySafeMode
        case .unavailable(let reason):
            state = .unavailable(Self.workspaceUnavailableReason(for: reason))
        case .closed:
            state = .closed
        }
    }

    func hideInfoStrip() {
        infoStripController.hide()
        if case .infoStripVisible = state {
            state = .closed
        }
    }

    func toggleInfoStrip() {
        if case .visible = infoStripController.displayState {
            hideInfoStrip()
        } else {
            showInfoStrip()
        }
    }

    func startIdleCountdown() {
        idleTask?.cancel()
        let delay = switchingService.activeWorkspace().infoStripConfig.idleDelaySeconds
        idleTask = Task { [weak self] in
            let nanoseconds = UInt64(max(delay, 1)) * 1_000_000_000
            try? await Task.sleep(nanoseconds: nanoseconds)
            await MainActor.run {
                self?.showInfoStrip()
            }
        }
    }

    func hoverInfoStrip() {
        showFunctionBar()
    }

    func functionBarHoverChanged(_ isHovering: Bool) {
        guard case .functionBarVisible = state else { return }
        if isHovering {
            idleTask?.cancel()
            return
        }
        let workspace = switchingService.activeWorkspace()
        if Self.shouldStartIdleCountdown(globalAutoShowEnabled: infoStripAutoShowEnabled(), workspace: workspace) {
            startIdleCountdown()
        }
    }

    func closeAll() {
        idleTask?.cancel()
        functionBarController.hide(source: .workspaceDisplay)
        infoStripController.hide()
        state = .closed
    }

    nonisolated static func shouldStartIdleCountdown(
        globalAutoShowEnabled: Bool,
        workspace: MenuBarWorkspace
    ) -> Bool {
        globalAutoShowEnabled && workspace.infoStripConfig.isEnabled
    }

    nonisolated private static func workspaceUnavailableReason(
        for reason: InfoStripUnavailableReason
    ) -> WorkspaceDisplayUnavailableReason {
        switch reason {
        case .previewDisabled:
            .previewsDisabled
        case .safeModeActive:
            .safeModeActive
        case .noActiveWorkspace:
            .noActiveWorkspace
        case .workspaceDisabled, .noTilesAvailable, .noDisplayAvailable:
            .infoStripUnavailable
        }
    }
}
