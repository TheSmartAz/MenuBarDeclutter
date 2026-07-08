import Foundation

/// Protocol for reading/writing system defaults. Abstracted so tests
/// can inject a mock without touching real global defaults.
nonisolated protocol MenuBarSpacingCommandRunner: Sendable {
    /// Read the current item spacing value.
    func readItemSpacing() -> Int?
    /// Read the current selection padding value.
    func readSelectionPadding() -> Int?
    /// Write the item spacing value.
    func writeItemSpacing(_ value: Int) -> Bool
    /// Write the selection padding value.
    func writeSelectionPadding(_ value: Int) -> Bool
    /// Delete the item spacing value (reset to system default).
    func deleteItemSpacing() -> Bool
    /// Delete the selection padding value (reset to system default).
    func deleteSelectionPadding() -> Bool
}

/// Default command runner that uses `UserDefaults` standard defaults.
/// In a sandboxed app, writes may fail; the service handles this gracefully.
final class DefaultMenuBarSpacingCommandRunner: MenuBarSpacingCommandRunner, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func readItemSpacing() -> Int? {
        guard defaults.object(forKey: MenuBarSpacingDefaultsKeys.itemSpacing) != nil else { return nil }
        return defaults.integer(forKey: MenuBarSpacingDefaultsKeys.itemSpacing)
    }

    func readSelectionPadding() -> Int? {
        guard defaults.object(forKey: MenuBarSpacingDefaultsKeys.selectionPadding) != nil else { return nil }
        return defaults.integer(forKey: MenuBarSpacingDefaultsKeys.selectionPadding)
    }

    func writeItemSpacing(_ value: Int) -> Bool {
        defaults.set(value, forKey: MenuBarSpacingDefaultsKeys.itemSpacing)
        return true
    }

    func writeSelectionPadding(_ value: Int) -> Bool {
        defaults.set(value, forKey: MenuBarSpacingDefaultsKeys.selectionPadding)
        return true
    }

    func deleteItemSpacing() -> Bool {
        defaults.removeObject(forKey: MenuBarSpacingDefaultsKeys.itemSpacing)
        return true
    }

    func deleteSelectionPadding() -> Bool {
        defaults.removeObject(forKey: MenuBarSpacingDefaultsKeys.selectionPadding)
        return true
    }
}
