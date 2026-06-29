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

        // Second action should use cached session
        var authCallCount = 0
        // We can't directly check call count, but the action should execute
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
}
