import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Workspace Layout Plan Summary")
struct WorkspaceLayoutPlanSummaryTests {
    private func plan(
        moves: [PlannedMove],
        satisfied: [String] = [],
        unresolved: [String] = []
    ) -> WorkspaceReconciliationPlan {
        WorkspaceReconciliationPlan(
            moves: moves,
            unresolvedItemKeys: unresolved,
            alreadySatisfiedItemKeys: satisfied
        )
    }

    @Test func emptyPlanWithNoTargets() {
        let summary = WorkspaceLayoutPlanSummary(plan(moves: []))
        #expect(summary.isEmpty)
        #expect(!summary.hasSavedTargets)
        #expect(summary.sentence == "No layout saved for this Workspace yet.")
    }

    @Test func emptyPlanButAlreadyMatching() {
        let summary = WorkspaceLayoutPlanSummary(plan(moves: [], satisfied: ["a", "b"]))
        #expect(summary.isEmpty)
        #expect(summary.hasSavedTargets)
        #expect(summary.sentence == "Bar already matches this Workspace.")
    }

    @Test func countsHideAndRevealMoves() {
        let summary = WorkspaceLayoutPlanSummary(plan(moves: [
            PlannedMove(itemKey: "a", from: .visible, to: .hidden),
            PlannedMove(itemKey: "b", from: .visible, to: .alwaysHidden),
            PlannedMove(itemKey: "c", from: .hidden, to: .visible)
        ]))
        #expect(summary.moveCount == 3)
        #expect(summary.hideCount == 2)
        #expect(summary.revealCount == 1)
        #expect(summary.sentence == "3 moves, 2 to hide, 1 to reveal")
    }

    @Test func includesUnresolvedInSentence() {
        let summary = WorkspaceLayoutPlanSummary(plan(
            moves: [PlannedMove(itemKey: "a", from: .visible, to: .hidden)],
            unresolved: ["x"]
        ))
        #expect(summary.unresolvedCount == 1)
        #expect(summary.sentence == "1 move, 1 to hide • 1 not found")
    }
}
