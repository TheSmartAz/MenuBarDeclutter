import AppKit
import Testing
@testable import MenuBarDeclutter

@Suite("StatusBarMenuBuilder Logic")
@MainActor
struct StatusBarMenuBuilderLogicTests {
    @Test func basicVisibilityActionsDisableOnlyCurrentNoOp() throws {
        let builder = StatusBarMenuBuilder(actions: Self.makeActions())

        var menu = builder.makeMenu()
        #expect(try menuItem("Reveal Hidden Items", in: menu).isEnabled == false)
        #expect(try menuItem("Collapse Hidden Items", in: menu).isEnabled == true)
        #expect(try menuItem("Reveal All Items", in: menu).isEnabled == true)

        builder.refresh(for: HidingVisibilityState.collapsed)
        menu = builder.makeMenu()
        #expect(try menuItem("Reveal Hidden Items", in: menu).isEnabled == true)
        #expect(try menuItem("Collapse Hidden Items", in: menu).isEnabled == false)
        #expect(try menuItem("Reveal All Items", in: menu).isEnabled == true)

        builder.refresh(for: HidingVisibilityState.revealAll)
        menu = builder.makeMenu()
        #expect(try menuItem("Reveal Hidden Items", in: menu).isEnabled == true)
        #expect(try menuItem("Collapse Hidden Items", in: menu).isEnabled == true)
        #expect(try menuItem("Reveal All Items", in: menu).isEnabled == false)
    }

    private static func makeActions() -> StatusBarMenuBuilder.Actions {
        StatusBarMenuBuilder.Actions(
            expand: {},
            collapse: {},
            toggle: {},
            revealAll: {},
            toggleRevealAll: {},
            emergencyRevealAndResetSeparators: {},
            findIcon: {},
            showSecondBar: {},
            hideSecondBar: {},
            toggleSecondBar: {},
            refreshMenuBarItems: {},
            toggleProMode: {},
            proModeTitle: { "Enable Pro Mode" },
            toggleAutomationPaused: {},
            automationPausedTitle: { "Pause Automation" },
            canRefreshMenuBarItems: { true },
            resetSeparatorLength: {},
            resetLayout: {},
            showDragHint: {},
            openArrangeSettings: {},
            openNewMenuBarItems: {},
            openRecoverySettings: {},
            openSettings: {},
            showDiagnostics: {},
            showAbout: {},
            quit: {}
        )
    }

    private func menuItem(_ title: String, in menu: NSMenu) throws -> NSMenuItem {
        try #require(actionItems(in: menu).first { $0.title == title })
    }

    private func actionItems(in menu: NSMenu) -> [NSMenuItem] {
        menu.items.flatMap { item -> [NSMenuItem] in
            if item.isSeparatorItem {
                return []
            }
            if let submenu = item.submenu {
                return actionItems(in: submenu)
            }
            return item.action == nil ? [] : [item]
        }
    }
}
