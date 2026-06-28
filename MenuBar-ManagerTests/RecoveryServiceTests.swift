import Foundation
import Testing
@testable import MenuBar_Manager

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
        store.iconMovingEnabled = true
        store.smartTriggersEnabled = true

        let service = RecoveryService(
            actions: RecoveryActions(
                disableProMode: {
                    store.proModeEnabled = false
                    store.accessibilityDiscoveryEnabled = false
                    store.iconMovingEnabled = false
                    store.smartTriggersEnabled = false
                }
            )
        )

        service.perform(.disableProMode)

        #expect(store.proModeEnabled == false)
        #expect(store.accessibilityDiscoveryEnabled == false)
        #expect(store.iconMovingEnabled == false)
        #expect(store.smartTriggersEnabled == false)
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
