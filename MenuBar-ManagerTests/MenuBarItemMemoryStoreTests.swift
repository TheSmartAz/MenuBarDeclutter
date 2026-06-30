import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("MenuBarItemMemoryStore")
@MainActor
struct MenuBarItemMemoryStoreTests {
    @Test func storesOnlyHashedItemKeysOnDisk() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let snapshot = TestSnapshots.makeSnapshot(
            id: "raw-sensitive-id",
            title: "Private Title",
            owningApplicationName: "Private App",
            bundleIdentifier: "com.example.private"
        )
        let store = MenuBarItemMemoryStore(fileURL: harness.fileURL)

        store.recordSelection(snapshot)
        store.toggleFavorite(snapshot)

        let data = try Data(contentsOf: harness.fileURL)
        let contents = String(decoding: data, as: UTF8.self)

        #expect(contents.contains(MenuBarItemMemoryStore.storageKey(for: snapshot)))
        #expect(!contents.contains("raw-sensitive-id"))
        #expect(!contents.contains("Private Title"))
        #expect(!contents.contains("Private App"))
        #expect(!contents.contains("com.example.private"))
    }

    @Test func recentsKeepNewestUniqueItemsWithinLimit() {
        let store = MenuBarItemMemoryStore(fileURL: nil, recentLimit: 2)
        let first = makeSnapshot(id: "first")
        let second = makeSnapshot(id: "second")
        let third = makeSnapshot(id: "third")

        store.recordSelection(first)
        store.recordSelection(second)
        store.recordSelection(first)
        store.recordSelection(third)

        #expect(store.recentItemStorageKeys == [
            MenuBarItemMemoryStore.storageKey(for: third),
            MenuBarItemMemoryStore.storageKey(for: first)
        ])
        #expect(store.recentRank(for: third) == 0)
        #expect(store.recentRank(for: first) == 1)
        #expect(store.recentRank(for: second) == nil)
    }

    @Test func favoritesAndRecentsRoundTripThroughDisk() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }
        let favorite = makeSnapshot(id: "favorite")
        let recent = makeSnapshot(id: "recent")

        do {
            let store = MenuBarItemMemoryStore(fileURL: harness.fileURL)
            store.toggleFavorite(favorite)
            store.recordSelection(recent)
        }

        let reloaded = MenuBarItemMemoryStore(fileURL: harness.fileURL)

        #expect(reloaded.isFavorite(favorite))
        #expect(reloaded.isRecent(recent))
        #expect(!reloaded.isFavorite(recent))
    }

    @Test func resetClearsPersistedState() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }
        let snapshot = makeSnapshot(id: "stored")

        do {
            let store = MenuBarItemMemoryStore(fileURL: harness.fileURL)
            store.recordSelection(snapshot)
            store.toggleFavorite(snapshot)
            store.resetRecents()
            store.resetFavorites()
        }

        let reloaded = MenuBarItemMemoryStore(fileURL: harness.fileURL)

        #expect(reloaded.recentCount == 0)
        #expect(reloaded.favoriteCount == 0)
    }

    private func makeSnapshot(id: String) -> MenuBarItemSnapshot {
        TestSnapshots.makeSnapshot(id: id)
    }

    private func makeHarness() throws -> PersistenceHarness {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("MenuBarItemMemoryStoreTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return PersistenceHarness(
            root: root,
            fileURL: root.appendingPathComponent("memory.json")
        )
    }

    private struct PersistenceHarness {
        let root: URL
        let fileURL: URL

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
