import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("LayoutCapacityService")
struct LayoutCapacityServiceTests {
    @Test func basicGeometryEstimate() {
        let service = LayoutCapacityService(now: { Date(timeIntervalSince1970: 1000) })
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = CGRect(x: 0, y: 25, width: 1440, height: 875)

        let estimate = service.estimateFromGeometry(
            screenID: "primary",
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            separatorFrame: nil,
            alwaysHiddenSeparatorFrame: nil,
            thresholdRatio: 0.85
        )

        #expect(estimate.screenID == "primary")
        #expect(estimate.source == .basicGeometryOnly)
        #expect(estimate.warnings.contains(.noAXSnapshot))
        #expect(estimate.estimatedMenuBarWidth == 1440)
        #expect(estimate.estimatedItemSlots > 0)
        #expect(estimate.generatedAt == Date(timeIntervalSince1970: 1000))
    }

    @Test func proAXSnapshotEstimate() {
        let service = LayoutCapacityService(now: { Date(timeIntervalSince1970: 2000) })
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1097)
        let visibleFrame = CGRect(x: 0, y: 38, width: 1728, height: 1059)

        let snapshot = MenuBarItemSnapshot(
            title: "Test",
            role: "AXButton",
            subrole: nil,
            frame: CGRect(x: 1500, y: 0, width: 30, height: 25),
            owningProcessIdentifier: 1234,
            owningApplicationName: "TestApp",
            bundleIdentifier: "com.test.app",
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1990)
        )

        let result = MenuBarScanResult(
            snapshots: [snapshot],
            scanTimestamp: Date(timeIntervalSince1970: 1990),
            axFailuresCount: 0
        )

        let estimate = service.estimate(
            screenID: "primary",
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            scanResult: result,
            thresholdRatio: 0.85,
            proModeEnabled: true
        )

        #expect(estimate.source == .proAXSnapshot)
        #expect(estimate.knownItemCount == 1)
        #expect(estimate.knownVisibleItemCount == 1)
        #expect(!estimate.warnings.contains(.staleAXSnapshot))
    }

    @Test func staleAXSnapshotWarning() {
        let now = Date(timeIntervalSince1970: 5000)
        let service = LayoutCapacityService(now: { now })
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = CGRect(x: 0, y: 25, width: 1440, height: 875)

        let snapshot = MenuBarItemSnapshot(
            title: "Test",
            role: "AXButton",
            subrole: nil,
            frame: CGRect(x: 1500, y: 0, width: 30, height: 25),
            owningProcessIdentifier: 1234,
            owningApplicationName: "TestApp",
            bundleIdentifier: "com.test.app",
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1000)
        )

        let result = MenuBarScanResult(
            snapshots: [snapshot],
            scanTimestamp: Date(timeIntervalSince1970: 1000),
            axFailuresCount: 0
        )

        let estimate = service.estimate(
            screenID: "primary",
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            scanResult: result,
            thresholdRatio: 0.85,
            proModeEnabled: true
        )

        #expect(estimate.warnings.contains(.staleAXSnapshot))
        #expect(estimate.source == .mixed)
    }

    @Test func fallsBackToGeometryWithoutAX() {
        let service = LayoutCapacityService()
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = CGRect(x: 0, y: 25, width: 1440, height: 875)

        let estimate = service.estimate(
            screenID: "primary",
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            scanResult: nil,
            thresholdRatio: 0.85,
            proModeEnabled: false
        )

        #expect(estimate.source == .basicGeometryOnly)
        #expect(estimate.knownItemCount == 0)
    }
}
