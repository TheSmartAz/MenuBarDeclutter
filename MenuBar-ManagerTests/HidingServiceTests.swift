import Foundation
import Testing
@testable import MenuBar_Manager

@Suite("HidingService")
@MainActor
struct HidingServiceTests {
    @Test func defaultsToExpandedWhenStoreIsClean() {
        let suiteName = "HidingServiceTests.clean.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)

        #expect(service.currentState == .expanded)
        #expect(store.isCollapsed == false)
    }

    @Test func startsFromPersistedCollapsed() {
        let suiteName = "HidingServiceTests.persisted.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "isCollapsed")
        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)

        #expect(service.currentState == .collapsed)
        #expect(store.isCollapsed == true)
    }

    @Test func collapseThenExpandTransitions() {
        let suiteName = "HidingServiceTests.transitions.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()

        var observedStates: [HidingState] = []
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)
        service.onStateChange = { observedStates.append($0) }

        #expect(service.currentState == .expanded)

        service.collapse()
        #expect(service.currentState == .collapsed)
        #expect(store.isCollapsed == true)

        service.expand()
        #expect(service.currentState == .expanded)
        #expect(store.isCollapsed == false)

        #expect(observedStates == [.collapsed, .expanded])
    }

    @Test func toggleFlipsStateAndPersists() {
        let suiteName = "HidingServiceTests.toggle.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)

        service.toggle()
        #expect(service.currentState == .collapsed)
        #expect(store.isCollapsed == true)

        service.toggle()
        #expect(service.currentState == .expanded)
        #expect(store.isCollapsed == false)
    }

    @Test func reapplyDoesNotChangeStateButReposts() {
        let suiteName = "HidingServiceTests.reapply.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()

        var calls = 0
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)
        service.onStateChange = { _ in calls += 1 }

        service.collapse()
        let callsAfterCollapse = calls

        service.applyState()
        #expect(calls == callsAfterCollapse + 1)
        #expect(service.currentState == .collapsed)
    }

    @Test func reloadedStoreReflectsPersistedState() {
        let suiteName = "HidingServiceTests.persists.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)
        service.collapse()

        // Reconstruct store from the same backing defaults and assert it sees
        // the persisted `isCollapsed` flag.
        let reloaded = SettingsStore(defaults: defaults)
        let reloadedService = HidingService(settingsStore: reloaded, diagnosticsLogger: logger)

        #expect(reloadedService.currentState == .collapsed)
        #expect(reloaded.isCollapsed == true)
    }

    // MARK: Phase 2 visibility state

    @Test func visibilityStateDefaultsToExpanded() {
        let suiteName = "HidingServiceTests.visibility.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)

        #expect(service.visibilityState == .expanded)
        #expect(service.currentState == .expanded)
    }

    @Test func revealAllTransitions() {
        let suiteName = "HidingServiceTests.revealAll.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        var observedVisibilities: [HidingVisibilityState] = []
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)
        service.onVisibilityChange = { observedVisibilities.append($0) }

        service.revealAll()
        #expect(service.visibilityState == .revealAll)
        #expect(service.currentState == .expanded)
        #expect(observedVisibilities == [.revealAll])

        service.toggleRevealAll()
        #expect(service.visibilityState == .collapsed)

        // Option-toggle cycle from collapsed should land back on revealAll.
        service.toggleRevealAll()
        #expect(service.visibilityState == .revealAll)
    }

    @Test func setVisibilityPersistsCollapsed() {
        let suiteName = "HidingServiceTests.setVisibility.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)

        service.setVisibility(.revealAll)
        #expect(store.isCollapsed == false)

        service.setVisibility(.collapsed)
        #expect(store.isCollapsed == true)
    }
}