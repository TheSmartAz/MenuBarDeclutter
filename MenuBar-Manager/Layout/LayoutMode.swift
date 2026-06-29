import Foundation

/// High-level layout mode introduced in Phase 10.
///
/// Describes the current layout surface state used by the
/// ``LayoutCoordinator`` and Settings UI.
nonisolated enum LayoutMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case normal
    case fullMenuBar
    case crowdedRescue
    case configuration

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal:
            "Normal"
        case .fullMenuBar:
            "Full Menu Bar"
        case .crowdedRescue:
            "Crowded Rescue"
        case .configuration:
            "Configuration"
        }
    }
}
