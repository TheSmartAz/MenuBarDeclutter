import AppKit
import Foundation

/// Owns the expand/collapse lifecycle of menu bar hiding in Basic Mode.
///
/// Phase 1 stored a binary ``HidingState``. Phase 2 promotes the model to
/// ``HidingVisibilityState`` (collapsed / expanded / revealAll) while
/// continuing to expose both surfaces:
/// * ``currentState`` remains a binary ``HidingState`` so Phase 1 callers and
///   tests observe the primary separator's collapsed/expanded state.
/// * ``visibilityState`` is the new source of truth and is replayed via
///   ``onVisibilityChange`` so separators (primary and always-hidden) can
///   apply their per-state lengths and symbols.
@MainActor
final class HidingService {
    /// Posted on `NotificationCenter` whenever ``currentState`` changes so
    /// non-observable observers (such as menu builders) can refresh.
    static let stateDidChangeNotification = Notification.Name("MBDHidingStateDidChange")

    /// Posted on `NotificationCenter` whenever ``visibilityState`` changes so
    /// observers (such as the always-hidden separator controller) can refresh
    /// without inspecting the binary ``currentState``.
    static let visibilityDidChangeNotification = Notification.Name("MBDVisibilityStateDidChange")

    private let settingsStore: SettingsStore
    private let screenGeometry: ScreenGeometryService
    private let diagnosticsLogger: DiagnosticsLogger

    /// Closure invoked after every successful state transition. Receives the
    /// new binary hiding state. Kept for Phase 1 compatibility.
    var onStateChange: ((HidingState) -> Void)?

    /// Closure invoked after every successful visibility transition. Receives
    /// the full ``HidingVisibilityState`` so callers can update both
    /// separators and any UI surfaces that distinguish revealAll.
    var onVisibilityChange: ((HidingVisibilityState) -> Void)?

    private(set) var visibilityState: HidingVisibilityState

    /// Binary view derived from ``visibilityState``. Kept for Phase 1
    /// callers and tests.
    var currentState: HidingState { visibilityState.primarySeparatorState }

    init(
        settingsStore: SettingsStore,
        screenGeometry: ScreenGeometryService = ScreenGeometryService(),
        diagnosticsLogger: DiagnosticsLogger
    ) {
        self.settingsStore = settingsStore
        self.screenGeometry = screenGeometry
        self.diagnosticsLogger = diagnosticsLogger
        self.visibilityState = settingsStore.isCollapsed ? .collapsed : .expanded
    }

    // MARK: Public transitions

    func expand() {
        applyVisibility(.expanded)
    }

    func collapse() {
        applyVisibility(.collapsed)
    }

    func toggle() {
        applyVisibility(visibilityState.toggled)
    }

    func revealAll() {
        applyVisibility(.revealAll)
    }

    func toggleRevealAll() {
        applyVisibility(visibilityState.optionToggled)
    }

    /// Set an explicit visibility state.
    func setVisibility(_ state: HidingVisibilityState) {
        applyVisibility(state)
    }

    /// Re-applies the current state to the menu bar. Used after display
    /// configuration changes and after the user-override length changes.
    func applyState() {
        applyVisibility(visibilityState, isReapply: true)
    }

    /// Re-applies the current state after a screen-configuration change so the
    /// collapsed separator still covers the (potentially larger) menu bar.
    func handleScreenParametersChanged() {
        diagnosticsLogger.log(
            "Screen parameters changed; recomputing collapsed length (\(screenGeometry.widestScreenWidth())pt wide)."
        )
        if visibilityState.isCollapsed {
            applyVisibility(visibilityState, isReapply: true)
        }
    }

    // MARK: Internal

    private func applyVisibility(_ newState: HidingVisibilityState, isReapply: Bool = false) {
        let previousState = visibilityState
        visibilityState = newState
        settingsStore.isCollapsed = newState.isCollapsed

        if previousState != newState {
            diagnosticsLogger.log("Visibility state -> \(newState.rawValue).")
        } else if isReapply {
            diagnosticsLogger.log("Visibility state re-applied (\(newState.rawValue)).")
        }

        onVisibilityChange?(newState)
        onStateChange?(currentState)
        NotificationCenter.default.post(name: Self.visibilityDidChangeNotification, object: self, userInfo: ["visibilityState": newState])
        NotificationCenter.default.post(name: Self.stateDidChangeNotification, object: self, userInfo: ["state": currentState])
    }
}