import Foundation

@MainActor
final class WorkspaceAssignmentService {
    private let switchingService: WorkspaceSwitchingService
    private let groupStore: IconGroupStore?
    private let newItemInboxStore: NewMenuBarItemInboxStore?
    private let safeModeActive: () -> Bool
    private let previewEnabled: () -> Bool
    private let now: () -> Date

    init(
        switchingService: WorkspaceSwitchingService,
        groupStore: IconGroupStore?,
        newItemInboxStore: NewMenuBarItemInboxStore? = nil,
        safeModeActive: @escaping () -> Bool = { false },
        previewEnabled: @escaping () -> Bool = { true },
        now: @escaping () -> Date = { Date() }
    ) {
        self.switchingService = switchingService
        self.groupStore = groupStore
        self.newItemInboxStore = newItemInboxStore
        self.safeModeActive = safeModeActive
        self.previewEnabled = previewEnabled
        self.now = now
    }

    func assignNewItem(_ item: NewMenuBarItem, to target: WorkspaceAssignmentTarget) -> WorkspaceAssignmentResult {
        let reference = MenuBarItemReference(stableHash: item.id, source: .itemMemory)
        let result = assignItemReference(reference, to: target)
        if result.shouldDismissNewItem {
            newItemInboxStore?.dismiss(itemID: item.id)
        }
        return result
    }

    func assignItemReference(
        _ reference: MenuBarItemReference,
        to target: WorkspaceAssignmentTarget
    ) -> WorkspaceAssignmentResult {
        if let validation = WorkspaceAssignmentValidator.canMutate(target: target, safeModeActive: safeModeActive()) {
            return validation
        }

        switch target {
        case .visibleOnly:
            return noMutationResult("Kept visible without Workspace assignment.", reason: "visibleOnly")
        case .manualHidden:
            return noMutationResult("Created manual hidden-placement recommendation. No icon was moved.", reason: "manualHidden")
        case .manualAlwaysHidden:
            return noMutationResult("Created manual always-hidden recommendation. No icon was moved.", reason: "manualAlwaysHidden")
        case .noAssignment:
            return noMutationResult("Left item unassigned.", reason: "noAssignment")
        case .currentWorkspace:
            guard previewEnabled() else { return previewUnavailableResult() }
            return assign(reference, toWorkspaceID: switchingService.activeWorkspace().id)
        case .workspace(let workspaceID):
            guard previewEnabled() else { return previewUnavailableResult() }
            return assign(reference, toWorkspaceID: workspaceID)
        case .group(let groupID):
            return assign(reference, toGroupID: groupID)
        case .newGroup(let name, let workspaceID):
            return createGroup(reference: reference, name: name, linkToWorkspaceID: workspaceID)
        }
    }

    private func assign(_ reference: MenuBarItemReference, toWorkspaceID workspaceID: UUID) -> WorkspaceAssignmentResult {
        let snapshot = switchingService.currentSnapshot()
        guard var workspace = snapshot.workspaces.first(where: { $0.id == workspaceID && !$0.isArchived }) else {
            return WorkspaceAssignmentResult(
                status: .missingWorkspace,
                message: "Workspace not found.",
                workspaceID: workspaceID,
                groupID: nil,
                diagnosticReason: "missingWorkspace"
            )
        }

        if workspace.functionItems.contains(where: { item in
            if case .menuBarItem(let existing) = item.kind {
                return existing.stableHash == reference.stableHash
            }
            return false
        }) {
            return WorkspaceAssignmentResult(
                status: .noChange,
                message: "Item is already in this Workspace.",
                workspaceID: workspaceID,
                groupID: nil,
                diagnosticReason: "alreadyAssigned"
            )
        }

        workspace.functionItems.append(WorkspaceItem(
            kind: .menuBarItem(reference),
            createdAt: now(),
            updatedAt: now()
        ))
        workspace.updatedAt = now()

        let result = switchingService.updateWorkspace(workspace)
        guard result.status == .success else {
            return WorkspaceAssignmentResult(
                status: .failed,
                message: result.message,
                workspaceID: workspaceID,
                groupID: nil,
                diagnosticReason: result.diagnosticReason?.rawValue
            )
        }

        return WorkspaceAssignmentResult(
            status: .success,
            message: "Added item to Workspace.",
            workspaceID: workspaceID,
            groupID: nil,
            diagnosticReason: "workspaceAssigned"
        )
    }

