import Foundation

struct SettingsValidationIssue: Equatable, Sendable {
    let code: String
    let title: String
    let detail: String
    let severity: HealthSeverity
    let recoveryAction: HealthRecoveryAction?

    init(
        code: String,
        title: String,
        detail: String,
        severity: HealthSeverity = .warning,
        recoveryAction: HealthRecoveryAction? = nil
    ) {
        self.code = code
        self.title = title
        self.detail = detail
        self.severity = severity
        self.recoveryAction = recoveryAction
    }
}

struct HealthCheckSnapshot: Equatable, Sendable {
    var controlItemExists: Bool
    var primarySeparatorExpected: Bool
    var primarySeparatorExists: Bool
    var alwaysHiddenEnabled: Bool
    var alwaysHiddenSeparatorExists: Bool
    var primarySeparatorLength: Double
    var alwaysHiddenSeparatorLength: Double
    var widestScreenWidth: Double
    var screenCount: Int
    var settingsIssues: [SettingsValidationIssue]
    var globalHotkeyEnabled: Bool
    var globalHotkeyRegistered: Bool
    var searchHotkeyEnabled: Bool
    var searchHotkeyRegistered: Bool
    var autoRehideEnabled: Bool
    var autoRehideScheduled: Bool
    var visibilityState: HidingVisibilityState
    var hoverRevealEnabled: Bool
    var hoverRevealPollingActive: Bool
    var proModeEnabled: Bool
    var accessibilityDiscoveryEnabled: Bool
    var accessibilityPermissionStatus: AccessibilityPermissionStatus
    var lastMenuBarScanTime: Date?
    var menuBarScanFailuresCount: Int
    var axScanStaleThreshold: TimeInterval
    var layoutFeaturesEnabled: Bool = true
    var fullMenuBarModeActive: Bool = false
    var spacerItemsEnabled: Bool = true
    var spacerItemCount: Int = 0
    var visibleSpacerItemCount: Int = 0
    var groupsEnabled: Bool = true
    var groupCount: Int = 0
    var protectedGroupCount: Int = 0
    var duplicateGroupNames: Bool = false
    var groupStatusItemsEnabled: Bool = false
    var groupStatusItemCount: Int = 0
    var dynamicHotkeysEnabled: Bool = false
    var dynamicHotkeyBindingCount: Int = 0
    var dynamicHotkeyRegisteredCount: Int = 0
    var dynamicHotkeyConflictCount: Int = 0
    var privateAccessEnabled: Bool = false
    var privateAccessUnlockActive: Bool = false
    var appIntentsEnabled: Bool = true
    var safeModeActive: Bool = false
    var functionBarPreviewEnabled: Bool = false
    var functionBarVisible: Bool = false
    var infoStripPreviewEnabled: Bool = false
    var infoStripVisible: Bool = false
    var infoStripSelectedTileProviderCount: Int = 0
    var infoStripAvailableSelectedTileProviderCount: Int = 0
    var infoStripInvalidProviderIDCount: Int = 0
    var infoStripRotationResult: String? = nil
    var infoStripPlacementFailed: Bool = false
    var infoStripTimingInvalid: Bool = false
    var workspaceStoreLoadStatus: WorkspaceStoreLoadStatus = .notLoaded
    var workspaceValidationIssueCount: Int = 0
    var workspaceMissingGroupReferenceCount: Int = 0
    var workspaceDetachedSourceGroupMissingCount: Int = 0
    var workspaceUnresolvedMenuBarProxyReferenceCount: Int = 0
    var workspaceMissingProfileBindingCount: Int = 0
}

struct HealthService {
    var now: () -> Date = { Date() }

