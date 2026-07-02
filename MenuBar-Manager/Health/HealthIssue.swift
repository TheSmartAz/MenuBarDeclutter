import Foundation

enum HealthSeverity: String, CaseIterable, Codable, Hashable, Sendable {
    case warning
    case critical

    var displayName: String {
        switch self {
        case .warning:
            "Warning"
        case .critical:
            "Critical"
        }
    }

    var sortRank: Int {
        switch self {
        case .critical:
            0
        case .warning:
            1
        }
    }
}

enum HealthRecoveryAction: String, CaseIterable, Codable, Hashable, Sendable {
    case recreateStatusItems
    case resetSeparatorLengths
    case expandAll
    case disableAutoRehideTemporarily
    case disableHoverRevealTemporarily
    case resetMenuBarScanInterval
    case resetSecondBarPosition
    case refreshAccessibilityPermissionStatus
    case resetSettingsToDefaults
    case disableProMode
    case enterSafeModeNextLaunch
    case exitFullMenuBarMode
    case hideOptionalSpacerItems
    case disableDynamicHotkeys
    case disableGroupStatusItems
    case clearPrivateAccessUnlock
    case resetWorkspacesToDefaults
    case resetCurrentWorkspaceLayout
    case removeMissingWorkspaceGroupReferences
    case discardSetBuilderDraft
    case hideFunctionBar
    case disableFunctionBarPreview
    case disableSetBuilderPreview
    case hideInfoStrip
    case disableInfoStripPreview
    case resetInfoStripSettings
    case resetInfoStripPlacement
    case clearInvalidInfoStripProviders
    case showFunctionBarInstead

    var displayName: String {
        switch self {
        case .recreateStatusItems:
            "Recreate status items"
        case .resetSeparatorLengths:
            "Reset separator lengths"
        case .expandAll:
            "Expand all"
        case .disableAutoRehideTemporarily:
            "Disable auto-rehide temporarily"
        case .disableHoverRevealTemporarily:
            "Disable hover reveal temporarily"
        case .resetMenuBarScanInterval:
            "Reset menu bar scan interval"
        case .resetSecondBarPosition:
            "Reset Second Bar position"
        case .refreshAccessibilityPermissionStatus:
            "Refresh Accessibility permission status"
        case .resetSettingsToDefaults:
            "Reset settings to defaults"
        case .disableProMode:
            "Disable Pro Mode"
        case .enterSafeModeNextLaunch:
            "Enter Safe Mode next launch"
        case .exitFullMenuBarMode:
            "Exit Full Menu Bar Mode"
        case .hideOptionalSpacerItems:
            "Hide optional spacer items"
        case .disableDynamicHotkeys:
            "Disable dynamic hotkeys"
        case .disableGroupStatusItems:
            "Disable group status items"
        case .clearPrivateAccessUnlock:
            "Clear Private Access unlock"
        case .resetWorkspacesToDefaults:
            "Reset workspaces to defaults"
        case .resetCurrentWorkspaceLayout:
            "Reset current Workspace layout"
        case .removeMissingWorkspaceGroupReferences:
            "Remove missing Workspace group references"
        case .discardSetBuilderDraft:
            "Discard Set Builder draft"
        case .hideFunctionBar:
            "Hide Function Bar"
        case .disableFunctionBarPreview:
            "Disable Function Bar Preview"
        case .disableSetBuilderPreview:
            "Disable Set Builder Preview"
        case .hideInfoStrip:
            "Hide Info Strip"
        case .disableInfoStripPreview:
            "Disable Info Strip Preview"
        case .resetInfoStripSettings:
            "Reset Info Strip settings"
        case .resetInfoStripPlacement:
            "Reset Info Strip placement"
        case .clearInvalidInfoStripProviders:
            "Clear invalid Info Strip tiles"
        case .showFunctionBarInstead:
            "Show Function Bar instead"
        }
    }
}

struct HealthIssue: Identifiable, Equatable, Codable, Sendable {
    let code: String
    let severity: HealthSeverity
    let title: String
    let detail: String
    let recoveryAction: HealthRecoveryAction?

    var id: String { code }
}
