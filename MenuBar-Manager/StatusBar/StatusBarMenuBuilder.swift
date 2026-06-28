import AppKit
import Foundation

/// Builds the menu shown by both the control item and the right-click menu
/// on the separator. The builder is stateless with respect to AppKit: it
/// generates ``NSMenu`` instances on demand and refreshes their dynamic
/// items whenever the hiding state changes via ``refresh(for:)``.
@MainActor
final class StatusBarMenuBuilder {
    struct Actions {
        let expand: () -> Void
        let collapse: () -> Void
        let toggle: () -> Void
        let revealAll: () -> Void
        let toggleRevealAll: () -> Void
        let findIcon: () -> Void
        let showSecondBar: () -> Void
        let hideSecondBar: () -> Void
        let toggleSecondBar: () -> Void
        let refreshMenuBarItems: () -> Void
        let toggleProMode: () -> Void
        let proModeTitle: () -> String
        let toggleAutomationPaused: () -> Void
        let automationPausedTitle: () -> String
        let canRefreshMenuBarItems: () -> Bool
        let resetSeparatorLength: () -> Void
        let showDragHint: () -> Void
        let openSettings: () -> Void
        let showDiagnostics: () -> Void
        let showAbout: () -> Void
        let quit: () -> Void
    }

    private let actions: Actions
    private let commandTarget: StatusBarMenuCommandTarget

    init(actions: Actions) {
        self.actions = actions
        self.commandTarget = StatusBarMenuCommandTarget(actions: actions)
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu(title: AppConstants.displayName)

        menu.addItem(
            menuItem(
                title: "Expand Hidden Items",
                action: #selector(StatusBarMenuCommandTarget.expand(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Collapse Hidden Items",
                action: #selector(StatusBarMenuCommandTarget.collapse(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
           menuItem(
                title: "Toggle Hidden Items",
                action: #selector(StatusBarMenuCommandTarget.toggle(_:)),
                keyEquivalent: "h"
            )
        )

        menu.addItem(
            menuItem(
                title: "Reveal All Hidden Items",
                action: #selector(StatusBarMenuCommandTarget.revealAll(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Reveal All",
                action: #selector(StatusBarMenuCommandTarget.toggleRevealAll(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Find Icon...",
                action: #selector(StatusBarMenuCommandTarget.findIcon(_:)),
                keyEquivalent: "f"
            )
        )

        menu.addItem(
            menuItem(
                title: "Show Second Bar",
                action: #selector(StatusBarMenuCommandTarget.showSecondBar(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Hide Second Bar",
                action: #selector(StatusBarMenuCommandTarget.hideSecondBar(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Second Bar",
                action: #selector(StatusBarMenuCommandTarget.toggleSecondBar(_:)),
                keyEquivalent: "s"
            )
        )

        let refreshItem = menuItem(
            title: "Refresh Menu Bar Items",
            action: #selector(StatusBarMenuCommandTarget.refreshMenuBarItems(_:)),
            keyEquivalent: "r"
        )
        refreshItem.isEnabled = actions.canRefreshMenuBarItems()
        menu.addItem(refreshItem)

        menu.addItem(
            menuItem(
                title: actions.proModeTitle(),
                action: #selector(StatusBarMenuCommandTarget.toggleProMode(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: actions.automationPausedTitle(),
                action: #selector(StatusBarMenuCommandTarget.toggleAutomationPaused(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Reset Separator Length",
                action: #selector(StatusBarMenuCommandTarget.resetSeparatorLength(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Show Drag Hint",
                action: #selector(StatusBarMenuCommandTarget.showDragHint(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Settings...",
                action: #selector(StatusBarMenuCommandTarget.openSettings(_:)),
                keyEquivalent: ","
            )
        )

        menu.addItem(
            menuItem(
                title: "Show Diagnostics",
                action: #selector(StatusBarMenuCommandTarget.showDiagnostics(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "About \(AppConstants.displayName)",
                action: #selector(StatusBarMenuCommandTarget.showAbout(_:)),
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Quit",
                action: #selector(StatusBarMenuCommandTarget.quit(_:)),
                keyEquivalent: "q"
            )
        )

        return menu
    }

    /// Updates dynamic menu items for the new visibility state. Because we
    /// rebuild the menu on every open, this primarily exists as a hook for
    /// future onboarding and any state-dependent badges or disabled items.
    func refresh(for visibility: HidingVisibilityState) {
        // No persistent menu instance to mutate today; the next `makeMenu()`
        // call will reflect `visibility` indirectly through the actions caller.
        // The hook is here so we can add badges/disable logic without an API
        // change in follow-up tasks.
        _ = visibility
    }

    /// Backward-compatible refresh that maps a legacy binary state to a
    /// visibility state. Kept for Phase 1 callers/tests.
    func refresh(for state: HidingState) {
        refresh(for: state.isCollapsed ? HidingVisibilityState.collapsed : HidingVisibilityState.expanded)
    }

    private func menuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = commandTarget
        return item
    }
}

@MainActor
private final class StatusBarMenuCommandTarget: NSObject {
    private let actions: StatusBarMenuBuilder.Actions

    init(actions: StatusBarMenuBuilder.Actions) {
        self.actions = actions
    }

    @objc func expand(_ sender: NSMenuItem) {
        actions.expand()
    }

    @objc func collapse(_ sender: NSMenuItem) {
        actions.collapse()
    }

    @objc func toggle(_ sender: NSMenuItem) {
        actions.toggle()
    }

    @objc func revealAll(_ sender: NSMenuItem) {
        actions.revealAll()
    }

    @objc func toggleRevealAll(_ sender: NSMenuItem) {
        actions.toggleRevealAll()
    }

    @objc func findIcon(_ sender: NSMenuItem) {
        actions.findIcon()
    }

    @objc func showSecondBar(_ sender: NSMenuItem) {
        actions.showSecondBar()
    }

    @objc func hideSecondBar(_ sender: NSMenuItem) {
        actions.hideSecondBar()
    }

    @objc func toggleSecondBar(_ sender: NSMenuItem) {
        actions.toggleSecondBar()
    }

    @objc func refreshMenuBarItems(_ sender: NSMenuItem) {
        actions.refreshMenuBarItems()
    }

    @objc func toggleProMode(_ sender: NSMenuItem) {
        actions.toggleProMode()
    }

    @objc func toggleAutomationPaused(_ sender: NSMenuItem) {
        actions.toggleAutomationPaused()
    }

    @objc func resetSeparatorLength(_ sender: NSMenuItem) {
        actions.resetSeparatorLength()
    }

    @objc func showDragHint(_ sender: NSMenuItem) {
        actions.showDragHint()
    }

    @objc func openSettings(_ sender: NSMenuItem) {
        actions.openSettings()
    }

    @objc func showDiagnostics(_ sender: NSMenuItem) {
        actions.showDiagnostics()
    }

    @objc func showAbout(_ sender: NSMenuItem) {
        actions.showAbout()
    }

    @objc func quit(_ sender: NSMenuItem) {
        actions.quit()
    }
}
