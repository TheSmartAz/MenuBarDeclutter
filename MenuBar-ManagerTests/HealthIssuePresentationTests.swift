import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Health Issue Presentation")
@MainActor
struct HealthIssuePresentationTests {
    @Test func severityDisplayNamesMatchUserFacingLabels() {
        #expect(HealthSeverity.warning.displayName == "Warning")
        #expect(HealthSeverity.critical.displayName == "Critical")
    }

    @Test func severitySortRanksPutCriticalIssuesFirst() {
        #expect(HealthSeverity.critical.sortRank < HealthSeverity.warning.sortRank)
        #expect([HealthSeverity.warning, .critical].sorted { $0.sortRank < $1.sortRank } == [.critical, .warning])
    }

    @Test func recoveryActionDisplayNamesMatchUserFacingLabels() {
        let expectedDisplayNames: [HealthRecoveryAction: String] = [
            .recreateStatusItems: "Recreate status items",
            .resetSeparatorLengths: "Reset separator lengths",
            .expandAll: "Expand all",
            .disableAutoRehideTemporarily: "Disable auto-rehide temporarily",
            .disableHoverRevealTemporarily: "Disable hover reveal temporarily",
            .resetMenuBarScanInterval: "Reset menu bar scan interval",
            .resetSecondBarPosition: "Reset Second Bar position",
            .refreshAccessibilityPermissionStatus: "Refresh Accessibility permission status",
            .resetSettingsToDefaults: "Reset settings to defaults",
            .disableProMode: "Disable Pro Mode",
            .enterSafeModeNextLaunch: "Enter Safe Mode next launch",
            .exitFullMenuBarMode: "Exit Full Menu Bar Mode",
            .hideOptionalSpacerItems: "Hide optional spacer items",
            .disableDynamicHotkeys: "Disable dynamic hotkeys",
            .disableGroupStatusItems: "Disable group status items",
            .clearPrivateAccessUnlock: "Clear Private Access unlock",
            .resetWorkspacesToDefaults: "Reset workspaces to defaults",
            .resetCurrentWorkspaceLayout: "Reset current Workspace layout",
            .removeMissingWorkspaceGroupReferences: "Remove missing Workspace group references",
            .discardSetBuilderDraft: "Discard Set Builder draft",
            .hideFunctionBar: "Hide Function Bar",
            .disableFunctionBarPreview: "Disable Function Bar Preview",
            .disableSetBuilderPreview: "Disable Set Builder Preview",
            .hideInfoStrip: "Hide Info Strip",
            .disableInfoStripPreview: "Disable Info Strip Preview",
            .resetInfoStripSettings: "Reset Info Strip settings",
            .resetInfoStripPlacement: "Reset Info Strip placement",
            .clearInvalidInfoStripProviders: "Clear invalid Info Strip tiles",
            .showFunctionBarInstead: "Show Function Bar instead"
        ]

        #expect(HealthRecoveryAction.allCases.count == expectedDisplayNames.count)

        for action in HealthRecoveryAction.allCases {
            #expect(action.displayName == expectedDisplayNames[action])
        }
    }
}
