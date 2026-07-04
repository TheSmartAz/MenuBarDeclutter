import AppKit
import Foundation

nonisolated struct StatusMenuAdvancedVisibility: Equatable, Sendable {
    let proModeEnabled: Bool
    let automationPaused: Bool
    let iconMovingEnabled: Bool
    let menuBarSpacingLabsEnabled: Bool
    let dogfoodModeEnabled: Bool
    var workspacesPreviewEnabled: Bool = false
    var functionBarPreviewEnabled: Bool = false
    var infoStripPreviewEnabled: Bool = false

    var isRelevant: Bool {
        proModeEnabled
            || !automationPaused
            || iconMovingEnabled
            || menuBarSpacingLabsEnabled
            || dogfoodModeEnabled
            || (workspacesPreviewEnabled && (functionBarPreviewEnabled || infoStripPreviewEnabled))
    }
}

/// Builds the menu shown by both the control item and the right-click menu
/// on the separator. The builder generates ``NSMenu`` instances on demand and
/// keeps a small, non-AppKit visibility snapshot so each open can show the
/// current Basic Mode state without asking for sensitive permissions.
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
        var findIconStatusMenuEnabled: () -> Bool = { true }
        var secondBarStatusMenuEnabled: () -> Bool = { true }
        var safeModeActive: () -> Bool = { false }
        var advancedMenuRelevant: () -> Bool = { false }
        var canShowNewMenuBarItems: () -> Bool = { false }
        var newMenuBarItemReviewCount: () -> Int = { 0 }
        var commandAvailability: (MenuBarCommand) -> MenuBarCommandAvailability = { _ in .available }
        var routeCommand: ((MenuBarCommand) -> Void)?
        var dogfoodModeEnabled: () -> Bool = { false }
        let canRefreshMenuBarItems: () -> Bool
        let resetSeparatorLength: () -> Void
        let resetLayout: () -> Void
        let showDragHint: () -> Void
        let openArrangeSettings: () -> Void
        let openNewMenuBarItems: () -> Void
        let openRecoverySettings: () -> Void
        let openSettings: () -> Void
        let showDiagnostics: () -> Void
        let showAbout: () -> Void
        let quit: () -> Void
        var openProfilesSettings: () -> Void = {}
        // Phase 10 layout actions
        var enterFullMenuBarMode: () -> Void = {}
        var exitFullMenuBarMode: () -> Void = {}
        var fullMenuBarModeIsActive: () -> Bool = { false }
        var showLayoutSuggestions: () -> Void = {}
        var openLayoutSettings: () -> Void = {}
        var openAdvancedSettings: () -> Void = {}
        var openWorkspacesPreview: () -> Void = {}
        var workspacesPreviewEnabled: () -> Bool = { false }
        var functionBarPreviewEnabled: () -> Bool = { false }
        var infoStripPreviewEnabled: () -> Bool = { false }
        var functionBarVisible: () -> Bool = { false }
        var infoStripVisible: () -> Bool = { false }
        var showFunctionBarPreview: () -> Void = {}
        var hideFunctionBarPreview: () -> Void = {}
        var showInfoStripPreview: () -> Void = {}
        var hideInfoStripPreview: () -> Void = {}
        var previewSpacingPreset: () -> Void = {}
        var showAssistedMoveGuide: () -> Void = {}
        var addSpacerDivider: () -> Void = {}
        var addSpacer: () -> Void = {}
        var toggleSpacerMarkers: () -> Void = {}
        var revealInlineAnyway: () -> Void = {}
        var crowdedRevealIntercepted: () -> Bool = { false }
    }

    private let actions: Actions
    private let commandTarget: StatusBarMenuCommandTarget
    private var visibilityState: HidingVisibilityState = .expanded

    init(actions: Actions) {
        self.actions = actions
        self.commandTarget = StatusBarMenuCommandTarget(actions: actions)
    }

    func makeMenu() -> NSMenu {
        if actions.safeModeActive() {
            return makeSafeModeMenu()
        }

        let menu = NSMenu(title: AppConstants.displayName)
        menu.autoenablesItems = false

        addStatusSummary(to: menu)
        menu.addItem(.separator())

        menu.addItem(sectionHeader("Basic Mode", systemImage: "checkmark.shield"))
        menu.addItem(menuItem(
            title: "Reveal Hidden Items",
            command: .expand,
            keyEquivalent: "",
            systemImage: "eye",
            toolTip: "Show items in the Hidden zone without requesting extra permissions.",
            isEnabled: visibilityState != .expanded
        ))
        menu.addItem(menuItem(
            title: "Collapse Hidden Items",
            command: .collapse,
            keyEquivalent: "",
            systemImage: "eye.slash",
            toolTip: "Return Hidden-zone items to the decluttered layout.",
            isEnabled: visibilityState != .collapsed
        ))

        menu.addItem(
            menuItem(
                title: "Reveal All Items",
                command: .revealAll,
                keyEquivalent: "",
                systemImage: "rectangle.expand.vertical",
                toolTip: "Reveal Hidden and Always-Hidden items until you collapse again.",
                isEnabled: visibilityState != .revealAll
            )
        )

        menu.addItem(.separator())

        menu.addItem(sectionHeader("Find & Rescue", systemImage: "lifepreserver"))
        menu.addItem(
            menuItem(
                title: "Workspaces…",
                command: .openWorkspacesPreview,
                keyEquivalent: "",
                systemImage: "rectangle.3.group",
                toolTip: "Open workspace preview settings and profile-linked layouts."
            )
        )

        if actions.findIconStatusMenuEnabled() {
            menu.addItem(
                routedMenuItem(
                    title: "Find Icon…",
                    command: .findIcon,
                    routedCommand: MenuBarCommand(action: .showFindIcon, source: .statusMenu),
                    keyEquivalent: "f",
                    systemImage: "magnifyingglass",
                    toolTip: "Open local Find Icon search when Pro discovery gates are satisfied."
                )
            )
        }

        if actions.secondBarStatusMenuEnabled() {
            let secondBarCommand = MenuBarCommand(
                action: actions.secondBarVisible() ? .hideSecondBar : .showSecondBar,
                target: .secondBar,
                source: .statusMenu
            )
            menu.addItem(
                routedMenuItem(
                    title: actions.secondBarVisible() ? "Hide Second Bar" : "Show Second Bar",
                    command: .toggleSecondBar,
                    routedCommand: secondBarCommand,
                    keyEquivalent: "s",
                    systemImage: "rectangle.bottomthird.inset.filled",
                    toolTip: "Show or hide the optional Second Bar surface for hidden items."
                )
            )
        }

        menu.addItem(.separator())

        menu.addItem(sectionHeader("Layout", systemImage: "arrow.up.left.and.arrow.down.right"))
        menu.addItem(
            menuItem(
                title: "Arrange Items…",
                command: .openArrangeSettings,
                keyEquivalent: "",
                systemImage: "arrow.up.left.and.arrow.down.right",
                toolTip: "Open layout and assisted arrangement controls."
            )
        )

        let newItemCount = actions.newMenuBarItemReviewCount()
        if actions.canShowNewMenuBarItems(), newItemCount > 0 {
            menu.addItem(
                menuItem(
                    title: newItemCount == 1 ? "Review 1 New Item…" : "Review \(newItemCount) New Items…",
                    command: .openNewMenuBarItems,
                    keyEquivalent: "",
                    systemImage: "tray",
                    toolTip: "Review newly discovered menu bar items before assigning zones."
                )
            )
        }

        if actions.fullMenuBarModeIsActive() {
            menu.addItem(
                routedMenuItem(
                    title: "Exit Full Menu Bar Mode",
                    command: .exitFullMenuBarMode,
                    routedCommand: MenuBarCommand(action: .exitFullMenuBarMode, target: .fullMenuBarMode, source: .statusMenu),
                    keyEquivalent: "",
                    systemImage: "rectangle.compress.vertical",
                    toolTip: "Return to the saved decluttered layout."
                )
            )
        } else {
            menu.addItem(
                routedMenuItem(
                    title: "Full Menu Bar Mode",
                    command: .enterFullMenuBarMode,
                    routedCommand: MenuBarCommand(action: .enterFullMenuBarMode, target: .fullMenuBarMode, source: .statusMenu),
                    keyEquivalent: "",
                    systemImage: "rectangle.expand.vertical",
                    toolTip: "Reveal the full menu bar layout temporarily."
                )
            )
        }

        if actions.advancedMenuRelevant() {
            menu.addItem(.separator())
            menu.addItem(advancedSubmenu())
        }

        menu.addItem(.separator())

        menu.addItem(sectionHeader("Support", systemImage: "cross.case"))
        menu.addItem(
            menuItem(
                title: "Recovery…",
                command: .openRecoverySettings,
                keyEquivalent: "",
                systemImage: "cross.case",
                toolTip: "Open recovery tools for layout resets, Safe Mode, and diagnostics."
            )
        )

        menu.addItem(
            menuItem(
                title: "Settings…",
                command: .openSettings,
                keyEquivalent: ",",
                systemImage: "gearshape",
                toolTip: "Open MenuBarDeclutter settings."
            )
        )

        if actions.crowdedRevealIntercepted() {
            menu.addItem(
                menuItem(
                    title: "Reveal Inline Anyway",
                    command: .revealInlineAnyway,
                    keyEquivalent: "",
                    systemImage: "arrow.right.circle",
                    toolTip: "Override the crowded-menu warning for the current reveal attempt."
                )
            )
        }

        menu.addItem(
            menuItem(
                title: "Diagnostics…",
                command: .showDiagnostics,
                keyEquivalent: "",
                systemImage: "waveform.path.ecg",
                toolTip: "Open local diagnostics and export support information."
            )
        )

        menu.addItem(
            menuItem(
                title: "Quit",
                command: .quit,
                keyEquivalent: "q",
                systemImage: "power",
                toolTip: "Quit MenuBarDeclutter."
            )
        )

        return menu
    }

    private func makeSafeModeMenu() -> NSMenu {
        let menu = NSMenu(title: AppConstants.displayName)
        menu.autoenablesItems = false

        menu.addItem(statusLine(title: "Status: Safe Mode active", systemImage: "cross.case"))
        menu.addItem(privacyStatusLine())
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Show MenuBarDeclutter", command: .expand, keyEquivalent: "", systemImage: "eye"))
        menu.addItem(menuItem(title: "Reset Layout", command: .resetLayout, keyEquivalent: "", systemImage: "arrow.counterclockwise"))
        menu.addItem(menuItem(title: "Open Settings", command: .openSettings, keyEquivalent: ",", systemImage: "gearshape"))
        menu.addItem(menuItem(title: "Export Diagnostics", command: .showDiagnostics, keyEquivalent: "", systemImage: "waveform.path.ecg"))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Quit", command: .quit, keyEquivalent: "q", systemImage: "power"))

        return menu
    }

    private func advancedSubmenu() -> NSMenuItem {
        let parent = NSMenuItem(title: "Advanced", action: nil, keyEquivalent: "")
        parent.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Advanced")

        let submenu = NSMenu(title: "Advanced")
        submenu.autoenablesItems = false

        let refreshItem = menuItem(
            title: "Refresh Menu Bar Items",
            command: .refreshMenuBarItems,
            keyEquivalent: "r",
            systemImage: "arrow.clockwise"
        )
        refreshItem.isEnabled = actions.canRefreshMenuBarItems()
        if !refreshItem.isEnabled {
            refreshItem.toolTip = "Unavailable until Pro Mode, Accessibility Discovery, and Accessibility permission are enabled."
        }
        submenu.addItem(refreshItem)

        submenu.addItem(menuItem(title: "Apply Profile…", command: .openProfilesSettings, keyEquivalent: "", systemImage: "person.crop.rectangle.stack"))
        submenu.addItem(menuItem(title: actions.proModeTitle(), command: .toggleProMode, keyEquivalent: "", systemImage: "star"))
        submenu.addItem(menuItem(title: actions.automationPausedTitle(), command: .toggleAutomationPaused, keyEquivalent: "", systemImage: actions.automationPaused() ? "play.circle" : "pause.circle"))
        submenu.addItem(.separator())
        submenu.addItem(menuItem(title: "Spacing Labs Settings…", command: .openLayoutSettings, keyEquivalent: "", systemImage: "ruler"))
        let canShowFunctionBarPreview = actions.workspacesPreviewEnabled() && actions.functionBarPreviewEnabled()
        if canShowFunctionBarPreview || actions.functionBarVisible() {
            submenu.addItem(
                routedMenuItem(
                    title: actions.functionBarVisible() ? "Hide Function Bar Preview" : "Show Function Bar Preview",
                    command: actions.functionBarVisible() ? .hideFunctionBarPreview : .showFunctionBarPreview,
                    routedCommand: MenuBarCommand(
                        action: actions.functionBarVisible() ? .hideFunctionBar : .showFunctionBar,
                        target: .functionBar,
                        source: .statusMenu
                    ),
                    keyEquivalent: "",
                    systemImage: "menubar.rectangle"
                )
            )
        }
        let canShowInfoStripPreview = actions.workspacesPreviewEnabled() && actions.infoStripPreviewEnabled()
        if canShowInfoStripPreview || actions.infoStripVisible() {
            submenu.addItem(
                routedMenuItem(
                    title: actions.infoStripVisible() ? "Hide Info Strip Preview" : "Show Info Strip Preview",
                    command: actions.infoStripVisible() ? .hideInfoStripPreview : .showInfoStripPreview,
                    routedCommand: MenuBarCommand(
                        action: actions.infoStripVisible() ? .hideInfoStrip : .showInfoStrip,
                        target: .infoStrip,
                        source: .statusMenu
                    ),
                    keyEquivalent: "",
                    systemImage: "info.circle"
                )
            )
        }
        submenu.addItem(
            routedMenuItem(
                title: "Preview Spacing Preset",
                command: .previewSpacingPreset,
                routedCommand: MenuBarCommand(action: .spacingPresetDryRun, target: .spacingPreset("status-menu"), source: .statusMenu),
                keyEquivalent: "",
                systemImage: "ruler.fill"
            )
        )
        submenu.addItem(
            routedMenuItem(
                title: "Assisted Move Guide…",
                command: .showAssistedMoveGuide,
                routedCommand: MenuBarCommand(action: .showAssistedMoveGuide, source: .statusMenu),
                keyEquivalent: "",
                systemImage: "arrow.up.left.and.arrow.down.right"
            )
        )
        if actions.dogfoodModeEnabled() {
            submenu.addItem(menuItem(title: "Dogfood Diagnostics…", command: .showDogfoodDiagnostics, keyEquivalent: "", systemImage: "checklist"))
        }
        submenu.addItem(.separator())
        submenu.addItem(menuItem(title: "Layout Suggestions…", command: .showLayoutSuggestions, keyEquivalent: "", systemImage: "lightbulb"))
        submenu.addItem(menuItem(title: "Add Divider", command: .addSpacerDivider, keyEquivalent: "", systemImage: "rectangle.split.1x2"))
        submenu.addItem(menuItem(title: "Add Spacer", command: .addSpacer, keyEquivalent: "", systemImage: "arrow.left.and.right"))
        submenu.addItem(menuItem(title: "Toggle Spacer Markers", command: .toggleSpacerMarkers, keyEquivalent: "", systemImage: "eye"))
        submenu.addItem(menuItem(title: "Advanced Settings…", command: .openAdvancedSettings, keyEquivalent: "", systemImage: "slider.horizontal.3"))
        submenu.addItem(menuItem(title: "About \(AppConstants.displayName)", command: .showAbout, keyEquivalent: "", systemImage: "info.circle"))

        parent.submenu = submenu
        return parent
    }

    /// Updates dynamic menu items for the new visibility state. Because we
    /// rebuild the menu on every open, this primarily exists as a hook for
    /// future onboarding and any state-dependent badges or disabled items.
    func refresh(for visibility: HidingVisibilityState) {
        visibilityState = visibility
    }

    /// Backward-compatible refresh that maps a legacy binary state to a
    /// visibility state. Kept for Phase 1 callers/tests.
    func refresh(for state: HidingState) {
        refresh(for: state.isCollapsed ? HidingVisibilityState.collapsed : HidingVisibilityState.expanded)
    }

    private func sectionHeader(_ title: String, systemImage: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        if let systemImage {
            item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        }
        return item
    }

    private func addStatusSummary(to menu: NSMenu) {
        menu.addItem(
            statusLine(
                title: visibilityState.statusMenuTitle,
                systemImage: visibilityState.statusMenuSystemImage,
                toolTip: visibilityState.statusMenuToolTip
            )
        )
        menu.addItem(privacyStatusLine())
    }

    private func privacyStatusLine() -> NSMenuItem {
        statusLine(
            title: "Privacy: no sensitive permissions requested here",
            systemImage: "hand.raised",
            toolTip: "This menu does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access."
        )
    }

    private func statusLine(
        title: String,
        systemImage: String,
        toolTip: String? = nil
    ) -> NSMenuItem {
        let item = sectionHeader(title)
        item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        item.toolTip = toolTip
        return item
    }

    private func menuItem(
        title: String,
        command: StatusBarMenuCommand,
        keyEquivalent: String,
        systemImage: String? = nil,
        toolTip: String? = nil,
        isEnabled: Bool = true
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: #selector(StatusBarMenuCommandTarget.performCommand(_:)),
            keyEquivalent: keyEquivalent
        )
        item.tag = command.rawValue
        item.target = commandTarget
        item.isEnabled = isEnabled
        if let systemImage {
            item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        }
        item.toolTip = toolTip
        return item
    }

    private func routedMenuItem(
        title: String,
        command: StatusBarMenuCommand,
        routedCommand: MenuBarCommand,
        keyEquivalent: String,
        systemImage: String? = nil,
        toolTip: String? = nil
    ) -> NSMenuItem {
        let item = menuItem(title: title, command: command, keyEquivalent: keyEquivalent, systemImage: systemImage, toolTip: toolTip)
        let availability = actions.commandAvailability(routedCommand)
        item.isEnabled = availability.isAvailable
        if !availability.isAvailable {
            item.toolTip = availability.message
        }
        return item
    }
}

