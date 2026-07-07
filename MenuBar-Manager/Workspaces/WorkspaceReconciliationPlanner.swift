import Foundation

/// The desired end-state zone for one real menu bar item under a workspace.
/// Codable so it doubles as the stored per-workspace visibility target.
nonisolated struct WorkspaceItemTarget: Codable, Equatable, Sendable {
    let itemKey: String
    let desiredZone: MenuBarZone

    init(itemKey: String, desiredZone: MenuBarZone) {
        self.itemKey = itemKey
        self.desiredZone = desiredZone
    }

    /// Captures a workspace's desired visibility from the current live scan:
    /// each non-system, known-zone item's current zone becomes its target
    /// ("save this layout to the workspace"). Deduplicates by item key.
    static func capture(
        from snapshots: [MenuBarItemSnapshot],
        keyFor: (MenuBarItemSnapshot) -> String = WorkspaceItemKey.key(for:)
    ) -> [WorkspaceItemTarget] {
        var seen = Set<String>()
        var targets: [WorkspaceItemTarget] = []
        for snapshot in snapshots where !snapshot.isLikelySystemItem && snapshot.zone != .unknown {
            let key = keyFor(snapshot)
            guard seen.insert(key).inserted else { continue }
            targets.append(WorkspaceItemTarget(itemKey: key, desiredZone: snapshot.zone))
        }
        return targets
    }
}

/// The current observed zone of one real menu bar item, from a live scan.
nonisolated struct ReconciliationItemState: Equatable, Sendable {
    let itemKey: String
    let currentZone: MenuBarZone

    init(itemKey: String, currentZone: MenuBarZone) {
        self.itemKey = itemKey
        self.currentZone = currentZone
    }
}

/// One move a workspace switch will perform on a real item.
nonisolated struct PlannedMove: Equatable, Sendable {
    let itemKey: String
    let from: MenuBarZone
    let to: MenuBarZone

    /// Bridge to the measured single-move primitive used at execution time.
    var command: IconMoveCommand { .moveToZone(to) }
}

/// The full plan for switching to a workspace, expressed as visibility changes
/// on real items (Level-2). This is the dry-run preview *and* the execution
/// order; it never itself touches the menu bar.
///
/// Design decisions this encodes:
/// - **Least surprise:** items the workspace has no opinion on are left as-is
///   (never force-hidden), and targets not currently present are reported as
///   unresolved rather than failing the switch.
/// - **Hide-first ordering:** moves toward more-hidden zones run first, to free
///   visible-bar space and keep any partial state on the safer (more-hidden) side.
/// - **Atomic rollback support:** `rollbackPlan(afterApplying:)` reverses the
///   moves already applied so a failed switch can be undone all-or-nothing.
nonisolated struct WorkspaceReconciliationPlan: Equatable, Sendable {
    let moves: [PlannedMove]
    let unresolvedItemKeys: [String]
    let alreadySatisfiedItemKeys: [String]

    var isNoOp: Bool { moves.isEmpty }

    /// The reverse moves needed to undo the first `appliedCount` moves, in
    /// reverse application order (undo the most recent first).
    func rollbackPlan(afterApplying appliedCount: Int) -> [PlannedMove] {
        let clamped = max(0, min(appliedCount, moves.count))
        return moves.prefix(clamped).reversed().map {
            PlannedMove(itemKey: $0.itemKey, from: $0.to, to: $0.from)
        }
    }
}

/// Pure, deterministic reconciliation: given the live scan and a workspace's
/// desired visibility, produce the ordered set of real-item moves to realize it.
/// Fully unit-testable and independent of storage, UI, and execution.
nonisolated struct WorkspaceReconciliationPlanner {
    func plan(
        current: [ReconciliationItemState],
        target: [WorkspaceItemTarget]
    ) -> WorkspaceReconciliationPlan {
        let currentByKey = Dictionary(
            current.map { ($0.itemKey, $0.currentZone) },
            uniquingKeysWith: { first, _ in first }
        )
        let targetByKey = Dictionary(
            target.map { ($0.itemKey, $0.desiredZone) },
            uniquingKeysWith: { first, _ in first }
        )

        var moves: [PlannedMove] = []
        var unresolved: [String] = []
        var satisfied: [String] = []

        for (key, desiredZone) in targetByKey {
            guard let currentZone = currentByKey[key] else {
                unresolved.append(key)
                continue
            }
            if currentZone == desiredZone {
                satisfied.append(key)
            } else {
                moves.append(PlannedMove(itemKey: key, from: currentZone, to: desiredZone))
            }
        }

        moves.sort { lhs, rhs in
            let lhsHidden = Self.hiddenness(lhs.to)
            let rhsHidden = Self.hiddenness(rhs.to)
            return lhsHidden != rhsHidden ? lhsHidden > rhsHidden : lhs.itemKey < rhs.itemKey
        }

        return WorkspaceReconciliationPlan(
            moves: moves,
            unresolvedItemKeys: unresolved.sorted(),
            alreadySatisfiedItemKeys: satisfied.sorted()
        )
    }

    /// Higher = more hidden. Drives hide-first ordering.
    private static func hiddenness(_ zone: MenuBarZone) -> Int {
        switch zone {
        case .alwaysHidden:
            3
        case .hidden:
            2
        case .visible:
            1
        case .unknown:
            0
        }
    }
}