    func makeReport(snapshot: HealthCheckSnapshot, dogfoodRunID: String? = nil) -> HealthReport {
        var issues: [HealthIssue] = []

        if !snapshot.controlItemExists {
            issues.append(
                HealthIssue(
                    code: "status.control.missing",
                    severity: .critical,
                    title: "Control item is missing",
                    detail: "The menu bar control item is not installed, so the app cannot expose repair actions from the menu bar.",
                    recoveryAction: .recreateStatusItems
                )
            )
        }

        if snapshot.primarySeparatorExpected && !snapshot.primarySeparatorExists {
            issues.append(
                HealthIssue(
                    code: "status.primary-separator.missing",
                    severity: .critical,
                    title: "Primary separator is missing",
                    detail: "The primary separator item should be installed for the current settings but is absent.",
                    recoveryAction: .recreateStatusItems
                )
            )
        }

        if snapshot.alwaysHiddenEnabled && !snapshot.alwaysHiddenSeparatorExists {
            issues.append(
                HealthIssue(
                    code: "status.always-hidden-separator.missing",
                    severity: .critical,
                    title: "Always-hidden separator is missing",
                    detail: "Always-hidden mode is enabled, but the always-hidden separator item is not installed.",
                    recoveryAction: .recreateStatusItems
                )
            )
        }

        appendSeparatorLengthIssue(
            ifNeededFor: "primary",
            length: snapshot.primarySeparatorLength,
            isInstalled: snapshot.primarySeparatorExists,
            issues: &issues
        )
        appendSeparatorLengthIssue(
            ifNeededFor: "always-hidden",
            length: snapshot.alwaysHiddenSeparatorLength,
            isInstalled: snapshot.alwaysHiddenSeparatorExists,
            issues: &issues
        )

        if snapshot.screenCount <= 0 || !snapshot.widestScreenWidth.isFinite || snapshot.widestScreenWidth <= 0 {
            issues.append(
                HealthIssue(
                    code: "screen.geometry.invalid",
                    severity: .critical,
                    title: "Screen geometry is invalid",
                    detail: "No valid screen width is available for separator placement.",
                    recoveryAction: .expandAll
                )
            )
        }

        for settingsIssue in snapshot.settingsIssues {
            issues.append(
                HealthIssue(
                    code: "settings.\(settingsIssue.code)",
                    severity: settingsIssue.severity,
                    title: settingsIssue.title,
                    detail: settingsIssue.detail,
                    recoveryAction: settingsIssue.recoveryAction
                )
            )
        }

        if snapshot.globalHotkeyEnabled != snapshot.globalHotkeyRegistered {
            issues.append(
                HealthIssue(
                    code: "hotkey.visibility.registration-mismatch",
                    severity: .warning,
                    title: "Visibility hotkey state does not match settings",
                    detail: "The visibility hotkey setting is \(enabledText(snapshot.globalHotkeyEnabled)), but runtime registration is \(enabledText(snapshot.globalHotkeyRegistered)).",
                    recoveryAction: nil
                )
            )
        }

        if snapshot.searchHotkeyEnabled != snapshot.searchHotkeyRegistered {
            issues.append(
                HealthIssue(
                    code: "hotkey.search.registration-mismatch",
                    severity: .warning,
                    title: "Find Icon hotkey state does not match settings",
                    detail: "The Find Icon hotkey setting is \(enabledText(snapshot.searchHotkeyEnabled)), but runtime registration is \(enabledText(snapshot.searchHotkeyRegistered)).",
                    recoveryAction: nil
                )
            )
        }

        if !snapshot.autoRehideEnabled && snapshot.autoRehideScheduled {
            issues.append(
                HealthIssue(
                    code: "rehide.disabled-but-scheduled",
                    severity: .warning,
                    title: "Auto-rehide is scheduled while disabled",
                    detail: "A runtime auto-rehide countdown is active even though the setting is disabled.",
                    recoveryAction: .disableAutoRehideTemporarily
                )
            )
        } else if snapshot.visibilityState.isCollapsed && snapshot.autoRehideScheduled {
            issues.append(
                HealthIssue(
                    code: "rehide.scheduled-while-collapsed",
                    severity: .warning,
                    title: "Auto-rehide timer is stuck",
                    detail: "Auto-rehide should not remain scheduled while the menu bar is already collapsed.",
                    recoveryAction: .disableAutoRehideTemporarily
                )
            )
        }

        if !snapshot.hoverRevealEnabled && snapshot.hoverRevealPollingActive {
            issues.append(
                HealthIssue(
                    code: "hover.disabled-but-polling",
                    severity: .warning,
                    title: "Hover reveal is polling while disabled",
                    detail: "The hover reveal timer is active even though the setting is disabled.",
                    recoveryAction: .disableHoverRevealTemporarily
                )
            )
        }

        appendProModeIssues(snapshot: snapshot, issues: &issues)
        appendLayoutIssues(snapshot: snapshot, issues: &issues)
        appendPhase11Issues(snapshot: snapshot, issues: &issues)
        appendWorkspacePreviewIssues(snapshot: snapshot, issues: &issues)

        return HealthReport(generatedAt: now(), issues: issues, dogfoodRunID: dogfoodRunID)
    }

