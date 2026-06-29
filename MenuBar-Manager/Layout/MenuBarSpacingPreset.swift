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

/// Result of a spacing apply/restore/reset operation.
nonisolated struct MenuBarSpacingApplyResult: Equatable, Sendable {
    let success: Bool
    let isDryRun: Bool
    let message: String
    let preset: MenuBarSpacingPreset
}
