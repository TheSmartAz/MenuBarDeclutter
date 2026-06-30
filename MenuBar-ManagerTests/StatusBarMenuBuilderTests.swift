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
                canRefreshMenuBarItems: false
            )
        )

        let menu = builder.makeMenu()
        let headers = menu.items.filter { !$0.isSeparatorItem && $0.action == nil }
        let commandItems = menu.items.filter { !$0.isSeparatorItem && $0.action != nil }

        #expect(headers.map { $0.title } == [
            "Visibility",
            "Find & Bars",
            "Pro Features",
            "Layout",
            "Recovery",
            AppConstants.displayName
        ])

        #expect(
            commandItems.map { $0.title } == [
                "Expand Hidden Items",
                "Collapse Hidden Items",
                "Toggle Hidden Items",
                "Reveal All Items",
                "Toggle Reveal All",
                "Find Icon…",
                "Show Second Bar",
                "Refresh Menu Bar Items",
                "Disable Pro Mode",
                "Resume Automation",
                "Enter Full Menu Bar Mode",
                "Layout Suggestions…",
                "Add Divider",
                "Add Spacer",
                "Toggle Spacer Markers",
                "Layout Settings…",
                "Show Drag Hint",
                "Reset Separator Length",
                "Reveal All and Reset Separators",
                "Settings…",
                "Diagnostics…",
                "About \(AppConstants.displayName)",
                "Quit"
            ]
        )
        #expect(
            commandItems.map { $0.keyEquivalent } == [
                "", "", "h", "", "", "f", "s", "r", "", "", "", "", "", "", "", "", "", "", "", ",", "", "", "q"
            ]
        )
        #expect(commandItems.allSatisfy { $0.image != nil })
        #expect(commandItems.map { $0.action }.allSatisfy { $0 == commandItems.first?.action })
        #expect(commandItems.first { $0.title == "Refresh Menu Bar Items" }?.isEnabled == false)
    }

    @Test func menuCommandsDispatchToMatchingActionClosures() throws {
        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                canRefreshMenuBarItems: true
            )
        )

        let commandItems = builder.makeMenu().items.filter { !$0.isSeparatorItem }

        for (item, expectedCommand) in zip(commandItems.filter({ $0.action != nil }), MenuActionRecorder.menuCommands) {
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

        try perform("Enter Full Menu Bar Mode", in: menu)
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

    @Test func routedToggleCommandsRespectCurrentMenuState() throws {
        let recorder = MenuActionRecorder()
        let builder = StatusBarMenuBuilder(
            actions: Self.makeActions(
                recorder: recorder,
                automationPausedTitle: "Resume Automation",
                automationPaused: true,
                secondBarVisible: true,
                fullMenuBarModeIsActive: true,
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
    }

    private static func makeActions(
        recorder: MenuActionRecorder = MenuActionRecorder(),
        proModeTitle: String = "Enable Pro Mode",
        automationPausedTitle: String = "Pause Automation",
        automationPaused: Bool = false,
        secondBarVisible: Bool = false,
        fullMenuBarModeIsActive: Bool = false,
        canRefreshMenuBarItems: Bool = true,
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
            routeCommand: routeCommands ? { recorder.route($0) } : nil,
            canRefreshMenuBarItems: { canRefreshMenuBarItems },
            resetSeparatorLength: { recorder.record(.resetSeparatorLength) },
            showDragHint: { recorder.record(.showDragHint) },
            openSettings: { recorder.record(.openSettings) },
            showDiagnostics: { recorder.record(.showDiagnostics) },
            showAbout: { recorder.record(.showAbout) },
            quit: { recorder.record(.quit) },
            enterFullMenuBarMode: { recorder.record(.enterFullMenuBarMode) },
            exitFullMenuBarMode: { recorder.record(.exitFullMenuBarMode) },
            fullMenuBarModeIsActive: { fullMenuBarModeIsActive },
            showLayoutSuggestions: { recorder.record(.showLayoutSuggestions) },
            openLayoutSettings: { recorder.record(.openLayoutSettings) },
            addSpacerDivider: { recorder.record(.addSpacerDivider) },
            addSpacer: { recorder.record(.addSpacer) },
            toggleSpacerMarkers: { recorder.record(.toggleSpacerMarkers) },
            revealInlineAnyway: { recorder.record(.revealInlineAnyway) },
            crowdedRevealIntercepted: { false }
        )
    }

    private func perform(_ title: String, in menu: NSMenu) throws {
        let item = try #require(menu.items.first { $0.title == title })
        let action = try #require(item.action)
        let didSendAction = NSApplication.shared.sendAction(action, to: item.target, from: item)
        #expect(didSendAction)
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
        case showDragHint
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
        case exitFullMenuBarMode
        case revealInlineAnyway
    }

    static let menuCommands: [Command] = [
        .expand,
        .collapse,
        .toggle,
        .revealAll,
        .toggleRevealAll,
        .findIcon,
        .toggleSecondBar,
        .refreshMenuBarItems,
        .toggleProMode,
        .toggleAutomationPaused,
        .enterFullMenuBarMode,
        .showLayoutSuggestions,
        .addSpacerDivider,
        .addSpacer,
        .toggleSpacerMarkers,
        .openLayoutSettings,
        .showDragHint,
        .resetSeparatorLength,
        .emergencyRevealAndResetSeparators,
        .openSettings,
        .showDiagnostics,
        .showAbout,
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
