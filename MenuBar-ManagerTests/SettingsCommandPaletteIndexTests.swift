import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Settings command palette index")
struct SettingsCommandPaletteIndexTests {
    @Test func indexesVisibleAndAdvancedSettingsDestinations() {
        let index = SettingsCommandPaletteIndex.make(includeDogfood: false)

        #expect(index.search("Hide Reveal").contains { entry in
            entry.destination == .hideReveal && entry.source == .visibleSettings
        })
        #expect(index.search("Search hotkey").contains { entry in
            entry.destination == .search && entry.source == .advancedSettings
        })
        #expect(index.search("Dynamic Hotkeys").contains { entry in
            entry.destination == .hotkeys && entry.source == .advancedAlias
        })
        #expect(index.search("Spacing Labs").contains { entry in
            entry.destination == .layout && entry.source == .advancedAlias
        })
    }

    @Test func searchSplitsQueryIntoLocalizedStandardContainsTokens() {
        let index = SettingsCommandPaletteIndex.make(includeDogfood: false)
        let results = index.search("menu items")

        #expect(results.contains { entry in
            entry.destination == .menuBarItems
        })
        #expect(results.allSatisfy { entry in
            entry.searchableText.localizedStandardContains("menu")
                && entry.searchableText.localizedStandardContains("items")
        })
    }

    @Test func actionsOnlyAppearWhenAvailable() {
        let unavailableIndex = SettingsCommandPaletteIndex.make(includeDogfood: false)
        #expect(unavailableIndex.search("Run Health Check").allSatisfy { $0.action != .runHealthCheck })

        let availableIndex = SettingsCommandPaletteIndex.make(
            includeDogfood: false,
            availableActions: [.runHealthCheck, .showDragHint]
        )

        #expect(availableIndex.search("Run Health Check").contains { entry in
            entry.id == "settings.action.runHealthCheck"
                && entry.action == .runHealthCheck
                && entry.kind == .action
        })
        #expect(availableIndex.search("Command Drag").contains { entry in
            entry.action == .showDragHint
        })
    }

    @Test func entryIdentitiesAreStableAcrossEquivalentQueries() {
        let index = SettingsCommandPaletteIndex.make(
            includeDogfood: false,
            availableActions: [.runHealthCheck]
        )

        let firstIDs = index.search(" health ").map(\.id)
        let secondIDs = index.search("health").map(\.id)

        #expect(firstIDs == secondIDs)
        #expect(firstIDs.contains("settings.action.runHealthCheck"))
        #expect(index.entries.map(\.id).count == Set(index.entries.map(\.id)).count)
    }

    @Test func emptyQueryReturnsLocalOnlyEntriesInIndexOrder() {
        let index = SettingsCommandPaletteIndex.make(
            includeDogfood: false,
            availableActions: [.revealAll]
        )
        let results = index.search("   ")

        #expect(results.first?.id == "settings.section.general")
        #expect(results.contains { $0.id == "settings.action.revealAll" })
        #expect(results.allSatisfy { $0.isPrivacySafeLocalOnly })
    }

    @Test func dogfoodAliasHonorsDogfoodVisibility() {
        let hiddenIndex = SettingsCommandPaletteIndex.make(includeDogfood: false)
        #expect(hiddenIndex.search("Dogfood").isEmpty)

        let visibleIndex = SettingsCommandPaletteIndex.make(includeDogfood: true)
        #expect(visibleIndex.search("Dogfood").contains { entry in
            entry.id == "settings.advancedAlias.dogfood"
                && entry.destination == .diagnostics
        })
    }
}
