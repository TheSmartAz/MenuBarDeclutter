import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Privacy Pro Setup Actions")
@MainActor
struct PrivacyProSetupActionsTests {
    @Test func enableProModeDoesNotEnableDiscoveryOrPrompt() {
        let suiteName = "PrivacyProSetupActionsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        var trustChecks = 0
        var promptChecks = 0
        let permissionService = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: {
                trustChecks += 1
                return false
            },
            promptTrustProvider: {
                promptChecks += 1
                return false
            },
            systemSettingsOpener: { true },
            statusCacheDuration: 0
        )
        trustChecks = 0

        PrivacyProSetupActions.enableProMode(
            settingsStore: store,
            permissionService: permissionService
        )

        #expect(store.proModeEnabled)
        #expect(!store.accessibilityDiscoveryEnabled)
        #expect(!store.secondBarPrimaryClickEnabled)
        #expect(trustChecks == 1)
        #expect(promptChecks == 0)
    }

    @Test func disableProModeAlsoDisablesDiscovery() {
        let suiteName = "PrivacyProSetupActionsTests.disable.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        store.secondBarPrimaryClickEnabled = true

        PrivacyProSetupActions.disableProMode(settingsStore: store)

        #expect(!store.proModeEnabled)
        #expect(!store.accessibilityDiscoveryEnabled)
        #expect(!store.secondBarPrimaryClickEnabled)
    }

    @Test func grantedAccessibilityPermissionDoesNotSilentlyEnablePrivateAccessFeatures() {
        let suiteName = "PrivacyProSetupActionsTests.granted.\(UUID().uuidString)"
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
        #expect(!store.secondBarPrimaryClickEnabled)
    }
}
