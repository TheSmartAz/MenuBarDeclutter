import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("AppIntentExecutionService")
@MainActor
struct AppIntentExecutionServiceTests {
    private func makeService(
        safeMode: Bool = false,
        automationPaused: Bool = false,
        appIntentsCanApplyProfiles: Bool = false,
        appIntentsCanAccessLabs: Bool = false,
        menuBarSpacingLabsEnabled: Bool = false
    ) -> (AppIntentExecutionService, SettingsStore) {
        let suiteName = "intent-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.automationPaused = automationPaused
        store.appIntentsCanApplyProfiles = appIntentsCanApplyProfiles
        store.appIntentsCanAccessLabs = appIntentsCanAccessLabs
        store.menuBarSpacingLabsEnabled = menuBarSpacingLabsEnabled

        let logger = DiagnosticsLogger()
        var expandCalled = false
        var collapseCalled = false
        var revealAllCalled = false
        var showSecondBarCalled = false
        var hideSecondBarCalled = false
        var enterFullCalled = false
        var exitFullCalled = false
        var pauseCalled = false
        var resumeCalled = false

        let service = AppIntentExecutionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            safeModeActive: { safeMode },
            expand: { expandCalled = true },
            collapse: { collapseCalled = true },
            revealAll: { revealAllCalled = true },
            showSecondBar: { showSecondBarCalled = true },
            hideSecondBar: { hideSecondBarCalled = true },
            enterFullMenuBarMode: { enterFullCalled = true },
            exitFullMenuBarMode: { exitFullCalled = true },
            applyProfileNamed: { _ in true },
            pauseAutomation: { pauseCalled = true },
            resumeAutomation: { resumeCalled = true }
        )

        return (service, store)
    }

    @Test func expandSucceeds() {
        let (service, _) = makeService()
        let result = service.expandMenuBarItems()
        #expect(result == .success)
    }

    @Test func safeModeBlocksExpand() {
        let (service, _) = makeService(safeMode: true)
        let result = service.expandMenuBarItems()
        #expect(result == .safeModeBlocked)
    }

    @Test func applyProfileBlockedWhenDisabled() {
        let (service, _) = makeService(appIntentsCanApplyProfiles: false)
        let result = service.applyProfile(name: "Test")
        #expect(result == .blocked("App Intents profile application is disabled."))
    }

    @Test func applyProfileBlockedWhenPaused() {
        let (service, _) = makeService(automationPaused: true, appIntentsCanApplyProfiles: true)
        let result = service.applyProfile(name: "Test")
        #expect(result == .automationPaused)
    }

    @Test func applyProfileSucceedsWhenEnabled() {
        let (service, _) = makeService(automationPaused: false, appIntentsCanApplyProfiles: true)
        let result = service.applyProfile(name: "Test")
        #expect(result == .success)
    }

    @Test func spacingPresetRequiresLabs() {
        let (service, _) = makeService(appIntentsCanAccessLabs: true, menuBarSpacingLabsEnabled: false)
        let result = service.setLayoutSpacingPreset("compact")
        #expect(result == .requiresLabs)
    }

    @Test func spacingPresetBlockedWhenLabsAccessDisabled() {
        let (service, _) = makeService(appIntentsCanAccessLabs: false)
        let result = service.setLayoutSpacingPreset("compact")
        guard case .blocked = result else {
            Issue.record("expected .blocked but got \(result)")
            return
        }
        #expect(Bool(true))
    }

    @Test func pauseAutomationAlwaysSucceeds() {
        let (service, _) = makeService(safeMode: true)
        let result = service.pauseAutomation()
        #expect(result == .success)
    }

    @Test func resumeAutomationAlwaysSucceeds() {
        let (service, _) = makeService(safeMode: true)
        let result = service.resumeAutomation()
        #expect(result == .success)
    }

    @Test func shortcutActionStatusesReflectSettingsGates() throws {
        let basicAction = try #require(AutomationShortcutAction.allActions.first { $0.title == "Expand Menu Bar Items" })
        let profileAction = try #require(AutomationShortcutAction.allActions.first { $0.title == "Apply Profile" })
        let labsAction = try #require(AutomationShortcutAction.allActions.first { $0.title == "Set Layout Spacing Preset" })

        #expect(basicAction.status(
            appIntentsEnabled: true,
            canApplyProfiles: false,
            canAccessLabs: false,
            spacingLabsEnabled: false
        ) == .ready)
        #expect(profileAction.status(
            appIntentsEnabled: true,
            canApplyProfiles: false,
            canAccessLabs: false,
            spacingLabsEnabled: false
        ) == .profileGated)
        #expect(profileAction.status(
            appIntentsEnabled: true,
            canApplyProfiles: true,
            canAccessLabs: false,
            spacingLabsEnabled: false
        ) == .ready)
        #expect(labsAction.status(
            appIntentsEnabled: true,
            canApplyProfiles: false,
            canAccessLabs: false,
            spacingLabsEnabled: false
        ) == .labsGated)
        #expect(labsAction.status(
            appIntentsEnabled: true,
            canApplyProfiles: false,
            canAccessLabs: true,
            spacingLabsEnabled: false
        ) == .requiresLabs)
        #expect(labsAction.status(
            appIntentsEnabled: true,
            canApplyProfiles: false,
            canAccessLabs: true,
            spacingLabsEnabled: true
        ) == .ready)
        #expect(basicAction.status(
            appIntentsEnabled: false,
            canApplyProfiles: true,
            canAccessLabs: true,
            spacingLabsEnabled: true
        ) == .disabled)
    }
}
