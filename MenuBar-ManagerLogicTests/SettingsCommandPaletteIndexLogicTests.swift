import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Settings Command Palette Logic")
struct SettingsCommandPaletteIndexLogicTests {
    @Test func advancedSurfacesUseReducedCommandPaletteLabels() throws {
        let index = SettingsCommandPaletteIndex.make(includeDogfood: false)

        func sectionEntry(_ section: SettingsSection) -> SettingsCommandPaletteEntry? {
            index.entries.first { entry in
                entry.id == "settings.section.\(section.rawValue)"
            }
        }

        let behavior = try #require(sectionEntry(.behavior))
        let layout = try #require(sectionEntry(.layout))
        let menuBarItems = try #require(sectionEntry(.menuBarItems))
        let search = try #require(sectionEntry(.search))
        let secondBar = try #require(sectionEntry(.secondBar))

        #expect(behavior.title == "Hide & Reveal Legacy")
        #expect(layout.title == "Layout Labs")
        #expect(menuBarItems.title == "Menu Bar Item Inspector")
        #expect(search.title == "Find Icon Settings")
        #expect(secondBar.title == "Second Bar Settings")
        #expect(search.subtitle.localizedStandardContains("Advanced surface"))
        #expect(index.search("Find Icon Settings").contains { entry in
            entry.destination == .search && entry.source == .advancedSettings
        })
    }
}
