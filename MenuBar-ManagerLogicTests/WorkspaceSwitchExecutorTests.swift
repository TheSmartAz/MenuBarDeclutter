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
        let plan = threeMovePlan()
        let mover = ScriptedMover()

        let outcome = await executor.apply(plan, using: mover)

        #expect(outcome == .applied(moveCount: 3))
        #expect(outcome.isClean)
        let keys = await mover.recordedCalls().map(\.itemKey)
        #expect(keys == ["A", "B", "C"])
    }

    @Test func noChangeForEmptyPlan() async {
        let plan = planner.plan(
            current: [ReconciliationItemState(itemKey: "A", currentZone: .visible)],
            target: [WorkspaceItemTarget(itemKey: "A", desiredZone: .visible)]
        )
        let mover = ScriptedMover()

        let outcome = await executor.apply(plan, using: mover)

        #expect(outcome == .noChange)
        #expect(await mover.recordedCalls().isEmpty)
    }

    @Test func rollsBackAppliedMovesOnFailure() async {
        let plan = threeMovePlan()
        // Fail the 2nd forward move (index 1).
        let mover = ScriptedMover(failingCallIndices: [1])

        let outcome = await executor.apply(plan, using: mover)

        #expect(outcome == .rolledBack(failedAt: 1))
        #expect(outcome.isClean)

        // Forward A, forward B (fails), then reverse of A back to visible.
        let calls = await mover.recordedCalls()
        #expect(calls.map(\.itemKey) == ["A", "B", "A"])
        #expect(calls.last?.command == .moveToZone(.visible))
    }

    @Test func reportsRollbackIncompleteWhenUndoAlsoFails() async {
        let plan = threeMovePlan()
        // Fail the 3rd forward move (index 2) and the first rollback move (index 3).
        let mover = ScriptedMover(failingCallIndices: [2, 3])

        let outcome = await executor.apply(plan, using: mover)

        #expect(outcome == .rollbackIncomplete(failedAt: 2, rollbackFailedAt: 0))
        #expect(!outcome.isClean)
    }

    @Test func rollbackReversesInOppositeOrder() async {
        let plan = threeMovePlan()
        // Fail the 3rd forward move (index 2); rollback should undo B then A.
        let mover = ScriptedMover(failingCallIndices: [2])

        let outcome = await executor.apply(plan, using: mover)

        #expect(outcome == .rolledBack(failedAt: 2))
        let calls = await mover.recordedCalls()
        // A, B, C(fail), then reverse B, reverse A.
        #expect(calls.map(\.itemKey) == ["A", "B", "C", "B", "A"])
        #expect(calls[3].command == .moveToZone(.visible)) // B back to visible
        #expect(calls[4].command == .moveToZone(.visible)) // A back to visible
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
