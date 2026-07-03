import AppKit
import Testing
@testable import MenuBarDeclutter

@Suite("StatusBarMenuBuilder")
@MainActor
struct StatusBarMenuBuilderTests {
    @Test func menuStructurePreservesTitlesKeyEquivalentsAndDynamicState() {
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                proModeTitle: "Disable Pro Mode",
                automationPausedTitle: "Resume Automation",
                workspacesPreviewEnabled: true,
                functionBarPreviewEnabled: true,
                infoStripPreviewEnabled: true,
                advancedMenuRelevant: true,
                canRefreshMenuBarItems: false
            )
        )

        let menu = builder.makeMenu()
        let infoItems = informationItems(in: menu)
        let commandItems = actionItems(in: menu)
        let advancedItems = try? #require(menu.items.first { $0.title == "Advanced" }?.submenu)

        #expect(menu.autoenablesItems == false)
        #expect(advancedItems?.autoenablesItems == false)
        #expect(infoItems.map { $0.title } == [
            "Status: hidden items visible",
            "Privacy: no sensitive permissions requested here"
        ])
        #expect(infoItems.first?.toolTip == "Hidden-zone items are currently visible.")

        #expect(
            commandItems.map { $0.title } == [
                "Reveal Hidden Items",
                "Collapse Hidden Items",
                "Reveal All Items",
                "Workspaces…",
                "Find Icon…",
                "Show Second Bar",
                "Arrange Items…",
                "Full Menu Bar Mode",
                "Refresh Menu Bar Items",
                "Apply Profile…",
                "Disable Pro Mode",
                "Resume Automation",
                "Spacing Labs Settings…",
                "Show Function Bar Preview",
                "Show Info Strip Preview",
                "Preview Spacing Preset",
                "Assisted Move Guide…",
                "Layout Suggestions…",
                "Add Divider",
                "Add Spacer",
                "Toggle Spacer Markers",
                "Advanced Settings…",
                "About \(AppConstants.displayName)",
                "Recovery…",
                "Settings…",
                "Diagnostics…",
                "Quit"
            ]
        )
        #expect(
            commandItems.map { $0.keyEquivalent } == [
                "", "", "", "", "f", "s", "", "", "r", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ",", "", "q"
            ]
        )
        #expect(commandItems.allSatisfy { $0.image != nil })
        #expect(commandItems.map { $0.action }.allSatisfy { $0 == commandItems.first?.action })
        #expect(commandItems.first { $0.title == "Reveal Hidden Items" }?.toolTip?.contains("Hidden zone") == true)
        #expect(commandItems.first { $0.title == "Settings…" }?.toolTip == "Open MenuBarDeclutter settings.")
        #expect(advancedItems?.items.filter { !$0.isSeparatorItem }.map { $0.title } == [
            "Refresh Menu Bar Items",
            "Apply Profile…",
            "Disable Pro Mode",
            "Resume Automation",
            "Spacing Labs Settings…",
            "Show Function Bar Preview",
            "Show Info Strip Preview",
            "Preview Spacing Preset",
            "Assisted Move Guide…",
            "Layout Suggestions…",
            "Add Divider",
            "Add Spacer",
            "Toggle Spacer Markers",
            "Advanced Settings…",
            "About \(AppConstants.displayName)"
        ])
        #expect(advancedItems?.items.first { $0.title == "Refresh Menu Bar Items" }?.isEnabled == false)
    }

    @Test func statusRowsReflectVisibilityStateAndPrivacyBoundary() throws {
        let builder = StatusBarMenuBuilder(actions: Self.makeActions())

        var menu = builder.makeMenu()
        #expect(informationItems(in: menu).map { $0.title } == [
            "Status: hidden items visible",
            "Privacy: no sensitive permissions requested here"
        ])

        builder.refresh(for: HidingVisibilityState.collapsed)
        menu = builder.makeMenu()
        #expect(informationItems(in: menu).map { $0.title } == [
            "Status: hidden items collapsed",
            "Privacy: no sensitive permissions requested here"
        ])

        builder.refresh(for: HidingVisibilityState.revealAll)
        menu = builder.makeMenu()
        #expect(informationItems(in: menu).map { $0.title } == [
            "Status: all items revealed",
            "Privacy: no sensitive permissions requested here"
        ])

        let privacyItem = try #require(informationItems(in: menu).last)
        #expect(privacyItem.isEnabled == false)
        #expect(privacyItem.toolTip?.contains("Accessibility") == true)
        #expect(privacyItem.toolTip?.contains("Screen Recording") == true)
        #expect(privacyItem.toolTip?.contains("network") == true)
    }

    @Test func menuCommandsDispatchToMatchingActionClosures() throws {
        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                workspacesPreviewEnabled: true,
                functionBarPreviewEnabled: true,
                infoStripPreviewEnabled: true,
                advancedMenuRelevant: true,
                canRefreshMenuBarItems: true
            )
        )

        let commandItems = actionItems(in: builder.makeMenu())

        for (item, expectedCommand) in zip(commandItems, MenuActionRecorder.menuCommands) {
            let action = try #require(item.action)
            let target = item.target

            recorder.commands.removeAll()
            let didSendAction = NSApplication.shared.sendAction(action, to: target, from: item)

            #expect(didSendAction)
            #expect(recorder.commands == [expectedCommand])
        }
    }

    @Test func routeableMenuCommandsUseCommandCenterHookWhenProvided() throws {
        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                workspacesPreviewEnabled: true,
                functionBarPreviewEnabled: true,
                infoStripPreviewEnabled: true,
                advancedMenuRelevant: true,
                routeCommands: true
            )
        )
        let menu = builder.makeMenu()

        try perform("Find Icon…", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .showFindIcon,
            source: .statusMenu
        ))

        try perform("Show Second Bar", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .showSecondBar,
            target: .secondBar,
            source: .statusMenu
        ))

        try perform("Pause Automation", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .pauseAutomation,
            target: .automation,
            source: .statusMenu
        ))

        try perform("Preview Spacing Preset", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .spacingPresetDryRun,
            target: .spacingPreset("status-menu"),
            source: .statusMenu
        ))

        try perform("Show Function Bar Preview", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .showFunctionBar,
            target: .functionBar,
            source: .statusMenu
        ))

        try perform("Show Info Strip Preview", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .showInfoStrip,
            target: .infoStrip,
            source: .statusMenu
        ))

        try perform("Assisted Move Guide…", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .showAssistedMoveGuide,
            source: .statusMenu
        ))

        try perform("Full Menu Bar Mode", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .enterFullMenuBarMode,
            target: .fullMenuBarMode,
            source: .statusMenu
        ))

        try perform("Layout Suggestions…", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .showLayoutSuggestions,
            target: .layoutSuggestions,
            source: .statusMenu
        ))
    }

    @Test func openNewItemsAppearsOnlyWhenGatedInboxHasItems() throws {
        let emptyMenu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                canShowNewMenuBarItems: true,
                newMenuBarItemReviewCount: 0
            )
        ).makeMenu()
        #expect(actionItems(in: emptyMenu).allSatisfy { !$0.title.localizedStandardContains("New Item") })

        let gatedOffMenu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                canShowNewMenuBarItems: false,
                newMenuBarItemReviewCount: 2
            )
        ).makeMenu()
        #expect(actionItems(in: gatedOffMenu).allSatisfy { !$0.title.localizedStandardContains("New Item") })

        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                canShowNewMenuBarItems: true,
                newMenuBarItemReviewCount: 2
            )
        )
        let menu = builder.makeMenu()

        try perform("Review 2 New Items…", in: menu)
        #expect(recorder.commands == [.openNewMenuBarItems])
    }

    @Test func advancedSubmenuAppearsOnlyWhenRelevant() {
        let defaultMenu = StatusBarMenuBuilder(actions: Self.makeActions()).makeMenu()
        #expect(defaultMenu.items.allSatisfy { $0.title != "Advanced" })

        let advancedMenu = StatusBarMenuBuilder(
            actions: Self.makeActions(advancedMenuRelevant: true)
        ).makeMenu()
        #expect(advancedMenu.items.contains { $0.title == "Advanced" && $0.submenu != nil })
    }

    @Test func advancedVisibilityIgnoresDefaultLayoutFeatures() {
        let defaultVisibility = StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false
        )
        #expect(!defaultVisibility.isRelevant)

        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: true,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false
        ).isRelevant)
        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: false,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false
        ).isRelevant)
        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: true,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false
        ).isRelevant)
        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: true,
            dogfoodModeEnabled: false
        ).isRelevant)
        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: true
        ).isRelevant)
        #expect(!StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false,
            workspacesPreviewEnabled: true
        ).isRelevant)
        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false,
            workspacesPreviewEnabled: true,
            functionBarPreviewEnabled: true
        ).isRelevant)
        #expect(!StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false,
            functionBarPreviewEnabled: true
        ).isRelevant)
        #expect(StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false,
            workspacesPreviewEnabled: true,
            infoStripPreviewEnabled: true
        ).isRelevant)
        #expect(!StatusMenuAdvancedVisibility(
            proModeEnabled: false,
            automationPaused: true,
            iconMovingEnabled: false,
            menuBarSpacingLabsEnabled: false,
            dogfoodModeEnabled: false,
            infoStripPreviewEnabled: true
        ).isRelevant)
    }

    @Test func advancedMenuHidesPreviewPanelActionsUntilPreviewGatesAreEnabled() throws {
        let menu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                functionBarPreviewEnabled: false,
                infoStripPreviewEnabled: false,
                advancedMenuRelevant: true
            )
        ).makeMenu()
        let advancedItems = try #require(menu.items.first { $0.title == "Advanced" }?.submenu?.items)
        let titles = advancedItems.map { item in item.title }

        #expect(!titles.contains("Show Function Bar Preview"))
        #expect(!titles.contains("Show Info Strip Preview"))
    }

    @Test func advancedMenuRequiresWorkspacesGateBeforeShowingInfoStripAction() throws {
        let inconsistentMenu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                workspacesPreviewEnabled: false,
                infoStripPreviewEnabled: true,
                advancedMenuRelevant: true
            )
        ).makeMenu()
        let inconsistentTitles = try #require(inconsistentMenu.items.first { $0.title == "Advanced" }?.submenu?.items.map(\.title))
        #expect(!inconsistentTitles.contains("Show Info Strip Preview"))

        let gatedMenu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                workspacesPreviewEnabled: true,
                infoStripPreviewEnabled: true,
                advancedMenuRelevant: true
            )
        ).makeMenu()
        let gatedTitles = try #require(gatedMenu.items.first { $0.title == "Advanced" }?.submenu?.items.map(\.title))
        #expect(gatedTitles.contains("Show Info Strip Preview"))

        let visibleMenu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                workspacesPreviewEnabled: false,
                infoStripPreviewEnabled: false,
                infoStripVisible: true,
                advancedMenuRelevant: true
            )
        ).makeMenu()
        let visibleTitles = try #require(visibleMenu.items.first { $0.title == "Advanced" }?.submenu?.items.map(\.title))
        #expect(visibleTitles.contains("Hide Info Strip Preview"))
    }

    @Test func routedMenuItemsExplainUnavailableCommandGates() throws {
        let unavailableMessage = "Enable Pro Mode and Accessibility Discovery first."
        let menu = StatusBarMenuBuilder(
            actions: Self.makeActions(
                advancedMenuRelevant: true,
                commandAvailability: { command in
                    switch command.action {
                    case .showFindIcon, .showSecondBar, .enterFullMenuBarMode, .spacingPresetDryRun, .showAssistedMoveGuide:
                        MenuBarCommandAvailability.unavailable(
                            message: unavailableMessage,
                            diagnosticReason: "testGate",
                            failedGate: .proMode
                        )
                    default:
                        .available
                    }
                }
            )
        ).makeMenu()

        for title in ["Find Icon…", "Show Second Bar", "Full Menu Bar Mode", "Preview Spacing Preset", "Assisted Move Guide…"] {
            let item = try #require(actionItems(in: menu).first { $0.title == title })
            #expect(item.isEnabled == false)
            #expect(item.toolTip == unavailableMessage)
        }
    }

    @Test func dogfoodEntryAppearsOnlyWhenDogfoodModeIsEnabled() {
        let hidden = StatusBarMenuBuilder(
            actions: Self.makeActions(advancedMenuRelevant: true)
        ).makeMenu()
        #expect(actionItems(in: hidden).allSatisfy { $0.title != "Dogfood Diagnostics…" })

        let visible = StatusBarMenuBuilder(
            actions: Self.makeActions(
                advancedMenuRelevant: true,
                dogfoodModeEnabled: true
            )
        ).makeMenu()
        #expect(actionItems(in: visible).contains { $0.title == "Dogfood Diagnostics…" })
    }

    @Test func dogfoodDiagnosticsEntryDispatchesToDiagnostics() throws {
        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                advancedMenuRelevant: true,
                dogfoodModeEnabled: true
            )
        )
        let menu = builder.makeMenu()

        try perform("Dogfood Diagnostics…", in: menu)

        #expect(recorder.commands == [.showDiagnostics])
    }

    @Test func safeModeMenuIsRecoveryFirst() {
        let menu = StatusBarMenuBuilder(
            actions: Self.makeActions(safeModeActive: true)
        ).makeMenu()

        #expect(menu.autoenablesItems == false)
        #expect(actionItems(in: menu).map { $0.title } == [
            "Show MenuBarDeclutter",
            "Reset Layout",
            "Open Settings",
            "Export Diagnostics",
            "Quit"
        ])
    }

    @Test func routedToggleCommandsRespectCurrentMenuState() throws {
        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                automationPausedTitle: "Resume Automation",
                automationPaused: true,
                secondBarVisible: true,
                fullMenuBarModeIsActive: true,
                advancedMenuRelevant: true,
                routeCommands: true
            )
        )
        let menu = builder.makeMenu()

        try perform("Hide Second Bar", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .hideSecondBar,
            target: .secondBar,
            source: .statusMenu
        ))

        try perform("Resume Automation", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .resumeAutomation,
            target: .automation,
            source: .statusMenu
        ))

        try perform("Exit Full Menu Bar Mode", in: menu)
        #expect(recorder.routedCommands.last == MenuBarCommand(
            action: .exitFullMenuBarMode,
            target: .fullMenuBarMode,
            source: .statusMenu
        ))

        let previewRecorder = MenuActionRecorder()
        let previewBuilder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: previewRecorder,
                functionBarVisible: true,
                infoStripVisible: true,
                advancedMenuRelevant: true,
                routeCommands: true
            )
        )
        let previewMenu = previewBuilder.makeMenu()

        try perform("Hide Function Bar Preview", in: previewMenu)
        #expect(previewRecorder.routedCommands.last == MenuBarCommand(
            action: .hideFunctionBar,
            target: .functionBar,
            source: .statusMenu
        ))

        try perform("Hide Info Strip Preview", in: previewMenu)
        #expect(previewRecorder.routedCommands.last == MenuBarCommand(
            action: .hideInfoStrip,
            target: .infoStrip,
            source: .statusMenu
        ))
    }

    private static func makeActions(
        recorder: MenuActionRecorder = MenuActionRecorder(),
        proModeTitle: String = "Enable Pro Mode",
        automationPausedTitle: String = "Pause Automation",
        automationPaused: Bool = false,
        secondBarVisible: Bool = false,
        canShowNewMenuBarItems: Bool = false,
        newMenuBarItemReviewCount: Int = 0,
        fullMenuBarModeIsActive: Bool = false,
        workspacesPreviewEnabled: Bool = false,
        functionBarPreviewEnabled: Bool = false,
        infoStripPreviewEnabled: Bool = false,
        functionBarVisible: Bool = false,
        infoStripVisible: Bool = false,
        safeModeActive: Bool = false,
        advancedMenuRelevant: Bool = false,
        dogfoodModeEnabled: Bool = false,
        canRefreshMenuBarItems: Bool = true,
        commandAvailability: @escaping (MenuBarCommand) -> MenuBarCommandAvailability = { _ in .available },
        routeCommands: Bool = false
    ) -> StatusBarMenuBuilder.Actions {
        StatusBarMenuBuilder.Actions(
            expand: { recorder.record(.expand) },
            collapse: { recorder.record(.collapse) },
            toggle: { recorder.record(.toggle) },
            revealAll: { recorder.record(.revealAll) },
            toggleRevealAll: { recorder.record(.toggleRevealAll) },
            emergencyRevealAndResetSeparators: { recorder.record(.emergencyRevealAndResetSeparators) },
            findIcon: { recorder.record(.findIcon) },
            showSecondBar: { recorder.record(.showSecondBar) },
            hideSecondBar: { recorder.record(.hideSecondBar) },
            toggleSecondBar: { recorder.record(.toggleSecondBar) },
            refreshMenuBarItems: { recorder.record(.refreshMenuBarItems) },
            toggleProMode: { recorder.record(.toggleProMode) },
            proModeTitle: { proModeTitle },
            toggleAutomationPaused: { recorder.record(.toggleAutomationPaused) },
            automationPausedTitle: { automationPausedTitle },
            automationPaused: { automationPaused },
            secondBarVisible: { secondBarVisible },
            safeModeActive: { safeModeActive },
            advancedMenuRelevant: { advancedMenuRelevant },
            canShowNewMenuBarItems: { canShowNewMenuBarItems },
            newMenuBarItemReviewCount: { newMenuBarItemReviewCount },
            commandAvailability: commandAvailability,
            routeCommand: routeCommands ? { recorder.route($0) } : nil,
            dogfoodModeEnabled: { dogfoodModeEnabled },
            canRefreshMenuBarItems: { canRefreshMenuBarItems },
            resetSeparatorLength: { recorder.record(.resetSeparatorLength) },
            resetLayout: { recorder.record(.resetLayout) },
            showDragHint: { recorder.record(.showDragHint) },
            openArrangeSettings: { recorder.record(.openArrangeSettings) },
            openNewMenuBarItems: { recorder.record(.openNewMenuBarItems) },
            openRecoverySettings: { recorder.record(.openRecoverySettings) },
            openSettings: { recorder.record(.openSettings) },
            showDiagnostics: { recorder.record(.showDiagnostics) },
            showAbout: { recorder.record(.showAbout) },
            quit: { recorder.record(.quit) },
            openProfilesSettings: { recorder.record(.openProfilesSettings) },
            enterFullMenuBarMode: { recorder.record(.enterFullMenuBarMode) },
            exitFullMenuBarMode: { recorder.record(.exitFullMenuBarMode) },
            fullMenuBarModeIsActive: { fullMenuBarModeIsActive },
            showLayoutSuggestions: { recorder.record(.showLayoutSuggestions) },
            openLayoutSettings: { recorder.record(.openLayoutSettings) },
            openAdvancedSettings: { recorder.record(.openAdvancedSettings) },
            openWorkspacesPreview: { recorder.record(.openWorkspacesPreview) },
            workspacesPreviewEnabled: { workspacesPreviewEnabled },
            functionBarPreviewEnabled: { functionBarPreviewEnabled },
            infoStripPreviewEnabled: { infoStripPreviewEnabled },
            functionBarVisible: { functionBarVisible },
            infoStripVisible: { infoStripVisible },
            showFunctionBarPreview: { recorder.record(.showFunctionBarPreview) },
            hideFunctionBarPreview: { recorder.record(.hideFunctionBarPreview) },
            showInfoStripPreview: { recorder.record(.showInfoStripPreview) },
            hideInfoStripPreview: { recorder.record(.hideInfoStripPreview) },
            previewSpacingPreset: { recorder.record(.previewSpacingPreset) },
            showAssistedMoveGuide: { recorder.record(.showAssistedMoveGuide) },
            addSpacerDivider: { recorder.record(.addSpacerDivider) },
            addSpacer: { recorder.record(.addSpacer) },
            toggleSpacerMarkers: { recorder.record(.toggleSpacerMarkers) },
            revealInlineAnyway: { recorder.record(.revealInlineAnyway) },
            crowdedRevealIntercepted: { false }
        )
    }

    private func perform(_ title: String, in menu: NSMenu) throws {
        let item = try #require(actionItems(in: menu).first { $0.title == title })
        let action = try #require(item.action)
        let didSendAction = NSApplication.shared.sendAction(action, to: item.target, from: item)
        #expect(didSendAction)
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

    private func informationItems(in menu: NSMenu) -> [NSMenuItem] {
        menu.items.filter { item in
            !item.isSeparatorItem && item.action == nil && item.submenu == nil
        }
    }
}

