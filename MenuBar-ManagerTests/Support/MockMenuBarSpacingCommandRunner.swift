import Foundation
@testable import MenuBarDeclutter

/// Mock command runner for tests. Does not touch real defaults.
final class MockMenuBarSpacingCommandRunner: MenuBarSpacingCommandRunner, @unchecked Sendable {
    private var storage: [String: Int] = [:]
    private(set) var writeCallCount = 0
    private(set) var deleteCallCount = 0
    var shouldFailWrites = false

    func readItemSpacing() -> Int? { storage[MenuBarSpacingDefaultsKeys.itemSpacing] }
    func readSelectionPadding() -> Int? { storage[MenuBarSpacingDefaultsKeys.selectionPadding] }

    func writeItemSpacing(_ value: Int) -> Bool {
        writeCallCount += 1
        guard !shouldFailWrites else { return false }
        storage[MenuBarSpacingDefaultsKeys.itemSpacing] = value
        return true
    }

    func writeSelectionPadding(_ value: Int) -> Bool {
        writeCallCount += 1
        guard !shouldFailWrites else { return false }
        storage[MenuBarSpacingDefaultsKeys.selectionPadding] = value
        return true
    }

    func deleteItemSpacing() -> Bool {
        deleteCallCount += 1
        guard !shouldFailWrites else { return false }
        storage.removeValue(forKey: MenuBarSpacingDefaultsKeys.itemSpacing)
        return true
    }

    func deleteSelectionPadding() -> Bool {
        deleteCallCount += 1
        guard !shouldFailWrites else { return false }
        storage.removeValue(forKey: MenuBarSpacingDefaultsKeys.selectionPadding)
        return true
    }
}
