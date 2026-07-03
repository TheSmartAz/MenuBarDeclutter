import Foundation

final class WorkspaceUsageIndex {
    private var snapshot: WorkspaceUsageIndexSnapshot = .empty

    @discardableResult
    func rebuild(
        snapshot storeSnapshot: WorkspaceStoreSnapshot,
        groups: [IconGroup],
        discoveredSnapshots: [MenuBarItemSnapshot] = []
    ) -> WorkspaceUsageIndexSnapshot {
        let groupsByID = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        let activeWorkspaceID = storeSnapshot.activeWorkspaceID
        let workspaces = storeSnapshot.workspaces.filter { !$0.isArchived }
        let groupMatcher = IconGroupMatcher()

        var builder = WorkspaceUsageBuilder(activeWorkspaceID: activeWorkspaceID)
        var workspaceIDsByGroupID: [UUID: Set<UUID>] = [:]
        var groupIDsByItemHash: [String: Set<UUID>] = [:]
        var missingGroupReferenceCount = 0

        for workspace in workspaces {
            for item in workspace.functionItems {
                switch item.kind {
                case .menuBarItem(let reference):
                    builder.addDirect(itemHash: reference.stableHash, workspaceID: workspace.id)
                case .group(let reference):
                    workspaceIDsByGroupID[reference.groupID, default: []].insert(workspace.id)
                    guard let group = groupsByID[reference.groupID] else {
                        missingGroupReferenceCount += 1
                        continue
                    }

                    for itemHash in itemHashes(
                        for: group,
                        discoveredSnapshots: discoveredSnapshots,
                        matcher: groupMatcher
                    ) {
                        groupIDsByItemHash[itemHash, default: []].insert(group.id)
                        builder.addGroup(
                            itemHash: itemHash,
                            groupID: group.id,
                            workspaceID: workspace.id,
                            referenceMode: reference.referenceMode
                        )
                    }
                case .command, .infoTile, .spacer, .divider:
                    break
                }
            }
        }

        self.snapshot = WorkspaceUsageIndexSnapshot(
            activeWorkspaceID: activeWorkspaceID,
            usagesByItemHash: builder.usages(),
            workspaceIDsByGroupID: workspaceIDsByGroupID.mapValues { sortedUUIDs($0) },
            groupIDsByItemHash: groupIDsByItemHash.mapValues { sortedUUIDs($0) },
            missingGroupReferenceCount: missingGroupReferenceCount,
            indexedWorkspaceCount: workspaces.count
        )
        return self.snapshot
    }

    func usage(for itemHash: String) -> WorkspaceItemUsage {
        snapshot.usage(for: itemHash)
    }

    func workspacesUsingItemHash(_ itemHash: String) -> [UUID] {
        usage(for: itemHash).workspaceIDs
    }

    func workspacesUsingGroup(_ groupID: UUID) -> [UUID] {
        snapshot.workspaceIDsByGroupID[groupID] ?? []
    }

    func groupsContainingItemHash(_ itemHash: String) -> [UUID] {
        snapshot.groupIDsByItemHash[itemHash] ?? []
    }

    func unassignedItemHashes(from discovered: [MenuBarItemReference]) -> [String] {
        discovered
            .map(\.stableHash)
            .filter { usage(for: $0).isUnassigned }
            .sorted()
    }

    func unassignedItemHashes(from discoveredSnapshots: [MenuBarItemSnapshot]) -> [String] {
        discoveredSnapshots
            .map(\.id)
            .filter { usage(for: $0).isUnassigned }
            .sorted()
    }

    private func itemHashes(
        for group: IconGroup,
        discoveredSnapshots: [MenuBarItemSnapshot],
        matcher: IconGroupMatcher
    ) -> [String] {
        var itemHashes: Set<String> = []

        if !discoveredSnapshots.isEmpty {
            for ref in group.itemRefs {
                for snapshot in matcher.match(ref: ref, snapshots: discoveredSnapshots) {
                    guard !snapshot.id.isEmpty else { continue }
                    itemHashes.insert(snapshot.id)
                }
            }
        }

        for itemHash in group.itemRefs.compactMap(\.snapshotStableID).filter({ !$0.isEmpty }) {
            itemHashes.insert(itemHash)
        }

        return itemHashes.sorted()
    }

    private func sortedUUIDs(_ ids: Set<UUID>) -> [UUID] {
        ids.sorted { $0.uuidString < $1.uuidString }
    }
}

private struct WorkspaceUsageBuilder {
    let activeWorkspaceID: UUID?
    private var workspaceIDsByItemHash: [String: Set<UUID>] = [:]
    private var groupIDsByItemHash: [String: Set<UUID>] = [:]
    private var directWorkspaceIDsByItemHash: [String: Set<UUID>] = [:]
    private var groupReferenceCountsByItemHash: [String: Int] = [:]
    private var linkedReferenceCountsByItemHash: [String: Int] = [:]
    private var detachedReferenceCountsByItemHash: [String: Int] = [:]

    init(activeWorkspaceID: UUID?) {
        self.activeWorkspaceID = activeWorkspaceID
    }

    mutating func addDirect(itemHash: String, workspaceID: UUID) {
        guard !itemHash.isEmpty else { return }
        workspaceIDsByItemHash[itemHash, default: []].insert(workspaceID)
        directWorkspaceIDsByItemHash[itemHash, default: []].insert(workspaceID)
    }

    mutating func addGroup(
        itemHash: String,
        groupID: UUID,
        workspaceID: UUID,
        referenceMode: WorkspaceGroupReferenceMode
    ) {
        guard !itemHash.isEmpty else { return }
        workspaceIDsByItemHash[itemHash, default: []].insert(workspaceID)
        groupIDsByItemHash[itemHash, default: []].insert(groupID)
        groupReferenceCountsByItemHash[itemHash, default: 0] += 1
        switch referenceMode {
        case .linked:
            linkedReferenceCountsByItemHash[itemHash, default: 0] += 1
        case .detached:
            detachedReferenceCountsByItemHash[itemHash, default: 0] += 1
        }
    }

    func usages() -> [String: WorkspaceItemUsage] {
        let allItemHashes = Set(workspaceIDsByItemHash.keys)
            .union(groupIDsByItemHash.keys)
            .union(directWorkspaceIDsByItemHash.keys)

        return Dictionary(uniqueKeysWithValues: allItemHashes.map { itemHash in
            let workspaceIDs = sortedUUIDs(workspaceIDsByItemHash[itemHash] ?? [])
            let groupIDs = sortedUUIDs(groupIDsByItemHash[itemHash] ?? [])
            return (
                itemHash,
                WorkspaceItemUsage(
                    itemHash: itemHash,
                    workspaceIDs: workspaceIDs,
                    groupIDs: groupIDs,
                    directWorkspaceCount: directWorkspaceIDsByItemHash[itemHash]?.count ?? 0,
                    groupReferenceCount: groupReferenceCountsByItemHash[itemHash] ?? 0,
                    linkedGroupReferenceCount: linkedReferenceCountsByItemHash[itemHash] ?? 0,
                    detachedGroupReferenceCount: detachedReferenceCountsByItemHash[itemHash] ?? 0,
                    isUsedInActiveWorkspace: activeWorkspaceID.map { workspaceIDs.contains($0) } ?? false,
                    isUnassigned: workspaceIDs.isEmpty && groupIDs.isEmpty
                )
            )
        })
    }

    private func sortedUUIDs(_ ids: Set<UUID>) -> [UUID] {
        ids.sorted { $0.uuidString < $1.uuidString }
    }
}
