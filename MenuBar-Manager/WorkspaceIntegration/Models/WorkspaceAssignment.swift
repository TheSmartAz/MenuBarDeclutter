import Foundation

nonisolated enum WorkspaceAssignmentTarget: Equatable, Sendable {
    case currentWorkspace
    case workspace(UUID)
    case group(UUID)
    case newGroup(name: String, workspaceID: UUID?)
    case visibleOnly
    case manualHidden
    case manualAlwaysHidden
    case noAssignment
}

nonisolated struct WorkspaceAssignmentResult: Equatable, Sendable {
    var status: WorkspaceAssignmentStatus
    var message: String
    var workspaceID: UUID?
    var groupID: UUID?
    var diagnosticReason: String?

    var shouldDismissNewItem: Bool {
        switch status {
        case .success, .noChange:
            true
        case .unavailable, .requiresPro, .missingWorkspace, .missingGroup, .validationFailed, .blockedBySafeMode, .failed:
            false
        }
    }
}

nonisolated enum WorkspaceAssignmentStatus: Equatable, Sendable {
    case success
    case noChange
    case unavailable
    case requiresPro
    case missingWorkspace
    case missingGroup
    case validationFailed
    case blockedBySafeMode
    case failed
}

nonisolated enum WorkspaceAssignmentValidator {
    static func canMutate(target: WorkspaceAssignmentTarget, safeModeActive: Bool) -> WorkspaceAssignmentResult? {
        guard safeModeActive else { return nil }
        switch target {
        case .visibleOnly, .manualHidden, .manualAlwaysHidden, .noAssignment:
            return nil
        case .currentWorkspace, .workspace, .group, .newGroup:
            return WorkspaceAssignmentResult(
                status: .blockedBySafeMode,
                message: "Safe Mode keeps Workspace assignment changes paused.",
                workspaceID: nil,
                groupID: nil,
                diagnosticReason: "safeMode"
            )
        }
    }
}