private extension HidingVisibilityState {
    var statusMenuTitle: String {
        switch self {
        case .collapsed:
            "Status: hidden items collapsed"
        case .expanded:
            "Status: hidden items visible"
        case .revealAll:
            "Status: all items revealed"
        }
    }

    var statusMenuSystemImage: String {
        switch self {
        case .collapsed:
            "eye.slash"
        case .expanded:
            "eye"
        case .revealAll:
            "rectangle.expand.vertical"
        }
    }

    var statusMenuToolTip: String {
        switch self {
        case .collapsed:
            "Hidden-zone items are currently collapsed."
        case .expanded:
            "Hidden-zone items are currently visible."
        case .revealAll:
            "All menu bar item zones are currently revealed."
        }
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
    case resetLayout
    case showDragHint
    case openArrangeSettings
    case openNewMenuBarItems
    case openRecoverySettings
    case openSettings
    case showDiagnostics
    case showAbout
    case quit
    case openProfilesSettings
    // Phase 10 layout commands
    case enterFullMenuBarMode
    case exitFullMenuBarMode
    case showLayoutSuggestions
    case openLayoutSettings
    case openAdvancedSettings
    case openWorkspacesPreview
    case showFunctionBarPreview
    case hideFunctionBarPreview
    case showInfoStripPreview
    case hideInfoStripPreview
    case previewSpacingPreset
    case showAssistedMoveGuide
    case showDogfoodDiagnostics
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
        case .resetLayout:
            actions.resetLayout()
        case .showDragHint:
            actions.showDragHint()
        case .openArrangeSettings:
            actions.openArrangeSettings()
        case .openNewMenuBarItems:
            actions.openNewMenuBarItems()
        case .openRecoverySettings:
            actions.openRecoverySettings()
        case .openSettings:
            actions.openSettings()
        case .showDiagnostics:
            actions.showDiagnostics()
        case .showAbout:
            actions.showAbout()
        case .quit:
            actions.quit()
        case .openProfilesSettings:
            actions.openProfilesSettings()
        case .enterFullMenuBarMode:
            actions.enterFullMenuBarMode()
        case .exitFullMenuBarMode:
            actions.exitFullMenuBarMode()
        case .showLayoutSuggestions:
            actions.showLayoutSuggestions()
        case .openLayoutSettings:
            actions.openLayoutSettings()
        case .openAdvancedSettings:
            actions.openAdvancedSettings()
        case .openWorkspacesPreview:
            actions.openWorkspacesPreview()
        case .showFunctionBarPreview:
            actions.showFunctionBarPreview()
        case .hideFunctionBarPreview:
            actions.hideFunctionBarPreview()
        case .showInfoStripPreview:
            actions.showInfoStripPreview()
        case .hideInfoStripPreview:
            actions.hideInfoStripPreview()
        case .previewSpacingPreset:
            actions.previewSpacingPreset()
        case .showAssistedMoveGuide:
            actions.showAssistedMoveGuide()
        case .showDogfoodDiagnostics:
            actions.showDiagnostics()
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
        case .showFunctionBarPreview:
            MenuBarCommand(action: .showFunctionBar, target: .functionBar, source: .statusMenu)
        case .hideFunctionBarPreview:
            MenuBarCommand(action: .hideFunctionBar, target: .functionBar, source: .statusMenu)
        case .showInfoStripPreview:
            MenuBarCommand(action: .showInfoStrip, target: .infoStrip, source: .statusMenu)
        case .hideInfoStripPreview:
            MenuBarCommand(action: .hideInfoStrip, target: .infoStrip, source: .statusMenu)
        case .previewSpacingPreset:
            MenuBarCommand(action: .spacingPresetDryRun, target: .spacingPreset("status-menu"), source: .statusMenu)
        case .showAssistedMoveGuide:
            MenuBarCommand(action: .showAssistedMoveGuide, source: .statusMenu)
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
