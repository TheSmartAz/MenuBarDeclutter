import Foundation

@MainActor
final class WorkspaceSwitchingService {
    private let store: WorkspaceStoreProtocol
    private let safeModeActive: () -> Bool
    private let now: () -> Date

    private var snapshot: WorkspaceStoreSnapshot

    init(
        store: WorkspaceStoreProtocol,
        initialSnapshot: WorkspaceStoreSnapshot,
        safeModeActive: @escaping () -> Bool = { false },
        now: @escaping () -> Date = { Date() }
    ) {
        self.store = store
        self.snapshot = initialSnapshot
        self.safeModeActive = safeModeActive
        self.now = now
    }

    func reload() throws {
        snapshot = try store.load()
    }

    func importSnapshot(_ importedSnapshot: WorkspaceStoreSnapshot) throws {
        try store.save(importedSnapshot)
        snapshot = try store.load()
    }

    func currentSnapshot() -> WorkspaceStoreSnapshot {
        snapshot
    }

    func activeWorkspace() -> MenuBarWorkspace {
        if let activeID = snapshot.activeWorkspaceID,
           let workspace = snapshot.workspaces.first(where: { $0.id == activeID && !$0.isArchived }) {
            return workspace
        }
        return snapshot.workspaces.first(where: { !$0.isArchived })
            ?? MenuBarWorkspace.defaultWorkspaces(now: now())[0]
    }

