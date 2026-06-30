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
            fullMenuBarModeAvailable: true
        ))

        #expect(decision == .secondBar)
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
        requireProEstimate: Bool = false,
        secondBarAvailable: Bool = false,
        fullMenuBarModeAvailable: Bool = false,
        layoutSuggestionsAvailable: Bool = false,
        safeModeActive: Bool = false
    ) -> CrowdedRevealDecisionInput {
        CrowdedRevealDecisionInput(
            intent: intent,
            currentVisibility: currentVisibility,
            estimate: estimate(crowded: crowded, source: source),
            rescueEnabled: rescueEnabled,
            autoOpenSecondBar: autoOpenSecondBar,
            requireProEstimate: requireProEstimate,
            secondBarAvailable: secondBarAvailable,
            fullMenuBarModeAvailable: fullMenuBarModeAvailable,
            layoutSuggestionsAvailable: layoutSuggestionsAvailable,
            safeModeActive: safeModeActive
        )
    }

    private func estimate(
        crowded: Bool,
        source: LayoutCapacitySource
    ) -> LayoutCapacityEstimate {
        LayoutCapacityEstimate(
            screenID: "primary",
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
            estimatedMenuBarWidth: 1440,
            estimatedUsableRightSideWidth: 720,
            knownItemCount: 18,
            knownVisibleItemCount: 12,
            knownHiddenItemCount: 4,
            knownAlwaysHiddenItemCount: 2,
            estimatedItemSlots: 20,
            estimatedUsedSlots: crowded ? 19 : 8,
            usedCapacityRatio: crowded ? 0.95 : 0.4,
            isLikelyCrowded: crowded,
            isLikelyNotchConstrained: false,
            source: source,
            warnings: crowded ? [.extremelyCrowded] : [],
            generatedAt: Date(timeIntervalSince1970: 1)
        )
    }
}