    static func validateSettings(_ store: SettingsStore) -> [SettingsValidationIssue] {
        var issues: [SettingsValidationIssue] = []

        if !store.expandedSeparatorLength.isFinite || store.expandedSeparatorLength <= 0 {
            issues.append(
                SettingsValidationIssue(
                    code: "expanded-separator-length",
                    title: "Expanded separator length is corrupted",
                    detail: "Expanded separator length must be a positive finite number.",
                    severity: .critical,
                    recoveryAction: .resetSeparatorLengths
                )
            )
        }

        if let override = store.collapsedSeparatorLengthOverride,
           !isSaneSeparatorLength(override) {
            issues.append(
                SettingsValidationIssue(
                    code: "collapsed-separator-override",
                    title: "Collapsed separator override is corrupted",
                    detail: "Collapsed separator override must be finite and within the supported status item range.",
                    severity: .critical,
                    recoveryAction: .resetSeparatorLengths
                )
            )
        }

        if !store.menuBarScanIntervalSeconds.isFinite {
            issues.append(
                SettingsValidationIssue(
                    code: "scan-interval",
                    title: "Menu bar scan interval is corrupted",
                    detail: "The Accessibility scan interval must be finite.",
                    recoveryAction: .resetMenuBarScanInterval
                )
            )
        }

        if SecondBarPositionMode(rawValue: store.secondBarPositionModeRaw) == nil {
            issues.append(
                SettingsValidationIssue(
                    code: "second-bar-position",
                    title: "Second Bar position setting is corrupted",
                    detail: "The stored Second Bar position mode is not recognized.",
                    recoveryAction: .resetSecondBarPosition
                )
            )
        }

        if let status = store.lastAccessibilityPermissionStatus,
           AccessibilityPermissionStatus(rawValue: status) == nil {
            issues.append(
                SettingsValidationIssue(
                    code: "accessibility-permission-status",
                    title: "Accessibility permission status is corrupted",
                    detail: "The stored Accessibility permission status is not recognized.",
                    recoveryAction: .refreshAccessibilityPermissionStatus
                )
            )
        }

        return issues
    }

    private func appendSeparatorLengthIssue(
        ifNeededFor name: String,
        length: Double,
        isInstalled: Bool,
        issues: inout [HealthIssue]
    ) {
        guard isInstalled else { return }
        guard Self.isSaneSeparatorLength(length) else {
            issues.append(
                HealthIssue(
                    code: "status.\(name)-separator.length-invalid",
                    severity: .critical,
                    title: "\(name.capitalized) separator length is invalid",
                    detail: "The \(name) separator length is \(length), outside the supported finite range.",
                    recoveryAction: .resetSeparatorLengths
                )
            )
            return
        }
    }

