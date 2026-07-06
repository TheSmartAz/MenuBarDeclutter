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
            primaryClickOptIn: true
        ) == .toggleInlineVisibility)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .licensed,
            readiness: .ready,
            primaryClickOptIn: false
        ) == .toggleInlineVisibility)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .licensed,
            readiness: .ready,
            primaryClickOptIn: true
        ) == .toggleCompactStrip)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .trialActive(expiration: Date(timeIntervalSince1970: 100)),
            readiness: .screenRecordingMissing,
            primaryClickOptIn: true
        ) == .showSecondBarRequirements)

        #expect(StatusBarPrimaryClickRouter.route(
            entitlement: .trialActive(expiration: Date(timeIntervalSince1970: 100)),
            readiness: .screenRecordingMissing,
            primaryClickOptIn: false
        ) == .toggleInlineVisibility)
    }

    @Test func compactStripIncludesOnlyHiddenAccurateIconReadyItemsInOriginalOrder() {
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

        #expect(plan.visibleItems.map(\.id) == ["hidden-a", "hidden-c"])
        #expect(plan.hiddenOverflowCount == 0)
        #expect(plan.needsAccurateIconCount == 1)
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

    private func snapshot(_ id: String, zone: MenuBarZone) -> MenuBarItemSnapshot {
        TestSnapshots.makeSnapshot(
            id: id,
            title: id,
            frame: nil,
            owningApplicationName: id,
            bundleIdentifier: "com.example.\(id)",
            zone: zone
        )
    }
}
