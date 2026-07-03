import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("ProtectedActionGate")
@MainActor
struct ProtectedActionGateTests {
    @Test func authSuccessExecutesAction() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectIconMoving = true

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .success

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let gate = ProtectedActionGate(coordinator: coordinator)

        var actionExecuted = false
        let result = await gate.execute(resource: .iconMoving, reason: "Test") {
            actionExecuted = true
        }

        #expect(result)
        #expect(actionExecuted)
    }

    @Test func authCancelBlocksAction() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectIconMoving = true

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .cancel

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let gate = ProtectedActionGate(coordinator: coordinator)

        var actionExecuted = false
        let result = await gate.execute(resource: .iconMoving, reason: "Test") {
            actionExecuted = true
        }

        #expect(!result)
        #expect(!actionExecuted)
    }

    @Test func authFailureBlocksAction() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectIconMoving = true

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .failure("Biometric error")

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let gate = ProtectedActionGate(coordinator: coordinator)

        var actionExecuted = false
        let result = await gate.execute(resource: .iconMoving, reason: "Test") {
            actionExecuted = true
        }

        #expect(!result)
        #expect(!actionExecuted)
    }

    @Test func unlockedSessionSkipsAuth() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectIconMoving = true

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .success

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let gate = ProtectedActionGate(coordinator: coordinator)

        // First action authenticates
        var firstAction = false
        _ = await gate.execute(resource: .iconMoving, reason: "Test") {
            firstAction = true
        }
        #expect(firstAction)
        // Auth was called for the first action
        #expect(store.privateAccessLastAuthStatus == "success")

        // Second action should use cached session; the action should execute.
        var secondAction = false
        _ = await gate.execute(resource: .iconMoving, reason: "Test") {
            secondAction = true
        }
        #expect(secondAction)
    }

    @Test func unprotectedResourceDoesNotPrompt() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectIconMoving = false // Not protected

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .cancel // Should not be called

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let gate = ProtectedActionGate(coordinator: coordinator)

        var actionExecuted = false
        let result = await gate.execute(resource: .iconMoving, reason: "Test") {
            actionExecuted = true
        }

        #expect(result)
        #expect(actionExecuted)
    }

    @Test func disabledPrivateAccessDoesNotPrompt() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = false

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .cancel

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let gate = ProtectedActionGate(coordinator: coordinator)

        var actionExecuted = false
        let result = await gate.execute(resource: .iconMoving, reason: "Test") {
            actionExecuted = true
        }

        #expect(result)
        #expect(actionExecuted)
    }

    @Test func profileApplyAndAutomationResourcesHonorOptInProtection() {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectProfileApply = true
        store.privateAccessProtectAutomationCommands = true

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )
        let gate = ProtectedActionGate(coordinator: coordinator)

        #expect(!gate.canAccessWithoutPrompt(.profileApply))
        #expect(!gate.canAccessWithoutPrompt(.appIntent("expand")))

        store.privateAccessProtectProfileApply = false
        store.privateAccessProtectAutomationCommands = false

        #expect(gate.canAccessWithoutPrompt(.profileApply))
        #expect(gate.canAccessWithoutPrompt(.appIntent("expand")))
    }

    @Test func diagnosticsRedactProtectedGroupIdentifier() async throws {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.protectedGroupsRequireAuth = true

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .success

        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )
        let gate = ProtectedActionGate(coordinator: coordinator)
        let groupID = UUID()

        let result = await gate.execute(resource: .protectedGroup(groupID), reason: "Test") {}

        #expect(result)
        let event = try #require(logger.events.last)
        let eventText = ([event.message] + Array(event.metadata.values)).joined(separator: " ")
        #expect(event.metadata["resource"] == "protectedGroup")
        #expect(!eventText.contains(groupID.uuidString))
    }

    @Test func enablePrivateAccessAfterAuthenticationTurnsPolicyOnAndUnlocksSession() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = false

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .success
        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let result = await coordinator.enablePrivateAccessAfterAuthentication(reason: "Enable")

        #expect(result == .success)
        #expect(store.privateAccessEnabled)
        #expect(coordinator.isUnlocked)
        #expect(store.privateAccessLastAuthStatus == "success")
    }

    @Test func canceledEnablePrivateAccessAuthenticationLeavesPolicyOff() async {
        let suiteName = "pa-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = false

        let logger = DiagnosticsLogger()
        let mockAuth = MockAuthenticationService()
        mockAuth.result = .cancel
        let coordinator = PrivateAccessCoordinator(
            settingsStore: store,
            diagnosticsLogger: logger,
            authService: mockAuth
        )

        let result = await coordinator.enablePrivateAccessAfterAuthentication(reason: "Enable")

        #expect(result == .cancel)
        #expect(!store.privateAccessEnabled)
        #expect(!coordinator.isUnlocked)
        #expect(store.privateAccessLastAuthStatus == "cancel")
    }
}
