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
            .disableProMode,
            .resetSettingsToDefaults,
            .enterSafeModeNextLaunch
        ]

        let requested = Set(report.issues.compactMap(\.recoveryAction))
        return preferredOrder.filter { requested.contains($0) }
    }
}
