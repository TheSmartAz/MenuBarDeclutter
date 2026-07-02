import Foundation

nonisolated struct WorkspaceDiagnosticsSnapshot: Codable, Equatable, Sendable {
    var workspaceFeatureEnabled: Bool
    var workspaceCount: Int
    var archivedWorkspaceCount: Int
    var activeWorkspacePresent: Bool
    var activeWorkspaceIDHash: String?
    var validationIssueCount: Int
    var groupReferenceCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var missingGroupReferenceCount: Int
    var detachedSourceGroupMissingCount: Int = 0
    var protectedGroupReferenceCount: Int
    var missingProfileBindingCount: Int
    var commandItemCount: Int
    var menuBarItemReferenceCount: Int
    var unresolvedMenuBarItemReferenceCount: Int = 0
    var infoTileReferenceCount: Int
    var lastLoadStatus: WorkspaceStoreLoadStatus

    @MainActor
    static func make(
        settingsStore: SettingsStore,
        snapshot: WorkspaceStoreSnapshot?,
        validationIssues: [WorkspaceValidationIssue],
        lastLoadStatus: WorkspaceStoreLoadStatus,
        knownGroupIDs: Set<UUID>? = nil,
        protectedGroupIDs: Set<UUID> = [],
        knownProfileIDs: Set<UUID>? = nil,
        availableMenuBarItemHashes: Set<String>? = nil
    ) -> WorkspaceDiagnosticsSnapshot {
        let workspaces = snapshot?.workspaces ?? []
        let activeID = snapshot?.activeWorkspaceID
        var commandCount = 0
        var itemReferenceCount = 0
        var infoTileCount = 0
        var groupReferenceCount = 0
        var linkedGroupReferenceCount = 0
        var detachedGroupReferenceCount = 0
        var missingGroups = 0
        var detachedMissingSources = 0
        var protectedGroups = 0
        var missingProfiles = 0
        var unresolvedMenuBarItems = 0

        for workspace in workspaces {
            if let binding = workspace.physicalProfileBinding,
               let knownProfileIDs,
               !knownProfileIDs.contains(binding.profileID) {
                missingProfiles += 1
            }

            for item in workspace.functionItems {
                switch item.kind {
                case .command:
                    commandCount += 1
                case .menuBarItem(let reference):
                    itemReferenceCount += 1
                    if let availableMenuBarItemHashes,
                       !availableMenuBarItemHashes.contains(reference.stableHash) {
                        unresolvedMenuBarItems += 1
                    }
                case .infoTile:
                    infoTileCount += 1
                case .group(let reference):
                    groupReferenceCount += 1
                    if reference.referenceMode == .linked {
                        linkedGroupReferenceCount += 1
                    } else {
                        detachedGroupReferenceCount += 1
                    }

                    let resolution = WorkspaceGroupResolver.resolve(
                        reference: reference,
                        knownGroupIDs: knownGroupIDs,
                        protectedGroupIDs: protectedGroupIDs
                    )
                    if resolution.status == .missing {
                        missingGroups += 1
                    }
                    if resolution.status == .protected {
                        protectedGroups += 1
                    }
                    if reference.referenceMode == .detached,
                       let sourceGroupID = reference.sourceGroupID,
                       let knownGroupIDs,
                       !knownGroupIDs.contains(sourceGroupID) {
                        detachedMissingSources += 1
                    }
                case .spacer, .divider:
                    break
                }
            }
            infoTileCount += workspace.infoItems.count
        }

        return WorkspaceDiagnosticsSnapshot(
            workspaceFeatureEnabled: settingsStore.workspacesPreviewEnabled,
            workspaceCount: workspaces.count,
            archivedWorkspaceCount: workspaces.filter(\.isArchived).count,
            activeWorkspacePresent: activeID.map { id in workspaces.contains { $0.id == id && !$0.isArchived } } ?? false,
            activeWorkspaceIDHash: activeID.map { WorkspaceDiagnosticsRedactor.hash(id: $0) },
            validationIssueCount: validationIssues.reduce(0) { $0 + $1.count },
            groupReferenceCount: groupReferenceCount,
            linkedGroupReferenceCount: linkedGroupReferenceCount,
            detachedGroupReferenceCount: detachedGroupReferenceCount,
            missingGroupReferenceCount: missingGroups,
            detachedSourceGroupMissingCount: detachedMissingSources,
            protectedGroupReferenceCount: protectedGroups,
            missingProfileBindingCount: missingProfiles,
            commandItemCount: commandCount,
            menuBarItemReferenceCount: itemReferenceCount,
            unresolvedMenuBarItemReferenceCount: unresolvedMenuBarItems,
            infoTileReferenceCount: infoTileCount,
            lastLoadStatus: lastLoadStatus
        )
    }
}

nonisolated enum WorkspaceDiagnosticsRedactor {
    static func hash(id: UUID) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in id.uuidString.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return "workspace-\(String(hash, radix: 16))"
    }

    static func displayName(for workspace: MenuBarWorkspace) -> String {
        workspace.isProtected ? "Protected Workspace" : workspace.name
    }
}
