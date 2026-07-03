import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("CrowdedRevealDecisionEngine")
struct CrowdedRevealDecisionEngineTests {
    private let engine = CrowdedRevealDecisionEngine()

    @Test func enoughCapacityRevealsInline() {
        let decision = engine.decide(input(crowded: false))

        #expect(decision == .inlineReveal)
    }

    @Test func crowdedMenuPrefersSecondBarWhenAvailable() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            functionBarAvailable: true,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .secondBar)
    }

    @Test func crowdedMenuCanPreferFunctionBarWhenConfigured() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            functionBarAvailable: true,
            workspaceFallbackPreference: .preferFunctionBar,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .functionBar)
    }

    @Test func crowdedMenuFallsBackToSecondBarWhenFunctionBarUnavailable() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            functionBarAvailable: false,
            workspaceFallbackPreference: .preferFunctionBar,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .functionBarThenSecondBar)
    }

    @Test func crowdedMenuFallsBackToFullMenuBarMode() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: false,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .fullMenuBarMode)
    }

    @Test func safeModeSuppressesAutomationAndRevealsInline() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            safeModeActive: true
        ))

        #expect(decision == .inlineReveal)
    }

    @Test func requireProEstimateIgnoresBasicGeometryCrowding() {
        let decision = engine.decide(input(
            crowded: true,
            source: .basicGeometryOnly,
            requireProEstimate: true,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .inlineReveal)
    }

    @Test func normalExpandDoesNotAutoRescueOnBasicGeometryOnly() {
        let decision = engine.decide(input(
            intent: .expand,
            crowded: true,
            source: .basicGeometryOnly,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .inlineReveal)
    }

    @Test func notchConstrainedBacklogUsesSecondBarBeforeCrowdedThreshold() {
        let decision = engine.decide(input(
            crowded: false,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            notchConstrained: true,
            hiddenCount: 3,
            alwaysHiddenCount: 1
        ))

        #expect(decision == .secondBar)
    }

    @Test func proDiscoveryOffSkipsSecondBarAndUsesBasicFallback() {
        let decision = engine.decide(input(
            crowded: true,
            source: .basicGeometryOnly,
            proDiscoveryAvailable: false,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .fullMenuBarMode)
    }

    @Test func activeDisplayMismatchShowsSuggestionInsteadOfOpeningFallback() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            activeDisplayID: "external"
        ))

        #expect(decision == .showLayoutSuggestion)
    }

    @Test func highActiveAppMenuPressureCanTriggerRescue() {
        let decision = engine.decide(input(
            crowded: false,
            source: .proAXSnapshot,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            activeAppMenuPressure: .high
        ))

        #expect(decision == .secondBar)
    }

    @Test func noFallbackShowsLayoutSuggestionWhenAvailable() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            secondBarAvailable: false,
            fullMenuBarModeAvailable: false,
            layoutSuggestionsAvailable: true
        ))

        #expect(decision == .showLayoutSuggestion)
    }

    @Test func askBeforeSwitchingShowsSuggestionInsteadOfOpeningFallback() {
        let decision = engine.decide(input(
            crowded: true,
            source: .proAXSnapshot,
            askBeforeSwitching: true,
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true
        ))

        #expect(decision == .showLayoutSuggestion)
    }

    @Test func alreadyExpandedNormalExpandIsNoOp() {
        let decision = engine.decide(input(
            intent: .expand,
            currentVisibility: .expanded,
            crowded: true,
            source: .proAXSnapshot
        ))

        #expect(decision == .noOp)
    }

    private func input(
        intent: CrowdedRevealIntent = .revealAll,
        currentVisibility: HidingVisibilityState = .collapsed,
        crowded: Bool,
        source: LayoutCapacitySource = .proAXSnapshot,
        rescueEnabled: Bool = true,
        autoOpenSecondBar: Bool = true,
        askBeforeSwitching: Bool = false,
        requireProEstimate: Bool = false,
        proDiscoveryAvailable: Bool = true,
        secondBarAvailable: Bool = false,
        functionBarAvailable: Bool = false,
        workspaceFallbackPreference: CrowdedRescueWorkspaceFallbackPreference = .preferSecondBar,
        fullMenuBarModeAvailable: Bool = false,
        layoutSuggestionsAvailable: Bool = false,
        safeModeActive: Bool = false,
        activeDisplayID: String? = "primary",
        activeAppMenuPressure: CrowdedRevealMenuPressure = .unknown,
        notchConstrained: Bool = false,
        hiddenCount: Int = 4,
        alwaysHiddenCount: Int = 2
    ) -> CrowdedRevealDecisionInput {
        CrowdedRevealDecisionInput(
            intent: intent,
            currentVisibility: currentVisibility,
            estimate: estimate(
                crowded: crowded,
                source: source,
                notchConstrained: notchConstrained,
                hiddenCount: hiddenCount,
                alwaysHiddenCount: alwaysHiddenCount
            ),
            rescueEnabled: rescueEnabled,
            autoOpenSecondBar: autoOpenSecondBar,
            askBeforeSwitching: askBeforeSwitching,
            requireProEstimate: requireProEstimate,
            proDiscoveryAvailable: proDiscoveryAvailable,
            secondBarAvailable: secondBarAvailable,
            functionBarAvailable: functionBarAvailable,
            workspaceFallbackPreference: workspaceFallbackPreference,
            fullMenuBarModeAvailable: fullMenuBarModeAvailable,
            layoutSuggestionsAvailable: layoutSuggestionsAvailable,
            safeModeActive: safeModeActive,
            activeDisplayID: activeDisplayID,
            activeAppMenuPressure: activeAppMenuPressure
        )
    }

    private func estimate(
        crowded: Bool,
        source: LayoutCapacitySource,
        notchConstrained: Bool,
        hiddenCount: Int,
        alwaysHiddenCount: Int
    ) -> LayoutCapacityEstimate {
        LayoutCapacityEstimate(
            screenID: "primary",
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
            estimatedMenuBarWidth: 1440,
            estimatedUsableRightSideWidth: 720,
            knownItemCount: 18,
            knownVisibleItemCount: 12,
            knownHiddenItemCount: hiddenCount,
            knownAlwaysHiddenItemCount: alwaysHiddenCount,
            estimatedItemSlots: 20,
            estimatedUsedSlots: crowded ? 19 : 8,
            usedCapacityRatio: crowded ? 0.95 : 0.4,
            isLikelyCrowded: crowded,
            isLikelyNotchConstrained: notchConstrained,
            source: source,
            warnings: estimateWarnings(crowded: crowded, notchConstrained: notchConstrained),
            generatedAt: Date(timeIntervalSince1970: 1)
        )
    }

    private func estimateWarnings(crowded: Bool, notchConstrained: Bool) -> [LayoutCapacityWarning] {
        var warnings: [LayoutCapacityWarning] = []
        if crowded {
            warnings.append(.extremelyCrowded)
        }
        if notchConstrained {
            warnings.append(.notchConstrained)
        }
        return warnings
    }
}
