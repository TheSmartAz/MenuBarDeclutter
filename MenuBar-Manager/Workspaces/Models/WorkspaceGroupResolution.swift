import Foundation

nonisolated struct WorkspaceGroupResolution: Equatable, Sendable {
    var groupID: UUID
    var status: WorkspaceGroupResolutionStatus
    var itemCount: Int
}

nonisolated enum WorkspaceGroupResolutionStatus: String, Codable, Equatable, Sendable {
    case resolved
    case missing
    case protected
    case unavailable
}

nonisolated enum WorkspaceGroupResolver {
    static func resolve(
        reference: WorkspaceGroupReference,
        groups: [IconGroup]
    ) -> WorkspaceGroupResolution {
        guard let group = groups.first(where: { $0.id == reference.groupID }) else {
            return WorkspaceGroupResolution(groupID: reference.groupID, status: .missing, itemCount: 0)
        }

        if !group.isEnabled {
            return WorkspaceGroupResolution(groupID: reference.groupID, status: .unavailable, itemCount: group.itemCount)
        }

        if group.isProtected {
            return WorkspaceGroupResolution(groupID: reference.groupID, status: .protected, itemCount: group.itemCount)
        }

        return WorkspaceGroupResolution(groupID: reference.groupID, status: .resolved, itemCount: group.itemCount)
    }

    static func resolve(
        reference: WorkspaceGroupReference,
        knownGroupIDs: Set<UUID>?,
        protectedGroupIDs: Set<UUID> = [],
        itemCountsByGroupID: [UUID: Int] = [:]
    ) -> WorkspaceGroupResolution {
        guard let knownGroupIDs else {
            return WorkspaceGroupResolution(
                groupID: reference.groupID,
                status: .unavailable,
                itemCount: itemCountsByGroupID[reference.groupID] ?? 0
            )
        }

        if !knownGroupIDs.contains(reference.groupID) {
            return WorkspaceGroupResolution(groupID: reference.groupID, status: .missing, itemCount: 0)
        }

        if protectedGroupIDs.contains(reference.groupID) {
            return WorkspaceGroupResolution(
                groupID: reference.groupID,
                status: .protected,
                itemCount: itemCountsByGroupID[reference.groupID] ?? 0
            )
        }

        return WorkspaceGroupResolution(
            groupID: reference.groupID,
            status: .resolved,
            itemCount: itemCountsByGroupID[reference.groupID] ?? 0
        )
    }
}
