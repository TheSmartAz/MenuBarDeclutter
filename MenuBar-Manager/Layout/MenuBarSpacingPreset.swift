import Foundation

/// Presets for the experimental Menu Bar Spacing Manager.
nonisolated enum MenuBarSpacingPreset: String, CaseIterable, Identifiable, Sendable {
    case system
    case compact
    case dense
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System Default"
        case .compact: "Compact"
        case .dense: "Dense"
        case .custom: "Custom"
        }
    }

    var itemSpacing: Int? {
        switch self {
        case .system: nil
        case .compact: 8
        case .dense: 4
        case .custom: nil
        }
    }

    var selectionPadding: Int? {
        switch self {
        case .system: nil
        case .compact: 6
        case .dense: 4
        case .custom: nil
        }
    }
}

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

/// Result of a spacing apply/restore/reset operation.
nonisolated struct MenuBarSpacingApplyResult: Equatable, Sendable {
    let success: Bool
    let isDryRun: Bool
    let message: String
    let preset: MenuBarSpacingPreset
}
