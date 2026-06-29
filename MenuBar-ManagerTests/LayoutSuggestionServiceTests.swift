import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("LayoutSuggestionService")
struct LayoutSuggestionServiceTests {
    @Test func crowdedEstimateSuggestsSecondBar() {
        let service = LayoutSuggestionService(now: { Date(timeIntervalSince1970: 1000) })
        let estimate = LayoutCapacityEstimate(
            screenID: "primary",
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
            estimatedMenuBarWidth: 1440,
            estimatedUsableRightSideWidth: 720,
            knownItemCount: 0,
            knownVisibleItemCount: 0,
            knownHiddenItemCount: 0,
            knownAlwaysHiddenItemCount: 0,
            estimatedItemSlots: 20,
            estimatedUsedSlots: 20,
            usedCapacityRatio: 0.9,
            isLikelyCrowded: true,
            isLikelyNotchConstrained: false,
            source: .basicGeometryOnly,
            warnings: [],
            generatedAt: Date(timeIntervalSince1970: 1000)
        )

        let settings = LayoutSettings(
            store: SettingsStore(defaults: UserDefaults(suiteName: "suggestion-tests-\(UUID().uuidString)")!)
        )

        let suggestions = service.generate(
            estimate: estimate,
            settings: settings,
            proModeEnabled: false,
            secondBarEnabled: false,
            separatorLengthExtreme: false,
            manyHiddenItems: false
        )

        #expect(suggestions.contains { $0.id == "enable-second-bar" })
        #expect(suggestions.contains { $0.id == "use-full-menu-bar-mode" })
    }

    @Test func doesNotSuggestSecondBarWhenAlreadyEnabled() {
        let service = LayoutSuggestionService()
        let estimate = LayoutCapacityEstimate(
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
            usedCapacityRatio: 0.9,
            isLikelyCrowded: true,
            isLikelyNotchConstrained: false,
            source: .basicGeometryOnly,
            warnings: [],
            generatedAt: Date()
        )

        let settings = LayoutSettings(
            store: SettingsStore(defaults: UserDefaults(suiteName: "suggestion-tests-\(UUID().uuidString)")!)
        )

        let suggestions = service.generate(
            estimate: estimate,
            settings: settings,
            proModeEnabled: false,
            secondBarEnabled: true,
            separatorLengthExtreme: false,
            manyHiddenItems: false
        )

        #expect(!suggestions.contains { $0.id == "enable-second-bar" })
    }

    @Test func suggestsProModeForBetterEstimate() {
        let service = LayoutSuggestionService()
        let estimate = LayoutCapacityEstimate(
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
            estimatedUsedSlots: 10,
            usedCapacityRatio: 0.5,
            isLikelyCrowded: false,
            isLikelyNotchConstrained: false,
            source: .basicGeometryOnly,
            warnings: [],
            generatedAt: Date()
        )

        let settings = LayoutSettings(
            store: SettingsStore(defaults: UserDefaults(suiteName: "suggestion-tests-\(UUID().uuidString)")!)
        )

        let suggestions = service.generate(
            estimate: estimate,
            settings: settings,
            proModeEnabled: false,
            secondBarEnabled: false,
            separatorLengthExtreme: false,
            manyHiddenItems: false
        )

        let proSuggestion = suggestions.first { $0.id == "enable-pro-better-estimate" }
        #expect(proSuggestion != nil)
        #expect(proSuggestion?.requiresProMode == true)
        #expect(proSuggestion?.requiresManualAction == true)
    }

    @Test func separatorExtremeSuggestsReset() {
        let service = LayoutSuggestionService()
        let estimate = LayoutCapacityEstimate(
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
            estimatedUsedSlots: 5,
            usedCapacityRatio: 0.25,
            isLikelyCrowded: false,
            isLikelyNotchConstrained: false,
            source: .basicGeometryOnly,
            warnings: [],
            generatedAt: Date()
        )

        let settings = LayoutSettings(
            store: SettingsStore(defaults: UserDefaults(suiteName: "suggestion-tests-\(UUID().uuidString)")!)
        )

        let suggestions = service.generate(
            estimate: estimate,
            settings: settings,
            proModeEnabled: true,
            secondBarEnabled: true,
            separatorLengthExtreme: true,
            manyHiddenItems: false
        )

        #expect(suggestions.contains { $0.id == "reset-separator-length" })
    }
}
