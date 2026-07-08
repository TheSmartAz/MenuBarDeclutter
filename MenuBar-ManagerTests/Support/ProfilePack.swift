import Foundation
@testable import MenuBarDeclutter

/// A reusable profile pack that can be exported and imported independently
/// of global settings.
///
/// This is a legacy compatibility format kept for older local exports. New
/// whole-app backup/restore flows should use `SettingsExportPackage`.
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

    private enum CodingKeys: String, CodingKey {
        case packVersion
        case name
        case description
        case createdAt
        case profiles
        case groups
        case hotkeyBindings
        case spacerItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            packVersion: try container.decodeIfPresent(Int.self, forKey: .packVersion) ?? 1,
            name: try container.decode(String.self, forKey: .name),
            description: try container.decodeIfPresent(String.self, forKey: .description),
            createdAt: try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date(),
            profiles: try container.decodeIfPresent([ProfileExportEntry].self, forKey: .profiles) ?? [],
            groups: try container.decodeIfPresent([IconGroup].self, forKey: .groups) ?? [],
            hotkeyBindings: try container.decodeIfPresent([HotkeyBinding].self, forKey: .hotkeyBindings) ?? [],
            spacerItems: try container.decodeIfPresent([SpacerItemModel].self, forKey: .spacerItems) ?? []
        )
    }
}

/// Store for legacy profile packs.
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
        let data = try JSONCoding.encodePrettySorted(pack)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Load a profile pack from a file.
    func load(from url: URL) throws -> ProfilePack {
        let data = try Data(contentsOf: url)
        return try JSONCoding.decode(ProfilePack.self, from: data)
    }

    /// List all saved profile packs.
    func listPacks() -> [URL] {
        guard let urls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        return urls.filter { $0.pathExtension == "json" }
    }
}
