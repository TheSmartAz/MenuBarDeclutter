import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SearchService")
@MainActor
struct SearchServiceTests {
    private let service = SearchService()

    @Test func exactAppNameMatchRanksFirst() {
        let snapshots = [
            makeSnapshot(id: "generic", appName: "Cloud Sync", title: "Dropbox", bundleID: "com.example.sync"),
            makeSnapshot(id: "exact", appName: "Dropbox", title: "Sync Complete", bundleID: "com.dropbox.Dropbox")
        ]

        let results = service.results(from: snapshots, query: "Dropbox")

        #expect(results.first?.id == "exact")
        #expect(results.first?.matchReason == .exactAppName)
    }

    @Test func prefixMatchFindsAppOrTitle() {
        let snapshots = [
            makeSnapshot(id: "other", appName: "Calendar", title: "Today"),
            makeSnapshot(id: "prefix", appName: "Raycast", title: "Command Center")
        ]

        let results = service.results(from: snapshots, query: "ray")

        #expect(results.map(\.id) == ["prefix"])
        #expect(results.first?.matchReason == .prefix)
    }

    @Test func bundleIdentifierContainsMatchFindsItem() {
        let snapshots = [
            makeSnapshot(id: "bundle", appName: "Utility", title: "Status", bundleID: "com.acme.menuutility"),
            makeSnapshot(id: "miss", appName: "Notes", title: "Note", bundleID: "com.example.notes")
        ]

        let results = service.results(from: snapshots, query: "menuutility")

        #expect(results.map(\.id) == ["bundle"])
        #expect(results.first?.matchReason == .bundleIdentifier)
    }

    @Test func hiddenItemsRankAboveVisibleItemsForSameMatch() {
        let visible = makeSnapshot(
            id: "visible",
            appName: "Sync",
            title: "Sync",
            zone: .visible
        )
        let hidden = makeSnapshot(
            id: "hidden",
            appName: "Sync",
            title: "Sync",
            zone: .hidden
        )

        let results = service.results(from: [visible, hidden], query: "Sync")

        #expect(results.first?.id == "hidden")
    }

    @Test func emptyQueryReturnsRecentItems() {
        let old = makeSnapshot(
            id: "old",
            appName: "Old",
            title: "Old",
            timestamp: Date(timeIntervalSince1970: 1)
        )
        let recent = makeSnapshot(
            id: "recent",
            appName: "Recent",
            title: "Recent",
            timestamp: Date(timeIntervalSince1970: 10)
        )

        let results = service.results(from: [old, recent], query: "")

        #expect(results.map(\.id) == ["recent", "old"])
        #expect(results.allSatisfy { $0.matchReason == .recent })
    }

    @Test func zoneFilterLimitsResults() {
        let snapshots = [
            makeSnapshot(id: "visible", appName: "Cloud", title: "Sync", zone: .visible),
            makeSnapshot(id: "hidden", appName: "Cloud", title: "Sync", zone: .hidden),
            makeSnapshot(id: "always", appName: "Cloud", title: "Sync", zone: .alwaysHidden)
        ]

        let results = service.results(
            from: snapshots,
            query: "Cloud",
            filter: .hidden
        )

        #expect(results.map(\.id) == ["hidden"])
    }

    @Test func favoritesFilterUsesMemoryStore() {
        let favorite = makeSnapshot(id: "favorite", appName: "Favorite", title: "Sync")
        let other = makeSnapshot(id: "other", appName: "Other", title: "Sync")
        let memoryStore = MenuBarItemMemoryStore(fileURL: nil)
        memoryStore.toggleFavorite(favorite)

        let results = service.results(
            from: [favorite, other],
            query: "Sync",
            filter: .favorites,
            memoryStore: memoryStore
        )

        #expect(results.map(\.id) == ["favorite"])
    }

    @Test func recentFilterUsesMemoryOrder() {
        let first = makeSnapshot(id: "first", appName: "First", title: "Item")
        let second = makeSnapshot(id: "second", appName: "Second", title: "Item")
        let third = makeSnapshot(id: "third", appName: "Third", title: "Item")
        let memoryStore = MenuBarItemMemoryStore(fileURL: nil)
        memoryStore.recordSelection(second)
        memoryStore.recordSelection(first)

        let results = service.results(
            from: [third, second, first],
            query: "",
            filter: .recent,
            memoryStore: memoryStore
        )

        #expect(results.map(\.id) == ["first", "second"])
    }

    private func makeSnapshot(
        id: String,
        appName: String,
        title: String?,
        bundleID: String = "com.example.\(UUID().uuidString)",
        zone: MenuBarZone = .visible,
        timestamp: Date = Date(timeIntervalSince1970: 5)
    ) -> MenuBarItemSnapshot {
        TestSnapshots.makeSnapshot(
            id: id,
            title: title,
            owningApplicationName: appName,
            bundleIdentifier: bundleID,
            zone: zone,
            scanTimestamp: timestamp
        )
    }
}
