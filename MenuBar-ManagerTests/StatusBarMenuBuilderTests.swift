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
        let commandItems = menu.items.filter { !$0.isSeparatorItem }

        #expect(
            commandItems.map { $0.title } == [
                "Expand Hidden Items",
                "Collapse Hidden Items",
                "Toggle Hidden Items",
                "Reveal All Hidden Items",
                "Toggle Reveal All",
                "Emergency: Reveal All + Reset Separators",
                "Find Icon...",
                "Show Second Bar",
                "Hide Second Bar",
                "Toggle Second Bar",
                "Refresh Menu Bar Items",
                "Disable Pro Mode",
                "Resume Automation",
                "Reset Separator Length",
                "Show Drag Hint",
                "Enter Full Menu Bar Mode",
                "Layout Suggestions…",
                "Add Divider",
                "Add Spacer",
                "Toggle Spacer Markers",
                "Open Layout Settings",
                "Settings...",
                "Show Diagnostics",
                "About \(AppConstants.displayName)",
                "Quit"
            ]
        )
        #expect(
            commandItems.map { $0.keyEquivalent } == [
                "", "", "h", "", "", "", "f", "", "", "s", "r", "", "", "", "", "", "", "", "", "", "", ",", "", "", "q"
            ]
        )
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

        for (item, expectedCommand) in zip(commandItems, MenuActionRecorder.Command.allCases) {
            let action = try #require(item.action)
            let target = item.target

            recorder.commands.removeAll()
            let didSendAction = NSApplication.shared.sendAction(action, to: target, from: item)

            #expect(didSendAction)
            #expect(recorder.commands == [expectedCommand])
        }
    }

    private static func makeActions(
        recorder: MenuActionRecorder = MenuActionRecorder(),
        proModeTitle: String = "Enable Pro Mode",
        automationPausedTitle: String = "Pause Automation",
        canRefreshMenuBarItems: Bool = true
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
            canRefreshMenuBarItems: { canRefreshMenuBarItems },
            resetSeparatorLength: { recorder.record(.resetSeparatorLength) },
            showDragHint: { recorder.record(.showDragHint) },
            openSettings: { recorder.record(.openSettings) },
            showDiagnostics: { recorder.record(.showDiagnostics) },
            showAbout: { recorder.record(.showAbout) },
            quit: { recorder.record(.quit) },
            enterFullMenuBarMode: { recorder.record(.enterFullMenuBarMode) },
            exitFullMenuBarMode: { recorder.record(.exitFullMenuBarMode) },
            fullMenuBarModeIsActive: { false },
            showLayoutSuggestions: { recorder.record(.showLayoutSuggestions) },
            openLayoutSettings: { recorder.record(.openLayoutSettings) },
            addSpacerDivider: { recorder.record(.addSpacerDivider) },
            addSpacer: { recorder.record(.addSpacer) },
            toggleSpacerMarkers: { recorder.record(.toggleSpacerMarkers) },
            revealInlineAnyway: { recorder.record(.revealInlineAnyway) },
            crowdedRevealIntercepted: { false }
        )
    }
}

@MainActor
private final class MenuActionRecorder {
    enum Command: CaseIterable, Equatable {
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

    var commands: [Command] = []

    func record(_ command: Command) {
        commands.append(command)
    }
}
