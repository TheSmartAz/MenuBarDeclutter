import Foundation

/// The result of applying a workspace's real layout: the plan that was computed
/// (also usable as a dry-run preview) plus the atomic apply outcome.
nonisolated struct WorkspaceLayoutApplyResult: Equatable, Sendable {
    let plan: WorkspaceReconciliationPlan
    let outcome: WorkspaceSwitchOutcome
}

/// Orchestrates a Level-2 workspace switch: reconcile the live scan against the
/// workspace's target visibility, then apply the moves atomically. Pure
/// composition over the (tested) planner + executor + a `MoveExecuting`, so the
/// whole path is unit-testable with a fake mover.
nonisolated struct WorkspaceLayoutSwitcher {
    private let planner: WorkspaceReconciliationPlanner
    private let executor: WorkspaceSwitchExecutor
    private let keyFor: @Sendable (MenuBarItemSnapshot) -> String

    init(
        planner: WorkspaceReconciliationPlanner = WorkspaceReconciliationPlanner(),
        executor: WorkspaceSwitchExecutor = WorkspaceSwitchExecutor(),
        keyFor: @escaping @Sendable (MenuBarItemSnapshot) -> String = WorkspaceItemKey.key(for:)
    ) {
        self.planner = planner
        self.executor = executor
        self.keyFor = keyFor
    }

    /// Dry-run: the moves needed to reach `workspace`'s target from `currentScan`.
    /// Touches nothing. System items are excluded from the current state (they
    /// are not managed), so a target referencing one surfaces as unresolved.
    func plan(
        for workspace: MenuBarWorkspace,
        currentScan: [MenuBarItemSnapshot]
    ) -> WorkspaceReconciliationPlan {
        let current = currentScan
            .filter { !$0.isLikelySystemItem }
            .map { ReconciliationItemState(itemKey: keyFor($0), currentZone: $0.zone) }
        return planner.plan(current: current, target: workspace.itemTargets)
    }

    /// Applies the workspace's target layout atomically via `mover`.
    func apply(
        _ workspace: MenuBarWorkspace,
        currentScan: [MenuBarItemSnapshot],
        using mover: any MoveExecuting
    ) async -> WorkspaceLayoutApplyResult {
        let plan = plan(for: workspace, currentScan: currentScan)
        let outcome = await executor.apply(plan, using: mover)
        return WorkspaceLayoutApplyResult(plan: plan, outcome: outcome)
    }
}
