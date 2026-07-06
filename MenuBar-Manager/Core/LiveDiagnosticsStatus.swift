import Foundation
import Observation

enum MenuBarScanLifecycleState: String {
    case idle = "Idle"
    case requested = "Requested"
    case running = "Running"
    case completed = "Completed"
    case skipped = "Skipped"
}

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
    var menuBarScanLifecycleState: MenuBarScanLifecycleState = .idle
    var menuBarScanLastReason: String? = nil
    var menuBarScanLastSkipReason: String? = nil
    var scannedMenuBarItems: [MenuBarItemSnapshot] = []
    var lastMenuBarScanTime: Date? = nil
    var menuBarScanFailuresCount: Int = 0
    var menuBarScanVisibleCount: Int = 0
    var menuBarScanHiddenCount: Int = 0
    var menuBarScanAlwaysHiddenCount: Int = 0
    var menuBarScanUnknownCount: Int = 0
    var menuBarScanFailureSummary: String? = nil
    var newMenuBarItemReviewCount: Int = 0
    var searchIndexItemCount: Int = 0
    var searchLastResultCount: Int = 0
    var searchIndexRebuildDurationMilliseconds: Double? = nil
    var searchRankingDurationMilliseconds: Double? = nil
    var searchPanelOpenDurationMilliseconds: Double? = nil
    var searchLatestScanAgeSeconds: Double? = nil
    var lastSearchActivationOutcome: String? = nil
    var secondBarVisible: Bool = false
    var secondBarItemCount: Int = 0
    var secondBarCurrentScreen: String? = nil
    var secondBarLastPosition: String? = nil
    var secondBarIconWarmUpInProgress: Bool = false
    var secondBarLastIconWarmUpResult: String? = nil
    var secondBarLastCompactVisibleItemCount: Int = 0
    var secondBarLastCompactOverflowItemCount: Int = 0
    var secondBarLastCompactFallbackIconCount: Int = 0
    var secondBarLastCompactScanState: String? = nil
    var secondBarLastCompactAvoidedNotch: Bool? = nil
    var secondBarLastActivationResult: String? = nil
    var secondBarLastActivationMatrixResult: String? = nil
    var secondBarLastActivationTargetZone: String? = nil
    var secondBarLastActivationVisitedElementCount: Int? = nil
    var secondBarLastActivationAXError: String? = nil
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

    func applyRuntimeState(_ state: LiveDiagnosticsRuntimeState) {
        setIfChanged(\.visibilityState, to: state.visibilityState)
        setIfChanged(\.primarySeparatorLength, to: state.primarySeparatorLength)
        setIfChanged(\.alwaysHiddenSeparatorLength, to: state.alwaysHiddenSeparatorLength)
        setIfChanged(\.alwaysHiddenSeparatorInstalled, to: state.alwaysHiddenSeparatorInstalled)
        setIfChanged(\.hotkeyRegistered, to: state.hotkeyRegistered)
        setIfChanged(\.searchHotkeyRegistered, to: state.searchHotkeyRegistered)
        setIfChanged(\.hoverPollingActive, to: state.hoverPollingActive)
        setIfChanged(\.autoRehideScheduled, to: state.autoRehideScheduled)
        setIfChanged(\.lastRehideReason, to: state.lastRehideReason)
        setIfChanged(\.accessibilityPermissionStatus, to: state.accessibilityPermissionStatus)
        setIfChanged(\.automationPaused, to: state.automationPaused)
    }

    func updateSearchIndexItemCount(_ count: Int) {
        setIfChanged(\.searchIndexItemCount, to: count)
    }

    func updateSearchPerformance(_ performance: SearchPerformanceDiagnostics) {
        setIfChanged(\.searchIndexItemCount, to: performance.indexItemCount)
        setIfChanged(\.searchLastResultCount, to: performance.resultCount)
        setIfChanged(\.searchIndexRebuildDurationMilliseconds, to: performance.indexRebuildDurationMilliseconds)
        setIfChanged(\.searchRankingDurationMilliseconds, to: performance.rankingDurationMilliseconds)
        setIfChanged(\.searchLatestScanAgeSeconds, to: performance.latestScanAgeSeconds)
    }

    func updateSearchPanelOpenDuration(milliseconds: Double) {
        setIfChanged(\.searchPanelOpenDurationMilliseconds, to: milliseconds)
    }

    func updateNewMenuBarItemReviewCount(_ count: Int) {
        setIfChanged(\.newMenuBarItemReviewCount, to: count)
    }

    func updateSecondBarItemCount(_ count: Int) {
        setIfChanged(\.secondBarItemCount, to: count)
    }

    func updateSecondBarIconWarmUp(
        inProgress: Bool,
        result: String?
    ) {
        setIfChanged(\.secondBarIconWarmUpInProgress, to: inProgress)
        if let result {
            setIfChanged(\.secondBarLastIconWarmUpResult, to: result)
        }
    }

    func updateSecondBarCompactStrip(plan: SecondBarCompactStripPlan) {
        setIfChanged(\.secondBarLastCompactVisibleItemCount, to: plan.visibleItems.count)
        setIfChanged(\.secondBarLastCompactOverflowItemCount, to: plan.hiddenOverflowCount)
        setIfChanged(\.secondBarLastCompactFallbackIconCount, to: plan.needsAccurateIconCount)
        setIfChanged(\.secondBarLastCompactScanState, to: plan.scanState.diagnosticsLabel)
    }

    func updateSecondBarCompactPlacement(avoidedNotch: Bool) {
        setIfChanged(\.secondBarLastCompactAvoidedNotch, to: avoidedNotch)
    }

    func updateSecondBarDirectActivation(
        result: MenuBarItemDirectActivationResult,
        targetZone: MenuBarZone
    ) {
        setIfChanged(\.secondBarLastActivationResult, to: result.status.rawValue)
        setIfChanged(\.secondBarLastActivationMatrixResult, to: result.matrixOutcome.rawValue)
        setIfChanged(\.secondBarLastActivationTargetZone, to: targetZone.rawValue)
        setIfChanged(\.secondBarLastActivationVisitedElementCount, to: result.visitedElementCount)
        setIfChanged(\.secondBarLastActivationAXError, to: result.axErrorDescription)
    }

    func updateSearchAndSecondBarItemCounts(_ counts: LiveDiagnosticsMenuBarItemCounts) {
        updateSearchIndexItemCount(counts.searchIndexItemCount)
        updateSecondBarItemCount(counts.secondBarItemCount)
    }

    func updateStatusBarVisibility(
        state: HidingVisibilityState,
        primarySeparatorLength: Double,
        alwaysHiddenSeparatorLength: Double,
        alwaysHiddenSeparatorInstalled: Bool
    ) {
        setIfChanged(\.visibilityState, to: state)
        setIfChanged(\.primarySeparatorLength, to: primarySeparatorLength)
        setIfChanged(\.alwaysHiddenSeparatorLength, to: alwaysHiddenSeparatorLength)
        setIfChanged(\.alwaysHiddenSeparatorInstalled, to: alwaysHiddenSeparatorInstalled)
    }

    private func setIfChanged<Value: Equatable>(
        _ keyPath: ReferenceWritableKeyPath<LiveDiagnosticsStatus, Value>,
        to value: Value
    ) {
        guard self[keyPath: keyPath] != value else { return }
        self[keyPath: keyPath] = value
    }
}

