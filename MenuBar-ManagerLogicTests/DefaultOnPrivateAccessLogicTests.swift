import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Default-On Private Access Logic")
@MainActor
struct DefaultOnPrivateAccessLogicTests {
    @Test func findIconAndSecondBarDefaultOnFlagsStartEnabled() {
        let suiteName = "logic-defaults-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(store.searchEnabled)
        #expect(store.secondBarEnabled)
        #expect(!store.proModeEnabled)
        #expect(!store.accessibilityDiscoveryEnabled)
    }

    @Test func grantedAccessibilityDoesNotSilentlyEnablePrivateAccessFlags() {
        let suiteName = "logic-accessibility-granted-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = false
        store.accessibilityDiscoveryEnabled = false
        store.searchEnabled = false
        store.secondBarEnabled = false

        let permissionService = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: DiagnosticsLogger(),
            trustProvider: { true },
            promptTrustProvider: { true },
            systemSettingsOpener: { true },
            statusCacheDuration: 0
        )

        #expect(permissionService.status == .granted)
        #expect(!store.proModeEnabled)
        #expect(!store.accessibilityDiscoveryEnabled)
        #expect(!store.searchEnabled)
        #expect(!store.secondBarEnabled)
    }

    @Test func appShortcutFindIconStatusIgnoresLegacySearchFlag() {
        let action = AutomationShortcutAction.showFindIcon

        #expect(action.status(
            appIntentsEnabled: true,
            proModeEnabled: true,
            accessibilityDiscoveryEnabled: true,
            canApplyProfiles: false,
            canAccessLabs: false,
            spacingLabsEnabled: false
        ) == .ready)
    }
}
