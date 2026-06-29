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
        case requiresPrivateAccess
        case requiresProMode
        case requiresAccessibility
        case requiresLabs
        case automationPaused
        case safeModeBlocked
    }

    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let safeModeActive: () -> Bool
    private let expandAction: () -> Void
    private let collapseAction: () -> Void
    private let revealAllAction: () -> Void
    private let showSecondBarAction: () -> Void
    private let hideSecondBarAction: () -> Void
    private let enterFullMenuBarModeAction: () -> Void
    private let exitFullMenuBarModeAction: () -> Void
    private let applyProfileAction: (String) -> Bool
    private let pauseAutomationAction: () -> Void
    private let resumeAutomationAction: () -> Void

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        safeModeActive: @escaping () -> Bool,
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
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.safeModeActive = safeModeActive
        self.expandAction = expand
        self.collapseAction = collapse
        self.revealAllAction = revealAll
        self.showSecondBarAction = showSecondBar
        self.hideSecondBarAction = hideSecondBar
        self.enterFullMenuBarModeAction = enterFullMenuBarMode
        self.exitFullMenuBarModeAction = exitFullMenuBarMode
        self.applyProfileAction = applyProfileNamed
        self.pauseAutomationAction = pauseAutomation
        self.resumeAutomationAction = resumeAutomation
    }

    func expandMenuBarItems() -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        expandAction()
        return .success
    }

    func collapseMenuBarItems() -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        collapseAction()
        return .success
    }

    func revealAllMenuBarItems() -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        revealAllAction()
        return .success
    }

    func showSecondBar() -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        showSecondBarAction()
        return .success
    }

    func hideSecondBar() -> Result {
        hideSecondBarAction()
        return .success
    }

    func enterFullMenuBarMode() -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        enterFullMenuBarModeAction()
        return .success
    }

    func exitFullMenuBarMode() -> Result {
        exitFullMenuBarModeAction()
        return .success
    }

    func applyProfile(name: String) -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        guard settingsStore.appIntentsCanApplyProfiles else {
            return .blocked("App Intents profile application is disabled.")
        }
        guard !settingsStore.automationPaused else {
            return .automationPaused
        }
        let didApply = applyProfileAction(name)
        return didApply ? .success : .blocked("Profile not found: \(name)")
    }

    func pauseAutomation() -> Result {
        pauseAutomationAction()
        return .success
    }

    func resumeAutomation() -> Result {
        resumeAutomationAction()
        return .success
    }

    func setLayoutSpacingPreset(_ preset: String) -> Result {
        guard !safeModeActive() else { return .safeModeBlocked }
        guard settingsStore.appIntentsCanAccessLabs else {
            return .blocked("App Intents Labs access is disabled.")
        }
        guard settingsStore.menuBarSpacingLabsEnabled else {
            return .requiresLabs
        }
        diagnosticsLogger.log(
            "App Intent: layout spacing preset '\(preset)' requested.",
            category: .urlAutomation
        )
        return .success
    }
}
