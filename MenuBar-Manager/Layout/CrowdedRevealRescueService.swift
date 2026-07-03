import CoreGraphics
import Foundation

/// Result of a crowded reveal rescue evaluation.
nonisolated enum CrowdedRevealRescueResult: Equatable, Sendable {
    /// The menu bar is not crowded; proceed with normal inline reveal.
    case proceedInline
    /// The menu bar is crowded and Second Bar was opened.
    case openedSecondBar
    /// The menu bar is crowded and the active Workspace Function Bar was opened.
    case openedFunctionBar
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
    private let openFunctionBar: () -> Void
    private let enterFullMenuBarMode: () -> Void
    private let showLayoutSuggestions: () -> Void
    private let decisionEngine: CrowdedRevealDecisionEngine

    /// Tracks whether the last reveal was intercepted by rescue.
    private(set) var lastRevealIntercepted = false
    private(set) var lastResult: CrowdedRevealRescueResult?
    private(set) var lastDecision: CrowdedRevealDecision?
    private(set) var lastExplanation: String?
    private var rescueCount = 0
    private var lastRescueAt: Date?

    init(
        diagnosticsLogger: DiagnosticsLogger,
        settingsStore: SettingsStore,
        capacityService: LayoutCapacityService = LayoutCapacityService(),
        now: @escaping () -> Date = { Date() },
        openSecondBar: @escaping () -> Void,
        openFunctionBar: @escaping () -> Void = {},
        enterFullMenuBarMode: @escaping () -> Void,
        showLayoutSuggestions: @escaping () -> Void = {},
        decisionEngine: CrowdedRevealDecisionEngine = CrowdedRevealDecisionEngine()
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.settingsStore = settingsStore
        self.capacityService = capacityService
        self.now = now
        self.openSecondBar = openSecondBar
        self.openFunctionBar = openFunctionBar
        self.enterFullMenuBarMode = enterFullMenuBarMode
        self.showLayoutSuggestions = showLayoutSuggestions
        self.decisionEngine = decisionEngine
    }

    /// Evaluate whether to intercept a reveal based on capacity and the caller's
    /// reveal intent.
    func evaluate(
        intent: CrowdedRevealIntent,
        currentVisibility: HidingVisibilityState,
        estimate: LayoutCapacityEstimate,
        secondBarAvailable: Bool,
        functionBarAvailable: Bool = false,
        fullMenuBarModeAvailable: Bool,
        layoutSuggestionsAvailable: Bool,
        safeModeActive: Bool,
        activeDisplayID: String? = nil,
        activeAppMenuPressure: CrowdedRevealMenuPressure = .unknown
    ) -> CrowdedRevealRescueResult {
        let proDiscoveryAvailable = settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled
        let decision = decisionEngine.decide(CrowdedRevealDecisionInput(
            intent: intent,
            currentVisibility: currentVisibility,
            estimate: estimate,
            rescueEnabled: settingsStore.crowdedRevealRescueEnabled,
            autoOpenSecondBar: settingsStore.crowdedRevealAutoOpenSecondBar,
            askBeforeSwitching: settingsStore.crowdedRevealAskBeforeSwitching,
            requireProEstimate: settingsStore.crowdedRevealRequireProEstimate,
            proDiscoveryAvailable: proDiscoveryAvailable,
            secondBarAvailable: secondBarAvailable,
            functionBarAvailable: functionBarAvailable,
            workspaceFallbackPreference: CrowdedRescueWorkspaceFallbackPreference(rawValue: settingsStore.crowdedRescueWorkspaceFallbackPreference) ?? .preferSecondBar,
            fullMenuBarModeAvailable: fullMenuBarModeAvailable,
            layoutSuggestionsAvailable: layoutSuggestionsAvailable,
            safeModeActive: safeModeActive,
            activeDisplayID: activeDisplayID ?? estimate.screenID,
            activeAppMenuPressure: activeAppMenuPressure
        ))
        lastDecision = decision

        switch decision {
        case .inlineReveal:
            lastRevealIntercepted = false
            lastResult = .proceedInline
            lastExplanation = nil
            return .proceedInline
        case .noOp:
            lastRevealIntercepted = false
            lastResult = .noOp
            lastExplanation = nil
            return .noOp
        case .secondBar, .functionBar, .functionBarThenSecondBar, .askFunctionBarOrSecondBar, .fullMenuBarMode, .showLayoutSuggestion:
            lastRevealIntercepted = true
            rescueCount += 1
            lastRescueAt = now()
        }

        if decision == .functionBar {
            openFunctionBar()
            lastExplanation = "Opened Function Bar because inline reveal may not fit."
            diagnosticsLogger.log(
                lastExplanation ?? "Opened Function Bar for crowded reveal rescue.",
                category: .layout,
                metadata: decisionMetadata(
                    for: estimate,
                    intent: intent,
                    fallback: "functionBar",
                    proDiscoveryAvailable: proDiscoveryAvailable,
                    activeDisplayID: activeDisplayID,
                    activeAppMenuPressure: activeAppMenuPressure
                )
            )
            lastResult = .openedFunctionBar
            return .openedFunctionBar
        }

        if decision == .secondBar || decision == .functionBarThenSecondBar {
            openSecondBar()
            lastExplanation = decision == .functionBarThenSecondBar
                ? "Function Bar was unavailable, so Second Bar opened because inline reveal may not fit."
                : "Opened Second Bar because inline reveal may not fit."
            diagnosticsLogger.log(
                lastExplanation ?? "Opened Second Bar for crowded reveal rescue.",
                category: .layout,
                metadata: decisionMetadata(
                    for: estimate,
                    intent: intent,
                    fallback: decision == .functionBarThenSecondBar ? "functionBarThenSecondBar" : "secondBar",
                    proDiscoveryAvailable: proDiscoveryAvailable,
                    activeDisplayID: activeDisplayID,
                    activeAppMenuPressure: activeAppMenuPressure
                )
            )
            lastResult = .openedSecondBar
            return .openedSecondBar
        }

        if decision == .fullMenuBarMode {
            enterFullMenuBarMode()
            lastExplanation = "Full Menu Bar Mode temporarily reveals items because inline reveal may not fit."
            diagnosticsLogger.log(
                lastExplanation ?? "Entered Full Menu Bar Mode for crowded reveal rescue.",
                category: .layout,
                metadata: decisionMetadata(
                    for: estimate,
                    intent: intent,
                    fallback: "fullMenuBarMode",
                    proDiscoveryAvailable: proDiscoveryAvailable,
                    activeDisplayID: activeDisplayID,
                    activeAppMenuPressure: activeAppMenuPressure
                )
            )
            lastResult = .enteredFullMenuBarMode
            return .enteredFullMenuBarMode
        }

        showLayoutSuggestions()
        lastExplanation = "Inline reveal may not fit. Try Apple menu bar settings to reduce system items, or use Arrange to move items manually."
        diagnosticsLogger.log(
            lastExplanation ?? "Showing crowded reveal suggestion only.",
            level: .warning,
            category: .layout,
            metadata: decisionMetadata(
                for: estimate,
                intent: intent,
                fallback: "layoutSuggestion",
                proDiscoveryAvailable: proDiscoveryAvailable,
                activeDisplayID: activeDisplayID,
                activeAppMenuPressure: activeAppMenuPressure
            )
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
        lastExplanation = nil
        return .inlineOverride
    }

    /// Reset rescue state (used by health recovery).
    func resetState() {
        lastRevealIntercepted = false
        lastResult = nil
        lastDecision = nil
        lastExplanation = nil
        rescueCount = 0
        lastRescueAt = nil
    }

    /// Number of times rescue has been triggered recently.
    var recentRescueCount: Int { rescueCount }

    private func decisionMetadata(
        for estimate: LayoutCapacityEstimate,
        intent: CrowdedRevealIntent,
        fallback: String,
        proDiscoveryAvailable: Bool,
        activeDisplayID: String?,
        activeAppMenuPressure: CrowdedRevealMenuPressure
    ) -> [String: String] {
        [
            "intent": intent.rawValue,
            "fallback": fallback,
            "ratio": estimate.usedCapacityRatio.formatted(.number.precision(.fractionLength(2))),
            "source": estimate.source.rawValue,
            "hiddenCount": "\(estimate.knownHiddenItemCount)",
            "alwaysHiddenCount": "\(estimate.knownAlwaysHiddenItemCount)",
            "notchRisk": "\(estimate.isLikelyNotchConstrained)",
            "displayWidth": Double(estimate.screenFrame.width).formatted(.number.precision(.fractionLength(0))),
            "estimateDisplayMatchesActiveDisplay": "\(activeDisplayID == nil || activeDisplayID == estimate.screenID)",
            "proDiscoveryAvailable": "\(proDiscoveryAvailable)",
            "appMenuPressure": activeAppMenuPressure.rawValue
        ]
    }
}
