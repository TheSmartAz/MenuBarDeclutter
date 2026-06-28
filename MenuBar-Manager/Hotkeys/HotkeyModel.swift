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
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_ANSI_0): return "0"
        case UInt32(kVK_ANSI_1): return "1"
        case UInt32(kVK_ANSI_2): return "2"
        case UInt32(kVK_ANSI_3): return "3"
        case UInt32(kVK_ANSI_4): return "4"
        case UInt32(kVK_ANSI_5): return "5"
        case UInt32(kVK_ANSI_6): return "6"
        case UInt32(kVK_ANSI_7): return "7"
        case UInt32(kVK_ANSI_8): return "8"
        case UInt32(kVK_ANSI_9): return "9"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        case UInt32(kVK_F1): return "F1"
        case UInt32(kVK_F2): return "F2"
        case UInt32(kVK_F3): return "F3"
        case UInt32(kVK_F4): return "F4"
        case UInt32(kVK_F5): return "F5"
        case UInt32(kVK_F6): return "F6"
        case UInt32(kVK_F7): return "F7"
        case UInt32(kVK_F8): return "F8"
        case UInt32(kVK_F9): return "F9"
        case UInt32(kVK_F10): return "F10"
        case UInt32(kVK_F11): return "F11"
        case UInt32(kVK_F12): return "F12"
        default:
            return "Key\(keyCode)"
        }
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