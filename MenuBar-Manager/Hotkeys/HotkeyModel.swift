import AppKit
import Carbon
import Carbon.HIToolbox
import Foundation

/// Pure value type describing a global hotkey combination.
///
/// The model holds the raw virtual key code and Carbon modifier flags so the
/// recording/registering logic stays independent of Carbon's runtime types.
/// Pure formatting helpers here are unit-tested without an AppKit connection.
struct HotkeyModel: Equatable, Sendable, Hashable {
    /// Virtual key code (matches `kVK_*` constants from Carbon.HIToolbox).
    let keyCode: UInt32

    /// Carbon modifier flags as used by `RegisterEventHotKey`
    /// (built from `cmdKey`, `optionKey`, `shiftKey`, `controlKey`).
    let modifiersRaw: UInt32

    init(keyCode: UInt32, modifiersRaw: UInt32) {
        self.keyCode = keyCode
        self.modifiersRaw = modifiersRaw
    }

    /// App default hotkey: Option + Command + B.
    static let defaultHotkey = HotkeyModel(
        keyCode: AppConstants.defaultHotkeyCode,
        modifiersRaw: AppConstants.defaultHotkeyModifierFlags
    )

    private static let keyDisplayNamesByCode: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_Escape): "Esc",
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_F1): "F1",
        UInt32(kVK_F2): "F2",
        UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4",
        UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7",
        UInt32(kVK_F8): "F8",
        UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11",
        UInt32(kVK_F12): "F12"
    ]

    /// `true` when no modifiers are set. Rejecting empty modifiers prevents
    /// registering keys that would fire on every unmodified keypress.
    var hasNoModifiers: Bool { modifiersRaw == 0 }

    /// Carbon flags exposed individually for diagnostics/UI.
    var hasCommand: Bool { modifiersRaw & UInt32(cmdKey) != 0 }
    var hasOption: Bool { modifiersRaw & UInt32(optionKey) != 0 }
    var hasShift: Bool { modifiersRaw & UInt32(shiftKey) != 0 }
    var hasControl: Bool { modifiersRaw & UInt32(controlKey) != 0 }

    /// Localized display string used in Settings and Diagnostics. Order
    /// follows Apple's convention: Control, Option, Shift, Command, then key.
    var displayName: String {
        var parts: [String] = []
        if hasControl { parts.append("⌃") }
        if hasOption { parts.append("⌥") }
        if hasShift { parts.append("⇧") }
        if hasCommand { parts.append("⌘") }
        parts.append(keyDisplayName)
        return parts.joined()
    }

    /// Human-readable name for the virtual key code. Covers the keys most
    /// likely to be re-bound by users; anything unmapped falls back to a
    /// stable placeholder.
    var keyDisplayName: String {
        Self.keyDisplayNamesByCode[keyCode] ?? "Key\(keyCode)"
    }
}

extension HotkeyModel {
    /// Builds a `HotkeyModel` from an `NSEvent` (e.g., captured during the
    /// Settings hotkey recorder). Modifier flags are translated from AppKit's
    /// bit mask to the Carbon flag mask.
    init?(from event: NSEvent) {
        guard event.type == .keyDown || event.type == .keyUp else { return nil }
        let carbonModifiers = Self.carbonModifierFlags(from: event.modifierFlags)
        guard carbonModifiers != 0 else { return nil }
        self.keyCode = UInt32(event.keyCode)
        self.modifiersRaw = carbonModifiers
    }

    /// Translate AppKit's `NSEvent.modifierFlags` intersection into the Carbon
    /// flag bit mask used by `RegisterEventHotKey`. Helper exposed for tests.
    static func carbonModifierFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var raw: UInt32 = 0
        if flags.contains(.command) { raw |= UInt32(cmdKey) }
        if flags.contains(.option) { raw |= UInt32(optionKey) }
        if flags.contains(.shift) { raw |= UInt32(shiftKey) }
        if flags.contains(.control) { raw |= UInt32(controlKey) }
        return raw
    }
}
