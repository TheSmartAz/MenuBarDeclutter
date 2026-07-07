import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Workspace Item Key")
struct WorkspaceItemKeyTests {
    private func snap(
        bundle: String?,
        app: String? = "App",
        zone: MenuBarZone = .hidden,
        frame: CGRect? = CGRect(x: 100, y: 0, width: 20, height: 20),
        title: String? = "T"
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 1,
            owningApplicationName: app,
            bundleIdentifier: bundle,
            zone: zone,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1)
        )
    }

    @Test func prefersBundleIdentifier() {
        #expect(WorkspaceItemKey.key(for: snap(bundle: "com.example.app")) == "bundle:com.example.app")
    }

    @Test func fallsBackToApplicationName() {
        #expect(WorkspaceItemKey.key(for: snap(bundle: nil, app: "Example")) == "app:Example")
    }

    @Test func fallsBackToSnapshotID() {
        let value = snap(bundle: nil, app: nil)
        #expect(WorkspaceItemKey.key(for: value) == "id:" + value.id)
    }

    @Test func isStableAcrossZoneAndFrameChanges() {
        let before = snap(bundle: "com.example.app", zone: .hidden, frame: CGRect(x: 100, y: 0, width: 20, height: 20))
        let after = snap(bundle: "com.example.app", zone: .visible, frame: CGRect(x: 500, y: 0, width: 20, height: 20))
        // Same logical item after a move: the frame-derived id changes, but the key must not.
        #expect(before.id != after.id)
        #expect(WorkspaceItemKey.key(for: before) == WorkspaceItemKey.key(for: after))
    }
}
