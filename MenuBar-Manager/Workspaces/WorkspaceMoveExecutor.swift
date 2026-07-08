import Foundation

/// Production `MoveExecuting`: resolves a workspace item key to the current live
/// snapshot and routes the move through the measured `IconMoveService`.
///
/// Each call rescans, so it targets the item at its *current* position — earlier
/// moves in a switch shift everything. Returns `true` only on a verified success
/// (`IconMoveOutcome.succeeded`); a missing item, skip, cancel, or failure all
/// map to `false`, which the `WorkspaceSwitchExecutor` treats as a failed move
/// and rolls back.
///
/// Isolation: the adapter itself is off the main actor, but the scan and the move
/// both run on the main actor via the injected `@MainActor @Sendable` closures
/// (that is where `IconMoveService` and the scanner live).
nonisolated struct WorkspaceMoveExecutor: MoveExecuting {
    private let scan: @MainActor @Sendable () async -> [MenuBarItemSnapshot]
    private let performMove: @MainActor @Sendable (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult
    private let keyFor: @Sendable (MenuBarItemSnapshot) -> String

    init(
        scan: @escaping @MainActor @Sendable () async -> [MenuBarItemSnapshot],
        performMove: @escaping @MainActor @Sendable (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult,
        keyFor: @escaping @Sendable (MenuBarItemSnapshot) -> String = WorkspaceItemKey.key(for:)
    ) {
        self.scan = scan
        self.performMove = performMove
        self.keyFor = keyFor
    }

    func move(itemKey: String, command: IconMoveCommand) async -> Bool {
        let snapshots = await scan()
        guard let snapshot = snapshots.first(where: { keyFor($0) == itemKey }) else {
            return false
        }
        let result = await performMove(snapshot, command)
        return result.outcome == .succeeded
    }
}
