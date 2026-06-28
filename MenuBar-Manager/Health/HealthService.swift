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
}

struct HealthService {
    var now: () -> Date = { Date() }

    func makeReport(snapshot: HealthCheckSnapshot) -> HealthReport {
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

        return HealthReport(generatedAt: now(), issues: issues)
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
                    title: "Accessibility Discovery is enabled without Pro Mode",
                    detail: "Discovery depends on Pro Mode and should be disabled when Pro Mode is off.",
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
                    title: "Pro Mode permission is unavailable",
                    detail: "Pro Mode discovery is enabled, but Accessibility permission is \(snapshot.accessibilityPermissionStatus.displayName).",
                    recoveryAction: .disableProMode
                )
            )
        }

        if proDiscoveryEnabled && snapshot.menuBarScanFailuresCount >= 3 {
            issues.append(
                HealthIssue(
                    code: "pro.repeated-ax-failures",
                    severity: .critical,
                    title: "Pro Mode scans are repeatedly failing",
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
                    detail: "Pro Mode is enabled, but no Accessibility scan has completed.",
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

    private func enabledText(_ value: Bool) -> String {
        value ? "enabled" : "disabled"
    }

    private static func isSaneSeparatorLength(_ length: Double) -> Bool {
        length.isFinite
            && length > 0
            && length <= AppConstants.collapsedSeparatorMaximumLength * 1.25
    }
}
