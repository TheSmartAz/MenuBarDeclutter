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

    @Test func keyDisplayNameCoversKnownKeyCodes() {
        let expectedNames: [(UInt32, String)] = [
            (UInt32(kVK_ANSI_A), "A"),
            (UInt32(kVK_ANSI_B), "B"),
            (UInt32(kVK_ANSI_C), "C"),
            (UInt32(kVK_ANSI_D), "D"),
            (UInt32(kVK_ANSI_E), "E"),
            (UInt32(kVK_ANSI_F), "F"),
            (UInt32(kVK_ANSI_G), "G"),
            (UInt32(kVK_ANSI_H), "H"),
            (UInt32(kVK_ANSI_I), "I"),
            (UInt32(kVK_ANSI_J), "J"),
            (UInt32(kVK_ANSI_K), "K"),
            (UInt32(kVK_ANSI_L), "L"),
            (UInt32(kVK_ANSI_M), "M"),
            (UInt32(kVK_ANSI_N), "N"),
            (UInt32(kVK_ANSI_O), "O"),
            (UInt32(kVK_ANSI_P), "P"),
            (UInt32(kVK_ANSI_Q), "Q"),
            (UInt32(kVK_ANSI_R), "R"),
            (UInt32(kVK_ANSI_S), "S"),
            (UInt32(kVK_ANSI_T), "T"),
            (UInt32(kVK_ANSI_U), "U"),
            (UInt32(kVK_ANSI_V), "V"),
            (UInt32(kVK_ANSI_W), "W"),
            (UInt32(kVK_ANSI_X), "X"),
            (UInt32(kVK_ANSI_Y), "Y"),
            (UInt32(kVK_ANSI_Z), "Z"),
            (UInt32(kVK_ANSI_0), "0"),
            (UInt32(kVK_ANSI_1), "1"),
            (UInt32(kVK_ANSI_2), "2"),
            (UInt32(kVK_ANSI_3), "3"),
            (UInt32(kVK_ANSI_4), "4"),
            (UInt32(kVK_ANSI_5), "5"),
            (UInt32(kVK_ANSI_6), "6"),
            (UInt32(kVK_ANSI_7), "7"),
            (UInt32(kVK_ANSI_8), "8"),
            (UInt32(kVK_ANSI_9), "9"),
            (UInt32(kVK_Space), "Space"),
            (UInt32(kVK_Return), "Return"),
            (UInt32(kVK_Tab), "Tab"),
            (UInt32(kVK_Delete), "Delete"),
            (UInt32(kVK_Escape), "Esc"),
            (UInt32(kVK_LeftArrow), "←"),
            (UInt32(kVK_RightArrow), "→"),
            (UInt32(kVK_UpArrow), "↑"),
            (UInt32(kVK_DownArrow), "↓"),
            (UInt32(kVK_F1), "F1"),
            (UInt32(kVK_F2), "F2"),
            (UInt32(kVK_F3), "F3"),
            (UInt32(kVK_F4), "F4"),
            (UInt32(kVK_F5), "F5"),
            (UInt32(kVK_F6), "F6"),
            (UInt32(kVK_F7), "F7"),
            (UInt32(kVK_F8), "F8"),
            (UInt32(kVK_F9), "F9"),
            (UInt32(kVK_F10), "F10"),
            (UInt32(kVK_F11), "F11"),
            (UInt32(kVK_F12), "F12")
        ]

        for (keyCode, expectedName) in expectedNames {
            let model = HotkeyModel(keyCode: keyCode, modifiersRaw: UInt32(cmdKey))
            #expect(model.keyDisplayName == expectedName)
        }
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