    func switchWorkspace(id: UUID, source: WorkspaceSwitchSource = .settings) -> WorkspaceSwitchResult {
        guard let workspace = snapshot.workspaces.first(where: { $0.id == id }) else {
            return .init(status: .notFound, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace not found.", diagnosticReason: .workspaceMissing)
        }
        guard !workspace.isArchived else {
            return .init(status: .archived, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Archived workspaces cannot become active.", diagnosticReason: .workspaceArchived)
        }
        guard snapshot.activeWorkspaceID != id else {
            return .init(status: .noChange, activeWorkspaceID: id, message: "Workspace already active.", diagnosticReason: .noChange)
        }

        snapshot.activeWorkspaceID = id
        snapshot.updatedAt = now()
        return persist(status: .success, message: safeModeActive() ? "Workspace switched. Runtime previews remain suppressed in Safe Mode." : "Workspace switched.")
    }

    func createWorkspace(_ draft: WorkspaceDraft) -> WorkspaceSwitchResult {
        guard snapshot.workspaces.count < WorkspaceValidationConstants.maxWorkspaces else {
            return .init(
                status: .invalidWorkspace,
                activeWorkspaceID: snapshot.activeWorkspaceID,
                message: "Workspace limit reached.",
                diagnosticReason: .tooManyWorkspaces
            )
        }

        var workspace = MenuBarWorkspace(name: draft.name, iconName: draft.iconName, createdAt: now(), updatedAt: now())
        var issues: [WorkspaceValidationIssue] = []
        workspace = WorkspaceValidation.repair(workspace, issues: &issues, now: now())
        snapshot.workspaces.append(workspace)
        snapshot.activeWorkspaceID = workspace.id
        snapshot.updatedAt = now()
        return persist(status: .success, message: "Workspace created.")
    }

    func duplicateWorkspace(id: UUID) -> WorkspaceSwitchResult {
        guard snapshot.workspaces.count < WorkspaceValidationConstants.maxWorkspaces else {
            return .init(
                status: .invalidWorkspace,
                activeWorkspaceID: snapshot.activeWorkspaceID,
                message: "Workspace limit reached.",
                diagnosticReason: .tooManyWorkspaces
            )
        }

        guard let source = snapshot.workspaces.first(where: { $0.id == id }) else {
            return .init(status: .notFound, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace not found.", diagnosticReason: .workspaceMissing)
        }
        var copy = source
        copy.id = UUID()
        copy.name = "\(source.name) Copy"
        copy.isProtected = false
        copy.createdAt = now()
        copy.updatedAt = now()
        copy.functionItems = copy.functionItems.map { item in
            var copyItem = item
            copyItem.id = UUID()
            copyItem.createdAt = now()
            copyItem.updatedAt = now()
            return copyItem
        }
        snapshot.workspaces.append(copy)
        snapshot.activeWorkspaceID = copy.id
        snapshot.updatedAt = now()
        return persist(status: .success, message: "Workspace duplicated.")
    }

    func archiveWorkspace(id: UUID) -> WorkspaceSwitchResult {
        guard let index = snapshot.workspaces.firstIndex(where: { $0.id == id }) else {
            return .init(status: .notFound, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace not found.", diagnosticReason: .workspaceMissing)
        }
        let remaining = snapshot.workspaces.filter { !$0.isArchived && $0.id != id }
        guard !remaining.isEmpty else {
            return .init(status: .invalidWorkspace, activeWorkspaceID: snapshot.activeWorkspaceID, message: "The last workspace cannot be archived.", diagnosticReason: .lastWorkspace)
        }
        snapshot.workspaces[index].isArchived = true
        snapshot.workspaces[index].updatedAt = now()
        if snapshot.activeWorkspaceID == id {
            snapshot.activeWorkspaceID = remaining[0].id
        }
        snapshot.updatedAt = now()
        return persist(status: .success, message: "Workspace archived.")
    }

    func deleteWorkspace(id: UUID) -> WorkspaceSwitchResult {
        let remaining = snapshot.workspaces.filter { !$0.isArchived && $0.id != id }
        guard !remaining.isEmpty else {
            return .init(status: .invalidWorkspace, activeWorkspaceID: snapshot.activeWorkspaceID, message: "The last workspace cannot be deleted.", diagnosticReason: .lastWorkspace)
        }
        let originalCount = snapshot.workspaces.count
        snapshot.workspaces.removeAll { $0.id == id }
        guard snapshot.workspaces.count != originalCount else {
            return .init(status: .notFound, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace not found.", diagnosticReason: .workspaceMissing)
        }
        if snapshot.activeWorkspaceID == id {
            snapshot.activeWorkspaceID = remaining[0].id
        }
        snapshot.updatedAt = now()
        return persist(status: .success, message: "Workspace deleted.")
    }

    func resetWorkspacesToDefaults() -> WorkspaceSwitchResult {
        do {
            snapshot = try store.resetToDefaults()
            return .init(status: .success, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspaces reset to defaults.", diagnosticReason: nil)
        } catch {
            return .init(status: .failed, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace reset failed.", diagnosticReason: .saveFailed)
        }
    }

    func resetActiveWorkspaceLayoutToDefaults() -> WorkspaceSwitchResult {
        var workspace = activeWorkspace()
        let defaultWorkspace = MenuBarWorkspace.defaultWorkspaces(now: now()).first
            ?? MenuBarWorkspace(name: "Default", createdAt: now(), updatedAt: now())
        workspace.functionItems = defaultWorkspace.functionItems
        workspace.infoItems = defaultWorkspace.infoItems
        workspace.itemTargets = []
        workspace.functionBarConfig = .default
        workspace.infoStripConfig = .default
        workspace.displayMode = .functionBar
        workspace.hoverBehavior = .noChange
        workspace.clickBehavior = .openWorkspacePreview
        workspace.physicalProfileBinding = nil
        return updateWorkspace(workspace)
    }

    func removeMissingGroupReferences(knownGroupIDs: Set<UUID>) -> WorkspaceSwitchResult {
        var removedCount = 0
        snapshot.workspaces = snapshot.workspaces.map { workspace in
            var updatedWorkspace = workspace
            let originalCount = updatedWorkspace.functionItems.count
            updatedWorkspace.functionItems.removeAll { item in
                guard case .group(let reference) = item.kind else { return false }
                return !knownGroupIDs.contains(reference.groupID)
            }
            let removedInWorkspace = originalCount - updatedWorkspace.functionItems.count
            if removedInWorkspace > 0 {
                removedCount += removedInWorkspace
                updatedWorkspace.updatedAt = now()
            }
            return updatedWorkspace
        }

        guard removedCount > 0 else {
            return .init(
                status: .noChange,
                activeWorkspaceID: snapshot.activeWorkspaceID,
                message: "No missing Workspace group references were found.",
                diagnosticReason: .noChange
            )
        }

        snapshot.updatedAt = now()
        return persist(
            status: .success,
            message: "Removed \(removedCount) missing Workspace group reference(s)."
        )
    }

    func updateWorkspace(_ workspace: MenuBarWorkspace) -> WorkspaceSwitchResult {
        guard let index = snapshot.workspaces.firstIndex(where: { $0.id == workspace.id }) else {
            return .init(status: .notFound, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace not found.", diagnosticReason: .workspaceMissing)
        }
        var issues: [WorkspaceValidationIssue] = []
        snapshot.workspaces[index] = WorkspaceValidation.repair(workspace, issues: &issues, now: now())
        snapshot.workspaces[index].updatedAt = now()
        snapshot.updatedAt = now()
        return persist(status: .success, message: issues.isEmpty ? "Workspace saved." : "Workspace saved with safe repairs.")
    }

    private func persist(status: WorkspaceSwitchStatus, message: String) -> WorkspaceSwitchResult {
        do {
            try store.save(snapshot)
            snapshot = try store.load()
            return WorkspaceSwitchResult(status: status, activeWorkspaceID: snapshot.activeWorkspaceID, message: message, diagnosticReason: nil)
        } catch {
            return WorkspaceSwitchResult(status: .failed, activeWorkspaceID: snapshot.activeWorkspaceID, message: "Workspace change could not be saved.", diagnosticReason: .saveFailed)
        }
    }
}

nonisolated enum WorkspaceSwitchSource: String, Codable, Equatable, Sendable {
    case settings
    case functionBar
    case setBuilder
    case internalRecovery
}

nonisolated struct WorkspaceSwitchResult: Equatable, Sendable {
    var status: WorkspaceSwitchStatus
    var activeWorkspaceID: UUID?
    var message: String
    var diagnosticReason: WorkspaceSwitchDiagnosticReason?
}

nonisolated enum WorkspaceSwitchStatus: String, Equatable, Sendable {
    case success
    case notFound
    case archived
    case blockedBySafeMode
    case invalidWorkspace
    case failed
    case noChange
}

nonisolated enum WorkspaceSwitchDiagnosticReason: String, Equatable, Sendable {
    case workspaceMissing
    case workspaceArchived
    case lastWorkspace
    case tooManyWorkspaces
    case saveFailed
    case safeModeRuntimeSuppressed
    case noChange
}
