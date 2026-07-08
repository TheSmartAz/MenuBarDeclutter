import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

private struct StubMover: MoveExecuting {
    let succeeds: Bool
    func move(itemKey: String, command: IconMoveCommand) async -> Bool { succeeds }
}

private func makeSnap(bundle: String, zone: MenuBarZone) -> MenuBarItemSnapshot {
    MenuBarItemSnapshot(
        title: "T",
        role: "AXMenuBarItem",
        subrole: nil,
        frame: CGRect(x: 0, y: 0, width: 20, height: 20),
        owningProcessIdentifier: 1,
        owningApplicationName: "App",
        bundleIdentifier: bundle,
        zone: zone,
        isLikelySystemItem: false,
        scanTimestamp: Date(timeIntervalSince1970: 1)
    )
}

@MainActor
@Suite("Workspace Layout Coordinator")
struct WorkspaceLayoutCoordinatorTests {
    @Test func captureSetsItemTargetsFromScan() async {
        let items = [makeSnap(bundle: "com.a", zone: .visible), makeSnap(bundle: "com.b", zone: .hidden)]
        let coordinator = WorkspaceLayoutCoordinator(
            scan: { items },
            mover: StubMover(succeeds: true),
            isApplyEnabled: { true }
        )
        let updated = await coordinator.captureCurrentLayout(into: MenuBarWorkspace(name: "W"))
        #expect(updated.itemTargets.count == 2)
        #expect(updated.itemTargets.contains(WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .visible)))
    }

    @Test func applyReturnsNilWhenGateDisabled() async {
        let items = [makeSnap(bundle: "com.a", zone: .visible)]
        let coordinator = WorkspaceLayoutCoordinator(
            scan: { items },
            mover: StubMover(succeeds: true),
            isApplyEnabled: { false }
        )
        let ws = MenuBarWorkspace(name: "W", itemTargets: [WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)])
        let result = await coordinator.applyLayoutIfEnabled(for: ws)
        #expect(result == nil)
    }

    @Test func applyReturnsNilWhenNoTargets() async {
        let coordinator = WorkspaceLayoutCoordinator(
            scan: { [] },
            mover: StubMover(succeeds: true),
            isApplyEnabled: { true }
        )
        let result = await coordinator.applyLayoutIfEnabled(for: MenuBarWorkspace(name: "W"))
        #expect(result == nil)
    }

    @Test func applyRunsWhenEnabledWithTargets() async {
        let items = [makeSnap(bundle: "com.a", zone: .visible)]
        let coordinator = WorkspaceLayoutCoordinator(
            scan: { items },
            mover: StubMover(succeeds: true),
            isApplyEnabled: { true }
        )
        let ws = MenuBarWorkspace(name: "W", itemTargets: [WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)])
        let result = await coordinator.applyLayoutIfEnabled(for: ws)
        #expect(result?.outcome.appliedCount == 1)
    }

    @Test func learnsUnmovableItemsAndSkipsThemNextTime() async {
        let items = [makeSnap(bundle: "com.a", zone: .visible)]
        let coordinator = WorkspaceLayoutCoordinator(
            scan: { items },
            mover: StubMover(succeeds: false),   // com.a cannot move
            isApplyEnabled: { true }
        )
        let ws = MenuBarWorkspace(
            name: "W",
            itemTargets: [WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)]
        )

        // First apply: com.a is attempted and fails.
        let first = await coordinator.applyLayoutIfEnabled(for: ws)
        #expect(first?.outcome.failedItemKeys == ["bundle:com.a"])
        #expect(first?.skippedUnmovableKeys.isEmpty == true)

        // Second apply: com.a is now known-unmovable -> skipped, not re-attempted.
        let second = await coordinator.applyLayoutIfEnabled(for: ws)
        #expect(second?.outcome.isNoOp == true)
        #expect(second?.skippedUnmovableKeys == ["bundle:com.a"])
    }
}
