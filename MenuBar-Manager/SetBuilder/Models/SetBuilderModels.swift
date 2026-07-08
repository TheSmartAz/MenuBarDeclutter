import Foundation

nonisolated struct SetBuilderDraft: Identifiable, Equatable, Sendable {
    var id: UUID { workspaceID }
    var workspaceID: UUID
    var originalWorkspace: MenuBarWorkspace
    var editedWorkspace: MenuBarWorkspace
    var pendingChanges: [SetBuilderChange]
    var validationIssues: [SetBuilderValidationIssue]
    var isDirty: Bool
    var lastAutosavedAt: Date?

    init(workspace: MenuBarWorkspace) {
        self.workspaceID = workspace.id
        self.originalWorkspace = workspace
        self.editedWorkspace = workspace
        self.pendingChanges = []
        self.validationIssues = []
        self.isDirty = false
        self.lastAutosavedAt = nil
    }
}

nonisolated struct SetBuilderItemIcon: Equatable, Sendable {
    var systemName: String
}

nonisolated enum SetBuilderItemStatus: String, Equatable, Sendable {
    case valid
    case missingReference
    case requiresPro
    case requiresAccessibility
    case stale
    case protected
    case deferred
    case invalid
}

nonisolated enum SetBuilderItemSource: String, Equatable, Sendable {
    case workspace
    case commandLibrary
    case groupLibrary
    case proxyLibrary
    case layoutLibrary
    case infoTileLibrary
}

nonisolated enum SetBuilderChange: Equatable, Sendable {
    case addItem(WorkspaceItem)
    case removeItem(UUID)
    case moveItem(itemID: UUID, from: Int, to: Int)
    case updateItem(WorkspaceItem)
    case renameWorkspace(String)
    case changeWorkspaceIcon(String)
    case addGroupReference(WorkspaceGroupReference)
    case detachGroupReference(groupID: UUID, newGroupID: UUID)
    case updateInfoStripConfig(WorkspaceInfoStripConfig)
}

nonisolated struct SetBuilderValidationIssue: Equatable, Sendable {
    var message: String
}

nonisolated struct SetBuilderLibraryItem: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var subtitle: String?
    var systemImage: String
    var kind: SetBuilderLibraryItemKind
    var isEnabled: Bool
    var badge: String?
}

nonisolated enum SetBuilderLibraryItemKind: Equatable, Sendable {
    case command(WorkspaceCommandReference)
    case group(UUID)
    case menuBarItem(MenuBarItemReference)
    case spacer
    case divider
    case infoTile(String)
}

nonisolated enum SetBuilderSelection: Equatable, Sendable {
    case none
    case workspace(UUID)
    case item(UUID)
}

nonisolated struct WorkspaceGroupUsageIndex: Equatable, Sendable {
    private var referencesByGroupID: [UUID: Set<UUID>]

    init(workspaces: [MenuBarWorkspace]) {
        var referencesByGroupID: [UUID: Set<UUID>] = [:]
        for workspace in workspaces {
            for item in workspace.functionItems {
                guard case .group(let reference) = item.kind,
                      reference.referenceMode == .linked else {
                    continue
                }
                referencesByGroupID[reference.groupID, default: []].insert(workspace.id)
            }
        }
        self.referencesByGroupID = referencesByGroupID
    }

    func workspacesReferencing(groupID: UUID) -> [UUID] {
        (referencesByGroupID[groupID] ?? []).sorted { $0.uuidString < $1.uuidString }
    }

    func referenceCount(groupID: UUID) -> Int {
        workspacesReferencing(groupID: groupID).count
    }
}

nonisolated struct SetBuilderDiagnosticsSnapshot: Codable, Equatable, Sendable {
    var previewEnabled: Bool
    var workspaceCount: Int
    var workspaceWithItemsCount: Int
    var totalWorkspaceItemCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var missingGroupReferenceCount: Int
    var detachedSourceGroupMissingCount: Int = 0
    var menuBarProxyReferenceCount: Int
    var unresolvedMenuBarProxyReferenceCount: Int = 0
    var commandItemCount: Int
    var spacerDividerCount: Int
    var lastCommitResult: String?
    var lastValidationIssueCount: Int

    static func make(
        previewEnabled: Bool,
        workspaces: [MenuBarWorkspace],
        groups: [IconGroup],
        lastCommitResult: String?,
        lastValidationIssueCount: Int,
        availableMenuBarItemHashes: Set<String>? = nil
    ) -> SetBuilderDiagnosticsSnapshot {
        let knownGroupIDs = Set(groups.map(\.id))
        var linkedGroupReferenceCount = 0
        var detachedGroupReferenceCount = 0
        var missingGroupReferenceCount = 0
        var detachedSourceGroupMissingCount = 0
        var menuBarProxyReferenceCount = 0
        var unresolvedMenuBarProxyReferenceCount = 0
        var commandItemCount = 0
        var spacerDividerCount = 0

        for item in workspaces.flatMap(\.functionItems) {
            switch item.kind {
            case .group(let reference):
                if reference.referenceMode == .detached {
                    detachedGroupReferenceCount += 1
                } else {
                    linkedGroupReferenceCount += 1
                }
                if !knownGroupIDs.contains(reference.groupID) {
                    missingGroupReferenceCount += 1
                }
                if reference.referenceMode == .detached,
                   let sourceGroupID = reference.sourceGroupID,
                   !knownGroupIDs.contains(sourceGroupID) {
                    detachedSourceGroupMissingCount += 1
                }
            case .menuBarItem(let reference):
                menuBarProxyReferenceCount += 1
                if let availableMenuBarItemHashes,
                   !availableMenuBarItemHashes.contains(reference.stableHash) {
                    unresolvedMenuBarProxyReferenceCount += 1
                }
            case .command:
                commandItemCount += 1
            case .spacer, .divider:
                spacerDividerCount += 1
            case .infoTile:
                break
            }
        }

        return SetBuilderDiagnosticsSnapshot(
            previewEnabled: previewEnabled,
            workspaceCount: workspaces.count,
            workspaceWithItemsCount: workspaces.filter { !$0.functionItems.isEmpty }.count,
            totalWorkspaceItemCount: workspaces.reduce(0) { $0 + $1.functionItems.count },
            linkedGroupReferenceCount: linkedGroupReferenceCount,
            detachedGroupReferenceCount: detachedGroupReferenceCount,
            missingGroupReferenceCount: missingGroupReferenceCount,
            detachedSourceGroupMissingCount: detachedSourceGroupMissingCount,
            menuBarProxyReferenceCount: menuBarProxyReferenceCount,
            unresolvedMenuBarProxyReferenceCount: unresolvedMenuBarProxyReferenceCount,
            commandItemCount: commandItemCount,
            spacerDividerCount: spacerDividerCount,
            lastCommitResult: lastCommitResult,
            lastValidationIssueCount: lastValidationIssueCount
        )
    }
}
