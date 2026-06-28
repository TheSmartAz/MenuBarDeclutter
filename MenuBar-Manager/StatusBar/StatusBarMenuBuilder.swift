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
                command: .expand,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Collapse Hidden Items",
                command: .collapse,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Hidden Items",
                command: .toggle,
                keyEquivalent: "h"
            )
        )

        menu.addItem(
            menuItem(
                title: "Reveal All Hidden Items",
                command: .revealAll,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Reveal All",
                command: .toggleRevealAll,
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Find Icon...",
                command: .findIcon,
                keyEquivalent: "f"
            )
        )

        menu.addItem(
            menuItem(
                title: "Show Second Bar",
                command: .showSecondBar,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Hide Second Bar",
                command: .hideSecondBar,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Second Bar",
                command: .toggleSecondBar,
                keyEquivalent: "s"
            )
        )

        let refreshItem = menuItem(
            title: "Refresh Menu Bar Items",
            command: .refreshMenuBarItems,
            keyEquivalent: "r"
        )
        refreshItem.isEnabled = actions.canRefreshMenuBarItems()
        menu.addItem(refreshItem)

        menu.addItem(
            menuItem(
                title: actions.proModeTitle(),
                command: .toggleProMode,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: actions.automationPausedTitle(),
                command: .toggleAutomationPaused,
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Reset Separator Length",
                command: .resetSeparatorLength,
                keyEquivalent: ""
            )
        )

        menu.addItem(
            menuItem(
                title: "Show Drag Hint",
                command: .showDragHint,
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Settings...",
                command: .openSettings,
                keyEquivalent: ","
            )
        )

        menu.addItem(
            menuItem(
                title: "Show Diagnostics",
                command: .showDiagnostics,
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "About \(AppConstants.displayName)",
                command: .showAbout,
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Quit",
                command: .quit,
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

    private func menuItem(title: String, command: StatusBarMenuCommand, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: #selector(StatusBarMenuCommandTarget.performCommand(_:)),
            keyEquivalent: keyEquivalent
        )
        item.tag = command.rawValue
        item.target = commandTarget
        return item
    }
}

private enum StatusBarMenuCommand: Int {
    case expand = 1
    case collapse
    case toggle
    case revealAll
    case toggleRevealAll
    case findIcon
    case showSecondBar
    case hideSecondBar
    case toggleSecondBar
    case refreshMenuBarItems
    case toggleProMode
    case toggleAutomationPaused
    case resetSeparatorLength
    case showDragHint
    case openSettings
    case showDiagnostics
    case showAbout
    case quit

    func perform(using actions: StatusBarMenuBuilder.Actions) {
        switch self {
        case .expand:
            actions.expand()
        case .collapse:
            actions.collapse()
        case .toggle:
            actions.toggle()
        case .revealAll:
            actions.revealAll()
        case .toggleRevealAll:
            actions.toggleRevealAll()
        case .findIcon:
            actions.findIcon()
        case .showSecondBar:
            actions.showSecondBar()
        case .hideSecondBar:
            actions.hideSecondBar()
        case .toggleSecondBar:
            actions.toggleSecondBar()
        case .refreshMenuBarItems:
            actions.refreshMenuBarItems()
        case .toggleProMode:
            actions.toggleProMode()
        case .toggleAutomationPaused:
            actions.toggleAutomationPaused()
        case .resetSeparatorLength:
            actions.resetSeparatorLength()
        case .showDragHint:
            actions.showDragHint()
        case .openSettings:
            actions.openSettings()
        case .showDiagnostics:
            actions.showDiagnostics()
        case .showAbout:
            actions.showAbout()
        case .quit:
            actions.quit()
        }
    }
}

@MainActor
private final class StatusBarMenuCommandTarget: NSObject {
    private let actions: StatusBarMenuBuilder.Actions

    init(actions: StatusBarMenuBuilder.Actions) {
        self.actions = actions
    }

    @objc func performCommand(_ sender: NSMenuItem) {
        guard let command = StatusBarMenuCommand(rawValue: sender.tag) else { return }
        command.perform(using: actions)
    }
}
