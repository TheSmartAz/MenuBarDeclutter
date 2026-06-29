import Foundation

/// A user-created icon group that organizes menu bar items.
nonisolated struct IconGroup: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var symbolName: String?
    var colorName: String?
    var notes: String?
    var isEnabled: Bool
    var isProtected: Bool
    var showInSecondBar: Bool
    var showAsStatusItem: Bool
    var sortOrder: Int
    var itemRefs: [IconGroupItemRef]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String? = nil,
        colorName: String? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        isProtected: Bool = false,
        showInSecondBar: Bool = true,
        showAsStatusItem: Bool = false,
        sortOrder: Int = 0,
        itemRefs: [IconGroupItemRef] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorName = colorName
        self.notes = notes
        self.isEnabled = isEnabled
        self.isProtected = isProtected
        self.showInSecondBar = showInSecondBar
        self.showAsStatusItem = showAsStatusItem
        self.sortOrder = sortOrder
        self.itemRefs = itemRefs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Count of item references in this group.
    var itemCount: Int { itemRefs.count }

    /// Whether this group has any items.
    var isEmpty: Bool { itemRefs.isEmpty }
}
