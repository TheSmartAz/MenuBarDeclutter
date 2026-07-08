import Foundation

/// A compact, display-ready summary of a reconciliation plan for the Workspaces
/// settings UI. Pure and testable — the view renders `sentence`.
nonisolated struct WorkspaceLayoutPlanSummary: Equatable, Sendable {
    let moveCount: Int
    let hideCount: Int
    let revealCount: Int
    let satisfiedCount: Int
    let unresolvedCount: Int

    var isEmpty: Bool { moveCount == 0 }
    var hasSavedTargets: Bool { moveCount > 0 || satisfiedCount > 0 || unresolvedCount > 0 }

    init(_ plan: WorkspaceReconciliationPlan) {
        self.moveCount = plan.moves.count
        self.hideCount = plan.moves.filter { Self.hiddenness($0.to) > Self.hiddenness($0.from) }.count
        self.revealCount = plan.moves.filter { Self.hiddenness($0.to) < Self.hiddenness($0.from) }.count
        self.satisfiedCount = plan.alreadySatisfiedItemKeys.count
        self.unresolvedCount = plan.unresolvedItemKeys.count
    }

    var sentence: String {
        guard moveCount > 0 else {
            return hasSavedTargets
                ? "Bar already matches this Workspace."
                : "No layout saved for this Workspace yet."
        }
        var parts = ["\(moveCount) move\(moveCount == 1 ? "" : "s")"]
        if hideCount > 0 { parts.append("\(hideCount) to hide") }
        if revealCount > 0 { parts.append("\(revealCount) to reveal") }
        var sentence = parts.joined(separator: ", ")
        if unresolvedCount > 0 { sentence += " • \(unresolvedCount) not found" }
        return sentence
    }

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
