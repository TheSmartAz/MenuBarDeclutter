import Foundation
import Observation

nonisolated struct PlacementItemPreferences: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var preferences: [String: PlacementItemPreference]

    static let empty = PlacementItemPreferences(
        schemaVersion: 1,
        preferences: [:]
    )
}

@MainActor
@Observable
final class PlacementItemPreferenceStore {
    @ObservationIgnored private let fileURL: URL?
    @ObservationIgnored private let fileManager: FileManager

    private var state: PlacementItemPreferences

    var preferences: [String: PlacementItemPreference] {
        state.preferences
    }

    init(
        fileURL: URL?,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.state = Self.load(from: fileURL, fileManager: fileManager)
    }

    func preference(for storageKey: String) -> PlacementItemPreference? {
        state.preferences[storageKey]
    }

    func setPreference(_ preference: PlacementItemPreference, for storageKey: String) {
        guard !storageKey.isEmpty else { return }
        guard state.preferences[storageKey] != preference else { return }
        state.preferences[storageKey] = preference
        save()
    }

    func clearPreference(for storageKey: String) {
        guard state.preferences.removeValue(forKey: storageKey) != nil else { return }
        save()
    }

    func reset() {
        guard state != .empty else { return }
        state = .empty
        save()
    }

    private func save() {
        guard let fileURL else { return }

        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(state).write(to: fileURL, options: [.atomic])
        } catch {
            // Planner preferences are advisory. Failing closed keeps Arrange usable.
        }
    }

    private static func load(from fileURL: URL?, fileManager: FileManager) -> PlacementItemPreferences {
        guard let fileURL,
              fileManager.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(PlacementItemPreferences.self, from: data)
            guard state.schemaVersion == PlacementItemPreferences.empty.schemaVersion else {
                return .empty
            }
            return state
        } catch {
            return .empty
        }
    }
}
