import Foundation

/// Type of spacer/divider item the user can create.
nonisolated enum SpacerItemType: String, CaseIterable, Identifiable, Codable, Sendable {
    case divider
    case thinSpacer
    case wideSpacer
    case label
    case icon
    case invisible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .divider:
            "Divider"
        case .thinSpacer:
            "Thin Spacer"
        case .wideSpacer:
            "Wide Spacer"
        case .label:
            "Label"
        case .icon:
            "Icon"
        case .invisible:
            "Invisible"
        }
    }

    var defaultLength: Double {
        switch self {
        case .divider:
            2
        case .thinSpacer:
            10
        case .wideSpacer:
            30
        case .label:
            20
        case .icon:
            24
        case .invisible:
            10
        }
    }

    var defaultSystemImageName: String? {
        switch self {
        case .divider:
            "line.vertical"
        case .icon:
            "circle"
        default:
            nil
        }
    }
}

/// Model for a user-created spacer/divider status item.
nonisolated struct SpacerItemModel: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var type: SpacerItemType
    var title: String
    var systemImageName: String?
    var length: Double
    var isVisible: Bool
    var showMarker: Bool
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        type: SpacerItemType,
        title: String = "",
        systemImageName: String? = nil,
        length: Double? = nil,
        isVisible: Bool = true,
        showMarker: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.systemImageName = systemImageName ?? type.defaultSystemImageName
        self.length = Self.clampLength(length ?? type.defaultLength)
        self.isVisible = isVisible
        self.showMarker = showMarker
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Minimum and maximum spacer length.
    static let minLength: Double = 1
    static let maxLength: Double = 200

    static func clampLength(_ value: Double) -> Double {
        if value.isNaN { return minLength }
        if value == .infinity { return maxLength }
        if value == -.infinity { return minLength }
        return min(max(value, minLength), maxLength)
    }
}
