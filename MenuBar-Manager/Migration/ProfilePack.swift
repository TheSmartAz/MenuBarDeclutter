import Foundation

/// A reusable profile pack that can be exported and imported independently
/// of global settings.
nonisolated struct ProfilePack: Codable, Equatable, Sendable {
    let packVersion: Int
    let name: String
    let description: String?
    let createdAt: Date
    let profiles: [ProfileExportEntry]
    let groups: [IconGroup]
    let hotkeyBindings: [HotkeyBinding]
    let spacerItems: [SpacerItemModel]

    init(
        packVersion: Int = 1,
        name: String,
        description: String? = nil,
        createdAt: Date = Date(),
        profiles: [ProfileExportEntry] = [],
        groups: [IconGroup] = [],
        hotkeyBindings: [HotkeyBinding] = [],
        spacerItems: [SpacerItemModel] = []
    ) {
        self.packVersion = packVersion
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.profiles = profiles
        self.groups = groups
        self.hotkeyBindings = hotkeyBindings
        self.spacerItems = spacerItems
    }
}

/// Store for profile packs.
@MainActor
final class ProfilePackStore {
    private let directory: URL
    private let fileManager: FileManager
    private let diagnosticsLogger: DiagnosticsLogger?

    init(
        directory: URL,
        fileManager: FileManager = .default,
        diagnosticsLogger: DiagnosticsLogger? = nil
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Save a profile pack to disk.
    func save(_ pack: ProfilePack) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(pack.name.replacingOccurrences(of: " ", with: "-")).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pack)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Load a profile pack from a file.
    func load(from url: URL) throws -> ProfilePack {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ProfilePack.self, from: data)
    }

    /// List all saved profile packs.
    func listPacks() -> [URL] {
        guard let urls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        return urls.filter { $0.pathExtension == "json" }
    }
}
