import CoreGraphics
import Foundation
import Testing
@testable import MenuBar_Manager

@Suite("ProfileApplicationDryRun")
@MainActor
struct ProfileApplicationDryRunTests {
    @Test func dryRunReportsMovesAndRequirements() {
        let harness = makeHarness()
        let profile = ProfileModel(
            name: "Work",
            preferredVisibilityState: .expanded,
            targetZonesByBundleID: ["com.example.sync": .visible]
        )
        let snapshot = makeSnapshot(bundleID: "com.example.sync", zone: .hidden)

        let summary = harness.service.dryRun(
            profile: profile,
            snapshots: [snapshot],
            accessibilityStatus: .denied,
            allowProMoves: false
        )

        #expect(summary.itemsToReveal == ["Expand hidden items"])
        #expect(summary.itemsToMove.count == 1)
        #expect(summary.permissionRequirements.count == 3)
    }

    @Test func applyBasicSettingsDoesNotRunZoneMoves() {
        let harness = makeHarness()
        let profile = ProfileModel(
            name: "Focus",
            preferredVisibilityState: .collapsed,
            showSecondBar: true,
            autoRehideEnabled: false,
            hoverRevealEnabled: true,
            targetZonesByBundleID: ["com.example.sync": .visible]
        )

        let summary = harness.service.applyBasicSettings(
            profile: profile,
            snapshots: [makeSnapshot(bundleID: "com.example.sync", zone: .hidden)],
            accessibilityStatus: .granted,
            allowProMoves: false
        )

        #expect(harness.store.secondBarEnabled)
        #expect(harness.store.autoRehideEnabled == false)
        #expect(harness.store.hoverRevealEnabled)
        #expect(harness.appliedVisibility == .collapsed)
        #expect(summary.permissionRequirements.contains("Zone moves require explicit confirmation and are not run by normal profile apply."))
    }

    private func makeHarness() -> Harness {
        let suiteName = "ProfileApplicationDryRunTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let liveStatus = LiveDiagnosticsStatus()
        let box = VisibilityBox()
        let service = ProfileApplicationService(
            settingsStore: store,
            diagnosticsLogger: logger,
            liveStatus: liveStatus,
            setVisibility: { box.value = $0 }
        )
        return Harness(store: store, service: service, visibilityBox: box, defaults: defaults, suiteName: suiteName)
    }

    private func makeSnapshot(bundleID: String, zone: MenuBarZone) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: "snapshot-\(bundleID)",
            title: "Status",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: CGRect(x: 100, y: 850, width: 24, height: 22),
            owningProcessIdentifier: 42,
            owningApplicationName: "Sync",
            bundleIdentifier: bundleID,
            zone: zone,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1)
        )
    }

    private final class VisibilityBox {
        var value: HidingVisibilityState?
    }

    private struct Harness {
        let store: SettingsStore
        let service: ProfileApplicationService
        let visibilityBox: VisibilityBox
        let defaults: UserDefaults
        let suiteName: String

        var appliedVisibility: HidingVisibilityState? {
            visibilityBox.value
        }

        func tearDown() {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }
}
