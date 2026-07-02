import Foundation

nonisolated struct WorkspaceStoreSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var activeWorkspaceID: UUID?
    var workspaces: [MenuBarWorkspace]
    var createdAt: Date
    var updatedAt: Date

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        activeWorkspaceID: UUID? = nil,
        workspaces: [MenuBarWorkspace],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.activeWorkspaceID = activeWorkspaceID
        self.workspaces = workspaces
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func defaults(now: Date = Date()) -> WorkspaceStoreSnapshot {
        let workspaces = MenuBarWorkspace.defaultWorkspaces(now: now)
        return WorkspaceStoreSnapshot(
            activeWorkspaceID: workspaces.first?.id,
            workspaces: workspaces,
            createdAt: now,
            updatedAt: now
        )
    }
}

nonisolated enum WorkspaceStoreLoadStatus: String, Codable, Equatable, Sendable {
    case notLoaded
    case loaded
    case createdDefaults
    case repaired
    case corruptedBackupCreated
    case failed
}

nonisolated enum WorkspaceBackupReason: String, Codable, Equatable, Sendable {
    case corrupted
    case repaired
    case manual
}

nonisolated enum WorkspaceStoreError: LocalizedError, Equatable, Sendable {
    case writeFailed(String)
    case readFailed(String)
    case backupEscapedAppSupport

    var errorDescription: String? {
        switch self {
        case .writeFailed(let reason):
            "Workspace store write failed: \(reason)"
        case .readFailed(let reason):
            "Workspace store read failed: \(reason)"
        case .backupEscapedAppSupport:
            "Workspace backup path escaped Application Support."
        }
    }
}
