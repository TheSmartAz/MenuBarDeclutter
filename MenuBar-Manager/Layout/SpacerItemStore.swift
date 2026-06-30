import Foundation

/// Persistent store for spacer/divider items. Uses a JSON file in
/// Application Support. Handles corruption by backing up and resetting.
@MainActor
final class SpacerItemStore {
    private let fileURL: URL
    private let backupsDirectory: URL
    private let fileManager: FileManager
    private let diagnosticsLogger: DiagnosticsLogger?
    private let now: () -> Date

    private(set) var items: [SpacerItemModel] = []

    /// Schema version for the JSON file.
    static let schemaVersion = 1

    init(
        directory: URL,
        backupsDirectory: URL,
        fileManager: FileManager = .default,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.fileURL = directory.appendingPathComponent("spacers.json")
        self.backupsDirectory = backupsDirectory
        self.fileManager = fileManager
        self.diagnosticsLogger = diagnosticsLogger
        self.now = now
    }

    /// Load items from disk. If the file is corrupted, back it up and reset.
    func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            items = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(SpacerItemContainer.self, from: data)
            items = container.items.sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            diagnosticsLogger?.log(
                "Spacer store corrupted, backing up and resetting.",
                level: .warning,
                category: .layout
            )
            backupCorruptedFile()
            items = []
        }
    }

    /// Save items to disk.
    func save() {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let container = SpacerItemContainer(
                schemaVersion: Self.schemaVersion,
                items: items
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(container)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            diagnosticsLogger?.log(
                "Failed to save spacer store: \(error.localizedDescription)",
                level: .warning,
                category: .layout
            )
        }
    }

    /// Add a new spacer item.
    @discardableResult
    func add(type: SpacerItemType, title: String = "") -> SpacerItemModel {
        let sortOrder = (items.last?.sortOrder ?? -1) + 1
        var item = SpacerItemModel(type: type, title: title, sortOrder: sortOrder)
        item.updatedAt = now()
        items.append(item)
        save()
        return item
    }

    /// Remove a spacer item by ID.
    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    /// Update a spacer item.
    func update(id: UUID, transform: (inout SpacerItemModel) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        transform(&items[index])
        items[index].updatedAt = now()
        save()
    }

    /// Remove all spacer items.
    func reset() {
        items.removeAll()
        save()
    }

    /// Update sort order for all items.
    func reorder(_ newItems: [SpacerItemModel]) {
        items = newItems.enumerated().map { index, item in
            var updated = item
            updated.sortOrder = index
            updated.updatedAt = now()
            return updated
        }
        save()
    }

    /// Merge imported spacers by identity without deleting local-only spacers.
    func importItems(_ importedItems: [SpacerItemModel]) {
        guard !importedItems.isEmpty else { return }
        for item in importedItems {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            } else {
                items.append(item)
            }
        }
        items.sort { $0.sortOrder < $1.sortOrder }
        save()
    }

    /// Hide all spacer markers.
    func hideAllMarkers() {
        for index in items.indices {
            items[index].showMarker = false
            items[index].updatedAt = now()
        }
        save()
    }

    /// Show all spacer markers.
    func showAllMarkers() {
        for index in items.indices {
            items[index].showMarker = true
            items[index].updatedAt = now()
        }
        save()
    }

    /// Set visibility for all items.
    func setAllVisible(_ visible: Bool) {
        for index in items.indices {
            items[index].isVisible = visible
            items[index].updatedAt = now()
        }
        save()
    }

    var visibleItems: [SpacerItemModel] {
        items.filter { $0.isVisible }
    }

    var itemCount: Int { items.count }

    private func backupCorruptedFile() {
        let backupURL = backupsDirectory.appendingPathComponent("spacers-corrupted-\(Int(now().timeIntervalSince1970)).json")
        do {
            try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.copyItem(at: fileURL, to: backupURL)
            }
        } catch {
            diagnosticsLogger?.log(
                "Failed to back up corrupted spacer store: \(error.localizedDescription)",
                level: .warning,
                category: .layout
            )
        }
    }
}

/// JSON container for spacer items.
nonisolated struct SpacerItemContainer: Codable, Sendable {
    let schemaVersion: Int
    let items: [SpacerItemModel]
}
