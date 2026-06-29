import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("DynamicHotkeyRegistrationService")
@MainActor
struct DynamicHotkeyRegistrationServiceTests {
    @Test func registersEnabledNonConflictingBindings() {
        let harness = Harness()
        harness.store.dynamicHotkeysEnabled = true
        harness.bindingStore.add(binding: HotkeyBinding(action: .enterFullMenuBarMode, keyCode: 37, modifiersRaw: 0x0900))
        harness.bindingStore.add(binding: HotkeyBinding(action: .exitFullMenuBarMode, keyCode: 4, modifiersRaw: 0x0900))

        harness.service.refreshRegistrations()

        #expect(harness.service.lastSnapshot.attemptedCount == 2)
        #expect(harness.service.lastSnapshot.registeredCount == 2)
        #expect(harness.manager.registered.count == 2)
    }

    @Test func skipsConflictingBindings() {
        let harness = Harness()
        harness.store.dynamicHotkeysEnabled = true
        harness.bindingStore.add(binding: HotkeyBinding(action: .enterFullMenuBarMode, keyCode: 37, modifiersRaw: 0x0900))
        harness.bindingStore.add(binding: HotkeyBinding(action: .exitFullMenuBarMode, keyCode: 37, modifiersRaw: 0x0900))

        harness.service.refreshRegistrations()

        #expect(harness.service.lastSnapshot.conflictCount == 2)
        #expect(harness.service.lastSnapshot.registeredCount == 0)
        #expect(harness.manager.registered.isEmpty)
    }

    @Test func disabledSettingUnregistersBindings() {
        let harness = Harness()
        harness.store.dynamicHotkeysEnabled = true
        let binding = harness.bindingStore.add(binding: HotkeyBinding(action: .enterFullMenuBarMode, keyCode: 37, modifiersRaw: 0x0900))
        harness.service.refreshRegistrations()

        harness.store.dynamicHotkeysEnabled = false
        harness.service.refreshRegistrations()

        #expect(harness.manager.unregistered.contains(.dynamic(binding.id)))
        #expect(harness.service.lastSnapshot.registeredCount == 0)
    }

    @Test func firedBindingRoutesThroughCommandResult() async {
        let harness = Harness()
        harness.store.dynamicHotkeysEnabled = true
        let binding = harness.bindingStore.add(binding: HotkeyBinding(action: .enterFullMenuBarMode, keyCode: 37, modifiersRaw: 0x0900))
        harness.service.refreshRegistrations()

        harness.manager.fire(identifier: .dynamic(binding.id))
        await Task.yield()
        await Task.yield()

        #expect(harness.routedActions == [.enterFullMenuBarMode])
    }

    private final class MockHotkeyManager: DynamicHotkeyManaging {
        var registered: [GlobalHotkeyManager.RegistrationIdentifier: HotkeyModel] = [:]
        var actions: [GlobalHotkeyManager.RegistrationIdentifier: () -> Void] = [:]
        var unregistered: [GlobalHotkeyManager.RegistrationIdentifier] = []

        func register(
            identifier: GlobalHotkeyManager.RegistrationIdentifier,
            hotkey: HotkeyModel?,
            action: @escaping () -> Void
        ) {
            if let hotkey {
                registered[identifier] = hotkey
                actions[identifier] = action
            } else {
                registered.removeValue(forKey: identifier)
                actions.removeValue(forKey: identifier)
            }
        }

        func unregister(identifier: GlobalHotkeyManager.RegistrationIdentifier) {
            registered.removeValue(forKey: identifier)
            actions.removeValue(forKey: identifier)
            unregistered.append(identifier)
        }

        func isRegistered(identifier: GlobalHotkeyManager.RegistrationIdentifier) -> Bool {
            registered[identifier] != nil
        }

        func fire(identifier: GlobalHotkeyManager.RegistrationIdentifier) {
            actions[identifier]?()
        }
    }

    private final class Harness {
        let store: SettingsStore
        let bindingStore: HotkeyBindingStore
        let manager = MockHotkeyManager()
        var routedActions: [HotkeyAction] = []

        lazy var service = DynamicHotkeyRegistrationService(
            settingsStore: store,
            bindingStore: bindingStore,
            hotkeyManager: manager,
            diagnosticsLogger: DiagnosticsLogger(),
            routeAction: { [self] action in
                routedActions.append(action)
                return MenuBarCommandResult(
                    status: .success,
                    message: "ok",
                    diagnosticReason: "success",
                    commandName: action.displayLabel,
                    targetKind: "test"
                )
            }
        )

        init() {
            let suiteName = "DynamicHotkeyRegistrationServiceTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)
            store = SettingsStore(defaults: defaults)
            let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            bindingStore = HotkeyBindingStore(directory: root, backupsDirectory: root.appendingPathComponent("Backups", isDirectory: true))
        }
    }
}
