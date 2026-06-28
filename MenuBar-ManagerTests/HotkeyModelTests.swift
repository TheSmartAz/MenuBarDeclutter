import AppKit
import Carbon
import Carbon.HIToolbox
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HotkeyModel")
@MainActor
struct HotkeyModelTests {
    @Test func defaultHotkey() {
        let model = HotkeyModel.defaultHotkey
        #expect(model.keyCode == AppConstants.defaultHotkeyCode)
        #expect(model.modifiersRaw == AppConstants.defaultHotkeyModifierFlags)
        #expect(model.hasCommand)
        #expect(model.hasOption)
        #expect(!model.hasShift)
        #expect(!model.hasControl)
        #expect(!model.hasNoModifiers)
    }

    @Test func displayNameIncludesModifiers() {
        let model = HotkeyModel(
            keyCode: UInt32(kVK_ANSI_B),
            modifiersRaw: UInt32(cmdKey | optionKey)
        )
        #expect(model.displayName.contains("⌘"))
        #expect(model.displayName.contains("⌥"))
        #expect(model.displayName.contains("B"))
        // Order: Control, Option, Shift, Command, then key.
        // ⌥ should appear before ⌘ in the string.
        let optionIndex = model.displayName.firstIndex(of: "⌥")
        let commandIndex = model.displayName.firstIndex(of: "⌘")
        #expect(optionIndex != nil)
        #expect(commandIndex != nil)
        #expect(optionIndex! < commandIndex!)
    }

    @Test func carbonModifierFlagsTranslation() {
        var flags: NSEvent.ModifierFlags = []
        flags.insert(.command)
        flags.insert(.option)
        let carbon = HotkeyModel.carbonModifierFlags(from: flags)
        #expect(carbon == UInt32(cmdKey | optionKey))

        flags = []
        flags.insert(.control)
        flags.insert(.shift)
        #expect(HotkeyModel.carbonModifierFlags(from: flags) == UInt32(controlKey | shiftKey))
    }

    @Test func emptyModifiersRejectedInEventInit() {
        let flags: NSEvent.ModifierFlags = []
        // Craft a minimal fake keyDown event with no modifiers.
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: flags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "b",
            charactersIgnoringModifiers: "b",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_B)
        ) else {
            Issue.record("Failed to synthesize NSEvent")
            return
        }
        #expect(HotkeyModel(from: event) == nil)
    }

    @Test func keyNameFallback() {
        let model = HotkeyModel(keyCode: 999, modifiersRaw: UInt32(cmdKey))
        #expect(model.keyDisplayName == "Key999")
    }

    @Test func restoreDefaultsMatchesDefault() {
        let suiteName = "HotkeyModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.resetGlobalHotkeyToDefault()

        let reloaded = SettingsStore(defaults: defaults)
        let restored = reloaded.effectiveGlobalHotkey()

        #expect(restored.keyCode == AppConstants.defaultHotkeyCode)
        #expect(restored.modifiersRaw == AppConstants.defaultHotkeyModifierFlags)
        #expect(store.effectiveGlobalHotkey() == HotkeyModel.defaultHotkey)
    }

    @Test func setGlobalHotkeyClearsWhenNil() {
        let suiteName = "HotkeyModelTests.clear.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.setGlobalHotkey(HotkeyModel(keyCode: UInt32(kVK_ANSI_H), modifiersRaw: UInt32(cmdKey | shiftKey)))
        #expect(store.effectiveGlobalHotkey().keyCode == UInt32(kVK_ANSI_H))

        store.setGlobalHotkey(nil)
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.effectiveGlobalHotkey() == HotkeyModel.defaultHotkey)
    }

    @Test func searchHotkeyDefaultsToOptionCommandFAndIsDisabled() {
        let suiteName = "HotkeyModelTests.search.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let hotkey = store.effectiveSearchHotkey()

        #expect(!store.searchHotkeyEnabled)
        #expect(hotkey.keyCode == AppConstants.defaultSearchHotkeyCode)
        #expect(hotkey.modifiersRaw == AppConstants.defaultSearchHotkeyModifierFlags)
        #expect(hotkey.displayName == "⌥⌘F")
    }
}
