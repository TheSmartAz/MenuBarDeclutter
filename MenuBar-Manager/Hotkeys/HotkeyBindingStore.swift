import Foundation

/// Persistent store for hotkey bindings.
@MainActor
final class HotkeyBindingStore {
    private let fileURL: URL
    private let backupsDirectory: URL
    private let fileManager: FileManager
    private let diagnosticsLogger: DiagnosticsLogger?
    private let now: () -> Date

    private(set) var bindings: [HotkeyBinding] = []

    init(
        directory: URL,
        backupsDirectory: URL,
        fileManager: FileManager = .default,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.fileURL = directory.appendingPathComponent("hotkeys.json")
        self.backupsDirectory = backupsDirectory
        self.fileManager = fileManager
        self.diagnosticsLogger = diagnosticsLogger
        self.now = now
    }

    func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            bindings = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(HotkeyBindingContainer.self, from: data)
            bindings = container.bindings
        } catch {
            diagnosticsLogger?.log(
                "Hotkey binding store corrupted, backing up and resetting.",
                level: .warning,
                category: .hotkey
            )
            backupCorruptedFile()
            bindings = []
        }
    }

    func save() {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let container = HotkeyBindingContainer(bindings: bindings)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(container)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            diagnosticsLogger?.log(
                "Failed to save hotkey binding store: \(error.localizedDescription)",
                level: .warning,
                category: .hotkey
            )
        }
    }

    @discardableResult
    func add(binding: HotkeyBinding) -> HotkeyBinding {
        var b = binding
        b.updatedAt = now()
        bindings.append(b)
        save()
        return b
    }

    func remove(id: UUID) {
        bindings.removeAll { $0.id == id }
        save()
    }

    func update(id: UUID, transform: (inout HotkeyBinding) -> Void) {
        guard let index = bindings.firstIndex(where: { $0.id == id }) else { return }
        transform(&bindings[index])
        bindings[index].updatedAt = now()
        save()
    }

    /// Replace the in-memory binding list with a validated imported list.
    func replaceAll(_ importedBindings: [HotkeyBinding]) {
        bindings = importedBindings
        save()
    }

    func reset() {
        bindings.removeAll()
        save()
    }

    var count: Int { bindings.count }
    var enabledCount: Int { bindings.filter(\.isEnabled).count }

    private func backupCorruptedFile() {
        let backupURL = backupsDirectory.appendingPathComponent("hotkeys-corrupted-\(Int(now().timeIntervalSince1970)).json")
        try? fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
    }
}

nonisolated struct HotkeyBindingContainer: Codable, Sendable {
    let bindings: [HotkeyBinding]
}
