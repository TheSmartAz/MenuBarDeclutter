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
        let result = await switcher.apply(workspace, currentScan: snapshots, using: mover)
        log(result)
        return result
    }
}
