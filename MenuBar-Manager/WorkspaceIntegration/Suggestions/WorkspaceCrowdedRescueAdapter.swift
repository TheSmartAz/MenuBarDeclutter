import Foundation

nonisolated enum CrowdedRescueWorkspaceFallbackPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case preferSecondBar
    case preferFunctionBar
    case askEveryTime
    case preferInlineOnly
    case preferFullMenuBarMode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preferSecondBar: "Prefer Second Bar"
        case .preferFunctionBar: "Prefer Function Bar"
        case .askEveryTime: "Ask Every Time"
        case .preferInlineOnly: "Inline Only"
        case .preferFullMenuBarMode: "Prefer Full Menu Bar"
        }
    }
}

nonisolated struct WorkspaceCrowdedRescueContext: Equatable, Sendable {
    var functionBarPreviewEnabled: Bool
    var activeWorkspaceExists: Bool
    var activeWorkspaceItemCount: Int
    var functionBarControllerAvailable: Bool
    var safeModeActive: Bool
    var preference: CrowdedRescueWorkspaceFallbackPreference
}
