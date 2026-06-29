import Foundation

/// Value-type snapshot of Phase 10 layout settings derived from
/// ``SettingsStore``. Used to pass configuration into pure layout logic
/// without threading the full observable store deep into calculations.
nonisolated struct LayoutSettings: Equatable, Sendable {
    var layoutFeaturesEnabled: Bool
    var fullMenuBarModeEnabled: Bool
    var crowdedRevealRescueEnabled: Bool
    var layoutSuggestionsEnabled: Bool
    var showCapacityWarnings: Bool

    var fullMenuBarModeAutoExitEnabled: Bool
    var fullMenuBarModeAutoExitSeconds: Double
    var fullMenuBarModeShowsSecondBar: Bool
    var fullMenuBarModeSuspendsAutoRehide: Bool
    var fullMenuBarModeShowsSpacerMarkers: Bool

    var crowdedRevealAutoOpenSecondBar: Bool
    var crowdedRevealThresholdRatio: Double
    var crowdedRevealRequireProEstimate: Bool

    var spacerItemsEnabled: Bool
    var showSpacerMarkers: Bool
    var spacerItemsJSONVersion: Int

    var menuBarSpacingLabsEnabled: Bool
    var menuBarSpacingPreset: String
    var menuBarSpacingCustomItemSpacing: Int
    var menuBarSpacingCustomSelectionPadding: Int
    var menuBarSpacingHasBackup: Bool
    var menuBarSpacingLastApplyStatus: String?
    var menuBarSpacingLastApplyDate: Date?

    @MainActor
    init(store: SettingsStore) {
        self.layoutFeaturesEnabled = store.layoutFeaturesEnabled
        self.fullMenuBarModeEnabled = store.fullMenuBarModeEnabled
        self.crowdedRevealRescueEnabled = store.crowdedRevealRescueEnabled
        self.layoutSuggestionsEnabled = store.layoutSuggestionsEnabled
        self.showCapacityWarnings = store.showCapacityWarnings
        self.fullMenuBarModeAutoExitEnabled = store.fullMenuBarModeAutoExitEnabled
        self.fullMenuBarModeAutoExitSeconds = store.fullMenuBarModeAutoExitSeconds
        self.fullMenuBarModeShowsSecondBar = store.fullMenuBarModeShowsSecondBar
        self.fullMenuBarModeSuspendsAutoRehide = store.fullMenuBarModeSuspendsAutoRehide
        self.fullMenuBarModeShowsSpacerMarkers = store.fullMenuBarModeShowsSpacerMarkers
        self.crowdedRevealAutoOpenSecondBar = store.crowdedRevealAutoOpenSecondBar
        self.crowdedRevealThresholdRatio = store.crowdedRevealThresholdRatio
        self.crowdedRevealRequireProEstimate = store.crowdedRevealRequireProEstimate
        self.spacerItemsEnabled = store.spacerItemsEnabled
        self.showSpacerMarkers = store.showSpacerMarkers
        self.spacerItemsJSONVersion = store.spacerItemsJSONVersion
        self.menuBarSpacingLabsEnabled = store.menuBarSpacingLabsEnabled
        self.menuBarSpacingPreset = store.menuBarSpacingPreset
        self.menuBarSpacingCustomItemSpacing = store.menuBarSpacingCustomItemSpacing
        self.menuBarSpacingCustomSelectionPadding = store.menuBarSpacingCustomSelectionPadding
        self.menuBarSpacingHasBackup = store.menuBarSpacingHasBackup
        self.menuBarSpacingLastApplyStatus = store.menuBarSpacingLastApplyStatus
        self.menuBarSpacingLastApplyDate = store.menuBarSpacingLastApplyDate
    }
}
