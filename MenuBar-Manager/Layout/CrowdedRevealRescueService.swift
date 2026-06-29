import Foundation

/// Result of a crowded reveal rescue evaluation.
nonisolated enum CrowdedRevealRescueResult: Equatable, Sendable {
    /// The menu bar is not crowded; proceed with normal inline reveal.
    case proceedInline
    /// The menu bar is crowded and Second Bar was opened.
    case openedSecondBar
    /// The menu bar is crowded and Full Menu Bar Mode was entered.
    case enteredFullMenuBarMode
    /// The menu bar is crowded but no rescue was available; a suggestion was logged.
    case suggestedOnly
    /// The user explicitly chose to reveal inline anyway, overriding the rescue.
    case inlineOverride
}

/// When normal inline reveal is likely to be ineffective because the menu bar
/// is crowded, this service opens or suggests Second Bar instead of forcing
/// a bad inline reveal.
@MainActor
final class CrowdedRevealRescueService {
    private let diagnosticsLogger: DiagnosticsLogger
    private let settingsStore: SettingsStore
    private let capacityService: LayoutCapacityService
    private let now: () -> Date
    private let openSecondBar: () -> Void
    private let enterFullMenuBarMode: () -> Void

    /// Tracks whether the last reveal was intercepted by rescue.
    private(set) var lastRevealIntercepted = false
    private(set) var lastResult: CrowdedRevealRescueResult?
    private var rescueCount = 0
    private var lastRescueAt: Date?

    init(
        diagnosticsLogger: DiagnosticsLogger,
        settingsStore: SettingsStore,
        capacityService: LayoutCapacityService = LayoutCapacityService(),
        now: @escaping () -> Date = { Date() },
        openSecondBar: @escaping () -> Void,
        enterFullMenuBarMode: @escaping () -> Void
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.settingsStore = settingsStore
        self.capacityService = capacityService
        self.now = now
        self.openSecondBar = openSecondBar
        self.enterFullMenuBarMode = enterFullMenuBarMode
    }

    /// Evaluate whether to intercept a reveal based on the capacity estimate.
    /// Returns the rescue action to take.
    func evaluate(
        estimate: LayoutCapacityEstimate,
        secondBarAvailable: Bool,
        fullMenuBarModeAvailable: Bool
    ) -> CrowdedRevealRescueResult {
        guard settingsStore.crowdedRevealRescueEnabled else {
            lastRevealIntercepted = false
            lastResult = .proceedInline
            return .proceedInline
        }

        guard estimate.isLikelyCrowded else {
            lastRevealIntercepted = false
            lastResult = .proceedInline
            return .proceedInline
        }

        lastRevealIntercepted = true
        rescueCount += 1
        lastRescueAt = now()

        if settingsStore.crowdedRevealAutoOpenSecondBar && secondBarAvailable {
            openSecondBar()
            diagnosticsLogger.log(
                "Opened Second Bar because the menu bar appears crowded.",
                category: .layout,
                metadata: ["ratio": String(format: "%.2f", estimate.usedCapacityRatio)]
            )
            lastResult = .openedSecondBar
            return .openedSecondBar
        }

        if fullMenuBarModeAvailable {
            enterFullMenuBarMode()
            diagnosticsLogger.log(
                "Entered Full Menu Bar Mode because the menu bar appears crowded and Second Bar is unavailable.",
                category: .layout,
                metadata: ["ratio": String(format: "%.2f", estimate.usedCapacityRatio)]
            )
            lastResult = .enteredFullMenuBarMode
            return .enteredFullMenuBarMode
        }

        diagnosticsLogger.log(
            "Menu bar appears crowded but no rescue available; showing suggestion only.",
            level: .warning,
            category: .layout
        )
        lastResult = .suggestedOnly
        return .suggestedOnly
    }

    /// Force inline reveal, overriding the rescue. Used by "Reveal Inline Anyway".
    func revealInlineAnyway() -> CrowdedRevealRescueResult {
        lastRevealIntercepted = false
        diagnosticsLogger.log("User chose to reveal inline anyway, overriding crowded rescue.", category: .layout)
        lastResult = .inlineOverride
        return .inlineOverride
    }

    /// Reset rescue state (used by health recovery).
    func resetState() {
        lastRevealIntercepted = false
        lastResult = nil
        rescueCount = 0
        lastRescueAt = nil
    }

    /// Number of times rescue has been triggered recently.
    var recentRescueCount: Int { rescueCount }
}
