import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SecondBarViewModel")
@MainActor
struct SecondBarViewModelTests {
    @Test func filtersHiddenItemsBySearchQuery() {
        let viewModel = SecondBarViewModel()
        let settingsStore = SettingsStore(defaults: TestDefaults.makeIsolated())
        let snapshots = [
            makeSnapshot(appName: "Calendar", bundleID: "com.apple.Calendar", zone: .hidden),
            makeSnapshot(appName: "Dropbox", title: "Sync", bundleID: "com.dropbox.Dropbox", zone: .hidden),
            makeSnapshot(appName: "Clock", bundleID: "com.apple.clock", zone: .alwaysHidden)
        ]

        let results = viewModel.items(
            from: snapshots,
            settingsStore: settingsStore,
            query: "drop"
        )

        #expect(results.map(\.owningApplicationName) == ["Dropbox"])
    }

    @Test func excludesDisabledZones() {
        let viewModel = SecondBarViewModel()
        let settingsStore = SettingsStore(defaults: TestDefaults.makeIsolated())
        settingsStore.secondBarShowAlwaysHiddenItems = false
        let snapshots = [
            makeSnapshot(appName: "Hidden", zone: .hidden),
            makeSnapshot(appName: "Deep", zone: .alwaysHidden)
        ]

        let results = viewModel.items(from: snapshots, settingsStore: settingsStore)

        #expect(results.map(\.owningApplicationName) == ["Hidden"])
    }

    @Test func favoritesFilterKeepsSecondBarEligibleItemsOnly() {
        let viewModel = SecondBarViewModel()
        let settingsStore = SettingsStore(defaults: TestDefaults.makeIsolated())
        let hidden = makeSnapshot(appName: "Hidden Favorite", zone: .hidden)
        let visible = makeSnapshot(appName: "Visible Favorite", zone: .visible)
        let memoryStore = MenuBarItemMemoryStore(fileURL: nil)
        memoryStore.toggleFavorite(hidden)
        memoryStore.toggleFavorite(visible)

        let results = viewModel.items(
            from: [visible, hidden],
            settingsStore: settingsStore,
            filter: .favorites,
            memoryStore: memoryStore
        )

        #expect(results.map(\.owningApplicationName) == ["Hidden Favorite"])
    }

    @Test func recentFilterUsesMemoryOrderWithinSecondBarZones() {
        let viewModel = SecondBarViewModel()
        let settingsStore = SettingsStore(defaults: TestDefaults.makeIsolated())
        let first = makeSnapshot(appName: "First", zone: .hidden)
        let second = makeSnapshot(appName: "Second", zone: .alwaysHidden)
        let visible = makeSnapshot(appName: "Visible", zone: .visible)
        let memoryStore = MenuBarItemMemoryStore(fileURL: nil)
        memoryStore.recordSelection(second)
        memoryStore.recordSelection(first)
        memoryStore.recordSelection(visible)

        let results = viewModel.items(
            from: [second, visible, first],
            settingsStore: settingsStore,
            filter: .recent,
            memoryStore: memoryStore
        )

        #expect(results.map(\.owningApplicationName) == ["First", "Second"])
    }

    private func makeSnapshot(
        appName: String,
        title: String? = nil,
        bundleID: String? = nil,
        zone: MenuBarZone
    ) -> MenuBarItemSnapshot {
        TestSnapshots.makeSnapshot(
            id: appName,
            title: title,
            frame: nil,
            owningProcessIdentifier: nil,
            owningApplicationName: appName,
            bundleIdentifier: bundleID,
            zone: zone,
            scanTimestamp: Date(timeIntervalSince1970: 0)
        )
    }
}
