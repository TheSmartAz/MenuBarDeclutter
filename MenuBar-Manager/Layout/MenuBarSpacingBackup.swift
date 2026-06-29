import Foundation

/// Backup of the system's original spacing values before applying a preset.
nonisolated struct MenuBarSpacingBackup: Codable, Equatable, Sendable {
    let itemSpacing: Int?
    let selectionPadding: Int?
    let createdAt: Date

    init(itemSpacing: Int?, selectionPadding: Int?, createdAt: Date = Date()) {
        self.itemSpacing = itemSpacing
        self.selectionPadding = selectionPadding
        self.createdAt = createdAt
    }
}
