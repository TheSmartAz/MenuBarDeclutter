import Foundation

nonisolated enum MenuBarCommandTarget: Equatable, Hashable, Sendable {
    case none
    case globalVisibility
    case menuBarItem(id: String)
    case group(UUID)
    case profileID(UUID)
    case profileName(String)
    case secondBar
    case iconPanel
    case fullMenuBarMode
    case layoutSuggestions
    case spacingPreset(String)
    case automation
    case protectedResource(ProtectedResource)

    var diagnosticKind: String {
        switch self {
        case .none:
            "none"
        case .globalVisibility:
            "globalVisibility"
        case .menuBarItem:
            "menuBarItem"
        case .group:
            "group"
        case .profileID, .profileName:
            "profile"
        case .secondBar:
            "secondBar"
        case .iconPanel:
            "iconPanel"
        case .fullMenuBarMode:
            "fullMenuBarMode"
        case .layoutSuggestions:
            "layoutSuggestions"
        case .spacingPreset:
            "spacingPreset"
        case .automation:
            "automation"
        case .protectedResource:
            "protectedResource"
        }
    }
}
