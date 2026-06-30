import CryptoKit
import Foundation
import Observation

@MainActor
@Observable
final class MenuBarItemMemoryStore {
    private struct State: Codable, Equatable {
        var schemaVersion: Int
        var recentItemStorageKeys: [String]
        var favoriteItemStorageKeys: [String]

        static let empty = State(
            schemaVersion: 1,
            recentItemStorageKeys: [],
            favoriteItemStorageKeys: []
        )
    }

    private let fileURL: URL?
    private let fileManager: FileManager
    private let recentLimit: Int
    private var state: State

    init(
        fileURL: URL?,
        fileManager: FileManager = .default,
        recentLimit: Int = 30
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.recentLimit = max(0, recentLimit)
        var loadedState = Self.loadState(from: fileURL, fileManager: fileManager)
        if loadedState.recentItemStorageKeys.count > self.recentLimit {
            loadedState.recentItemStorageKeys.removeLast(
                loadedState.recentItemStorageKeys.count - self.recentLimit
            )
        }
        self.state = loadedState
    }

    var recentCount: Int {
        state.recentItemStorageKeys.count
    }

    var favoriteCount: Int {
        state.favoriteItemStorageKeys.count
    }

    var recentItemStorageKeys: [String] {
        state.recentItemStorageKeys
    }

    var favoriteItemStorageKeys: Set<String> {
        Set(state.favoriteItemStorageKeys)
    }

    func recordSelection(_ snapshot: MenuBarItemSnapshot) {
        guard recentLimit > 0 else { return }

        let key = Self.storageKey(for: snapshot)
        var keys = state.recentItemStorageKeys.filter { $0 != key }
        keys.insert(key, at: 0)
        if keys.count > recentLimit {
            keys.removeLast(keys.count - recentLimit)
        }

        updateState {
            $0.recentItemStorageKeys = keys
        }
    }

    @discardableResult
    func toggleFavorite(_ snapshot: MenuBarItemSnapshot) -> Bool {
        let key = Self.storageKey(for: snapshot)
        var keys = Set(state.favoriteItemStorageKeys)
        let isFavorite: Bool
        if keys.contains(key) {
            keys.remove(key)
            isFavorite = false
        } else {
            keys.insert(key)
            isFavorite = true
        }

        updateState {
            $0.favoriteItemStorageKeys = keys.sorted()
        }
        return isFavorite
    }

    func isFavorite(_ snapshot: MenuBarItemSnapshot) -> Bool {
        state.favoriteItemStorageKeys.contains(Self.storageKey(for: snapshot))
    }

    func isRecent(_ snapshot: MenuBarItemSnapshot) -> Bool {
        recentRank(for: snapshot) != nil
    }

    func recentRank(for snapshot: MenuBarItemSnapshot) -> Int? {
        state.recentItemStorageKeys.firstIndex(of: Self.storageKey(for: snapshot))
    }

    func resetRecents() {
        updateState {
            $0.recentItemStorageKeys = []
        }
    }

    func resetFavorites() {
        updateState {
            $0.favoriteItemStorageKeys = []
        }
    }

    static func storageKey(for snapshot: MenuBarItemSnapshot) -> String {
        let digest = SHA256.hash(data: Data(snapshot.id.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func updateState(_ mutate: (inout State) -> Void) {
        var nextState = state
        mutate(&nextState)
        guard nextState != state else { return }
        state = nextState
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
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Recents/favorites are convenience state only; failing closed keeps
            // Basic Mode and Pro workflows usable without surfacing a modal error.
        }
    }

    private static func loadState(from fileURL: URL?, fileManager: FileManager) -> State {
        guard let fileURL,
              fileManager.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(State.self, from: data)
            guard state.schemaVersion == State.empty.schemaVersion else {
                return .empty
            }
            return State(
                schemaVersion: state.schemaVersion,
                recentItemStorageKeys: deduplicated(state.recentItemStorageKeys),
                favoriteItemStorageKeys: deduplicated(state.favoriteItemStorageKeys).sorted()
            )
        } catch {
            return .empty
        }
    }

    private static func deduplicated(_ keys: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for key in keys where !key.isEmpty && seen.insert(key).inserted {
            result.append(key)
        }
        return result
    }
}
