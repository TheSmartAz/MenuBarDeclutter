import Foundation

/// Manages the temporary Full Menu Bar Mode that reveals all items
/// and suspends auto-rehide for easier access.
///
/// This service owns the state transition logic only; actual visibility
/// changes are delegated through closures so the service remains
/// unit-testable without AppKit.
@MainActor
final class FullMenuBarModeService {
    /// Reasons the full menu bar mode can exit.
    enum ExitReason: String, Sendable {
        case manual
        case autoExit
        case safeMode
        case userStateChanged
    }

    /// Snapshot of the state when Full Menu Bar Mode was entered.
    struct StateSnapshot: Equatable, Sendable {
        let previousVisibility: HidingVisibilityState
        let enteredAt: Date
        let autoExitAt: Date?
    }

    private let diagnosticsLogger: DiagnosticsLogger
    private let settingsStore: SettingsStore
    private let now: () -> Date
    private let revealAll: () -> Void
    private let restoreVisibility: (HidingVisibilityState) -> Void
    private let suspendAutoRehide: () -> Void
    private let resumeAutoRehide: () -> Void
    private let showSpacerMarkers: (Bool) -> Void
    private let openSecondBar: (() -> Void)?

    private(set) var isActive = false
    private(set) var stateSnapshot: StateSnapshot?
    private(set) var lastExitReason: ExitReason?
    private var autoExitTask: Task<Void, Never>?
    private var userChangedState = false

    init(
        diagnosticsLogger: DiagnosticsLogger,
        settingsStore: SettingsStore,
        now: @escaping () -> Date = { Date() },
        revealAll: @escaping () -> Void,
        restoreVisibility: @escaping (HidingVisibilityState) -> Void,
        suspendAutoRehide: @escaping () -> Void,
        resumeAutoRehide: @escaping () -> Void,
        showSpacerMarkers: @escaping (Bool) -> Void,
        openSecondBar: (() -> Void)? = nil
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.settingsStore = settingsStore
        self.now = now
        self.revealAll = revealAll
        self.restoreVisibility = restoreVisibility
        self.suspendAutoRehide = suspendAutoRehide
        self.resumeAutoRehide = resumeAutoRehide
        self.showSpacerMarkers = showSpacerMarkers
        self.openSecondBar = openSecondBar
    }

    /// Enter Full Menu Bar Mode, saving the previous visibility state.
    /// - Parameter previousVisibility: The visibility state to restore on exit.
    func enter(previousVisibility: HidingVisibilityState) {
        guard !isActive else {
            diagnosticsLogger.log("Full Menu Bar Mode already active.", category: .layout)
            return
        }

        guard settingsStore.fullMenuBarModeEnabled else {
            diagnosticsLogger.log("Full Menu Bar Mode is disabled in settings.", level: .warning, category: .layout)
            return
        }

        let enteredAt = now()
        let autoExitAt: Date?
        if settingsStore.fullMenuBarModeAutoExitEnabled {
            autoExitAt = enteredAt.addingTimeInterval(settingsStore.fullMenuBarModeAutoExitSeconds)
        } else {
            autoExitAt = nil
        }

        stateSnapshot = StateSnapshot(
            previousVisibility: previousVisibility,
            enteredAt: enteredAt,
            autoExitAt: autoExitAt
        )
        isActive = true
        userChangedState = false

        revealAll()

        if settingsStore.fullMenuBarModeSuspendsAutoRehide {
            suspendAutoRehide()
        }

        if settingsStore.fullMenuBarModeShowsSpacerMarkers {
            showSpacerMarkers(true)
        }

        if settingsStore.fullMenuBarModeShowsSecondBar, let openSecondBar {
            openSecondBar()
        }

        diagnosticsLogger.log(
            "Full Menu Bar Mode entered.",
            category: .layout,
            metadata: ["autoExit": autoExitAt != nil ? "yes" : "no"]
        )

        if let autoExitAt {
            scheduleAutoExit(at: autoExitAt)
        }
    }

    /// Exit Full Menu Bar Mode, restoring the previous visibility state.
    func exit(reason: ExitReason = .manual) {
        guard isActive else { return }

        autoExitTask?.cancel()
        autoExitTask = nil

        let snapshot = stateSnapshot
        stateSnapshot = nil
        isActive = false
        lastExitReason = reason

        if settingsStore.fullMenuBarModeSuspendsAutoRehide {
            resumeAutoRehide()
        }

        // Restore previous visibility unless the user manually changed state
        // during full mode (in which case we respect their choice).
        if !userChangedState, let snapshot {
            restoreVisibility(snapshot.previousVisibility)
        }

        diagnosticsLogger.log(
            "Full Menu Bar Mode exited.",
            category: .layout,
            metadata: ["reason": reason.rawValue]
        )
    }

    /// Called when the user manually changes visibility during full mode.
    func noteUserStateChanged() {
        userChangedState = true
    }

    /// Cancel any pending auto-exit. Used when Safe Mode is activated.
    func cancelAutoExit() {
        autoExitTask?.cancel()
        autoExitTask = nil
    }

    private func scheduleAutoExit(at date: Date) {
        let delay = max(0, date.timeIntervalSince(now()))
        autoExitTask?.cancel()
        autoExitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, Task.isCancelled == false, self.isActive else { return }
            self.exit(reason: .autoExit)
        }
    }
}
