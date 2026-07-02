import Foundation

@MainActor
struct RecoveryActions {
    var recreateMissingStatusItems: () -> Void = {}
    var resetSeparatorLengths: () -> Void = {}
    var expandAll: () -> Void = {}
    var disableAutoRehideTemporarily: () -> Void = {}
    var disableHoverRevealTemporarily: () -> Void = {}
    var resetMenuBarScanInterval: () -> Void = {}
    var resetSecondBarPosition: () -> Void = {}
    var refreshAccessibilityPermissionStatus: () -> Void = {}
    var resetSettingsToDefaults: () -> Void = {}
    var disableProMode: () -> Void = {}
    var enterSafeModeNextLaunch: () -> Void = {}
    var exitFullMenuBarMode: () -> Void = {}
    var hideOptionalSpacerItems: () -> Void = {}
    var disableDynamicHotkeys: () -> Void = {}
    var disableGroupStatusItems: () -> Void = {}
    var clearPrivateAccessUnlock: () -> Void = {}
    var resetWorkspacesToDefaults: () -> Void = {}
    var resetCurrentWorkspaceLayout: () -> Void = {}
    var removeMissingWorkspaceGroupReferences: () -> Void = {}
    var discardSetBuilderDraft: () -> Void = {}
    var hideFunctionBar: () -> Void = {}
    var disableFunctionBarPreview: () -> Void = {}
    var disableSetBuilderPreview: () -> Void = {}
    var hideInfoStrip: () -> Void = {}
    var disableInfoStripPreview: () -> Void = {}
    var resetInfoStripSettings: () -> Void = {}
    var resetInfoStripPlacement: () -> Void = {}
    var clearInvalidInfoStripProviders: () -> Void = {}
    var showFunctionBarInstead: () -> Void = {}
}

@MainActor
final class RecoveryService {
    private let actions: RecoveryActions
    private let log: (String) -> Void

    init(
        actions: RecoveryActions = RecoveryActions(),
        log: @escaping (String) -> Void = { _ in }
    ) {
        self.actions = actions
        self.log = log
    }

    func recover(report: HealthReport) {
        guard !report.isHealthy else {
            log("Health recovery skipped: report is OK.")
            return
        }

        perform(.expandAll)

        let recoveryActions = orderedUniqueActions(for: report)
        for action in recoveryActions {
            perform(action)
        }

        log("Health recovery completed with \(recoveryActions.count) repair action(s).")
    }

    func perform(_ action: HealthRecoveryAction) {
        switch action {
        case .recreateStatusItems:
            actions.recreateMissingStatusItems()
        case .resetSeparatorLengths:
            actions.resetSeparatorLengths()
        case .expandAll:
            actions.expandAll()
        case .disableAutoRehideTemporarily:
            actions.disableAutoRehideTemporarily()
        case .disableHoverRevealTemporarily:
            actions.disableHoverRevealTemporarily()
        case .resetMenuBarScanInterval:
            actions.resetMenuBarScanInterval()
        case .resetSecondBarPosition:
            actions.resetSecondBarPosition()
        case .refreshAccessibilityPermissionStatus:
            actions.refreshAccessibilityPermissionStatus()
        case .resetSettingsToDefaults:
            actions.resetSettingsToDefaults()
        case .disableProMode:
            actions.disableProMode()
        case .enterSafeModeNextLaunch:
            actions.enterSafeModeNextLaunch()
        case .exitFullMenuBarMode:
            actions.exitFullMenuBarMode()
        case .hideOptionalSpacerItems:
            actions.hideOptionalSpacerItems()
        case .disableDynamicHotkeys:
            actions.disableDynamicHotkeys()
        case .disableGroupStatusItems:
            actions.disableGroupStatusItems()
        case .clearPrivateAccessUnlock:
            actions.clearPrivateAccessUnlock()
        case .resetWorkspacesToDefaults:
            actions.resetWorkspacesToDefaults()
        case .resetCurrentWorkspaceLayout:
            actions.resetCurrentWorkspaceLayout()
        case .removeMissingWorkspaceGroupReferences:
            actions.removeMissingWorkspaceGroupReferences()
        case .discardSetBuilderDraft:
            actions.discardSetBuilderDraft()
        case .hideFunctionBar:
            actions.hideFunctionBar()
        case .disableFunctionBarPreview:
            actions.disableFunctionBarPreview()
        case .disableSetBuilderPreview:
            actions.disableSetBuilderPreview()
        case .hideInfoStrip:
            actions.hideInfoStrip()
        case .disableInfoStripPreview:
            actions.disableInfoStripPreview()
        case .resetInfoStripSettings:
            actions.resetInfoStripSettings()
        case .resetInfoStripPlacement:
            actions.resetInfoStripPlacement()
        case .clearInvalidInfoStripProviders:
            actions.clearInvalidInfoStripProviders()
        case .showFunctionBarInstead:
            actions.showFunctionBarInstead()
        }

        log("Health recovery action: \(action.displayName).")
    }

    private func orderedUniqueActions(for report: HealthReport) -> [HealthRecoveryAction] {
        let preferredOrder: [HealthRecoveryAction] = [
            .recreateStatusItems,
            .resetSeparatorLengths,
            .disableAutoRehideTemporarily,
            .disableHoverRevealTemporarily,
            .resetMenuBarScanInterval,
            .resetSecondBarPosition,
            .refreshAccessibilityPermissionStatus,
            .exitFullMenuBarMode,
            .hideOptionalSpacerItems,
            .disableDynamicHotkeys,
            .disableGroupStatusItems,
            .clearPrivateAccessUnlock,
            .removeMissingWorkspaceGroupReferences,
            .discardSetBuilderDraft,
            .resetCurrentWorkspaceLayout,
            .resetWorkspacesToDefaults,
            .disableSetBuilderPreview,
            .disableFunctionBarPreview,
            .hideInfoStrip,
            .clearInvalidInfoStripProviders,
            .resetInfoStripSettings,
            .resetInfoStripPlacement,
            .showFunctionBarInstead,
            .disableInfoStripPreview,
            .hideFunctionBar,
            .disableProMode,
            .resetSettingsToDefaults,
            .enterSafeModeNextLaunch
        ]

        let requested = Set(report.issues.compactMap(\.recoveryAction))
        return preferredOrder.filter { requested.contains($0) }
    }
}
