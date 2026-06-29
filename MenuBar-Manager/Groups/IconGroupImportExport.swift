import Foundation

/// Import/export helpers for icon groups.
nonisolated struct IconGroupImportExport {
    /// Schema version for group export/import.
    static let exportSchemaVersion = 1

    /// Encode groups to JSON data.
    static func export(_ groups: [IconGroup]) throws -> Data {
        let container = IconGroupContainer(
            schemaVersion: exportSchemaVersion,
            groups: groups
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(container)
    }

    /// Decode groups from JSON data.
    static func importFrom(data: Data) throws -> [IconGroup] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let container = try decoder.decode(IconGroupContainer.self, from: data)
        return IconGroupSort.sort(container.groups)
    }

    /// Export a single group.
    static func exportGroup(_ group: IconGroup) throws -> Data {
        try export([group])
    }
}
