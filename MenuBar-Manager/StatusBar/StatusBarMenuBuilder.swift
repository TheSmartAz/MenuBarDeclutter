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
        let emergencyRevealAndResetSeparators: () -> Void
        let findIcon: () -> Void
        let showSecondBar: () -> Void
        let hideSecondBar: () -> Void
        let toggleSecondBar: () -> Void
        let refreshMenuBarItems: () -> Void
        let toggleProMode: () -> Void
        let proModeTitle: () -> String
        let toggleAutomationPaused: () -> Void
        let automationPausedTitle: () -> String
        var automationPaused: () -> Bool = { false }
        var secondBarVisible: () -> Bool = { false }
        var routeCommand: ((MenuBarCommand) -> Void)?
        let canRefreshMenuBarItems: () -> Bool
        let resetSeparatorLength: () -> Void
        let showDragHint: () -> Void
        let openSettings: () -> Void
        let showDiagnostics: () -> Void
        let showAbout: () -> Void
        let quit: () -> Void
        // Phase 10 layout actions
        var enterFullMenuBarMode: () -> Void = {}
        var exitFullMenuBarMode: () -> Void = {}
        var fullMenuBarModeIsActive: () -> Bool = { false }
        var showLayoutSuggestions: () -> Void = {}
        var openLayoutSettings: () -> Void = {}
        var addSpacerDivider: () -> Void = {}
        var addSpacer: () -> Void = {}
        var toggleSpacerMarkers: () -> Void = {}
        var revealInlineAnyway: () -> Void = {}
        var crowdedRevealIntercepted: () -> Bool = { false }
    }

    private let actions: Actions
    private let commandTarget: StatusBarMenuCommandTarget

    init(actions: Actions) {
        self.actions = actions
        self.commandTarget = StatusBarMenuCommandTarget(actions: actions)
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu(title: AppConstants.displayName)

        menu.addItem(sectionHeader("Visibility"))

        menu.addItem(
            menuItem(
                title: "Expand Hidden Items",
                command: .expand,
                keyEquivalent: "",
                systemImage: "eye"
            )
        )

        menu.addItem(
            menuItem(
                title: "Collapse Hidden Items",
                command: .collapse,
                keyEquivalent: "",
                systemImage: "eye.slash"
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Hidden Items",
                command: .toggle,
                keyEquivalent: "h",
                systemImage: "menubar.rectangle"
            )
        )

        menu.addItem(
            menuItem(
                title: "Reveal All Items",
                command: .revealAll,
                keyEquivalent: "",
                systemImage: "rectangle.expand.vertical"
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Reveal All",
                command: .toggleRevealAll,
                keyEquivalent: "",
                systemImage: "arrow.up.left.and.arrow.down.right"
            )
        )

        menu.addItem(.separator())
        menu.addItem(sectionHeader("Find & Bars"))

        menu.addItem(
            menuItem(
                title: "Find Icon…",
                command: .findIcon,
                keyEquivalent: "f",
                systemImage: "magnifyingglass"
            )
        )

        menu.addItem(
            menuItem(
                title: actions.secondBarVisible() ? "Hide Second Bar" : "Show Second Bar",
                command: .toggleSecondBar,
                keyEquivalent: "s",
                systemImage: "rectangle.bottomthird.inset.filled"
            )
        )

        menu.addItem(.separator())
        menu.addItem(sectionHeader("Pro Features"))

        let refreshItem = menuItem(
            title: "Refresh Menu Bar Items",
            command: .refreshMenuBarItems,
            keyEquivalent: "r",
            systemImage: "arrow.clockwise"
        )
        refreshItem.isEnabled = actions.canRefreshMenuBarItems()
        menu.addItem(refreshItem)

        menu.addItem(
            menuItem(
                title: actions.proModeTitle(),
                command: .toggleProMode,
                keyEquivalent: "",
                systemImage: "star"
            )
        )

        menu.addItem(
            menuItem(
                title: actions.automationPausedTitle(),
                command: .toggleAutomationPaused,
                keyEquivalent: "",
                systemImage: actions.automationPaused() ? "play.circle" : "pause.circle"
            )
        )

        menu.addItem(.separator())
        menu.addItem(sectionHeader("Layout"))

        // Phase 10 — Layout menu items
        if actions.fullMenuBarModeIsActive() {
            menu.addItem(
                menuItem(
                    title: "Exit Full Menu Bar Mode",
                    command: .exitFullMenuBarMode,
                    keyEquivalent: "",
                    systemImage: "rectangle.compress.vertical"
                )
            )
        } else {
            menu.addItem(
                menuItem(
                    title: "Enter Full Menu Bar Mode",
                    command: .enterFullMenuBarMode,
                    keyEquivalent: "",
                    systemImage: "rectangle.expand.vertical"
                )
            )
        }

        menu.addItem(
            menuItem(
                title: "Layout Suggestions…",
                command: .showLayoutSuggestions,
                keyEquivalent: "",
                systemImage: "lightbulb"
            )
        )

        if actions.crowdedRevealIntercepted() {
            menu.addItem(
                menuItem(
                    title: "Reveal Inline Anyway",
                    command: .revealInlineAnyway,
                    keyEquivalent: "",
                    systemImage: "arrow.right.circle"
                )
            )
        }

        menu.addItem(
            menuItem(
                title: "Add Divider",
                command: .addSpacerDivider,
                keyEquivalent: "",
                systemImage: "rectangle.split.1x2"
            )
        )

        menu.addItem(
            menuItem(
                title: "Add Spacer",
                command: .addSpacer,
                keyEquivalent: "",
                systemImage: "arrow.left.and.right"
            )
        )

        menu.addItem(
            menuItem(
                title: "Toggle Spacer Markers",
                command: .toggleSpacerMarkers,
                keyEquivalent: "",
                systemImage: "eye"
            )
        )

        menu.addItem(
            menuItem(
                title: "Layout Settings…",
                command: .openLayoutSettings,
                keyEquivalent: "",
                systemImage: "slider.horizontal.3"
            )
        )

        menu.addItem(.separator())
        menu.addItem(sectionHeader("Recovery"))

        menu.addItem(
            menuItem(
                title: "Show Drag Hint",
                command: .showDragHint,
                keyEquivalent: "",
                systemImage: "hand.point.up.left"
            )
        )

        menu.addItem(
            menuItem(
                title: "Reset Separator Length",
                command: .resetSeparatorLength,
                keyEquivalent: "",
                systemImage: "ruler"
            )
        )

        menu.addItem(
            menuItem(
                title: "Reveal All and Reset Separators",
                command: .emergencyRevealAndResetSeparators,
                keyEquivalent: "",
                systemImage: "exclamationmark.arrow.triangle.2.circlepath"
            )
        )

        menu.addItem(.separator())
        menu.addItem(sectionHeader(AppConstants.displayName))

        menu.addItem(
            menuItem(
                title: "Settings…",
                command: .openSettings,
                keyEquivalent: ",",
                systemImage: "gearshape"
            )
        )

        menu.addItem(
            menuItem(
                title: "Diagnostics…",
                command: .showDiagnostics,
                keyEquivalent: "",
                systemImage: "waveform.path.ecg"
            )
        )

        menu.addItem(
            menuItem(
                title: "About \(AppConstants.displayName)",
                command: .showAbout,
                keyEquivalent: "",
                systemImage: "info.circle"
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            menuItem(
                title: "Quit",
                command: .quit,
                keyEquivalent: "q",
                systemImage: "power"
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

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func menuItem(
        title: String,
        command: StatusBarMenuCommand,
        keyEquivalent: String,
        systemImage: String? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: #selector(StatusBarMenuCommandTarget.performCommand(_:)),
            keyEquivalent: keyEquivalent
        )
        item.tag = command.rawValue
        item.target = commandTarget
        if let systemImage {
            item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        }
        return item
    }
}

private enum StatusBarMenuCommand: Int {
    case expand = 1
    case collapse
    case toggle
    case revealAll
    case toggleRevealAll
    case emergencyRevealAndResetSeparators
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
    // Phase 10 layout commands
    case enterFullMenuBarMode
    case exitFullMenuBarMode
    case showLayoutSuggestions
    case openLayoutSettings
    case addSpacerDivider
    case addSpacer
    case toggleSpacerMarkers
    case revealInlineAnyway

    func perform(using actions: StatusBarMenuBuilder.Actions) {
        if let command = routedCommand(using: actions),
           let routeCommand = actions.routeCommand {
            routeCommand(command)
            return
        }

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
        case .emergencyRevealAndResetSeparators:
            actions.emergencyRevealAndResetSeparators()
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
        case .enterFullMenuBarMode:
            actions.enterFullMenuBarMode()
        case .exitFullMenuBarMode:
            actions.exitFullMenuBarMode()
        case .showLayoutSuggestions:
            actions.showLayoutSuggestions()
        case .openLayoutSettings:
            actions.openLayoutSettings()
        case .addSpacerDivider:
            actions.addSpacerDivider()
        case .addSpacer:
            actions.addSpacer()
        case .toggleSpacerMarkers:
            actions.toggleSpacerMarkers()
        case .revealInlineAnyway:
            actions.revealInlineAnyway()
        }
    }

    private func routedCommand(using actions: StatusBarMenuBuilder.Actions) -> MenuBarCommand? {
        switch self {
        case .findIcon:
            MenuBarCommand(action: .showFindIcon, source: .statusMenu)
        case .showSecondBar:
            MenuBarCommand(action: .showSecondBar, target: .secondBar, source: .statusMenu)
        case .hideSecondBar:
            MenuBarCommand(action: .hideSecondBar, target: .secondBar, source: .statusMenu)
        case .toggleSecondBar:
            MenuBarCommand(
                action: actions.secondBarVisible() ? .hideSecondBar : .showSecondBar,
                target: .secondBar,
                source: .statusMenu
            )
        case .toggleAutomationPaused:
            MenuBarCommand(
                action: actions.automationPaused() ? .resumeAutomation : .pauseAutomation,
                target: .automation,
                source: .statusMenu
            )
        case .enterFullMenuBarMode:
            MenuBarCommand(action: .enterFullMenuBarMode, target: .fullMenuBarMode, source: .statusMenu)
        case .exitFullMenuBarMode:
            MenuBarCommand(action: .exitFullMenuBarMode, target: .fullMenuBarMode, source: .statusMenu)
        case .showLayoutSuggestions:
            MenuBarCommand(action: .showLayoutSuggestions, target: .layoutSuggestions, source: .statusMenu)
        default:
            nil
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
