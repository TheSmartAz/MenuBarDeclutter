import Foundation

/// Performs one real-item move on demand. The production adapter resolves the
/// item key to a live snapshot and routes through the measured `IconMoveService`;
/// tests substitute a scripted double. Kept minimal so the switch control flow
/// depends only on "move one item; did it work?".
protocol MoveExecuting: Sendable {
    /// Perform one move; return `true` only on verified success.
    func move(itemKey: String, command: IconMoveCommand) async -> Bool
}

/// The result of applying a workspace reconciliation plan to the real menu bar.
nonisolated enum WorkspaceSwitchOutcome: Equatable, Sendable {
    /// The plan was empty; nothing was touched.
    case noChange
    /// Every planned move succeeded.
    case applied(moveCount: Int)
    /// A move failed; every move applied before it was reversed successfully,
    /// leaving the bar as it started. `failedAt` is the 0-based move index.
    case rolledBack(failedAt: Int)
    /// A move failed AND a later rollback move also failed, so the bar may be in
    /// a partial state. Both indices are reported for diagnostics.
    case rollbackIncomplete(failedAt: Int, rollbackFailedAt: Int)

    /// True unless the bar was left in a partial (non-atomic) state.
    var isClean: Bool {
        switch self {
        case .noChange, .applied, .rolledBack:
            true
        case .rollbackIncomplete:
            false
        }
    }
}

/// Applies a reconciliation plan one move at a time, stopping and rolling back
/// atomically on the first failure so a workspace switch is all-or-nothing.
///
/// This is pure control flow — the risky real moves live behind `MoveExecuting`,
/// and the ordering/rollback come from `WorkspaceReconciliationPlan`. That keeps
/// the "don't scramble the bar" guarantee fully unit-testable.
nonisolated struct WorkspaceSwitchExecutor {
    func apply(
        _ plan: WorkspaceReconciliationPlan,
        using mover: any MoveExecuting
    ) async -> WorkspaceSwitchOutcome {
        guard !plan.isNoOp else { return .noChange }

        for (index, move) in plan.moves.enumerated() {
            if await mover.move(itemKey: move.itemKey, command: move.command) {
                continue
            }

            // Move `index` failed. Undo the moves already applied (0..<index),
            // most-recent first, so the switch is atomic.
            let rollback = plan.rollbackPlan(afterApplying: index)
            for (rollbackIndex, rollbackMove) in rollback.enumerated() {
                let undone = await mover.move(
                    itemKey: rollbackMove.itemKey,
                    command: rollbackMove.command
                )
                if !undone {
                    return .rollbackIncomplete(failedAt: index, rollbackFailedAt: rollbackIndex)
                }
            }
            return .rolledBack(failedAt: index)
        }

        return .applied(moveCount: plan.moves.count)
    }
}
