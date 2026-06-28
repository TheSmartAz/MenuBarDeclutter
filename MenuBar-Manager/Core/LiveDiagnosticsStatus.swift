import Foundation
import Observation

/// Live snapshot of state surfaced in the Diagnostics view. Owned by
/// `AppEnvironment` and updated by the relevant services so the Settings UI
/// can show runtime state without reaching into each service directly.
@MainActor
@Observable
final class LiveDiagnosticsStatus {
    var visibilityState: HidingVisibilityState = .expanded
    var primarySeparatorLength: Double = 0
    var alwaysHiddenSeparatorLength: Double = 0
    var alwaysHiddenSeparatorInstalled: Bool = false
    var hotkeyRegistered: Bool = false
    var searchHotkeyRegistered: Bool = false
    var hoverPollingActive: Bool = false
    var autoRehideScheduled: Bool = false
    var lastRehideReason: String? = nil
    var accessibilityPermissionStatus: AccessibilityPermissionStatus = .notRequested
    var scannedMenuBarItems: [MenuBarItemSnapshot] = []
    var lastMenuBarScanTime: Date? = nil
    var menuBarScanFailuresCount: Int = 0
    var menuBarScanVisibleCount: Int = 0
    var menuBarScanHiddenCount: Int = 0
    var menuBarScanAlwaysHiddenCount: Int = 0
    var menuBarScanUnknownCount: Int = 0
    var searchIndexItemCount: Int = 0
    var lastSearchQuery: String = ""
    var lastSearchSelectedItem: String? = nil
    var lastSearchActivationOutcome: String? = nil
    var secondBarVisible: Bool = false
    var secondBarItemCount: Int = 0
    var secondBarCurrentScreen: String? = nil
    var secondBarLastPosition: String? = nil
    var lastSecondBarSelectedItem: String? = nil
    var iconMoveInProgress: Bool = false
    var lastIconMoveResult: String? = nil
    var lastIconMoveError: String? = nil
    var lastIconMoveDragPlanSummary: String? = nil
    var lastIconMoveVerificationSummary: String? = nil
    var lastIconMoveRetriesCount: Int = 0
    var activeProfileID: String? = nil
    var activeProfileName: String? = nil
    var lastTriggerFired: String? = nil
    var triggerEvaluationLog: String = ""
    var lastProfileApplyLog: String = ""
    var automationPaused: Bool = false
    var healthReport: HealthReport? = nil
    var safeModeActive: Bool = false
    var safeModeReasonSummary: String = "Inactive"

    init() {}
}
