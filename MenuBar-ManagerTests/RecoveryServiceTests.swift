import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("RecoveryService")
@MainActor
struct RecoveryServiceTests {
    @Test func recoveryResetsLengths() {
        var expanded = 0
        var resetLengths = 0

        let service = RecoveryService(
            actions: RecoveryActions(
                resetSeparatorLengths: {
                    resetLengths += 1
                },
                expandAll: {
                    expanded += 1
                }
            )
        )

        let report = HealthReport(
            generatedAt: Date(),
            issues: [
                HealthIssue(
                    code: "status.primary-separator.length-invalid",
                    severity: .critical,
                    title: "Bad length",
                    detail: "Length is invalid.",
                    recoveryAction: .resetSeparatorLengths
                )
            ]
        )

        service.recover(report: report)

        #expect(expanded == 1)
        #expect(resetLengths == 1)
    }

    @Test func proModeFailureDisablesDependentFeatures() {
        let suiteName = "RecoveryServiceTests.pro.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        store.secondBarPrimaryClickEnabled = true
        store.iconMovingEnabled = true
        store.smartTriggersEnabled = true

        let service = RecoveryService(
            actions: RecoveryActions(
                disableProMode: {
                    store.proModeEnabled = false
                    store.accessibilityDiscoveryEnabled = false
                    store.secondBarPrimaryClickEnabled = false
                    store.iconMovingEnabled = false
                    store.smartTriggersEnabled = false
                }
            )
        )

        service.perform(.disableProMode)

        #expect(store.proModeEnabled == false)
        #expect(store.accessibilityDiscoveryEnabled == false)
        #expect(store.secondBarPrimaryClickEnabled == false)
        #expect(store.iconMovingEnabled == false)
        #expect(store.smartTriggersEnabled == false)
    }

    @Test func previewPanelRecoveryHidesPanels() {
        var hidFunctionBar = 0
        var hidInfoStrip = 0
        var resetWorkspaces = 0
        var resetCurrentWorkspaceLayout = 0
        var removedMissingGroupReferences = 0
        var discardedSetBuilderDraft = 0
        var disabledFunctionBar = 0
        var disabledSetBuilder = 0
        var disabledInfoStrip = 0
        var resetInfoStripSettings = 0
        var resetInfoStripPlacement = 0
        var clearedInvalidProviders = 0
        var showedFunctionBarInstead = 0
        let service = RecoveryService(
            actions: RecoveryActions(
                resetWorkspacesToDefaults: {
                    resetWorkspaces += 1
                },
                resetCurrentWorkspaceLayout: {
                    resetCurrentWorkspaceLayout += 1
                },
                removeMissingWorkspaceGroupReferences: {
                    removedMissingGroupReferences += 1
                },
                discardSetBuilderDraft: {
                    discardedSetBuilderDraft += 1
                },
                hideFunctionBar: {
                    hidFunctionBar += 1
                },
                disableFunctionBarPreview: {
                    disabledFunctionBar += 1
                },
                disableSetBuilderPreview: {
                    disabledSetBuilder += 1
                },
                hideInfoStrip: {
                    hidInfoStrip += 1
                },
                disableInfoStripPreview: {
                    disabledInfoStrip += 1
                },
                resetInfoStripSettings: {
                    resetInfoStripSettings += 1
                },
                resetInfoStripPlacement: {
                    resetInfoStripPlacement += 1
                },
                clearInvalidInfoStripProviders: {
                    clearedInvalidProviders += 1
                },
                showFunctionBarInstead: {
                    showedFunctionBarInstead += 1
                }
            )
        )

        service.perform(.resetWorkspacesToDefaults)
        service.perform(.resetCurrentWorkspaceLayout)
        service.perform(.removeMissingWorkspaceGroupReferences)
        service.perform(.discardSetBuilderDraft)
        service.perform(.hideFunctionBar)
        service.perform(.disableFunctionBarPreview)
        service.perform(.disableSetBuilderPreview)
        service.perform(.hideInfoStrip)
        service.perform(.disableInfoStripPreview)
        service.perform(.resetInfoStripSettings)
        service.perform(.resetInfoStripPlacement)
        service.perform(.clearInvalidInfoStripProviders)
        service.perform(.showFunctionBarInstead)

        #expect(resetWorkspaces == 1)
        #expect(resetCurrentWorkspaceLayout == 1)
        #expect(removedMissingGroupReferences == 1)
        #expect(discardedSetBuilderDraft == 1)
        #expect(hidFunctionBar == 1)
        #expect(disabledFunctionBar == 1)
        #expect(disabledSetBuilder == 1)
        #expect(hidInfoStrip == 1)
        #expect(disabledInfoStrip == 1)
        #expect(resetInfoStripSettings == 1)
        #expect(resetInfoStripPlacement == 1)
        #expect(clearedInvalidProviders == 1)
        #expect(showedFunctionBarInstead == 1)
    }

    @Test func targetedSettingsRecoveryDoesNotResetAllSettings() {
        var expanded = 0
        var resetScanInterval = 0
        var resetSecondBarPosition = 0
        var refreshPermission = 0
        var resetAllSettings = 0

        let service = RecoveryService(
            actions: RecoveryActions(
                expandAll: {
                    expanded += 1
                },
                resetMenuBarScanInterval: {
                    resetScanInterval += 1
                },
                resetSecondBarPosition: {
                    resetSecondBarPosition += 1
                },
                refreshAccessibilityPermissionStatus: {
                    refreshPermission += 1
                },
                resetSettingsToDefaults: {
                    resetAllSettings += 1
                }
            )
        )

        let report = HealthReport(
            generatedAt: Date(),
            issues: [
                HealthIssue(
                    code: "settings.scan-interval",
                    severity: .warning,
                    title: "Bad scan interval",
                    detail: "Scan interval is invalid.",
                    recoveryAction: .resetMenuBarScanInterval
                ),
                HealthIssue(
                    code: "settings.second-bar-position",
                    severity: .warning,
                    title: "Bad Second Bar position",
                    detail: "Second Bar position is invalid.",
                    recoveryAction: .resetSecondBarPosition
                ),
                HealthIssue(
                    code: "settings.accessibility-permission-status",
                    severity: .warning,
                    title: "Bad permission status",
                    detail: "Permission status is invalid.",
                    recoveryAction: .refreshAccessibilityPermissionStatus
                )
            ]
        )

        service.recover(report: report)

        #expect(expanded == 1)
        #expect(resetScanInterval == 1)
        #expect(resetSecondBarPosition == 1)
        #expect(refreshPermission == 1)
        #expect(resetAllSettings == 0)
    }
}
