import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Accessibility Discovery Logic")
@MainActor
struct AccessibilityDiscoveryLogicTests {
    @Test func zoneClassificationUsesSeparatorFrames() {
        let primary = CGRect(x: 500, y: 0, width: 20, height: 24)
        let alwaysHidden = CGRect(x: 200, y: 0, width: 20, height: 24)

        #expect(
            MenuBarZone.classify(
                itemFrame: CGRect(x: 600, y: 0, width: 20, height: 24),
                primarySeparatorFrame: primary,
                alwaysHiddenSeparatorFrame: alwaysHidden
            ) == .visible
        )

        #expect(
            MenuBarZone.classify(
                itemFrame: CGRect(x: 300, y: 0, width: 20, height: 24),
                primarySeparatorFrame: primary,
                alwaysHiddenSeparatorFrame: alwaysHidden
            ) == .hidden
        )

        #expect(
            MenuBarZone.classify(
                itemFrame: CGRect(x: 100, y: 0, width: 20, height: 24),
                primarySeparatorFrame: primary,
                alwaysHiddenSeparatorFrame: alwaysHidden
            ) == .alwaysHidden
        )
    }

    @Test func zoneClassificationReturnsUnknownForMissingFrames() {
        let primary = CGRect(x: 500, y: 0, width: 20, height: 24)

        #expect(
            MenuBarZone.classify(
                itemFrame: nil,
                primarySeparatorFrame: primary,
                alwaysHiddenSeparatorFrame: nil
            ) == .unknown
        )

        #expect(
            MenuBarZone.classify(
                itemFrame: CGRect(x: 300, y: 0, width: 20, height: 24),
                primarySeparatorFrame: nil,
                alwaysHiddenSeparatorFrame: nil
            ) == .unknown
        )

        #expect(
            MenuBarZone.classify(
                itemFrame: CGRect(x: 300, y: 0, width: 20, height: 24),
                primarySeparatorFrame: primary,
                alwaysHiddenSeparatorFrame: nil
            ) == .hidden
        )
    }

    @Test func zoneClassificationTreatsMissingAlwaysHiddenSeparatorAsNoDeepZone() {
        let primary = CGRect(x: 500, y: 0, width: 20, height: 24)

        #expect(
            MenuBarZone.classify(
                itemFrame: CGRect(x: 300, y: 0, width: 20, height: 24),
                primarySeparatorFrame: primary,
                alwaysHiddenSeparatorFrame: nil
            ) == .hidden
        )
    }

    @Test func snapshotStableIDIsDeterministic() {
        let frame = CGRect(x: 100.2, y: 40.6, width: 24.2, height: 22.8)
        let first = MenuBarItemSnapshot.stableID(
            title: "Battery",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 42,
            bundleIdentifier: "com.apple.systemuiserver"
        )
        let second = MenuBarItemSnapshot.stableID(
            title: "Battery",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 42,
            bundleIdentifier: "com.apple.systemuiserver"
        )

        #expect(first == second)
    }

    @Test func snapshotStableIDChangesForDifferentOwners() {
        let frame = CGRect(x: 100, y: 40, width: 24, height: 22)
        let first = MenuBarItemSnapshot.stableID(
            title: "Sync",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 42,
            bundleIdentifier: "com.example.one"
        )
        let second = MenuBarItemSnapshot.stableID(
            title: "Sync",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 43,
            bundleIdentifier: "com.example.two"
        )

        #expect(first != second)
    }

    @Test func scanResultDeduplicatesByStableIDKeepingLatestSnapshot() {
        let id = "item-1"
        let old = makeSnapshot(id: id, title: "Old", timestamp: Date(timeIntervalSince1970: 1))
        let new = makeSnapshot(id: id, title: "New", timestamp: Date(timeIntervalSince1970: 2))

        let result = MenuBarScanResult(
            snapshots: [old, new],
            scanTimestamp: Date(timeIntervalSince1970: 2),
            axFailuresCount: 3
        )

        #expect(result.snapshots.count == 1)
        #expect(result.snapshots[0].title == "New")
        #expect(result.axFailuresCount == 3)
    }

    @Test func scanResultMergeDeduplicatesPreviousAndCurrentSnapshots() {
        let previous = MenuBarScanResult(
            snapshots: [
                makeSnapshot(id: "one", title: "One", timestamp: Date(timeIntervalSince1970: 1)),
                makeSnapshot(id: "two", title: "Two Old", timestamp: Date(timeIntervalSince1970: 1))
            ],
            scanTimestamp: Date(timeIntervalSince1970: 1),
            axFailuresCount: 0
        )
        let current = MenuBarScanResult(
            snapshots: [
                makeSnapshot(id: "two", title: "Two New", timestamp: Date(timeIntervalSince1970: 3))
            ],
            scanTimestamp: Date(timeIntervalSince1970: 3),
            axFailuresCount: 2
        )

        let merged = MenuBarScanResult.merge(previous: previous, current: current)

        #expect(merged.snapshots.count == 2)
        #expect(merged.snapshots.first { $0.id == "two" }?.title == "Two New")
        #expect(merged.axFailuresCount == 2)
        #expect(merged.scanTimestamp == current.scanTimestamp)
    }

    @Test func permissionStatusMappingDoesNotRequireAccessibilityPermission() {
        #expect(
            AccessibilityPermissionService.mapPermissionStatus(
                isTrusted: true,
                lastRecordedStatus: nil
            ) == .granted
        )
        #expect(
            AccessibilityPermissionService.mapPermissionStatus(
                isTrusted: false,
                lastRecordedStatus: nil
            ) == .notRequested
        )
        #expect(
            AccessibilityPermissionService.mapPermissionStatus(
                isTrusted: false,
                lastRecordedStatus: AccessibilityPermissionStatus.denied.rawValue
            ) == .denied
        )
        #expect(
            AccessibilityPermissionService.mapPermissionStatus(
                isTrusted: false,
                lastRecordedStatus: AccessibilityPermissionStatus.granted.rawValue
            ) == .denied
        )
        #expect(
            AccessibilityPermissionService.mapPermissionStatus(
                isTrusted: nil,
                lastRecordedStatus: AccessibilityPermissionStatus.granted.rawValue
            ) == .unknown
        )
    }

    private func makeSnapshot(
        id: String,
        title: String,
        timestamp: Date
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: id,
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: CGRect(x: 100, y: 40, width: 24, height: 22),
            owningProcessIdentifier: 42,
            owningApplicationName: "Example",
            bundleIdentifier: "com.example.app",
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: timestamp
        )
    }
}
