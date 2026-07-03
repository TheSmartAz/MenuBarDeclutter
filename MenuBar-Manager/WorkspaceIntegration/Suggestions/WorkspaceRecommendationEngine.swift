import Foundation

nonisolated struct WorkspaceRecommendationEngine: Sendable {
    func badges(
        usage: WorkspaceItemUsage,
        isNew: Bool = false,
        isMissing: Bool = false,
        isStale: Bool = false,
        isProtected: Bool = false
    ) -> [WorkspaceUsageBadge] {
        var badges: [WorkspaceUsageBadge] = []
        if usage.isUsedInActiveWorkspace { badges.append(.currentWorkspace) }
        if usage.workspaceIDs.count > 1 { badges.append(.usedInWorkspaces) }
        if usage.isUnassigned { badges.append(.unassigned) }
        if isNew { badges.append(.new) }
        if usage.linkedGroupReferenceCount > 0 { badges.append(.linkedGroup) }
        if usage.detachedGroupReferenceCount > 0 { badges.append(.detachedGroup) }
        if isMissing { badges.append(.missingReference) }
        if isStale { badges.append(.stale) }
        if isProtected { badges.append(.protected) }
        return badges
    }
}
