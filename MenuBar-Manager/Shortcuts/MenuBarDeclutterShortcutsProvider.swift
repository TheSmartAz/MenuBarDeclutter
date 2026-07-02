import AppIntents
import Foundation

/// App Shortcuts provider that exposes MenuBarDeclutter intents to the
/// Shortcuts app.
struct MenuBarDeclutterShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExpandMenuBarItemsIntent(),
            phrases: [
                "Expand menu bar items in \(.applicationName)",
                "Show hidden menu bar items in \(.applicationName)"
            ],
            shortTitle: "Expand Menu Bar Items",
            systemImageName: "chevron.left.2"
        )
        AppShortcut(
            intent: CollapseMenuBarItemsIntent(),
            phrases: [
                "Collapse menu bar items in \(.applicationName)",
                "Hide menu bar items in \(.applicationName)"
            ],
            shortTitle: "Collapse Menu Bar Items",
            systemImageName: "chevron.right.2"
        )
        AppShortcut(
            intent: RevealAllMenuBarItemsIntent(),
            phrases: [
                "Reveal all menu bar items in \(.applicationName)"
            ],
            shortTitle: "Reveal All Menu Bar Items",
            systemImageName: "rectangle.expand.vertical"
        )
        AppShortcut(
            intent: ShowFindIconIntent(),
            phrases: [
                "Show Find Icon in \(.applicationName)",
                "Find menu bar items in \(.applicationName)"
            ],
            shortTitle: "Show Find Icon",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: ShowSecondBarIntent(),
            phrases: [
                "Show second bar in \(.applicationName)"
            ],
            shortTitle: "Show Second Bar",
            systemImageName: "menubar.rectangle"
        )
        AppShortcut(
            intent: EnterFullMenuBarModeIntent(),
            phrases: [
                "Enter full menu bar mode in \(.applicationName)"
            ],
            shortTitle: "Enter Full Menu Bar Mode",
            systemImageName: "rectangle.split.3x1"
        )
        AppShortcut(
            intent: PauseAutomationIntent(),
            phrases: [
                "Pause automation in \(.applicationName)"
            ],
            shortTitle: "Pause Automation",
            systemImageName: "pause.circle"
        )
        AppShortcut(
            intent: ResumeAutomationIntent(),
            phrases: [
                "Resume automation in \(.applicationName)"
            ],
            shortTitle: "Resume Automation",
            systemImageName: "play.circle"
        )
    }
}

// MARK: - Individual Intents

struct ExpandMenuBarItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Expand Menu Bar Items"
    static let description = IntentDescription("Expand hidden menu bar items.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.expandMenuBarItems())
    }
}

struct CollapseMenuBarItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Collapse Menu Bar Items"
    static let description = IntentDescription("Collapse hidden menu bar items.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.collapseMenuBarItems())
    }
}

struct RevealAllMenuBarItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Reveal All Menu Bar Items"
    static let description = IntentDescription("Reveal all menu bar items including always-hidden.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.revealAllMenuBarItems())
    }
}

struct ShowFindIconIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Find Icon"
    static let description = IntentDescription("Open Find Icon for discovered menu bar items.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.showFindIcon())
    }
}

struct ShowSecondBarIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Second Bar"
    static let description = IntentDescription("Show the Second Bar window.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.showSecondBar())
    }
}

struct HideSecondBarIntent: AppIntent {
    static let title: LocalizedStringResource = "Hide Second Bar"
    static let description = IntentDescription("Hide the Second Bar window.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.hideSecondBar())
    }
}

struct EnterFullMenuBarModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Enter Full Menu Bar Mode"
    static let description = IntentDescription("Enter Full Menu Bar Mode to temporarily reveal all items.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.enterFullMenuBarMode())
    }
}

struct ExitFullMenuBarModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Exit Full Menu Bar Mode"
    static let description = IntentDescription("Exit Full Menu Bar Mode.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.exitFullMenuBarMode())
    }
}

struct ApplyProfileIntent: AppIntent {
    static let title: LocalizedStringResource = "Apply Profile"
    static let description = IntentDescription("Apply a named profile.")

    @Parameter(title: "Profile Name")
    var profileName: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.applyProfile(name: profileName))
    }
}

struct OpenGroupPanelIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Group Panel"
    static let description = IntentDescription("Open a group panel by group ID.")

    @Parameter(title: "Group ID")
    var groupID: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService,
              let id = UUID(uuidString: groupID) else {
            return appIntentDialogResult(message: "Group ID is invalid.")
        }
        return appIntentDialogResult(for: service.openGroupPanel(id: id))
    }
}

struct RevealGroupIntent: AppIntent {
    static let title: LocalizedStringResource = "Reveal Group"
    static let description = IntentDescription("Reveal a group by group ID.")

    @Parameter(title: "Group ID")
    var groupID: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService,
              let id = UUID(uuidString: groupID) else {
            return appIntentDialogResult(message: "Group ID is invalid.")
        }
        return appIntentDialogResult(for: service.revealGroup(id: id))
    }
}

struct PauseAutomationIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Automation"
    static let description = IntentDescription("Pause all automation triggers.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.pauseAutomation())
    }
}

struct ResumeAutomationIntent: AppIntent {
    static let title: LocalizedStringResource = "Resume Automation"
    static let description = IntentDescription("Resume all automation triggers.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.resumeAutomation())
    }
}

struct PreviewLayoutSpacingPresetIntent: AppIntent {
    static let title: LocalizedStringResource = "Preview Layout Spacing Preset"
    static let description = IntentDescription("Preview a menu bar spacing preset without applying global defaults.")

    @Parameter(title: "Preset", description: "Spacing preset: system, compact, dense, or custom.")
    var preset: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let service = AppEnvironment.shared?.intentExecutionService else {
            return appIntentDialogResult(message: "MenuBarDeclutter is not ready.")
        }
        return appIntentDialogResult(for: service.previewLayoutSpacingPreset(preset))
    }
}

private func appIntentDialogResult(
    for result: AppIntentExecutionService.Result
) -> IntentResultContainer<Never, Never, Never, IntentDialog> {
    appIntentDialogResult(message: AppIntentResultMapper.message(for: result))
}

private func appIntentDialogResult(
    message: String
) -> IntentResultContainer<Never, Never, Never, IntentDialog> {
    .result(dialog: IntentDialog(stringLiteral: message))
}
