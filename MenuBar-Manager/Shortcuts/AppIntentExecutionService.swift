import AppKit
import Foundation

/// Execution service for App Intents. All intents run through this shared
/// service to ensure consistent policy enforcement (Safe Mode, pause,
/// Private Access, Pro/Labs requirements).
@MainActor
final class AppIntentExecutionService {
    enum Result: Equatable {
        case success
        case blocked(String)
        case dryRunOnly(String)
        case requiresPrivateAccess
        case requiresProMode
        case requiresAccessibility
        case requiresLabs
        case automationPaused
        case safeModeBlocked
    }

    private let commandRouter: MenuBarCommandRouter

    init(commandRouter: MenuBarCommandRouter) {
        self.commandRouter = commandRouter
    }

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        safeModeActive: @escaping () -> Bool,
        accessibilityStatus: @escaping () -> AccessibilityPermissionStatus = { .granted },
        privateAccess: (any MenuBarCommandPrivateAccessChecking)? = nil,
        expand: @escaping () -> Void,
        collapse: @escaping () -> Void,
        revealAll: @escaping () -> Void,
        showSecondBar: @escaping () -> Void,
        hideSecondBar: @escaping () -> Void,
        enterFullMenuBarMode: @escaping () -> Void,
        exitFullMenuBarMode: @escaping () -> Void,
        applyProfileNamed: @escaping (String) -> Bool,
        pauseAutomation: @escaping () -> Void,
        resumeAutomation: @escaping () -> Void
    ) {
        var handlers = MenuBarCommandHandlers()
        handlers.expand = expand
        handlers.collapse = collapse
        handlers.revealAll = revealAll
        handlers.showSecondBar = showSecondBar
        handlers.hideSecondBar = hideSecondBar
        handlers.enterFullMenuBarMode = enterFullMenuBarMode
        handlers.exitFullMenuBarMode = exitFullMenuBarMode
        handlers.applyProfileNamed = applyProfileNamed
        handlers.pauseAutomation = pauseAutomation
        handlers.resumeAutomation = resumeAutomation

        self.commandRouter = MenuBarCommandRouter(
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            safeModeActive: safeModeActive,
            accessibilityStatus: accessibilityStatus,
            privateAccess: privateAccess,
            handlers: handlers
        )
    }

    func expandMenuBarItems() -> Result {
        route(.expand, target: .globalVisibility)
    }

    func collapseMenuBarItems() -> Result {
        route(.collapse, target: .globalVisibility)
    }

    func revealAllMenuBarItems() -> Result {
        route(.revealAll, target: .globalVisibility)
    }

    func showSecondBar() -> Result {
        route(.showSecondBar, target: .secondBar)
    }

    func hideSecondBar() -> Result {
        route(.hideSecondBar, target: .secondBar)
    }

    func enterFullMenuBarMode() -> Result {
        route(.enterFullMenuBarMode, target: .fullMenuBarMode)
    }

    func exitFullMenuBarMode() -> Result {
        route(.exitFullMenuBarMode, target: .fullMenuBarMode)
    }

    func applyProfile(name: String) -> Result {
        route(.applyProfile, target: .profileName(name))
    }

    func pauseAutomation() -> Result {
        route(.pauseAutomation, target: .automation)
    }

    func resumeAutomation() -> Result {
        route(.resumeAutomation, target: .automation)
    }

    func setLayoutSpacingPreset(_ preset: String) -> Result {
        route(.spacingPresetApply, target: .spacingPreset(preset))
    }

    private func route(
        _ action: MenuBarCommandAction,
        target: MenuBarCommandTarget
    ) -> Result {
        let command = MenuBarCommand(
            action: action,
            target: target,
            source: .appIntent
        )
        return Self.map(commandRouter.route(command))
    }

    private static func map(_ result: MenuBarCommandResult) -> Result {
        switch result.status {
        case .success, .noOp:
            return .success
        case .dryRunOnly:
            return .dryRunOnly(result.message)
        case .requiresUnlock:
            return .requiresPrivateAccess
        case .requiresPro:
            return .requiresProMode
        case .requiresPermission:
            return .requiresAccessibility
        case .requiresLabs:
            return .requiresLabs
        case .blocked where result.diagnosticReason == "automationPaused":
            return .automationPaused
        case .blocked where result.diagnosticReason == "safeMode":
            return .safeModeBlocked
        case .blocked, .unavailable, .failed:
            return .blocked(result.message)
        }
    }
}