@MainActor
private final class MenuActionRecorder {
    enum Command: Equatable {
        case expand
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
        case enterFullMenuBarMode
        case showLayoutSuggestions
        case addSpacerDivider
        case addSpacer
        case toggleSpacerMarkers
        case openLayoutSettings
        case openSettings
        case showDiagnostics
        case showAbout
        case quit
        case openProfilesSettings
        case exitFullMenuBarMode
        case openAdvancedSettings
        case openWorkspacesPreview
        case showFunctionBarPreview
        case hideFunctionBarPreview
        case showInfoStripPreview
        case hideInfoStripPreview
        case previewSpacingPreset
        case showAssistedMoveGuide
        case revealInlineAnyway
    }

    static let menuCommands: [Command] = [
        .expand,
        .collapse,
        .revealAll,
        .openWorkspacesPreview,
        .findIcon,
        .toggleSecondBar,
        .openArrangeSettings,
        .enterFullMenuBarMode,
        .refreshMenuBarItems,
        .openProfilesSettings,
        .toggleProMode,
        .toggleAutomationPaused,
        .openLayoutSettings,
        .showFunctionBarPreview,
        .showInfoStripPreview,
        .previewSpacingPreset,
        .showAssistedMoveGuide,
        .showLayoutSuggestions,
        .addSpacerDivider,
        .addSpacer,
        .toggleSpacerMarkers,
        .openAdvancedSettings,
        .showAbout,
        .openRecoverySettings,
        .openSettings,
        .showDiagnostics,
        .quit
    ]

    var commands: [Command] = []
    var routedCommands: [MenuBarCommand] = []

    func record(_ command: Command) {
        commands.append(command)
    }

    func route(_ command: MenuBarCommand) {
        routedCommands.append(command)
    }
}
