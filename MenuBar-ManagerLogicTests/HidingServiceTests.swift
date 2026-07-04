import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HidingService")
@MainActor
struct HidingServiceTests {
    @Test func defaultsToExpandedWhenStoreIsClean() {
        withHidingService { _, store, _, service in
            #expect(service.currentState == .expanded)
            #expect(store.isCollapsed == false)
        }
    }

    @Test func startsFromPersistedCollapsed() {
        withHidingService(configureDefaults: { defaults in
            defaults.set(true, forKey: "isCollapsed")
        }) { _, store, _, service in
            #expect(service.currentState == .collapsed)
            #expect(store.isCollapsed == true)
        }
    }

    @Test func collapseThenExpandTransitions() {
        withHidingService { _, store, _, service in
            var observedStates: [HidingState] = []
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
    }

    @Test func toggleFlipsStateAndPersists() {
        withHidingService { _, store, _, service in
            service.toggle()
            #expect(service.currentState == .collapsed)
            #expect(store.isCollapsed == true)

            service.toggle()
            #expect(service.currentState == .expanded)
            #expect(store.isCollapsed == false)
        }
    }

    @Test func reapplyDoesNotChangeStateButReposts() {
        withHidingService { _, _, logger, service in
            var calls = 0
            var visibilityCalls = 0
            let notifications = HidingNotificationProbe()
            service.onStateChange = { _ in calls += 1 }
            service.onVisibilityChange = { _ in visibilityCalls += 1 }
            NotificationCenter.default.addObserver(
                notifications,
                selector: #selector(HidingNotificationProbe.handleStateChange(_:)),
                name: HidingService.stateDidChangeNotification,
                object: service
            )
            NotificationCenter.default.addObserver(
                notifications,
                selector: #selector(HidingNotificationProbe.handleVisibilityChange(_:)),
                name: HidingService.visibilityDidChangeNotification,
                object: service
            )
            defer { NotificationCenter.default.removeObserver(notifications) }

            service.collapse()
            let callsAfterCollapse = calls
            let visibilityCallsAfterCollapse = visibilityCalls
            let stateNotificationsAfterCollapse = notifications.stateChangeCount
            let visibilityNotificationsAfterCollapse = notifications.visibilityChangeCount

            service.applyState()
            #expect(calls == callsAfterCollapse + 1)
            #expect(visibilityCalls == visibilityCallsAfterCollapse + 1)
            #expect(notifications.stateChangeCount == stateNotificationsAfterCollapse + 1)
            #expect(notifications.visibilityChangeCount == visibilityNotificationsAfterCollapse + 1)
            #expect(service.currentState == .collapsed)
            #expect(logger.events.last?.message == "Visibility state re-applied (collapsed).")
        }
    }

    @Test func noOpVisibilityTransitionDoesNotNotifyObservers() {
        withHidingService { _, _, logger, service in
            var stateCalls = 0
            var visibilityCalls = 0
            let notifications = HidingNotificationProbe()
            service.onStateChange = { _ in stateCalls += 1 }
            service.onVisibilityChange = { _ in visibilityCalls += 1 }
            NotificationCenter.default.addObserver(
                notifications,
                selector: #selector(HidingNotificationProbe.handleStateChange(_:)),
                name: HidingService.stateDidChangeNotification,
                object: service
            )
            NotificationCenter.default.addObserver(
                notifications,
                selector: #selector(HidingNotificationProbe.handleVisibilityChange(_:)),
                name: HidingService.visibilityDidChangeNotification,
                object: service
            )
            defer { NotificationCenter.default.removeObserver(notifications) }

            service.expand()

            #expect(service.visibilityState == .expanded)
            #expect(stateCalls == 0)
            #expect(visibilityCalls == 0)
            #expect(notifications.stateChangeCount == 0)
            #expect(notifications.visibilityChangeCount == 0)
            #expect(logger.events.isEmpty)
        }
    }

    @Test func reloadedStoreReflectsPersistedState() {
        withHidingService { defaults, _, logger, service in
            service.collapse()

            // Reconstruct store from the same backing defaults and assert it sees
            // the persisted `isCollapsed` flag.
            let reloaded = SettingsStore(defaults: defaults)
            let reloadedService = HidingService(settingsStore: reloaded, diagnosticsLogger: logger)

            #expect(reloadedService.currentState == .collapsed)
            #expect(reloaded.isCollapsed == true)
        }
    }

    // MARK: Phase 2 visibility state

    @Test func visibilityStateDefaultsToExpanded() {
        withHidingService { _, _, _, service in
            #expect(service.visibilityState == .expanded)
            #expect(service.currentState == .expanded)
        }
    }

    @Test func revealAllTransitions() {
        withHidingService { _, _, _, service in
            var observedVisibilities: [HidingVisibilityState] = []
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
    }

    @Test func setVisibilityPersistsCollapsed() {
        withHidingService { _, store, _, service in
            service.setVisibility(.revealAll)
            #expect(store.isCollapsed == false)

            service.setVisibility(.collapsed)
            #expect(store.isCollapsed == true)
        }
    }

    private func withHidingService(
        configureDefaults: (UserDefaults) -> Void = { _ in },
        _ body: (UserDefaults, SettingsStore, DiagnosticsLogger, HidingService) -> Void
    ) {
        let suiteName = "MenuBarDeclutterLogicTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        configureDefaults(defaults)
        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = HidingService(settingsStore: store, diagnosticsLogger: logger)
        body(defaults, store, logger, service)
    }
}

@MainActor
private final class HidingNotificationProbe: NSObject {
    private(set) var stateChangeCount = 0
    private(set) var visibilityChangeCount = 0

    @objc func handleStateChange(_ notification: Notification) {
        stateChangeCount += 1
    }

    @objc func handleVisibilityChange(_ notification: Notification) {
        visibilityChangeCount += 1
    }
}
