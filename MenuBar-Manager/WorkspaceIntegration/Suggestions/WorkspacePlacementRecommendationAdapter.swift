import Foundation

nonisolated enum WorkspacePlacementReason: Equatable, Sendable {
    case currentWorkspace
    case multipleWorkspaces(Int)
    case inactiveWorkspaceOnly
    case linkedGroup
    case detachedGroup
    case unassigned
    case noWorkspaceSignal

    var message: String {
        switch self {
        case .currentWorkspace:
            "Used in the current Workspace."
        case .multipleWorkspaces(let count):
            "Used in \(count) Workspaces."
        case .inactiveWorkspaceOnly:
            "Used only outside the current Workspace."
        case .linkedGroup:
            "Used through a linked Group."
        case .detachedGroup:
            "Used through a detached Group copy."
        case .unassigned:
            "Not assigned to any Workspace."
        case .noWorkspaceSignal:
            "No Workspace-specific recommendation."
        }
    }
}

nonisolated enum WorkspaceSuggestedAction: Equatable, Sendable {
    case addToCurrentWorkspace
    case addToGroup(UUID)
    case keepHiddenExposeInFunctionBar
    case removeFromInactiveWorkspace
    case reviewUnassigned
    case noWorkspaceAction
}

nonisolated struct WorkspaceAwarePlacementRecommendation: Equatable, Sendable {
    var baseRecommendation: PlacementRecommendation
    var usage: WorkspaceItemUsage
    var workspaceReason: WorkspacePlacementReason
    var suggestedWorkspaceAction: WorkspaceSuggestedAction?
}

nonisolated final class WorkspacePlacementRecommendationAdapter {
    func enrich(
        _ recommendation: PlacementRecommendation,
        usage: WorkspaceItemUsage
    ) -> WorkspaceAwarePlacementRecommendation {
        let reason: WorkspacePlacementReason
        if usage.isUnassigned {
            reason = .unassigned
        } else if usage.isUsedInActiveWorkspace {
            reason = .currentWorkspace
        } else if usage.workspaceIDs.count > 1 {
            reason = .multipleWorkspaces(usage.workspaceIDs.count)
        } else if usage.linkedGroupReferenceCount > 0 {
            reason = .linkedGroup
        } else if usage.detachedGroupReferenceCount > 0 {
            reason = .detachedGroup
        } else if !usage.workspaceIDs.isEmpty {
            reason = .inactiveWorkspaceOnly
        } else {
            reason = .noWorkspaceSignal
        }

        return WorkspaceAwarePlacementRecommendation(
            baseRecommendation: recommendation,
            usage: usage,
            workspaceReason: reason,
            suggestedWorkspaceAction: suggestedAction(for: recommendation, usage: usage)
        )
    }

    private func suggestedAction(
        for recommendation: PlacementRecommendation,
        usage: WorkspaceItemUsage
    ) -> WorkspaceSuggestedAction {
        if usage.isUnassigned {
            return recommendation == .moveToHidden || recommendation == .moveToAlwaysHidden
                ? .keepHiddenExposeInFunctionBar
                : .reviewUnassigned
        }
        if !usage.isUsedInActiveWorkspace, !usage.workspaceIDs.isEmpty {
            return .addToCurrentWorkspace
        }
        return .noWorkspaceAction
    }
}
