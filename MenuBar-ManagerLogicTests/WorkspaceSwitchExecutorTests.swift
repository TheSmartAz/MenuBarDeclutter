import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Workspace Switch Executor")
struct WorkspaceSwitchExecutorTests {
    private let planner = WorkspaceReconciliationPlanner()
    private let executor = WorkspaceSwitchExecutor()

    /// A three-move plan: A -> alwaysHidden, then B, C -> hidden (hide-first order).
    private func threeMovePlan() -> WorkspaceReconciliationPlan {
        planner.plan(
            current: [
                ReconciliationItemState(itemKey: "A", currentZone: .visible),
                ReconciliationItemState(itemKey: "B", currentZone: .visible),
                ReconciliationItemState(itemKey: "C", currentZone: .visible)
            ],
            target: [
                WorkspaceItemTarget(itemKey: "A", desiredZone: .alwaysHidden),
                WorkspaceItemTarget(itemKey: "B", desiredZone: .hidden),
                WorkspaceItemTarget(itemKey: "C", desiredZone: .hidden)
            ]
        )
    }

    @Test func appliesEveryMoveWhenEachSucceeds() async {
        let mover = ScriptedMover()
        let outcome = await executor.apply(threeMovePlan(), using: mover)

        #expect(outcome.appliedItemKeys == ["A", "B", "C"])
        #expect(outcome.failedItemKeys.isEmpty)
        #expect(!outcome.hasFailures)
        #expect(await mover.recordedCalls().map(\.itemKey) == ["A", "B", "C"])
    }

    @Test func noChangeForEmptyPlan() async {
        let plan = planner.plan(
            current: [ReconciliationItemState(itemKey: "A", currentZone: .visible)],
            target: [WorkspaceItemTarget(itemKey: "A", desiredZone: .visible)]
        )
        let mover = ScriptedMover()
        let outcome = await executor.apply(plan, using: mover)

        #expect(outcome.isNoOp)
        #expect(await mover.recordedCalls().isEmpty)
    }

    @Test func continuesPastFailuresAndReportsThemWithoutRollback() async {
        // B (the 2nd move) fails; best-effort still applies C, and never issues
        // reverse/rollback moves — each item is attempted exactly once, in order.
        let mover = ScriptedMover(failingCallIndices: [1])
        let outcome = await executor.apply(threeMovePlan(), using: mover)

        #expect(outcome.appliedItemKeys == ["A", "C"])
        #expect(outcome.failedItemKeys == ["B"])
        #expect(outcome.hasFailures)
        #expect(await mover.recordedCalls().map(\.itemKey) == ["A", "B", "C"])
    }

    @Test func reportsAllFailuresWhenNothingMoves() async {
        let mover = ScriptedMover(failingCallIndices: [0, 1, 2])
        let outcome = await executor.apply(threeMovePlan(), using: mover)

        #expect(outcome.appliedItemKeys.isEmpty)
        #expect(outcome.failedItemKeys == ["A", "B", "C"])
    }

    @Test func oneUnmovableItemDoesNotFailTheWholeSwitch() async {
        // The whole point of best-effort: a single stubborn item (C fails) must
        // not undo the others — A and B still land.
        let mover = ScriptedMover(failingCallIndices: [2])
        let outcome = await executor.apply(threeMovePlan(), using: mover)

        #expect(outcome.appliedItemKeys == ["A", "B"])
        #expect(outcome.failedItemKeys == ["C"])
    }
}

private actor ScriptedMover: MoveExecuting {
    struct Call: Equatable { let itemKey: String; let command: IconMoveCommand }

    private(set) var calls: [Call] = []
    private let failingCallIndices: Set<Int>

    init(failingCallIndices: Set<Int> = []) {
        self.failingCallIndices = failingCallIndices
    }

    func move(itemKey: String, command: IconMoveCommand) async -> Bool {
        let index = calls.count
        calls.append(Call(itemKey: itemKey, command: command))
        return !failingCallIndices.contains(index)
    }

    func recordedCalls() -> [Call] { calls }
}
