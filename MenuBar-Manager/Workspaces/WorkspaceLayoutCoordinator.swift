import Foundation

/// Ties the Level-2 pieces to the running app: captures the current bar into a
/// workspace's target visibility, and applies a workspace's layout to the real
/// bar — but only when the Assisted Move apply gate is on.
///
/// The gate defaults closed: with no targets, or the gate off, a switch stays
/// config-only (the existing Level-0 behavior), so real icons are never moved
/// unless the user has opted in.
@MainActor
final class WorkspaceLayoutCoordinator {
    private let switcher: WorkspaceLayoutSwitcher
    private let scan: @MainActor @Sendable () async -> [MenuBarItemSnapshot]
    private let mover: any MoveExecuting
    private let isApplyEnabled: () -> Bool
    private let log: (WorkspaceLayoutApplyResult) -> Void

    /// Item keys that failed to move this session; skipped on later applies so we
    /// don't re-attempt lost causes (background agents, drag-rejecting apps).
    private var knownUnmovableKeys: Set<String> = []

    init(
        switcher: WorkspaceLayoutSwitcher = WorkspaceLayoutSwitcher(),
        scan: @escaping @MainActor @Sendable () async -> [MenuBarItemSnapshot],
        mover: any MoveExecuting,
        isApplyEnabled: @escaping () -> Bool,
        log: @escaping (WorkspaceLayoutApplyResult) -> Void = { _ in }
    ) {
        self.switcher = switcher
        self.scan = scan
        self.mover = mover
        self.isApplyEnabled = isApplyEnabled
        self.log = log
    }

    /// Returns a copy of `workspace` whose `itemTargets` capture the current bar
    /// ("save this layout"). The caller persists it via the switching service.
    func captureCurrentLayout(into workspace: MenuBarWorkspace) async -> MenuBarWorkspace {
        let snapshots = await scan()
        var updated = workspace
        updated.itemTargets = WorkspaceItemTarget.capture(from: snapshots)
        return updated
    }

    /// Applies a workspace's target layout to the real bar iff the apply gate is
    /// on and the workspace has targets. Returns `nil` when it stayed hands-off.
    @discardableResult
    func applyLayoutIfEnabled(for workspace: MenuBarWorkspace) async -> WorkspaceLayoutApplyResult? {
        guard isApplyEnabled(), !workspace.itemTargets.isEmpty else { return nil }
        let snapshots = await scan()

        // Skip items already known unmovable this session so we don't re-attempt
        // lost causes; only the movable targets go to the switcher.
        let skipped = workspace.itemTargets
            .map(\.itemKey)
            .filter { knownUnmovableKeys.contains($0) }
        var movable = workspace
        movable.itemTargets = workspace.itemTargets.filter { !knownUnmovableKeys.contains($0.itemKey) }

        let applied = await switcher.apply(movable, currentScan: snapshots, using: mover)
        // Learn: anything that failed this pass is treated as unmovable next time.
        knownUnmovableKeys.formUnion(applied.outcome.failedItemKeys)

        let result = WorkspaceLayoutApplyResult(
            plan: applied.plan,
            outcome: applied.outcome,
            skippedUnmovableKeys: skipped
        )
        log(result)
        return result
    }
}
