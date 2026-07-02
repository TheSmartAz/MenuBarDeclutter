import Foundation

nonisolated struct SetBuilderDragPayload: Codable, Equatable, Sendable {
    var payloadID: UUID
    var payloadKind: SetBuilderDragPayloadKind
    var sourceKind: SetBuilderDragSourceKind
}

nonisolated enum SetBuilderDragPayloadKind: Codable, Equatable, Sendable {
    case command(String)
    case group(UUID)
    case menuBarItemHash(String)
    case spacer
    case divider
    case existingWorkspaceItem(UUID)
}

nonisolated enum SetBuilderDragSourceKind: String, Codable, Equatable, Sendable {
    case library
    case workspaceCanvas
}

nonisolated enum SetBuilderDropTarget: Equatable, Sendable {
    case workspaceCanvas(workspaceID: UUID, index: Int)
    case groupEditor(groupID: UUID, index: Int)
    case library
    case trash
}

nonisolated struct SetBuilderDropValidationResult: Equatable, Sendable {
    var isAccepted: Bool
    var reason: String?

    static let accepted = SetBuilderDropValidationResult(isAccepted: true, reason: nil)
    static func rejected(_ reason: String) -> SetBuilderDropValidationResult {
        SetBuilderDropValidationResult(isAccepted: false, reason: reason)
    }
}

nonisolated struct SetBuilderDropValidator {
    var maxItems: Int = WorkspaceValidationConstants.maxFunctionItems

    func validate(
        payload: SetBuilderDragPayload,
        target: SetBuilderDropTarget,
        workspace: MenuBarWorkspace?,
        groups: [IconGroup],
        dragDropEnabled: Bool,
        safeModeActive: Bool = false,
        proDiscoveryAvailable: Bool = true,
        availableMenuBarItemHashes: Set<String>? = nil
    ) -> SetBuilderDropValidationResult {
        guard dragDropEnabled else { return .rejected("Drag and drop is disabled.") }
        guard !safeModeActive else { return .rejected("Safe Mode disables drag and drop commits.") }
        guard case .workspaceCanvas(_, let index) = target else {
            return .rejected("This drop target is not supported yet.")
        }
        guard let workspace else { return .rejected("Workspace is unavailable.") }
        guard index >= 0 && index <= workspace.functionItems.count else {
            return .rejected("Drop index is invalid.")
        }
        guard workspace.functionItems.count < maxItems else {
            return .rejected("Workspace item limit reached.")
        }
        if case .group(let groupID) = payload.payloadKind,
           !groups.contains(where: { $0.id == groupID }) {
            return .rejected("Group is missing.")
        }
        if case .command(let actionID) = payload.payloadKind,
           !Self.isSupportedCommand(actionID) {
            return .rejected("Command is unsupported.")
        }
        if case .menuBarItemHash(let hash) = payload.payloadKind {
            guard proDiscoveryAvailable else {
                return .rejected("Menu bar item drops require Pro Discovery metadata.")
            }
            guard !hash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .rejected("Menu bar item reference is invalid.")
            }
            if let availableMenuBarItemHashes, !availableMenuBarItemHashes.contains(hash) {
                return .rejected("Menu bar item reference is unavailable.")
            }
        }
        return .accepted
    }

    private static func isSupportedCommand(_ actionID: String) -> Bool {
        WorkspaceCommandReference.supportedActionIDs.contains(actionID)
    }
}
