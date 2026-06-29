import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("CrowdedRevealRescueService")
@MainActor
struct CrowdedRevealRescueServiceTests {
    private func makeEstimate(crowded: Bool, ratio: Double = 0.9) -> LayoutCapacityEstimate {
        LayoutCapacityEstimate(
            screenID: "primary",
            screenFrame: .zero,
            visibleFrame: .zero,
            estimatedMenuBarWidth: 1440,
            estimatedUsableRightSideWidth: 720,
            knownItemCount: 0,
            knownVisibleItemCount: 0,
            knownHiddenItemCount: 0,
            knownAlwaysHiddenItemCount: 0,
            estimatedItemSlots: 20,
            estimatedUsedSlots: 20,
            usedCapacityRatio: ratio,
            isLikelyCrowded: crowded,
            isLikelyNotchConstrained: false,
            source: .basicGeometryOnly,
            warnings: [],
            generatedAt: Date()
        )
    }

    @Test func crowdedOpensSecondBarWhenEnabled() {
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
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true
        )

        #expect(result == .openedSecondBar)
        #expect(secondBarOpened)
        #expect(!fullModeEntered)
        #expect(service.lastRevealIntercepted)
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
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: false,
            fullMenuBarModeAvailable: true
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
            estimate: makeEstimate(crowded: false, ratio: 0.3),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true
        )

        #expect(result == .proceedInline)
        #expect(!service.lastRevealIntercepted)
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
            estimate: makeEstimate(crowded: true),
            secondBarAvailable: true,
            fullMenuBarModeAvailable: true
        )

        #expect(result == .proceedInline)
    }
}
