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
    @ObservationIgnored private let store: CodableFileStore<PlacementItemPreferences>?

    private var state: PlacementItemPreferences

    var preferences: [String: PlacementItemPreference] {
        state.preferences
    }

    init(
        fileURL: URL?,
        fileManager: FileManager = .default
    ) {
        let store: CodableFileStore<PlacementItemPreferences>?
        if let fileURL {
            // Preserve the original numeric (`.deferredToDate`) date format:
            // pass a plain encoder rather than the ISO8601 CodableFileStore
            // default so existing files still decode.
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            store = CodableFileStore(
                fileURL: fileURL,
                fileManager: fileManager,
                encoder: encoder,
                decoder: JSONDecoder()
            )
        } else {
            store = nil
        }
        self.store = store
        self.state = Self.load(from: store)
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
        guard let store else { return }

        do {
            try store.write(state)
        } catch {
            // Planner preferences are advisory. Failing closed keeps Arrange usable.
        }
    }

    private static func load(from store: CodableFileStore<PlacementItemPreferences>?) -> PlacementItemPreferences {
        guard let store else { return .empty }

        do {
            guard let state = try store.read() else {
                return .empty
            }
            guard state.schemaVersion == PlacementItemPreferences.empty.schemaVersion else {
                return .empty
            }
            return state
        } catch {
            return .empty
        }
    }
}