    private func assign(_ reference: MenuBarItemReference, toGroupID groupID: UUID) -> WorkspaceAssignmentResult {
        guard let groupStore else {
            return WorkspaceAssignmentResult(
                status: .unavailable,
                message: "Group store is unavailable.",
                workspaceID: nil,
                groupID: groupID,
                diagnosticReason: "groupStoreUnavailable"
            )
        }
        guard groupStore.groups.contains(where: { $0.id == groupID }) else {
            return WorkspaceAssignmentResult(
                status: .missingGroup,
                message: "Group not found.",
                workspaceID: nil,
                groupID: groupID,
                diagnosticReason: "missingGroup"
            )
        }
        if groupStore.groups.first(where: { $0.id == groupID })?.itemRefs.contains(where: { $0.snapshotStableID == reference.stableHash }) == true {
            return WorkspaceAssignmentResult(
                status: .noChange,
                message: "Item is already in this Group.",
                workspaceID: nil,
                groupID: groupID,
                diagnosticReason: "alreadyInGroup"
            )
        }
        groupStore.addItem(to: groupID, ref: IconGroupItemRef(snapshotStableID: reference.stableHash))
        return WorkspaceAssignmentResult(
            status: .success,
            message: "Added item to Group.",
            workspaceID: nil,
            groupID: groupID,
            diagnosticReason: "groupAssigned"
        )
    }

    private func createGroup(
        reference: MenuBarItemReference,
        name: String,
        linkToWorkspaceID workspaceID: UUID?
    ) -> WorkspaceAssignmentResult {
        guard let groupStore else {
            return WorkspaceAssignmentResult(
                status: .unavailable,
                message: "Group store is unavailable.",
                workspaceID: workspaceID,
                groupID: nil,
                diagnosticReason: "groupStoreUnavailable"
            )
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return WorkspaceAssignmentResult(
                status: .validationFailed,
                message: "Group name is required.",
                workspaceID: workspaceID,
                groupID: nil,
                diagnosticReason: "emptyGroupName"
            )
        }

        let group = groupStore.createGroup(name: trimmedName)
        groupStore.addItem(to: group.id, ref: IconGroupItemRef(snapshotStableID: reference.stableHash))

        if let workspaceID {
            let linkResult = link(groupID: group.id, toWorkspaceID: workspaceID)
            guard linkResult.status == .success || linkResult.status == .noChange else {
                return WorkspaceAssignmentResult(
                    status: linkResult.status,
                    message: "Created Group, but could not link it to the Workspace.",
                    workspaceID: workspaceID,
                    groupID: group.id,
                    diagnosticReason: linkResult.diagnosticReason
                )
            }
        }

        return WorkspaceAssignmentResult(
            status: .success,
            message: workspaceID == nil ? "Created Group with item." : "Created Group with item and linked it to Workspace.",
            workspaceID: workspaceID,
            groupID: group.id,
            diagnosticReason: "newGroupAssigned"
        )
    }

    private func link(groupID: UUID, toWorkspaceID workspaceID: UUID) -> WorkspaceAssignmentResult {
        let snapshot = switchingService.currentSnapshot()
        guard var workspace = snapshot.workspaces.first(where: { $0.id == workspaceID && !$0.isArchived }) else {
            return WorkspaceAssignmentResult(
                status: .missingWorkspace,
                message: "Workspace not found.",
                workspaceID: workspaceID,
                groupID: groupID,
                diagnosticReason: "missingWorkspace"
            )
        }

        if workspace.functionItems.contains(where: { item in
            if case .group(let reference) = item.kind {
                return reference.groupID == groupID
            }
            return false
        }) {
            return WorkspaceAssignmentResult(
                status: .noChange,
                message: "Group is already linked to Workspace.",
                workspaceID: workspaceID,
                groupID: groupID,
                diagnosticReason: "alreadyLinked"
            )
        }

        let reference = WorkspaceGroupReference(groupID: groupID, referenceMode: .linked, createdAt: now())
        workspace.functionItems.append(WorkspaceItem(kind: .group(reference), createdAt: now(), updatedAt: now()))
        workspace.updatedAt = now()
        let result = switchingService.updateWorkspace(workspace)
        return WorkspaceAssignmentResult(
            status: result.status == .success ? .success : .failed,
            message: result.message,
            workspaceID: workspaceID,
            groupID: groupID,
            diagnosticReason: result.diagnosticReason?.rawValue
        )
    }

    private func noMutationResult(_ message: String, reason: String) -> WorkspaceAssignmentResult {
        WorkspaceAssignmentResult(
            status: .success,
            message: message,
            workspaceID: nil,
            groupID: nil,
            diagnosticReason: reason
        )
    }

    private func previewUnavailableResult() -> WorkspaceAssignmentResult {
        WorkspaceAssignmentResult(
            status: .unavailable,
            message: "Workspaces Preview is disabled.",
            workspaceID: nil,
            groupID: nil,
            diagnosticReason: "workspacesPreviewDisabled"
        )
    }
}
