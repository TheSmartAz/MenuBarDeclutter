import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Workspace Target Model")
struct WorkspaceTargetModelTests {
    private func snap(
        bundle: String?,
        zone: MenuBarZone,
        system: Bool = false
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            title: "T",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: CGRect(x: 0, y: 0, width: 20, height: 20),
            owningProcessIdentifier: 1,
            owningApplicationName: "App",
            bundleIdentifier: bundle,
            zone: zone,
            isLikelySystemItem: system,
            scanTimestamp: Date(timeIntervalSince1970: 1)
        )
    }

    @Test func captureRecordsNonSystemKnownZoneItems() {
        let targets = WorkspaceItemTarget.capture(from: [
            snap(bundle: "com.a", zone: .visible),
            snap(bundle: "com.b", zone: .hidden),
            snap(bundle: "com.sys", zone: .visible, system: true),   // excluded: system
            snap(bundle: "com.unknown", zone: .unknown)              // excluded: unknown zone
        ])
        #expect(targets.count == 2)
        #expect(targets.contains(WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .visible)))
        #expect(targets.contains(WorkspaceItemTarget(itemKey: "bundle:com.b", desiredZone: .hidden)))
    }

    @Test func captureDeduplicatesByKeyKeepingFirst() {
        let targets = WorkspaceItemTarget.capture(from: [
            snap(bundle: "com.a", zone: .visible),
            snap(bundle: "com.a", zone: .hidden)
        ])
        #expect(targets.count == 1)
        #expect(targets.first?.desiredZone == .visible)
    }

    @Test func workspaceRoundTripsItemTargets() throws {
        let workspace = MenuBarWorkspace(
            name: "W",
            itemTargets: [WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)]
        )
        let data = try JSONEncoder().encode(workspace)
        let decoded = try JSONDecoder().decode(MenuBarWorkspace.self, from: data)
        #expect(decoded.itemTargets == workspace.itemTargets)
    }

    @Test func oldJSONWithoutItemTargetsMigratesToEmpty() throws {
        let json = Data(#"{"name":"Legacy"}"#.utf8)
        let decoded = try JSONDecoder().decode(MenuBarWorkspace.self, from: json)
        #expect(decoded.itemTargets.isEmpty)
        #expect(decoded.name == "Legacy")
    }
}
