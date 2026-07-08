import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Workspace Reconciliation Planner")
struct WorkspaceReconciliationPlannerTests {
    private let planner = WorkspaceReconciliationPlanner()

    private func state(_ key: String, _ zone: MenuBarZone) -> ReconciliationItemState {
        ReconciliationItemState(itemKey: key, currentZone: zone)
    }

    private func target(_ key: String, _ zone: MenuBarZone) -> WorkspaceItemTarget {
        WorkspaceItemTarget(itemKey: key, desiredZone: zone)
    }

    @Test func movesOnlyItemsWhoseZoneDiffers() {
        let plan = planner.plan(
            current: [state("A", .visible), state("B", .hidden)],
            target: [target("A", .hidden), target("B", .hidden)]
        )
        #expect(plan.moves == [PlannedMove(itemKey: "A", from: .visible, to: .hidden)])
        #expect(plan.alreadySatisfiedItemKeys == ["B"])
        #expect(plan.unresolvedItemKeys.isEmpty)
    }

    @Test func leavesItemsWithNoTargetUntouched() {
        let plan = planner.plan(
            current: [state("A", .visible), state("B", .hidden), state("C", .visible)],
            target: [target("A", .hidden)]
        )
        #expect(plan.moves.map(\.itemKey) == ["A"])
        // C has no target opinion → never appears anywhere.
        #expect(!plan.alreadySatisfiedItemKeys.contains("C"))
        #expect(!plan.unresolvedItemKeys.contains("C"))
        #expect(!plan.moves.contains { $0.itemKey == "C" })
    }

    @Test func reportsUnresolvedTargetsNotPresent() {
        let plan = planner.plan(
            current: [state("A", .visible)],
            target: [target("X", .hidden)]
        )
        #expect(plan.moves.isEmpty)
        #expect(plan.unresolvedItemKeys == ["X"])
    }

    @Test func ordersMovesHideFirst() {
        let plan = planner.plan(
            current: [state("A", .hidden), state("B", .visible), state("C", .visible)],
            target: [target("A", .visible), target("B", .alwaysHidden), target("C", .hidden)]
        )
        // Order by target hiddenness descending: alwaysHidden (B), hidden (C), visible (A).
        #expect(plan.moves.map(\.itemKey) == ["B", "C", "A"])
    }

    @Test func stableOrderByKeyWithinSameTargetZone() {
        let plan = planner.plan(
            current: [state("Zebra", .visible), state("Alpha", .visible)],
            target: [target("Zebra", .hidden), target("Alpha", .hidden)]
        )
        #expect(plan.moves.map(\.itemKey) == ["Alpha", "Zebra"])
    }

    @Test func isNoOpWhenEverythingSatisfied() {
        let plan = planner.plan(
            current: [state("A", .visible), state("B", .hidden)],
            target: [target("A", .visible), target("B", .hidden)]
        )
        #expect(plan.isNoOp)
        #expect(plan.moves.isEmpty)
        #expect(plan.alreadySatisfiedItemKeys == ["A", "B"])
    }

    @Test func rollbackReversesAppliedMovesWithSwappedZones() {
        let plan = planner.plan(
            current: [state("A", .visible), state("B", .visible), state("C", .visible)],
            target: [target("A", .alwaysHidden), target("B", .hidden), target("C", .hidden)]
        )
        // Ordered: A (alwaysHidden), then B, C (hidden, by key).
        #expect(plan.moves.map(\.itemKey) == ["A", "B", "C"])

        let rollback = plan.rollbackPlan(afterApplying: 2)
        // Undo B then A, with from/to swapped.
        #expect(rollback == [
            PlannedMove(itemKey: "B", from: .hidden, to: .visible),
            PlannedMove(itemKey: "A", from: .alwaysHidden, to: .visible)
        ])
    }

    @Test func rollbackClampsOutOfRangeCounts() {
        let plan = planner.plan(
            current: [state("A", .visible)],
            target: [target("A", .hidden)]
        )
        #expect(plan.rollbackPlan(afterApplying: 0).isEmpty)
        #expect(plan.rollbackPlan(afterApplying: 99).count == 1)
        #expect(plan.rollbackPlan(afterApplying: -5).isEmpty)
    }

    @Test func plannedMoveBridgesToMoveToZoneCommand() {
        let move = PlannedMove(itemKey: "A", from: .visible, to: .hidden)
        #expect(move.command == .moveToZone(.hidden))
    }

    @Test func duplicateTargetKeysAreDeduped() {
        let plan = planner.plan(
            current: [state("A", .visible)],
            target: [target("A", .hidden), target("A", .hidden)]
        )
        #expect(plan.moves.count == 1)
    }
}