nonisolated struct SearchPerformanceDiagnostics: Equatable, Sendable {
    let indexItemCount: Int
    let resultCount: Int
    let indexRebuildDurationMilliseconds: Double?
    let rankingDurationMilliseconds: Double?
    let latestScanAgeSeconds: Double?
}

struct LiveDiagnosticsRuntimeState: Equatable {
    let visibilityState: HidingVisibilityState
    let primarySeparatorLength: Double
    let alwaysHiddenSeparatorLength: Double
    let alwaysHiddenSeparatorInstalled: Bool
    let hotkeyRegistered: Bool
    let searchHotkeyRegistered: Bool
    let hoverPollingActive: Bool
    let autoRehideScheduled: Bool
    let lastRehideReason: String?
    let accessibilityPermissionStatus: AccessibilityPermissionStatus
    let automationPaused: Bool
}

struct LiveDiagnosticsMenuBarItemCounts: Equatable {
    let searchIndexItemCount: Int
    let secondBarItemCount: Int

    static func counts(
        from snapshots: [MenuBarItemSnapshot],
        includeHiddenInSecondBar: Bool,
        includeAlwaysHiddenInSecondBar: Bool
    ) -> LiveDiagnosticsMenuBarItemCounts {
        var secondBarItemCount = 0

        for snapshot in snapshots where snapshot.isVisibleInSecondBar(
            includeHidden: includeHiddenInSecondBar,
            includeAlwaysHidden: includeAlwaysHiddenInSecondBar
        ) {
            secondBarItemCount += 1
        }

        return LiveDiagnosticsMenuBarItemCounts(
            searchIndexItemCount: snapshots.count,
            secondBarItemCount: secondBarItemCount
        )
    }
}

private extension MenuBarItemSnapshot {
    func isVisibleInSecondBar(
        includeHidden: Bool,
        includeAlwaysHidden: Bool
    ) -> Bool {
        switch zone {
        case .hidden:
            return includeHidden
        case .alwaysHidden:
            return includeAlwaysHidden
        case .visible, .unknown:
            return false
        }
    }
}
