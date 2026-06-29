import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("MenuBarCommandRouter")
@MainActor
struct MenuBarCommandRouterTests {
    @Test func expandRunsHandler() {
        let store = makeStore()
        let logger = DiagnosticsLogger()
        var didExpand = false
        var handlers = MenuBarCommandHandlers()
        handlers.expand = { didExpand = true }
        let router = MenuBarCommandRouter(
            settingsStore: store,
            diagnosticsLogger: logger,
            handlers: handlers
        )

        let result = router.route(MenuBarCommand(action: .expand, target: .globalVisibility))

        #expect(result.status == .success)
        #expect(didExpand)
        #expect(logger.events.last?.metadata["command"] == "expand")
        #expect(logger.events.last?.metadata["target"] == "globalVisibility")
    }

    @Test func safeModeBlocksSafeModeSensitiveCommands() {
        let store = makeStore()
        var didExpand = false
        var handlers = MenuBarCommandHandlers()
        handlers.expand = { didExpand = true }
        let router = MenuBarCommandRouter(
            settingsStore: store,
            safeModeActive: { true },
            handlers: handlers
        )

        let result = router.route(MenuBarCommand(action: .expand, target: .globalVisibility))

        #expect(result.status == .blocked)
        #expect(result.diagnosticReason == "safeMode")
        #expect(!didExpand)
    }

    @Test func secondBarRequiresProModeBeforeAccessibility() {
        let store = makeStore()
        store.accessibilityDiscoveryEnabled = true
        let router = MenuBarCommandRouter(
            settingsStore: store,
            accessibilityStatus: { .granted }
        )

        let result = router.route(MenuBarCommand(action: .showSecondBar, target: .secondBar))

        #expect(result.status == .requiresPro)
        #expect(result.diagnosticReason == "proModeDisabled")
    }

    @Test func secondBarRequiresAccessibilityPermissionWhenProGatesAreEnabled() {
        let store = makeStore()
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        let router = MenuBarCommandRouter(
            settingsStore: store,
            accessibilityStatus: { .denied }
        )

        let result = router.route(MenuBarCommand(action: .showSecondBar, target: .secondBar))

        #expect(result.status == .requiresPermission)
        #expect(result.diagnosticReason == "accessibilityPermissionMissing")
    }

    @Test func appIntentProfileApplyRespectsAutomationPause() {
        let store = makeStore()
        store.appIntentsCanApplyProfiles = true
        store.automationPaused = true
        var didApply = false
        var handlers = MenuBarCommandHandlers()
        handlers.applyProfileNamed = { _ in
            didApply = true
            return true
        }
        let router = MenuBarCommandRouter(settingsStore: store, handlers: handlers)

        let result = router.route(MenuBarCommand(
            action: .applyProfile,
            target: .profileName("Work"),
            source: .appIntent
        ))

        #expect(result.status == .blocked)
        #expect(result.diagnosticReason == "automationPaused")
        #expect(!didApply)
    }

    @Test func spacingPresetApplyIsDryRunOnlyWhenLabsAreEnabled() {
        let store = makeStore()
        store.automationPaused = false
        store.appIntentsCanAccessLabs = true
        store.menuBarSpacingLabsEnabled = true
        let router = MenuBarCommandRouter(settingsStore: store)

        let result = router.route(MenuBarCommand(
            action: .spacingPresetApply,
            target: .spacingPreset("compact"),
            source: .appIntent
        ))

        #expect(result.status == .dryRunOnly)
        #expect(result.diagnosticReason == "spacingApplyDeferred")
    }

    @Test func privateAccessLockReportsRequiresUnlockWithoutRunning() {
        let store = makeStore()
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        var didShow = false
        var handlers = MenuBarCommandHandlers()
        handlers.showSecondBar = { didShow = true }
        let router = MenuBarCommandRouter(
            settingsStore: store,
            accessibilityStatus: { .granted },
            privateAccess: PrivateAccessProbe(canAccess: false),
            handlers: handlers
        )

        let result = router.route(MenuBarCommand(action: .showSecondBar, target: .secondBar))

        #expect(result.status == .requiresUnlock)
        #expect(result.diagnosticReason == "privateAccessLocked")
        #expect(!didShow)
    }

    @Test func commandDiagnosticsRedactTargetValues() throws {
        let store = makeStore()
        store.automationPaused = false
        store.appIntentsCanApplyProfiles = true
        let logger = DiagnosticsLogger()
        var handlers = MenuBarCommandHandlers()
        handlers.applyProfileNamed = { _ in true }
        let router = MenuBarCommandRouter(
            settingsStore: store,
            diagnosticsLogger: logger,
            handlers: handlers
        )

        let result = router.route(MenuBarCommand(
            action: .applyProfile,
            target: .profileName("Secret Client Profile"),
            source: .appIntent
        ))

        #expect(result.status == .success)
        let event = try #require(logger.events.last)
        let metadataText = event.metadata.values.joined(separator: " ")
        #expect(!metadataText.contains("Secret Client Profile"))
        #expect(event.metadata["target"] == "profile")
    }

    @Test func availabilitySummaryRedactsTargetValues() {
        let command = MenuBarCommand(
            action: .applyProfile,
            target: .profileName("Secret Client Profile"),
            source: .settings
        )
        let availability = MenuBarCommandAvailability.unavailable(
            status: .requiresUnlock,
            message: "This command requires Private Access unlock.",
            diagnosticReason: "privateAccessLocked",
            failedGate: .privateAccess
        )

        let summary = MenuBarCommandAvailabilitySummary(
            command: command,
            availability: availability
        )

        let summaryText = [
            summary.title,
            summary.statusText,
            summary.detail,
            summary.failedGateText ?? "",
            summary.targetKind
        ].joined(separator: " ")
        #expect(summary.statusText == "Unlock Needed")
        #expect(summary.targetKind == "profile")
        #expect(!summaryText.contains("Secret Client Profile"))
    }

    private func makeStore() -> SettingsStore {
        let suiteName = "command-router-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = SettingsStore(defaults: defaults)
        store.automationPaused = false
        return store
    }
}

@MainActor
private final class PrivateAccessProbe: MenuBarCommandPrivateAccessChecking {
    private let canAccess: Bool

    init(canAccess: Bool) {
        self.canAccess = canAccess
    }

    func canAccessWithoutPrompt(_ resource: ProtectedResource) -> Bool {
        canAccess
    }
}
