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
    /// The requested reveal was already satisfied.
    case noOp
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
    private let showLayoutSuggestions: () -> Void
    private let decisionEngine: CrowdedRevealDecisionEngine

    /// Tracks whether the last reveal was intercepted by rescue.
    private(set) var lastRevealIntercepted = false
    private(set) var lastResult: CrowdedRevealRescueResult?
    private(set) var lastDecision: CrowdedRevealDecision?
    private var rescueCount = 0
    private var lastRescueAt: Date?

    init(
        diagnosticsLogger: DiagnosticsLogger,
        settingsStore: SettingsStore,
        capacityService: LayoutCapacityService = LayoutCapacityService(),
        now: @escaping () -> Date = { Date() },
        openSecondBar: @escaping () -> Void,
        enterFullMenuBarMode: @escaping () -> Void,
        showLayoutSuggestions: @escaping () -> Void = {},
        decisionEngine: CrowdedRevealDecisionEngine = CrowdedRevealDecisionEngine()
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.settingsStore = settingsStore
        self.capacityService = capacityService
        self.now = now
        self.openSecondBar = openSecondBar
        self.enterFullMenuBarMode = enterFullMenuBarMode
        self.showLayoutSuggestions = showLayoutSuggestions
        self.decisionEngine = decisionEngine
    }

    /// Evaluate whether to intercept a reveal based on the capacity estimate.
    /// Returns the rescue action to take.
    func evaluate(
        estimate: LayoutCapacityEstimate,
        secondBarAvailable: Bool,
        fullMenuBarModeAvailable: Bool
    ) -> CrowdedRevealRescueResult {
        evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: estimate,
            secondBarAvailable: secondBarAvailable,
            fullMenuBarModeAvailable: fullMenuBarModeAvailable,
            layoutSuggestionsAvailable: settingsStore.layoutSuggestionsEnabled,
            safeModeActive: false
        )
    }

    /// Evaluate whether to intercept a reveal based on capacity and the caller's
    /// reveal intent.
    func evaluate(
        intent: CrowdedRevealIntent,
        currentVisibility: HidingVisibilityState,
        estimate: LayoutCapacityEstimate,
        secondBarAvailable: Bool,
        fullMenuBarModeAvailable: Bool,
        layoutSuggestionsAvailable: Bool,
        safeModeActive: Bool
    ) -> CrowdedRevealRescueResult {
        let decision = decisionEngine.decide(CrowdedRevealDecisionInput(
            intent: intent,
            currentVisibility: currentVisibility,
            estimate: estimate,
            rescueEnabled: settingsStore.crowdedRevealRescueEnabled,
            autoOpenSecondBar: settingsStore.crowdedRevealAutoOpenSecondBar,
            requireProEstimate: settingsStore.crowdedRevealRequireProEstimate,
            secondBarAvailable: secondBarAvailable,
            fullMenuBarModeAvailable: fullMenuBarModeAvailable,
            layoutSuggestionsAvailable: layoutSuggestionsAvailable,
            safeModeActive: safeModeActive
        ))
        lastDecision = decision

        switch decision {
        case .inlineReveal:
            lastRevealIntercepted = false
            lastResult = .proceedInline
            return .proceedInline
        case .noOp:
            lastRevealIntercepted = false
            lastResult = .noOp
            return .noOp
        case .secondBar, .fullMenuBarMode, .showLayoutSuggestion:
            lastRevealIntercepted = true
            rescueCount += 1
            lastRescueAt = now()
        }

        if decision == .secondBar {
            openSecondBar()
            diagnosticsLogger.log(
                "Opened Second Bar because the menu bar appears crowded.",
                category: .layout,
                metadata: decisionMetadata(for: estimate, intent: intent, fallback: "secondBar")
            )
            lastResult = .openedSecondBar
            return .openedSecondBar
        }

        if decision == .fullMenuBarMode {
            enterFullMenuBarMode()
            diagnosticsLogger.log(
                "Entered Full Menu Bar Mode because the menu bar appears crowded and Second Bar is unavailable.",
                category: .layout,
                metadata: decisionMetadata(for: estimate, intent: intent, fallback: "fullMenuBarMode")
            )
            lastResult = .enteredFullMenuBarMode
            return .enteredFullMenuBarMode
        }

        showLayoutSuggestions()
        diagnosticsLogger.log(
            "Menu bar appears crowded but no rescue available; showing suggestion only.",
            level: .warning,
            category: .layout,
            metadata: decisionMetadata(for: estimate, intent: intent, fallback: "layoutSuggestion")
        )
        lastResult = .suggestedOnly
        return .suggestedOnly
    }

    /// Force inline reveal, overriding the rescue. Used by "Reveal Inline Anyway".
    func revealInlineAnyway() -> CrowdedRevealRescueResult {
        lastRevealIntercepted = false
        diagnosticsLogger.log("User chose to reveal inline anyway, overriding crowded rescue.", category: .layout)
        lastResult = .inlineOverride
        lastDecision = .inlineReveal
        return .inlineOverride
    }

    /// Reset rescue state (used by health recovery).
    func resetState() {
        lastRevealIntercepted = false
        lastResult = nil
        lastDecision = nil
        rescueCount = 0
        lastRescueAt = nil
    }

    /// Number of times rescue has been triggered recently.
    var recentRescueCount: Int { rescueCount }

    private func decisionMetadata(
        for estimate: LayoutCapacityEstimate,
        intent: CrowdedRevealIntent,
        fallback: String
    ) -> [String: String] {
        [
            "intent": intent.rawValue,
            "fallback": fallback,
            "ratio": estimate.usedCapacityRatio.formatted(.number.precision(.fractionLength(2))),
            "source": estimate.source.rawValue
        ]
    }
}
