import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("ProSecondBarCompactStrip")
@MainActor
struct ProSecondBarCompactStripTests {
    @Test func readinessRequiresEntitlementAccessibilityAndAccurateIcons() {
        var input = ProSecondBarReadinessInput(
            entitlement: .basic,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermission: .granted,
            accurateIconsEnabled: true,
            screenCapturePermission: .granted
        )

        #expect(ProSecondBarReadiness.evaluate(input).state == .missingEntitlement)

        input.entitlement = .licensed
        input.accessibilityDiscoveryEnabled = false
        #expect(ProSecondBarReadiness.evaluate(input).state == .accessibilityDiscoveryDisabled)

        input.accessibilityDiscoveryEnabled = true
        input.accessibilityPermission = .denied
        #expect(ProSecondBarReadiness.evaluate(input).state == .accessibilityPermissionMissing)

        input.accessibilityPermission = .granted
        input.accurateIconsEnabled = false
        #expect(ProSecondBarReadiness.evaluate(input).state == .accurateIconsDisabled)

        input.accurateIconsEnabled = true
        input.screenCapturePermission = .notGranted
        #expect(ProSecondBarReadiness.evaluate(input).state == .screenRecordingMissing)

        input.screenCapturePermission = .granted
        #expect(ProSecondBarReadiness.evaluate(input).state == .ready)
    }