    private func appendProModeIssues(snapshot: HealthCheckSnapshot, issues: inout [HealthIssue]) {
        if !snapshot.proModeEnabled && snapshot.accessibilityDiscoveryEnabled {
            issues.append(
                HealthIssue(
                    code: "pro.discovery-enabled-without-pro",
                    severity: .warning,
                    title: "Accessibility Discovery is enabled without Optional Pro",
                    detail: "Discovery depends on Optional Pro and should be disabled when Optional Pro is off.",
                    recoveryAction: .disableProMode
                )
            )
        }

        let proDiscoveryEnabled = snapshot.proModeEnabled && snapshot.accessibilityDiscoveryEnabled
        if proDiscoveryEnabled && snapshot.accessibilityPermissionStatus != .granted {
            issues.append(
                HealthIssue(
                    code: "pro.permission-unavailable",
                    severity: .warning,
                    title: "Optional Pro permission is unavailable",
                    detail: "Optional Pro discovery is enabled, but Accessibility permission is \(snapshot.accessibilityPermissionStatus.displayName).",
                    recoveryAction: .refreshAccessibilityPermissionStatus
                )
            )
        }

        if proDiscoveryEnabled && snapshot.menuBarScanFailuresCount >= 3 {
            issues.append(
                HealthIssue(
                    code: "pro.repeated-ax-failures",
                    severity: .critical,
                    title: "Optional Pro scans are repeatedly failing",
                    detail: "The latest Accessibility scan reported \(snapshot.menuBarScanFailuresCount) failures.",
                    recoveryAction: .disableProMode
                )
            )
        }

        guard proDiscoveryEnabled,
              snapshot.accessibilityPermissionStatus == .granted else {
            return
        }

        guard let lastMenuBarScanTime = snapshot.lastMenuBarScanTime else {
            issues.append(
                HealthIssue(
                    code: "pro.ax-scan-missing",
                    severity: .warning,
                    title: "No recent Accessibility scan",
                    detail: "Optional Pro is enabled, but no Accessibility scan has completed.",
                    recoveryAction: nil
                )
            )
            return
        }

        let age = now().timeIntervalSince(lastMenuBarScanTime)
        if age > snapshot.axScanStaleThreshold {
            issues.append(
                HealthIssue(
                    code: "pro.ax-scan-stale",
                    severity: .warning,
                    title: "Accessibility scan is stale",
                    detail: "The latest Accessibility scan is older than \(Int(snapshot.axScanStaleThreshold)) seconds.",
                    recoveryAction: nil
                )
            )
        }
    }

    private func appendLayoutIssues(snapshot: HealthCheckSnapshot, issues: inout [HealthIssue]) {
        if !snapshot.layoutFeaturesEnabled && snapshot.fullMenuBarModeActive {
            issues.append(
                HealthIssue(
                    code: "layout.full-menu-bar.active-while-disabled",
                    severity: .warning,
                    title: "Full Menu Bar Mode is active while Layout is disabled",
                    detail: "Layout features are disabled, but Full Menu Bar Mode is still active.",
                    recoveryAction: .exitFullMenuBarMode
                )
            )
        }

        if !snapshot.spacerItemsEnabled && snapshot.visibleSpacerItemCount > 0 {
            issues.append(
                HealthIssue(
                    code: "layout.spacers.visible-while-disabled",
                    severity: .warning,
                    title: "Spacer items are visible while disabled",
                    detail: "Optional spacer status items should be hidden when spacer items are disabled.",
                    recoveryAction: .hideOptionalSpacerItems
                )
            )
        }
    }

    private func appendPhase11Issues(snapshot: HealthCheckSnapshot, issues: inout [HealthIssue]) {
        if snapshot.duplicateGroupNames {
            issues.append(
                HealthIssue(
                    code: "groups.duplicate-names",
                    severity: .warning,
                    title: "Duplicate group names",
                    detail: "Two or more groups have the same name. Rename one group to keep matching and import/export predictable.",
                    recoveryAction: nil
                )
            )
        }

        if !snapshot.groupsEnabled && snapshot.groupStatusItemCount > 0 {
            issues.append(
                HealthIssue(
                    code: "groups.status-items-visible-while-disabled",
                    severity: .warning,
                    title: "Group status items are visible while Groups are disabled",
                    detail: "Optional group status items should be hidden when Groups are disabled.",
                    recoveryAction: .disableGroupStatusItems
                )
            )
        }

        if snapshot.dynamicHotkeysEnabled,
           snapshot.dynamicHotkeyConflictCount > 0 {
            issues.append(
                HealthIssue(
                    code: "hotkey.dynamic.conflicts",
                    severity: .warning,
                    title: "Dynamic hotkey conflicts",
                    detail: "\(snapshot.dynamicHotkeyConflictCount) dynamic hotkey target(s) share the same key combination.",
                    recoveryAction: .disableDynamicHotkeys
                )
            )
        }

        if !snapshot.dynamicHotkeysEnabled && snapshot.dynamicHotkeyRegisteredCount > 0 {
            issues.append(
                HealthIssue(
                    code: "hotkey.dynamic.registered-while-disabled",
                    severity: .warning,
                    title: "Dynamic hotkeys registered while disabled",
                    detail: "Dynamic hotkey registrations should be cleared when the feature is disabled.",
                    recoveryAction: .disableDynamicHotkeys
                )
            )
        }

        if !snapshot.privateAccessEnabled && snapshot.privateAccessUnlockActive {
            issues.append(
                HealthIssue(
                    code: "privacy.private-access.unlock-active-while-disabled",
                    severity: .warning,
                    title: "Private Access unlock active while disabled",
                    detail: "The cached unlock session should be cleared when Private Access is disabled.",
                    recoveryAction: .clearPrivateAccessUnlock
                )
            )
        }
    }

