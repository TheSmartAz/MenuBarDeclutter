import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HealthService")
@MainActor
struct HealthServiceTests {
    @Test func missingSeparatorDetected() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.primarySeparatorExists = false

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.status == .critical)
        #expect(report.issues.contains { $0.code == "status.primary-separator.missing" })
        #expect(report.issues.first { $0.code == "status.primary-separator.missing" }?.recoveryAction == .recreateStatusItems)
    }

    @Test func corruptedSettingDetected() {
        let suiteName = "HealthServiceTests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.expandedSeparatorLength = -20
        store.secondBarPositionModeRaw = "somewhere-impossible"

        let issues = HealthService.validateSettings(store)

        #expect(issues.contains { $0.code == "expanded-separator-length" && $0.severity == .critical })
        #expect(issues.contains { $0.code == "second-bar-position" })
    }

    @Test func validateSettingsDeclaresKnownRecoveryActions() {
        let suiteName = "HealthServiceTests.settingActions.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.expandedSeparatorLength = -20
        store.collapsedSeparatorLengthOverride = AppConstants.collapsedSeparatorMaximumLength * 2
        store.secondBarPositionModeRaw = "somewhere-impossible"
        store.lastAccessibilityPermissionStatus = "legacy-status"

        let issues = HealthService.validateSettings(store)

        #expect(issues.first { $0.code == "expanded-separator-length" }?.recoveryAction == .resetSeparatorLengths)
        #expect(issues.first { $0.code == "collapsed-separator-override" }?.recoveryAction == .resetSeparatorLengths)
        #expect(issues.first { $0.code == "second-bar-position" }?.recoveryAction == .resetSecondBarPosition)
        #expect(issues.first { $0.code == "accessibility-permission-status" }?.recoveryAction == .refreshAccessibilityPermissionStatus)
        #expect(issues.allSatisfy { $0.recoveryAction != .resetSettingsToDefaults })
    }

    @Test func settingsIssuesUseDeclaredRecoveryActions() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.settingsIssues = [
            SettingsValidationIssue(
                code: "expanded-separator-length",
                title: "Bad expanded length",
                detail: "Expanded length is invalid.",
                severity: .critical,
                recoveryAction: .resetSeparatorLengths
            ),
            SettingsValidationIssue(
                code: "scan-interval",
                title: "Bad scan interval",
                detail: "Scan interval is invalid.",
                recoveryAction: .resetMenuBarScanInterval
            ),
            SettingsValidationIssue(
                code: "second-bar-position",
                title: "Bad Second Bar position",
                detail: "Second Bar position is invalid.",
                recoveryAction: .resetSecondBarPosition
            ),
            SettingsValidationIssue(
                code: "accessibility-permission-status",
                title: "Bad permission status",
                detail: "Permission status is invalid.",
                recoveryAction: .refreshAccessibilityPermissionStatus
            )
        ]

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.first { $0.code == "settings.expanded-separator-length" }?.recoveryAction == .resetSeparatorLengths)
        #expect(report.issues.first { $0.code == "settings.scan-interval" }?.recoveryAction == .resetMenuBarScanInterval)
        #expect(report.issues.first { $0.code == "settings.second-bar-position" }?.recoveryAction == .resetSecondBarPosition)
        #expect(report.issues.first { $0.code == "settings.accessibility-permission-status" }?.recoveryAction == .refreshAccessibilityPermissionStatus)
        #expect(report.issues.allSatisfy { $0.recoveryAction != .resetSettingsToDefaults })
    }

    @Test func unknownSettingsIssueHasNoAutomaticRecoveryAction() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.settingsIssues = [
            SettingsValidationIssue(
                code: "future-setting-code",
                title: "Future setting issue",
                detail: "This issue code is not known to this build."
            )
        ]

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.contains { $0.code == "settings.future-setting-code" && $0.recoveryAction == nil })
        #expect(report.issues.allSatisfy { $0.recoveryAction != .resetSettingsToDefaults })
    }

    @Test func staleAXScanDetectedWhenProModeEnabled() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 120) })
        var snapshot = Self.healthySnapshot()
        snapshot.proModeEnabled = true
        snapshot.accessibilityDiscoveryEnabled = true
        snapshot.accessibilityPermissionStatus = .granted
        snapshot.lastMenuBarScanTime = Date(timeIntervalSince1970: 0)
        snapshot.axScanStaleThreshold = 60

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.status == .warning)
        #expect(report.issues.contains { $0.code == "pro.ax-scan-stale" })
    }

    @Test func missingProPermissionRefreshesStatusWithoutDisablingProMode() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.proModeEnabled = true
        snapshot.accessibilityDiscoveryEnabled = true
        snapshot.accessibilityPermissionStatus = .denied

        let report = service.makeReport(snapshot: snapshot)

        let issue = report.issues.first { $0.code == "pro.permission-unavailable" }
        #expect(report.status == .warning)
        #expect(issue?.recoveryAction == .refreshAccessibilityPermissionStatus)
        #expect(report.issues.allSatisfy { $0.recoveryAction != .disableProMode })
    }

    @Test func repeatedAXFailuresCanStillDisableProMode() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.proModeEnabled = true
        snapshot.accessibilityDiscoveryEnabled = true
        snapshot.accessibilityPermissionStatus = .granted
        snapshot.menuBarScanFailuresCount = 3

        let report = service.makeReport(snapshot: snapshot)

        let issue = report.issues.first { $0.code == "pro.repeated-ax-failures" }
        #expect(report.status == .critical)
        #expect(issue?.recoveryAction == .disableProMode)
    }

    @Test func workspacePreviewRuntimeIssuesAreRecoverable() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.functionBarVisible = true
        snapshot.functionBarPreviewEnabled = false
        snapshot.infoStripVisible = true
        snapshot.infoStripPreviewEnabled = false

        var report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.first { $0.code == "workspace.function-bar.visible-while-disabled" }?.recoveryAction == .disableFunctionBarPreview)
        #expect(report.issues.first { $0.code == "workspace.info-strip.visible-while-disabled" }?.recoveryAction == .hideInfoStrip)

        snapshot.functionBarPreviewEnabled = true
        snapshot.infoStripPreviewEnabled = true
        snapshot.safeModeActive = true
        report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.first { $0.code == "workspace.function-bar.visible-in-safe-mode" }?.recoveryAction == .hideFunctionBar)
        #expect(report.issues.first { $0.code == "workspace.info-strip.visible-in-safe-mode" }?.recoveryAction == .hideInfoStrip)
    }

    @Test func infoStripHealthIssuesUseTargetedRecovery() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.infoStripPreviewEnabled = true
        snapshot.infoStripSelectedTileProviderCount = 2
        snapshot.infoStripAvailableSelectedTileProviderCount = 0
        snapshot.infoStripInvalidProviderIDCount = 1
        snapshot.infoStripPlacementFailed = true
        snapshot.infoStripTimingInvalid = true

        var report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.first { $0.code == "workspace.info-strip.invalid-provider-ids" }?.recoveryAction == .clearInvalidInfoStripProviders)
        #expect(report.issues.first { $0.code == "workspace.info-strip.no-available-selected-providers" }?.recoveryAction == .resetInfoStripSettings)
        #expect(report.issues.first { $0.code == "workspace.info-strip.placement-failing" }?.recoveryAction == .resetInfoStripPlacement)
        #expect(report.issues.first { $0.code == "workspace.info-strip.timing-invalid" }?.recoveryAction == .resetInfoStripSettings)

        snapshot.infoStripAvailableSelectedTileProviderCount = 1
        snapshot.infoStripInvalidProviderIDCount = 0
        snapshot.infoStripPlacementFailed = false
        snapshot.infoStripTimingInvalid = false
        snapshot.infoStripRotationResult = "empty"
        report = service.makeReport(snapshot: snapshot)

        #expect(report.issues.first { $0.code == "workspace.info-strip.rotation-failing" }?.recoveryAction == .resetInfoStripSettings)
    }

    @Test func workspaceStoreIssuesAreWarningsAndKeepBasicModeRecoverable() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.workspaceStoreLoadStatus = .corruptedBackupCreated
        snapshot.workspaceValidationIssueCount = 2
        snapshot.workspaceMissingGroupReferenceCount = 1
        snapshot.workspaceMissingProfileBindingCount = 1

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.status == .warning)
        #expect(report.issues.first { $0.code == "workspace.store.corrupted-reset" }?.recoveryAction == .resetWorkspacesToDefaults)
        #expect(report.issues.contains { $0.code == "workspace.validation.issues" })
        #expect(report.issues.first { $0.code == "workspace.references.missing-groups" }?.recoveryAction == .removeMissingWorkspaceGroupReferences)
        #expect(report.issues.contains { $0.code == "workspace.references.missing-profiles" })
        #expect(!report.issues.contains { $0.severity == .critical })
    }

    @Test func workspaceReferenceIssuesIncludeDetachedSourcesAndUnresolvedProxies() {
        let service = HealthService(now: { Date(timeIntervalSince1970: 10) })
        var snapshot = Self.healthySnapshot()
        snapshot.workspaceDetachedSourceGroupMissingCount = 1
        snapshot.workspaceUnresolvedMenuBarProxyReferenceCount = 2

        let report = service.makeReport(snapshot: snapshot)

        #expect(report.status == .warning)
        #expect(report.issues.first { $0.code == "workspace.references.detached-source-missing" }?.recoveryAction == nil)
        #expect(report.issues.first { $0.code == "workspace.references.unresolved-menu-bar-proxies" }?.recoveryAction == .resetCurrentWorkspaceLayout)
        #expect(!report.issues.contains { $0.severity == .critical })
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
            autoRehideEnabled: true,
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
