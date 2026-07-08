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
///
/// **Best-effort:** every movable item is moved; items that can't move (stubborn
/// apps, background agents like `com.openai.sky.CUAService`, items that reject
/// synthetic drags) are reported rather than rolled back. A single unmovable item
/// must not fail the whole switch — real menu bars almost always contain one.
nonisolated struct WorkspaceSwitchOutcome: Equatable, Sendable {
    /// Items that reached their target zone.
    let appliedItemKeys: [String]
    /// Items whose move did not verify (left where they were).
    let failedItemKeys: [String]

    static let noChange = WorkspaceSwitchOutcome(appliedItemKeys: [], failedItemKeys: [])

    var appliedCount: Int { appliedItemKeys.count }
    var failedCount: Int { failedItemKeys.count }
    var isNoOp: Bool { appliedItemKeys.isEmpty && failedItemKeys.isEmpty }
    var hasFailures: Bool { !failedItemKeys.isEmpty }
}

/// Applies a reconciliation plan one move at a time, **best-effort**: it moves
/// every item it can and records the ones it can't, rather than rolling the whole
/// switch back on the first failure.
///
/// This replaced an all-or-nothing atomic design after a hardware pass: a real bar
/// almost always has at least one unmovable item, so atomic rollback would fail
/// the entire apply every time. A failed move leaves its item where it was (the
/// common failure is "the item didn't move at all"), so the bar stays coherent —
/// the movable items reach their targets and the rest are reported to the user.
nonisolated struct WorkspaceSwitchExecutor {
    func apply(
        _ plan: WorkspaceReconciliationPlan,
        using mover: any MoveExecuting
    ) async -> WorkspaceSwitchOutcome {
        var applied: [String] = []
        var failed: [String] = []
        for move in plan.moves {
            if await mover.move(itemKey: move.itemKey, command: move.command) {
                applied.append(move.itemKey)
            } else {
                failed.append(move.itemKey)
            }
        }
        return WorkspaceSwitchOutcome(appliedItemKeys: applied, failedItemKeys: failed)
    }
}
