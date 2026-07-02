import Foundation

@MainActor
protocol WorkspaceStoreProtocol {
    func load() throws -> WorkspaceStoreSnapshot
    func save(_ snapshot: WorkspaceStoreSnapshot) throws
    func resetToDefaults() throws -> WorkspaceStoreSnapshot
    func backupCurrentStore(reason: WorkspaceBackupReason) throws -> URL?
}

@MainActor
final class WorkspaceStore: WorkspaceStoreProtocol {
    private let fileURL: URL
    private let backupService: WorkspaceBackupService
    private let fileManager: FileManager
    private let diagnosticsLogger: DiagnosticsLogger?
    private let now: () -> Date

    private(set) var snapshot: WorkspaceStoreSnapshot?
    private(set) var lastLoadStatus: WorkspaceStoreLoadStatus = .notLoaded
    private(set) var lastValidationIssues: [WorkspaceValidationIssue] = []

    init(
        fileURL: URL,
        backupsDirectory: URL,
        fileManager: FileManager = .default,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.fileURL = fileURL
        self.backupService = WorkspaceBackupService(backupsDirectory: backupsDirectory, fileManager: fileManager, now: now)
        self.fileManager = fileManager
        self.diagnosticsLogger = diagnosticsLogger
        self.now = now
    }

    func load() throws -> WorkspaceStoreSnapshot {
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            let defaults = WorkspaceStoreSnapshot.defaults(now: now())
            try save(defaults)
            lastLoadStatus = .createdDefaults
            snapshot = defaults
            lastValidationIssues = []
            return defaults
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try Self.decoder.decode(WorkspaceStoreSnapshot.self, from: data)
            let migrated = WorkspaceStoreMigration.migrate(decoded)
            let repaired = validate(migrated)
            let didMigrate = decoded.schemaVersion != WorkspaceStoreSnapshot.currentSchemaVersion
                || decoded.workspaces.contains { $0.schemaVersion != MenuBarWorkspace.currentSchemaVersion }
            if repaired.validation.didRepair || didMigrate {
                _ = try backupCurrentStore(reason: .repaired)
                try write(repaired.snapshot)
                lastLoadStatus = .repaired
            } else {
                lastLoadStatus = .loaded
            }
            snapshot = repaired.snapshot
            lastValidationIssues = repaired.validation.issues
            return repaired.snapshot
        } catch {
            _ = try? backupCurrentStore(reason: .corrupted)
            let defaults = WorkspaceStoreSnapshot.defaults(now: now())
            try save(defaults)
            diagnosticsLogger?.log(
                "Workspace store was corrupted and reset to defaults.",
                level: .warning,
                category: .recovery
            )
            lastLoadStatus = .corruptedBackupCreated
            snapshot = defaults
            lastValidationIssues = [.init(.allWorkspacesRecreated)]
            return defaults
        }
    }

    func save(_ snapshot: WorkspaceStoreSnapshot) throws {
        let repaired = validate(snapshot).snapshot
        try write(repaired)
        self.snapshot = repaired
    }

    func resetToDefaults() throws -> WorkspaceStoreSnapshot {
        _ = try? backupCurrentStore(reason: .manual)
        let defaults = WorkspaceStoreSnapshot.defaults(now: now())
        try save(defaults)
        lastLoadStatus = .createdDefaults
        lastValidationIssues = []
        return defaults
    }

    func backupCurrentStore(reason: WorkspaceBackupReason) throws -> URL? {
        try backupService.backup(fileURL: fileURL, reason: reason)
    }

    private func validate(_ snapshot: WorkspaceStoreSnapshot) -> (snapshot: WorkspaceStoreSnapshot, validation: WorkspaceValidationResult) {
        let validation = WorkspaceValidation.validate(
            workspaces: snapshot.workspaces,
            activeWorkspaceID: snapshot.activeWorkspaceID,
            now: now()
        )
        var repaired = snapshot
        repaired.schemaVersion = WorkspaceStoreSnapshot.currentSchemaVersion
        repaired.workspaces = validation.repairedWorkspaces
        repaired.activeWorkspaceID = validation.selectedActiveWorkspaceID
        if validation.didRepair {
            repaired.updatedAt = now()
        }
        return (repaired, validation)
    }

    private func write(_ snapshot: WorkspaceStoreSnapshot) throws {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try Self.encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WorkspaceStoreError.writeFailed(error.localizedDescription)
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

enum WorkspaceStoreMigration {
    static func migrate(_ snapshot: WorkspaceStoreSnapshot) -> WorkspaceStoreSnapshot {
        var migrated = snapshot
        migrated.schemaVersion = WorkspaceStoreSnapshot.currentSchemaVersion
        migrated.workspaces = migrated.workspaces.map { workspace in
            var migratedWorkspace = workspace
            migratedWorkspace.schemaVersion = MenuBarWorkspace.currentSchemaVersion
            return migratedWorkspace
        }
        return migrated
    }
}
