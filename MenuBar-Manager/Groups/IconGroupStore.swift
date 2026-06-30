import Foundation

/// Persistent store for icon groups. Uses a versioned JSON file in
/// Application Support. Handles corruption by backing up and resetting.
@MainActor
final class IconGroupStore {
    private let fileURL: URL
    private let backupsDirectory: URL
    private let fileManager: FileManager
    private let diagnosticsLogger: DiagnosticsLogger?
    private let now: () -> Date

    private(set) var groups: [IconGroup] = []

    /// Schema version for the JSON file.
    static let schemaVersion = 1

    init(
        directory: URL,
        backupsDirectory: URL,
        fileManager: FileManager = .default,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.fileURL = directory.appendingPathComponent("groups.json")
        self.backupsDirectory = backupsDirectory
        self.fileManager = fileManager
        self.diagnosticsLogger = diagnosticsLogger
        self.now = now
    }

    /// Load groups from disk. If the file is corrupted, back it up and reset.
    func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            groups = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(IconGroupContainer.self, from: data)
            groups = IconGroupSort.sort(container.groups)
        } catch {
            diagnosticsLogger?.log(
                "Group store corrupted, backing up and resetting.",
                level: .warning,
                category: .layout
            )
            backupCorruptedFile()
            groups = []
        }
    }

    /// Save groups to disk.
    func save() {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let container = IconGroupContainer(
                schemaVersion: Self.schemaVersion,
                groups: groups
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(container)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            diagnosticsLogger?.log(
                "Failed to save group store: \(error.localizedDescription)",
                level: .warning,
                category: .layout
            )
        }
    }

    /// Create a new group.
    @discardableResult
    func createGroup(name: String) -> IconGroup {
        let sortOrder = (groups.last?.sortOrder ?? -1) + 1
        var group = IconGroup(name: name, sortOrder: sortOrder)
        group.updatedAt = now()
        groups.append(group)
        save()
        return group
    }

    /// Remove a group by ID.
    func removeGroup(id: UUID) {
        groups.removeAll { $0.id == id }
        save()
    }

    /// Update a group.
    func updateGroup(id: UUID, transform: (inout IconGroup) -> Void) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        transform(&groups[index])
        groups[index].updatedAt = now()
        save()
    }

    /// Add an item ref to a group.
    func addItem(to groupID: UUID, ref: IconGroupItemRef) {
        updateGroup(id: groupID) { group in
            group.itemRefs.append(ref)
        }
    }

    /// Remove an item ref from a group.
    func removeItem(from groupID: UUID, itemRefID: UUID) {
        updateGroup(id: groupID) { group in
            group.itemRefs.removeAll { $0.id == itemRefID }
        }
    }

    /// Reorder groups.
    func reorder(_ newGroups: [IconGroup]) {
        groups = newGroups.enumerated().map { index, group in
            var updated = group
            updated.sortOrder = index
            updated.updatedAt = now()
            return updated
        }
        save()
    }

    /// Merge imported groups by identity without deleting groups that are only
    /// present locally.
    func importGroups(_ importedGroups: [IconGroup]) {
        guard !importedGroups.isEmpty else { return }
        for group in importedGroups {
            if let index = groups.firstIndex(where: { $0.id == group.id }) {
                groups[index] = group
            } else {
                groups.append(group)
            }
        }
        groups = IconGroupSort.sort(groups)
        save()
    }

    /// Reset all groups.
    func reset() {
        groups.removeAll()
        save()
    }

    var groupCount: Int { groups.count }
    var protectedGroupCount: Int { groups.filter(\.isProtected).count }

    private func backupCorruptedFile() {
        let backupURL = backupsDirectory.appendingPathComponent("groups-corrupted-\(Int(now().timeIntervalSince1970)).json")
        do {
            try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.copyItem(at: fileURL, to: backupURL)
            }
        } catch {
            diagnosticsLogger?.log(
                "Failed to back up corrupted group store: \(error.localizedDescription)",
                level: .warning,
                category: .layout
            )
        }
    }
}

/// JSON container for icon groups.
nonisolated struct IconGroupContainer: Codable, Sendable {
    let schemaVersion: Int
    let groups: [IconGroup]
}
