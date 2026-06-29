import Foundation

/// A hotkey binding that maps a key combination to a HotkeyAction.
nonisolated struct HotkeyBinding: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var action: HotkeyAction
    var keyCode: Int
    var modifiersRaw: UInt
    var isEnabled: Bool
    var label: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        action: HotkeyAction,
        keyCode: Int,
        modifiersRaw: UInt,
        isEnabled: Bool = true,
        label: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.action = action
        self.keyCode = keyCode
        self.modifiersRaw = modifiersRaw
        self.isEnabled = isEnabled
        self.label = label.isEmpty ? action.displayLabel : label
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Whether two bindings conflict (same key + modifiers).
    func conflicts(with other: HotkeyBinding) -> Bool {
        keyCode == other.keyCode && modifiersRaw == other.modifiersRaw
    }
}
