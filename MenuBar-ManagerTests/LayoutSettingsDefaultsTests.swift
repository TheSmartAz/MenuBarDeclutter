import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("LayoutSettingsDefaults")
@MainActor
struct LayoutSettingsDefaultsTests {
    @Test func freshInstallDefaultsAreSafe() {
        let suiteName = "layout-defaults-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(store.layoutFeaturesEnabled)
        #expect(store.fullMenuBarModeEnabled)
        #expect(store.crowdedRevealRescueEnabled)
        #expect(store.layoutSuggestionsEnabled)
        #expect(store.showCapacityWarnings)
        #expect(store.fullMenuBarModeAutoExitEnabled)
        #expect(store.fullMenuBarModeAutoExitSeconds == 30)
        #expect(!store.fullMenuBarModeShowsSecondBar)
        #expect(store.fullMenuBarModeSuspendsAutoRehide)
        #expect(store.fullMenuBarModeShowsSpacerMarkers)
        #expect(store.crowdedRevealAutoOpenSecondBar)
        #expect(!store.crowdedRevealAskBeforeSwitching)
        #expect(store.crowdedRescueWorkspaceFallbackPreference == CrowdedRescueWorkspaceFallbackPreference.preferSecondBar.rawValue)
        #expect(store.crowdedRevealThresholdRatio == 0.85)
        #expect(!store.crowdedRevealRequireProEstimate)
        #expect(store.spacerItemsEnabled)
        #expect(store.showSpacerMarkers)
        #expect(store.spacerItemsJSONVersion == 1)
        #expect(!store.menuBarSpacingLabsEnabled)
        #expect(store.menuBarSpacingPreset == "system")
        #expect(store.menuBarSpacingCustomItemSpacing == 12)
        #expect(store.menuBarSpacingCustomSelectionPadding == 8)
        #expect(!store.menuBarSpacingHasBackup)
        #expect(store.menuBarSpacingLastApplyStatus == nil)
        #expect(store.menuBarSpacingLastApplyDate == nil)
    }

    @Test func clampingFullMenuBarModeAutoExitSeconds() {
        let suiteName = "layout-clamp-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        store.fullMenuBarModeAutoExitSeconds = 1
        #expect(store.fullMenuBarModeAutoExitSeconds == 5)

        store.fullMenuBarModeAutoExitSeconds = 1000
        #expect(store.fullMenuBarModeAutoExitSeconds == 300)

        store.fullMenuBarModeAutoExitSeconds = .nan
        #expect(store.fullMenuBarModeAutoExitSeconds == 30)
    }

    @Test func clampingCrowdedRevealThresholdRatio() {
        let suiteName = "layout-clamp-ratio-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        store.crowdedRevealThresholdRatio = 0.1
        #expect(store.crowdedRevealThresholdRatio == 0.5)

        store.crowdedRevealThresholdRatio = 2.0
        #expect(store.crowdedRevealThresholdRatio == 1.0)

        store.crowdedRevealThresholdRatio = .nan
        #expect(store.crowdedRevealThresholdRatio == 0.85)
    }

    @Test func clampingMenuBarSpacingValues() {
        let suiteName = "layout-clamp-spacing-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        store.menuBarSpacingCustomItemSpacing = 1
        #expect(store.menuBarSpacingCustomItemSpacing == 2)

        store.menuBarSpacingCustomItemSpacing = 100
        #expect(store.menuBarSpacingCustomItemSpacing == 32)

        store.menuBarSpacingCustomSelectionPadding = 1
        #expect(store.menuBarSpacingCustomSelectionPadding == 2)

        store.menuBarSpacingCustomSelectionPadding = 100
        #expect(store.menuBarSpacingCustomSelectionPadding == 32)
    }

    @Test func resetAllSettingsRestoresPhase10Defaults() {
        let suiteName = "layout-reset-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        // Change values
        store.layoutFeaturesEnabled = false
        store.fullMenuBarModeEnabled = false
        store.menuBarSpacingLabsEnabled = true
        store.menuBarSpacingPreset = "compact"
        store.fullMenuBarModeAutoExitSeconds = 60
        store.crowdedRevealAskBeforeSwitching = true
        store.crowdedRescueWorkspaceFallbackPreference = CrowdedRescueWorkspaceFallbackPreference.preferFunctionBar.rawValue
        store.crowdedRevealThresholdRatio = 0.7

        // Reset
        store.restoreDefaults()

        #expect(store.layoutFeaturesEnabled)
        #expect(store.fullMenuBarModeEnabled)
        #expect(!store.menuBarSpacingLabsEnabled)
        #expect(store.menuBarSpacingPreset == "system")
        #expect(store.fullMenuBarModeAutoExitSeconds == 30)
        #expect(!store.crowdedRevealAskBeforeSwitching)
        #expect(store.crowdedRescueWorkspaceFallbackPreference == CrowdedRescueWorkspaceFallbackPreference.preferSecondBar.rawValue)
        #expect(store.crowdedRevealThresholdRatio == 0.85)
    }

    @Test func phase10ValuesPersist() {
        let suiteName = "layout-persist-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.layoutFeaturesEnabled = false
        store.fullMenuBarModeAutoExitSeconds = 120
        store.crowdedRevealAskBeforeSwitching = true
        store.crowdedRescueWorkspaceFallbackPreference = CrowdedRescueWorkspaceFallbackPreference.preferFunctionBar.rawValue
        store.menuBarSpacingPreset = "dense"
        store.menuBarSpacingLastApplyStatus = "applied"

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.layoutFeaturesEnabled == false)
        #expect(reloaded.fullMenuBarModeAutoExitSeconds == 120)
        #expect(reloaded.crowdedRevealAskBeforeSwitching)
        #expect(reloaded.crowdedRescueWorkspaceFallbackPreference == CrowdedRescueWorkspaceFallbackPreference.preferFunctionBar.rawValue)
        #expect(reloaded.menuBarSpacingPreset == "dense")
        #expect(reloaded.menuBarSpacingLastApplyStatus == "applied")
    }
}
