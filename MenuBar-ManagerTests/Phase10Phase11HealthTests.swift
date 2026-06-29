import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Phase 10 and 11 Health")
@MainActor
struct Phase10Phase11HealthTests {
    @Test func detectsVisibleSpacersWhileDisabled() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 1) })
        var snapshot = Self.healthySnapshot()
        snapshot.spacerItemsEnabled = false
        snapshot.visibleSpacerItemCount = 2

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.contains { $0.code == "layout.spacers.visible-while-disabled" })
        #expect(report.issues.first { $0.code == "layout.spacers.visible-while-disabled" }?.recoveryAction == .hideOptionalSpacerItems)
    }

    @Test func detectsDynamicHotkeyConflicts() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 1) })
        var snapshot = Self.healthySnapshot()
        snapshot.dynamicHotkeysEnabled = true
        snapshot.dynamicHotkeyConflictCount = 2

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.contains { $0.code == "hotkey.dynamic.conflicts" })
        #expect(report.issues.first { $0.code == "hotkey.dynamic.conflicts" }?.recoveryAction == .disableDynamicHotkeys)
    }

    @Test func detectsDuplicateGroupNames() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 1) })
        var snapshot = Self.healthySnapshot()
        snapshot.duplicateGroupNames = true

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.contains { $0.code == "groups.duplicate-names" })
    }

    private static func healthySnapshot() -> HealthCheckSnapshot {
        HealthCheckSnapshot(
            controlItemExists: true,
            primarySeparatorExpected: true,
            primarySeparatorExists: true,
            alwaysHiddenEnabled: false,
            alwaysHiddenSeparatorExists: false,
            primarySeparatorLength: AppConstants.defaultExpandedSeparatorLength,
            alwaysHiddenSeparatorLength: 0,
            widestScreenWidth: 1512,
            screenCount: 1,
            settingsIssues: [],
            globalHotkeyEnabled: false,
            globalHotkeyRegistered: false,
            searchHotkeyEnabled: false,
            searchHotkeyRegistered: false,
            autoRehideEnabled: false,
            autoRehideScheduled: false,
            visibilityState: .expanded,
            hoverRevealEnabled: false,
            hoverRevealPollingActive: false,
            proModeEnabled: false,
            accessibilityDiscoveryEnabled: false,
            accessibilityPermissionStatus: .notRequested,
            lastMenuBarScanTime: nil,
            menuBarScanFailuresCount: 0,
            axScanStaleThreshold: 60
        )
    }
}
