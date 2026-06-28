import Foundation
import Testing
@testable import MenuBar_Manager

@Suite("SecondBarViewModel")
@MainActor
struct SecondBarViewModelTests {
    @Test func filtersHiddenItemsBySearchQuery() {
        let viewModel = SecondBarViewModel()
        let settingsStore = SettingsStore(defaults: isolatedDefaults())
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
        let settingsStore = SettingsStore(defaults: isolatedDefaults())
        settingsStore.secondBarShowAlwaysHiddenItems = false
        let snapshots = [
            makeSnapshot(appName: "Hidden", zone: .hidden),
            makeSnapshot(appName: "Deep", zone: .alwaysHidden)
        ]

        let results = viewModel.items(from: snapshots, settingsStore: settingsStore)

        #expect(results.map(\.owningApplicationName) == ["Hidden"])
    }

    private func makeSnapshot(
        appName: String,
        title: String? = nil,
        bundleID: String? = nil,
        zone: MenuBarZone
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: appName,
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: nil,
            owningProcessIdentifier: nil,
            owningApplicationName: appName,
            bundleIdentifier: bundleID,
            zone: zone,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 0)
        )
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "SecondBarViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