    @Test func primaryClickRequiresExplicitSecondBarOptInBeforeUsingCompactStrip() {
        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .basic,
            readiness: .missingEntitlement,
            primaryClickOptIn: true,
            safeModeActive: false
        ) == .toggleInlineVisibility)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .licensed,
            readiness: .ready,
            primaryClickOptIn: false,
            safeModeActive: false
        ) == .toggleInlineVisibility)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .licensed,
            readiness: .ready,
            primaryClickOptIn: true,
            safeModeActive: false
        ) == .toggleCompactStrip)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .trialActive(expiration: Date(timeIntervalSince1970: 100)),
            readiness: .screenRecordingMissing,
            primaryClickOptIn: true,
            safeModeActive: false
        ) == .showSecondBarRequirements)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .trialActive(expiration: Date(timeIntervalSince1970: 100)),
            readiness: .screenRecordingMissing,
            primaryClickOptIn: false,
            safeModeActive: false
        ) == .toggleInlineVisibility)
    }

    @Test func primaryClickRoutesSafeModeToInlineEvenWhenReadyAndOptedIn() {
        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .licensed,
            readiness: .ready,
            primaryClickOptIn: true,
            safeModeActive: true
        ) == .toggleInlineVisibility)
    }

    @Test func compactStripIncludesHiddenItemsEvenWhenAccurateIconsAreNotReady() {
        let snapshots = [
            snapshot("visible", zone: .visible),
            snapshot("hidden-a", zone: .hidden),
            snapshot("always", zone: .alwaysHidden),
            snapshot("hidden-b", zone: .hidden),
            snapshot("hidden-c", zone: .hidden)
        ]
        let plan = SecondBarCompactStripPlanner.plan(
            snapshots: snapshots,
            accurateIconReadyIDs: ["hidden-a", "hidden-c"],
            maxVisibleItems: 8
        )

        #expect(plan.visibleItems.map(\.id) == ["hidden-a", "hidden-b", "hidden-c"])
        #expect(plan.hiddenOverflowCount == 0)
        #expect(plan.needsAccurateIconCount == 1)
        #expect(plan.totalAdditionalCount == 0)
        #expect(plan.scanState == .fresh)
    }

    @Test func compactStripFiltersToRightSideHiddenItemsOnNotchedScreen() {
        let screen = screen(
            notchAvoidanceRect: CGRect(x: 600, y: 875, width: 240, height: 25)
        )
        let snapshots = [
            snapshot("app-menu-left", zone: .hidden, frame: CGRect(x: 120, y: 876, width: 64, height: 22)),
            snapshot("notch-left", zone: .hidden, frame: CGRect(x: 700, y: 876, width: 24, height: 22)),
            snapshot("visible-right", zone: .visible, frame: CGRect(x: 900, y: 876, width: 24, height: 22)),
            snapshot("system-right", zone: .hidden, frame: CGRect(x: 940, y: 876, width: 24, height: 22), isLikelySystemItem: true),
            snapshot("hidden-right-a", zone: .hidden, frame: CGRect(x: 880, y: 876, width: 24, height: 22)),
            snapshot("hidden-right-b", zone: .hidden, frame: CGRect(x: 980, y: 876, width: 30, height: 22)),
            snapshot("always-right", zone: .alwaysHidden, frame: CGRect(x: 1020, y: 876, width: 24, height: 22))
        ]

        let candidates = SecondBarCompactStripPlanner.compactItemCandidates(
            snapshots: snapshots,
            screen: screen
        )

        #expect(candidates.map(\.id) == ["hidden-right-a", "hidden-right-b"])
    }

    @Test func compactStripUsesRightHalfFallbackWhenScreenHasNoNotch() {
        let screen = screen()
        let snapshots = [
            snapshot("left-hidden", zone: .hidden, frame: CGRect(x: 300, y: 876, width: 24, height: 22)),
            snapshot("right-hidden", zone: .hidden, frame: CGRect(x: 1000, y: 876, width: 24, height: 22))
        ]

        let candidates = SecondBarCompactStripPlanner.compactItemCandidates(
            snapshots: snapshots,
            screen: screen
        )

        #expect(candidates.map(\.id) == ["right-hidden"])
    }

    @Test func compactStripAcceptsTopOriginRightSideMenuBarFrames() {
        let screen = screen(
            notchAvoidanceRect: CGRect(x: 740, y: 875, width: 248, height: 25)
        )
        let snapshots = [
            snapshot("top-origin-left", zone: .hidden, frame: CGRect(x: 650, y: 4, width: 24, height: 22)),
            snapshot("top-origin-right", zone: .hidden, frame: CGRect(x: 1122, y: 4, width: 24, height: 22)),
            snapshot("not-menu-bar", zone: .hidden, frame: CGRect(x: 1160, y: 300, width: 24, height: 22))
        ]

        let candidates = SecondBarCompactStripPlanner.compactItemCandidates(
            snapshots: snapshots,
            screen: screen
        )

        #expect(candidates.map(\.id) == ["top-origin-right"])
    }

    @Test func compactStripCapacityUsesOriginalMenuBarItemWidths() {
        let screen = screen()
        let snapshots = [
            snapshot("narrow", zone: .hidden, frame: CGRect(x: 900, y: 876, width: 20, height: 22)),
            snapshot("wide", zone: .hidden, frame: CGRect(x: 940, y: 876, width: 72, height: 22)),
            snapshot("overflow", zone: .hidden, frame: CGRect(x: 1040, y: 876, width: 24, height: 22))
        ]

        let plan = SecondBarCompactStripPlanner.plan(
            snapshots: snapshots,
            accurateIconReadyIDs: ["narrow", "wide", "overflow"],
            availableItemWidth: 112,
            screen: screen
        )

        #expect(plan.visibleItems.map(\.id) == ["narrow", "wide"])
        #expect(plan.hiddenOverflowCount == 1)
        #expect(SecondBarCompactStripPlanner.itemMetrics(for: snapshots[1]).imageSize.width == 72)
    }

    @Test func compactStripAdditionalCountTracksOverflowNotMissingAccurateIcons() {
        let snapshots = [
            snapshot("a", zone: .hidden),
            snapshot("b", zone: .hidden),
            snapshot("c", zone: .hidden)
        ]

        let plan = SecondBarCompactStripPlanner.plan(
            snapshots: snapshots,
            accurateIconReadyIDs: ["a"],
            maxVisibleItems: 2
        )

        #expect(plan.visibleItems.map(\.id) == ["a", "b"])
        #expect(plan.hiddenOverflowCount == 1)
        #expect(plan.needsAccurateIconCount == 2)
        #expect(plan.totalAdditionalCount == 1)
        #expect(plan.hasAdditionalItems)
    }

    @Test func compactStripKeepsOneLineAndReportsOverflow() {
        let snapshots = [
            snapshot("a", zone: .hidden),
            snapshot("b", zone: .hidden),
            snapshot("c", zone: .hidden),
            snapshot("d", zone: .hidden)
        ]

        let plan = SecondBarCompactStripPlanner.plan(
            snapshots: snapshots,
            accurateIconReadyIDs: ["a", "b", "c", "d"],
            maxVisibleItems: 2
        )

        #expect(plan.visibleItems.map(\.id) == ["a", "b"])
        #expect(plan.hiddenOverflowCount == 2)
        #expect(plan.totalAdditionalCount == 2)
        #expect(plan.scanState == .fresh)
    }

    @Test func compactStripPlanReportsNoScanWhenNoScanTimeIsAvailable() {
        let plan = SecondBarCompactStripPlanner.plan(
            snapshots: [],
            accurateIconReadyIDs: [],
            maxVisibleItems: 8,
            lastScanTime: nil,
            now: Date(timeIntervalSince1970: 1_000)
        )

        #expect(plan.scanState == .noScan)
        #expect(plan.visibleItems.isEmpty)
        #expect(plan.totalAdditionalCount == 0)
    }

    @Test func compactStripPlanReportsStaleScanWhenLastScanIsOld() {
        let plan = SecondBarCompactStripPlanner.plan(
            snapshots: [snapshot("hidden", zone: .hidden)],
            accurateIconReadyIDs: ["hidden"],
            maxVisibleItems: 8,
            lastScanTime: Date(timeIntervalSince1970: 0),
            now: Date(timeIntervalSince1970: SecondBarCompactStripPlanner.staleScanThreshold + 1)
        )

        #expect(plan.scanState == .stale)
        #expect(plan.visibleItems.map(\.id) == ["hidden"])
        #expect(plan.hiddenOverflowCount == 0)
    }

    @Test func activationFailureFeedbackRetainsRetryTarget() {
        let failedSnapshot = snapshot("failed", zone: .hidden)
        let feedback = SecondBarCompactStripActivationFeedback(
            message: "Could not activate",
            tone: .warning,
            retrySnapshot: failedSnapshot
        )

        #expect(feedback.retrySnapshot == failedSnapshot)
    }

    private func snapshot(
        _ id: String,
        zone: MenuBarZone,
        frame: CGRect? = nil,
        isLikelySystemItem: Bool = false
    ) -> MenuBarItemSnapshot {
        TestSnapshots.makeSnapshot(
            id: id,
            title: id,
            frame: frame,
            owningApplicationName: id,
            bundleIdentifier: "com.example.\(id)",
            zone: zone,
            isLikelySystemItem: isLikelySystemItem
        )
    }

    private func screen(
        notchAvoidanceRect: CGRect? = nil
    ) -> SecondBarScreenSnapshot {
        SecondBarScreenSnapshot(
            id: "built-in",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
            isMain: true,
            notchAvoidanceRect: notchAvoidanceRect
        )
    }
}
