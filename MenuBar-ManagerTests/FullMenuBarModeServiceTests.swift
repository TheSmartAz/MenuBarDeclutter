import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("FullMenuBarModeService")
@MainActor
struct FullMenuBarModeServiceTests {
    @Test func enterSavesPreviousState() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "fmbm-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()
        var revealAllCalled = false
        var restoredState: HidingVisibilityState?

        let service = FullMenuBarModeService(
            diagnosticsLogger: logger,
            settingsStore: store,
            now: { Date(timeIntervalSince1970: 1000) },
            revealAll: { revealAllCalled = true },
            restoreVisibility: { state in restoredState = state },
            suspendAutoRehide: {},
            resumeAutoRehide: {},
            showSpacerMarkers: { _ in }
        )

        service.enter(previousVisibility: .collapsed)

        #expect(service.isActive)
        #expect(revealAllCalled)
        #expect(service.stateSnapshot?.previousVisibility == .collapsed)
    }

    @Test func exitRestoresPreviousState() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "fmbm-tests-\(UUID().uuidString)")!)
        store.fullMenuBarModeAutoExitEnabled = false
        let logger = DiagnosticsLogger()
        var restoredState: HidingVisibilityState?

        let service = FullMenuBarModeService(
            diagnosticsLogger: logger,
            settingsStore: store,
            revealAll: {},
            restoreVisibility: { state in restoredState = state },
            suspendAutoRehide: {},
            resumeAutoRehide: {},
            showSpacerMarkers: { _ in }
        )

        service.enter(previousVisibility: .expanded)
        service.exit()

        #expect(!service.isActive)
        #expect(restoredState == .expanded)
        #expect(service.lastExitReason == .manual)
    }

    @Test func userStateChangedPreventsRestore() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "fmbm-tests-\(UUID().uuidString)")!)
        store.fullMenuBarModeAutoExitEnabled = false
        let logger = DiagnosticsLogger()
        var restoredState: HidingVisibilityState?

        let service = FullMenuBarModeService(
            diagnosticsLogger: logger,
            settingsStore: store,
            revealAll: {},
            restoreVisibility: { state in restoredState = state },
            suspendAutoRehide: {},
            resumeAutoRehide: {},
            showSpacerMarkers: { _ in }
        )

        service.enter(previousVisibility: .collapsed)
        service.noteUserStateChanged()
        service.exit()

        #expect(restoredState == nil)
    }

    @Test func disabledInSettingsDoesNotEnter() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "fmbm-tests-\(UUID().uuidString)")!)
        store.fullMenuBarModeEnabled = false
        let logger = DiagnosticsLogger()

        let service = FullMenuBarModeService(
            diagnosticsLogger: logger,
            settingsStore: store,
            revealAll: {},
            restoreVisibility: { _ in },
            suspendAutoRehide: {},
            resumeAutoRehide: {},
            showSpacerMarkers: { _ in }
        )

        service.enter(previousVisibility: .collapsed)

        #expect(!service.isActive)
    }

    @Test func exitWithoutEnterIsNoop() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "fmbm-tests-\(UUID().uuidString)")!)
        let logger = DiagnosticsLogger()
        var restoreCalled = false

        let service = FullMenuBarModeService(
            diagnosticsLogger: logger,
            settingsStore: store,
            revealAll: {},
            restoreVisibility: { _ in restoreCalled = true },
            suspendAutoRehide: {},
            resumeAutoRehide: {},
            showSpacerMarkers: { _ in }
        )

        service.exit()

        #expect(!restoreCalled)
        #expect(!service.isActive)
    }
}