    private func appendWorkspacePreviewIssues(snapshot: HealthCheckSnapshot, issues: inout [HealthIssue]) {
        switch snapshot.workspaceStoreLoadStatus {
        case .corruptedBackupCreated:
            issues.append(
                HealthIssue(
                    code: "workspace.store.corrupted-reset",
                    severity: .warning,
                    title: "Workspace store was reset",
                    detail: "The workspace store could not be decoded, so a backup was created and safe defaults were restored. Basic Mode remains available.",
                    recoveryAction: .resetWorkspacesToDefaults
                )
            )
        case .repaired:
            issues.append(
                HealthIssue(
                    code: "workspace.store.repaired",
                    severity: .warning,
                    title: "Workspace store was repaired",
                    detail: "Workspace data needed safe repairs before use. Basic Mode remains available.",
                    recoveryAction: nil
                )
            )
        case .failed:
            issues.append(
                HealthIssue(
                    code: "workspace.store.failed",
                    severity: .warning,
                    title: "Workspace store failed to load",
                    detail: "Workspace preview data is unavailable, but Basic Mode remains available.",
                    recoveryAction: .resetWorkspacesToDefaults
                )
            )
        case .notLoaded, .loaded, .createdDefaults:
            break
        }

        if snapshot.workspaceValidationIssueCount > 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.validation.issues",
                    severity: .warning,
                    title: "Workspace data has validation repairs",
                    detail: "\(snapshot.workspaceValidationIssueCount) workspace validation issue(s) were repaired or reported without exposing item names.",
                    recoveryAction: nil
                )
            )
        }

        if snapshot.workspaceMissingGroupReferenceCount > 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.references.missing-groups",
                    severity: .warning,
                    title: "Workspace group references are missing",
                    detail: "\(snapshot.workspaceMissingGroupReferenceCount) group reference(s) could not be resolved. The workspace remains usable.",
                    recoveryAction: .removeMissingWorkspaceGroupReferences
                )
            )
        }

        if snapshot.workspaceDetachedSourceGroupMissingCount > 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.references.detached-source-missing",
                    severity: .warning,
                    title: "Detached group source is missing",
                    detail: "\(snapshot.workspaceDetachedSourceGroupMissingCount) detached group source reference(s) could not be resolved. Detached copies remain usable.",
                    recoveryAction: nil
                )
            )
        }

        if snapshot.workspaceUnresolvedMenuBarProxyReferenceCount > 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.references.unresolved-menu-bar-proxies",
                    severity: .warning,
                    title: "Workspace menu bar proxies are unresolved",
                    detail: "\(snapshot.workspaceUnresolvedMenuBarProxyReferenceCount) menu bar proxy reference(s) did not match the latest local Accessibility snapshot.",
                    recoveryAction: .resetCurrentWorkspaceLayout
                )
            )
        }

        if snapshot.workspaceMissingProfileBindingCount > 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.references.missing-profiles",
                    severity: .warning,
                    title: "Workspace profile bindings are missing",
                    detail: "\(snapshot.workspaceMissingProfileBindingCount) profile binding(s) could not be resolved. No physical layout changes were applied.",
                    recoveryAction: nil
                )
            )
        }

        if snapshot.functionBarVisible && snapshot.safeModeActive {
            issues.append(
                HealthIssue(
                    code: "workspace.function-bar.visible-in-safe-mode",
                    severity: .warning,
                    title: "Function Bar is visible in Safe Mode",
                    detail: "Safe Mode should suppress Function Bar runtime so recovery stays simple.",
                    recoveryAction: .hideFunctionBar
                )
            )
        } else if snapshot.functionBarVisible && !snapshot.functionBarPreviewEnabled {
            issues.append(
                HealthIssue(
                    code: "workspace.function-bar.visible-while-disabled",
                    severity: .warning,
                    title: "Function Bar is visible while disabled",
                    detail: "The Function Bar preview panel is visible even though its preview setting is disabled.",
                    recoveryAction: .disableFunctionBarPreview
                )
            )
        }

        if snapshot.infoStripVisible && snapshot.safeModeActive {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.visible-in-safe-mode",
                    severity: .warning,
                    title: "Info Strip is visible in Safe Mode",
                    detail: "Safe Mode should suppress Info Strip runtime so recovery stays simple.",
                    recoveryAction: .hideInfoStrip
                )
            )
        } else if snapshot.infoStripVisible && !snapshot.infoStripPreviewEnabled {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.visible-while-disabled",
                    severity: .warning,
                    title: "Info Strip is visible while disabled",
                    detail: "The Info Strip preview panel is visible even though its preview setting is disabled.",
                    recoveryAction: .hideInfoStrip
                )
            )
        }

        guard snapshot.infoStripPreviewEnabled else { return }

        if snapshot.infoStripInvalidProviderIDCount > 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.invalid-provider-ids",
                    severity: .warning,
                    title: "Info Strip has invalid tile IDs",
                    detail: "\(snapshot.infoStripInvalidProviderIDCount) selected Info Strip tile ID(s) are no longer registered.",
                    recoveryAction: .clearInvalidInfoStripProviders
                )
            )
        }

        if snapshot.infoStripSelectedTileProviderCount > 0
            && snapshot.infoStripAvailableSelectedTileProviderCount == 0 {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.no-available-selected-providers",
                    severity: .warning,
                    title: "Info Strip has no available tiles",
                    detail: "The active workspace has selected Info Strip tiles, but none can currently produce a tile.",
                    recoveryAction: .resetInfoStripSettings
                )
            )
        } else if isInfoStripRotationFailure(
            snapshot.infoStripRotationResult,
            safeModeActive: snapshot.safeModeActive
        ) {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.rotation-failing",
                    severity: .warning,
                    title: "Info Strip rotation is not producing tiles",
                    detail: "The Info Strip runtime reported \(snapshot.infoStripRotationResult ?? "an unknown result") while preview is enabled.",
                    recoveryAction: .resetInfoStripSettings
                )
            )
        }

        if snapshot.infoStripPlacementFailed {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.placement-failing",
                    severity: .warning,
                    title: "Info Strip placement failed",
                    detail: "The Info Strip could not find a valid display placement for its preview panel.",
                    recoveryAction: .resetInfoStripPlacement
                )
            )
        }

        if snapshot.infoStripTimingInvalid {
            issues.append(
                HealthIssue(
                    code: "workspace.info-strip.timing-invalid",
                    severity: .warning,
                    title: "Info Strip timing is invalid",
                    detail: "The active workspace has Info Strip idle or rotation timing outside the supported range.",
                    recoveryAction: .resetInfoStripSettings
                )
            )
        }
    }

    private func enabledText(_ value: Bool) -> String {
        value ? "enabled" : "disabled"
    }

    private func isInfoStripRotationFailure(_ result: String?, safeModeActive: Bool) -> Bool {
        guard let result else { return false }
        return result == "empty" || (result == "safeMode" && !safeModeActive)
    }

    private static func isSaneSeparatorLength(_ length: Double) -> Bool {
        length.isFinite
            && length > 0
            && length <= AppConstants.collapsedSeparatorMaximumLength * 1.25
    }
}
