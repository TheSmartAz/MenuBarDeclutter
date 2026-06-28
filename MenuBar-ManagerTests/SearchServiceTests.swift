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
