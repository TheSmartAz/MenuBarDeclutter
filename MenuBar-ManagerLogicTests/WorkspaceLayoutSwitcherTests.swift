import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

private struct StubMover: MoveExecuting {
    let succeeds: Bool
    func move(itemKey: String, command: IconMoveCommand) async -> Bool { succeeds }
}

@Suite("Workspace Layout Switcher")
struct WorkspaceLayoutSwitcherTests {
    private let switcher = WorkspaceLayoutSwitcher()

    private func snap(bundle: String, zone: MenuBarZone, system: Bool = false) -> MenuBarItemSnapshot {
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

    private func workspace(_ targets: [WorkspaceItemTarget]) -> MenuBarWorkspace {
        MenuBarWorkspace(name: "W", itemTargets: targets)
    }

    @Test func planReconcilesScanAgainstTargets() {
        let ws = workspace([WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)])
        let plan = switcher.plan(
            for: ws,
            currentScan: [snap(bundle: "com.a", zone: .visible), snap(bundle: "com.b", zone: .hidden)]
        )
        #expect(plan.moves == [PlannedMove(itemKey: "bundle:com.a", from: .visible, to: .hidden)])
    }

    @Test func planExcludesSystemItemsFromCurrentState() {
        let ws = workspace([WorkspaceItemTarget(itemKey: "bundle:com.sys", desiredZone: .hidden)])
        let plan = switcher.plan(for: ws, currentScan: [snap(bundle: "com.sys", zone: .visible, system: true)])
        #expect(plan.moves.isEmpty)
        #expect(plan.unresolvedItemKeys == ["bundle:com.sys"])
    }

    @Test func applyRunsPlanAndReturnsAppliedOutcome() async {
        let ws = workspace([WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)])
        let result = await switcher.apply(
            ws,
            currentScan: [snap(bundle: "com.a", zone: .visible)],
            using: StubMover(succeeds: true)
        )
        #expect(result.plan.moves.count == 1)
        #expect(result.outcome == .applied(moveCount: 1))
    }

    @Test func applyRollsBackWhenMoverFails() async {
        let ws = workspace([WorkspaceItemTarget(itemKey: "bundle:com.a", desiredZone: .hidden)])
        let result = await switcher.apply(
            ws,
            currentScan: [snap(bundle: "com.a", zone: .visible)],
            using: StubMover(succeeds: false)
        )
        #expect(result.outcome == .rolledBack(failedAt: 0))
    }
}
