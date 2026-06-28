import AppKit
import Foundation

/// Pure decision result computed by ``HoverRevealController`` whenever the
/// polling timer fires. Returned by ``processMouseLocation`` so the runtime
/// half of the controller can dispatch side effects (reveal / leave) without
/// duplicating logic in tests.
struct HoverRevealDecision: Equatable, Sendable {
    /// `true` when the cursor entered the menu bar band while collapsed.
    var shouldReveal: Bool
    /// `true` when the cursor left the band after a previous reveal.
    var shouldScheduleRehide: Bool
}

/// Timer-polled mouse watcher that reveals hidden items when the cursor enters
/// any menu bar band. Phase 2 deliberately avoids event taps and runs on a
/// polling timer since `NSEvent.mouseLocation` does not require permissions.
@MainActor
final class HoverRevealController {
    /// Invoked when the cursor enters the menu bar band while collapsed.
    var onReveal: (() -> Void)?

    /// Invoked when the cursor leaves the menu bar band after a reveal,
    /// provided auto-rehide is enabled.
    var onLeave: (() -> Void)?

    /// Returns `true` when the menu bar is currently in a *collapsed* state and
    /// would benefit from a hover reveal. Production wires this to
    /// `HidingService.currentState.isCollapsed`.
    var isCollapsedProvider: () -> Bool = { false }

    /// Returns `true` when auto-rehide is enabled. Production wires this to
    /// `SettingsStore.autoRehideEnabled`.
    var autoRehideEnabledProvider: () -> Bool = { true }

    /// Returns the current mouse location. Production reads
    /// `NSEvent.mouseLocation`. Tests stash a fixed point.
    var mouseLocationProvider: () -> CGPoint = { NSEvent.mouseLocation }

    private let settingsStore: SettingsStore
    private let screenGeometry: ScreenGeometryService
    private let diagnosticsLogger: DiagnosticsLogger

    private var pollTimer: Timer?
    private var wasHovering = false
    private(set) var isPollingActive = false

    init(
        settingsStore: SettingsStore,
        screenGeometry: ScreenGeometryService,
        diagnosticsLogger: DiagnosticsLogger
    ) {
        self.settingsStore = settingsStore
        self.screenGeometry = screenGeometry
        self.diagnosticsLogger = diagnosticsLogger
    }

    // MARK: Lifecycle

    /// Starts (or restarts) the polling timer according to the current
    /// settings. If hover reveal is disabled, the timer is stopped.
    func start() {
        guard settingsStore.hoverRevealEnabled else {
            stop()
            return
        }
        guard pollTimer == nil else { return }

        let interval = settingsStore.hoverRevealPollingIntervalSeconds
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        isPollingActive = true
        diagnosticsLogger.log("Hover reveal polling started (interval=\(interval)s).", level: .debug)
    }

    /// Stops the polling timer.
    func stop() {
        if pollTimer != nil {
            diagnosticsLogger.log("Hover reveal polling stopped.", level: .debug)
        }
        pollTimer?.invalidate()
        pollTimer = nil
        isPollingActive = false
        wasHovering = false
    }

    /// Restarts the polling timer after settings (interval, enable) change.
    func restart() {
        stop()
        start()
    }

    // MARK: Pure logic

    /// Computes the decision for a single tick given the current mouse state.
    ///
    /// `isInMenuBarBand` and `autoRehideEnabled` are passed in so tests stay
    /// deterministic; production plumbing folds in the providers instead.
    func processMouseLocation(
        isInMenuBarBand: Bool,
        isCollapsed: Bool,
        autoRehideEnabled: Bool
    ) -> HoverRevealDecision {
        var decision = HoverRevealDecision(shouldReveal: false, shouldScheduleRehide: false)

        if isInMenuBarBand && isCollapsed && !wasHovering {
            decision.shouldReveal = true
            wasHovering = true
        } else if !isInMenuBarBand && wasHovering {
            wasHovering = false
            decision.shouldScheduleRehide = autoRehideEnabled
        }

        return decision
    }

    // MARK: Internal

    func tick() {
        let isCollapsed = isCollapsedProvider()
        guard isCollapsed || wasHovering else { return }

        let point = mouseLocationProvider()
        let inBand = screenGeometry.isPointInAnyMenuBarBand(point)
        let decision = processMouseLocation(
            isInMenuBarBand: inBand,
            isCollapsed: isCollapsed,
            autoRehideEnabled: autoRehideEnabledProvider()
        )

        if decision.shouldReveal {
            diagnosticsLogger.log("Hover reveal: cursor entered menu bar; expanding.")
            onReveal?()
        }

        if decision.shouldScheduleRehide {
            diagnosticsLogger.log("Hover reveal: cursor left menu bar; scheduling auto-rehide.", level: .debug)
            onLeave?()
        }
    }
}
