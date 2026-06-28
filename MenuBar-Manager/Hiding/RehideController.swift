import AppKit
import Foundation

/// Snapshot of conditions that should postpone the auto-rehide timer.
struct RehidePostponementConditions: Equatable, Sendable {
    var mouseInMenuBarBand: Bool = false
    var settingsWindowKey: Bool = false
    var statusItemMenuOpen: Bool = false

    /// `true` when any condition is met.
    var shouldPostpone: Bool {
        mouseInMenuBarBand || settingsWindowKey || statusItemMenuOpen
    }
}

/// Records the reason the last auto-rehide either fired or did not. Surfaced
/// in Diagnostics so users can debug why the bar did not collapse.
enum RehideReason: String, Sendable {
    case timerExpired
    case userCollapsed
    case postponedMouseInMenuBar
    case postponedSettingsWindow
    case postponedMenuOpen
    case cancelled
}

/// Coordinates the one-shot auto-rehide timer introduced in Phase 2.
///
/// The controller is deliberately split into:
/// * **Pure logic** in ``processTick(now:autoRehideEnabled:autoRehideDelay:conditions:)``
///   so tests can drive it deterministically without a real `Timer`.
/// * **Runtime scheduling** via `Timer.scheduledTimer` for production. The
///   timer just calls ``processTick`` on each interval.
@MainActor
final class RehideController {
    /// Closure invoked when the auto-rehide timer fires. The owning controller
    /// wires this to `HidingService.collapse()`.
    var onRehide: (() -> Void)?

    /// Returns the live postponement conditions. Default closure returns an
    /// empty snapshot so tests can inject their own.
    var conditionsProvider: () -> RehidePostponementConditions = { RehidePostponementConditions() }

    /// Returns the configured auto-rehide delay in seconds. Production passes
    /// the live `SettingsStore.autoRehideDelaySeconds`; tests can stub it.
    var autoRehideDelayProvider: () -> TimeInterval = { 5 }

    /// Returns whether auto-rehide is currently enabled. Keeping this as a
    /// provider ensures the runtime timer path observes live Settings changes.
    var autoRehideEnabledProvider: () -> Bool = { true }

    /// Invoked whenever the scheduled flag or last reason changes so
    /// Diagnostics can stay current while a timer is active.
    var onStatusChange: (() -> Void)?

    private let diagnosticsLogger: DiagnosticsLogger
    private var pollTimer: Timer?
    private var fireDeadline: Date?
    private(set) var isScheduled = false
    private(set) var lastReason: RehideReason?

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    // MARK: Public API

    /// Starts a one-shot auto-rehide countdown for `delay` seconds. Replaces
    /// any in-flight countdown.
    func startCountdown(delay: TimeInterval) {
        cancel(reason: nil)
        guard delay > 0 else {
            // Non-positive delay fires immediately.
            lastReason = .timerExpired
            notifyStatusChanged()
            onRehide?()
            diagnosticsLogger.log("Auto-rehide fired immediately (delay=\(delay)s).")
            return
        }

        fireDeadline = Date().addingTimeInterval(delay)
        isScheduled = true
        startTimer()
        notifyStatusChanged()
        diagnosticsLogger.log("Auto-rehide scheduled in \(delay)s.")
    }

    /// Cancels any in-flight countdown.
    func cancel(reason: RehideReason? = .cancelled) {
        let hadActiveCountdown = hasActiveCountdown
        if hadActiveCountdown {
            diagnosticsLogger.log("Auto-rehide cancelled.", level: .debug)
        }
        pollTimer?.invalidate()
        pollTimer = nil
        fireDeadline = nil
        isScheduled = false
        if hadActiveCountdown {
            if let reason {
                lastReason = reason
            }
            notifyStatusChanged()
        }
    }

    /// Called when the user collapses manually so the timer can be cancelled
    /// and the reason recorded.
    func markUserCollapsed() {
        let hadActiveCountdown = hasActiveCountdown
        lastReason = .userCollapsed
        cancel(reason: nil)
        if !hadActiveCountdown {
            notifyStatusChanged()
        }
    }

    /// Called when the rehide fires so the reason is recorded and the
    /// countdown is no longer scheduled.
    func markRehideFired() {
        let hadActiveCountdown = hasActiveCountdown
        lastReason = .timerExpired
        cancel(reason: nil)
        if !hadActiveCountdown {
            notifyStatusChanged()
        }
    }

    /// Pure logic for advancing the timer. Tests call this with controlled
    /// `now` to drive deterministically without a real Timer.
    func processTick(
        now: Date,
        autoRehideEnabled: Bool,
        autoRehideDelay: TimeInterval,
        conditions: RehidePostponementConditions
    ) {
        guard autoRehideEnabled else {
            cancel()
            return
        }
        guard let deadline = fireDeadline else { return }

        if conditions.shouldPostpone {
            // Push the deadline out so the user keeps interacting.
            fireDeadline = now.addingTimeInterval(autoRehideDelay)
            let reason: RehideReason
            if conditions.mouseInMenuBarBand {
                reason = .postponedMouseInMenuBar
            } else if conditions.settingsWindowKey {
                reason = .postponedSettingsWindow
            } else {
                reason = .postponedMenuOpen
            }
            lastReason = reason
            notifyStatusChanged()
            return
        }

        if now >= deadline {
            lastReason = .timerExpired
            notifyStatusChanged()
            onRehide?()
            cancel(reason: nil)
        }
    }

    // MARK: Internal

    private func startTimer() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func tick() {
        processTick(
            now: Date(),
            autoRehideEnabled: autoRehideEnabledProvider(),
            autoRehideDelay: autoRehideDelayProvider(),
            conditions: conditionsProvider()
        )
    }

    private var hasActiveCountdown: Bool {
        pollTimer != nil || isScheduled || fireDeadline != nil
    }

    private func notifyStatusChanged() {
        onStatusChange?()
    }
}

extension RehideController {
    /// Reactive entry: called by StatusBarController when the user expands the
    /// hidden items so the controller can arm the auto-rehide countdown.
    func armAfterExpand(delay: TimeInterval) {
        startCountdown(delay: delay)
    }
}
