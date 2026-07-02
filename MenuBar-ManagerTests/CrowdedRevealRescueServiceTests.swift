import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("CrowdedRevealRescueService")
@MainActor
struct CrowdedRevealRescueServiceTests {
    private func makeEstimate(
        crowded: Bool,
        ratio: Double = 0.9,
        hiddenCount: Int = 0,
        alwaysHiddenCount: Int = 0,
        notchConstrained: Bool = false,
        screenWidth: Double = 1440
    ) -> LayoutCapacityEstimate {
        LayoutCapacityEstimate(
            screenID: "primary",
            screenFrame: CGRect(x: 0, y: 0, width: screenWidth, height: 900),
            visibleFrame: .zero,
            estimatedMenuBarWidth: screenWidth,
            estimatedUsableRightSideWidth: screenWidth / 2,
            knownItemCount: 0,
            knownVisibleItemCount: 0,
            knownHiddenItemCount: hiddenCount,
            knownAlwaysHiddenItemCount: alwaysHiddenCount,
            estimatedItemSlots: 20,
            estimatedUsedSlots: 20,
            usedCapacityRatio: ratio,
            isLikelyCrowded: crowded,
            isLikelyNotchConstrained: notchConstrained,
            source: .basicGeometryOnly,
            warnings: estimateWarnings(crowded: crowded, notchConstrained: notchConstrained),
            generatedAt: Date()
        )
    }

    @Test func crowdedOpensSecondBarWhenEnabled() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        let logger = DiagnosticsLogger()
        var secondBarOpened = false
        var fullModeEntered = false

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: { secondBarOpened = true },
            enterFullMenuBarMode: { fullModeEntered = true }
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: false
        )

        #expect(result == .openedSecondBar)
        #expect(secondBarOpened)
        #expect(!fullModeEntered)
        #expect(service.lastRevealIntercepted)
        #expect(service.lastExplanation == "Opened Second Bar because inline reveal may not fit.")
    }

    @Test func crowdedFallsBackToFullMenuBarMode() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()
        var fullModeEntered = false

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: {},
            enterFullMenuBarMode: { fullModeEntered = true }
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: false,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: false
        )

        #expect(result == .enteredFullMenuBarMode)
        #expect(fullModeEntered)
    }

    @Test func nonCrowdedProceedsInline() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: {},
            enterFullMenuBarMode: {}
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: false, ratio: 0.3),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: false
        )

        #expect(result == .proceedInline)
        #expect(!service.lastRevealIntercepted)
    }

    @Test func proDiscoveryOffFallsBackToFullMenuBarModeInsteadOfSecondBar() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()
        var secondBarOpened = false
        var fullModeEntered = false

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: { secondBarOpened = true },
            enterFullMenuBarMode: { fullModeEntered = true }
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: false
        )

        #expect(result == .enteredFullMenuBarMode)
        #expect(!secondBarOpened)
        #expect(fullModeEntered)
        #expect(service.lastExplanation == "Full Menu Bar Mode temporarily reveals items because inline reveal may not fit.")
    }

    @Test func inlineOverrideRespected() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: {},
            enterFullMenuBarMode: {}
        )

        let result = service.revealInlineAnyway()

        #expect(result == .inlineOverride)
        #expect(!service.lastRevealIntercepted)
    }

    @Test func safeModeProceedsInlineWithoutOpeningFallbacks() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()
        var secondBarOpened = false
        var fullModeEntered = false

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: { secondBarOpened = true },
            enterFullMenuBarMode: { fullModeEntered = true }
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: true
        )

        #expect(result == .proceedInline)
        #expect(!secondBarOpened)
        #expect(!fullModeEntered)
        #expect(!service.lastRevealIntercepted)
    }

    @Test func noFallbackOpensLayoutSuggestions() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()
        var suggestionsShown = false

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: {},
            enterFullMenuBarMode: {},
            showLayoutSuggestions: { suggestionsShown = true }
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: false,
            fullMenuBarModeAvailable: false,
            layoutSuggestionsAvailable: true,
            safeModeActive: false
        )

        #expect(result == .suggestedOnly)
        #expect(suggestionsShown)
        #expect(service.lastRevealIntercepted)
        #expect(service.lastExplanation == "Inline reveal may not fit. Try Apple menu bar settings to reduce system items, or use Arrange to move items manually.")
    }

    @Test func disabledInSettingsProceedsInline() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        store.crowdedRevealRescueEnabled = false
        let logger = DiagnosticsLogger()

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: {},
            enterFullMenuBarMode: {}
        )

        let result = service.evaluate(
            intent: .revealAll,
            currentVisibility: .collapsed,
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: false
        )

        #expect(result == .proceedInline)
    }

    @Test func diagnosticsMetadataUsesAggregateCrowdingSignals() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "crr-tests-\(UUID().uuidString)")!)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        let logger = DiagnosticsLogger()

        let service = CrowdedRevealRescueService(
            diagnosticsLogger: logger,
            settingsStore: store,
            openSecondBar: {},
            enterFullMenuBarMode: {}
        )

        _ = service.evaluate(
            intent: .revealItem,
            currentVisibility: .collapsed,
            estimate: makeEstimate(
                crowded: false,
                ratio: 0.7,
                hiddenCount: 3,
                alwaysHiddenCount: 1,
                notchConstrained: true,
                screenWidth: 1728
            ),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true,
            layoutSuggestionsAvailable: true,
            safeModeActive: false,
            activeAppMenuPressure: .normal
        )

        let event = logger.events.last
        #expect(event?.message == "Opened Second Bar because inline reveal may not fit.")
        #expect(event?.metadata["hiddenCount"] == "3")
        #expect(event?.metadata["alwaysHiddenCount"] == "1")
        #expect(event?.metadata["notchRisk"] == "true")
        #expect(event?.metadata["appMenuPressure"] == "normal")
        #expect(event?.metadata.keys.contains("itemID") == false)
        #expect(event?.metadata.keys.contains("bundleIdentifier") == false)
        #expect(event?.metadata.keys.contains("title") == false)
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
