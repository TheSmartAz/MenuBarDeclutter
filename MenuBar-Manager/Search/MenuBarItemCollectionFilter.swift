import Foundation

enum MenuBarItemCollectionFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case recent
    case favorites
    case currentWorkspace
    case anyWorkspace
    case unassigned
    case usedInOtherWorkspace
    case groups
    case newItems
    case visible
    case hidden
    case alwaysHidden
    case stale

    var id: String { rawValue }

    static let searchFilters: [MenuBarItemCollectionFilter] = [
        .all,
        .recent,
        .favorites,
        .currentWorkspace,
        .anyWorkspace,
        .unassigned,
        .usedInOtherWorkspace,
        .newItems,
        .groups,
        .visible,
        .hidden,
        .alwaysHidden,
        .stale
    ]

    static let secondBarFilters: [MenuBarItemCollectionFilter] = [
        .all,
        .recent,
        .favorites,
        .hidden,
        .alwaysHidden
    ]

    var displayName: String {
        switch self {
        case .all:
            "All"
        case .recent:
            "Recent"
        case .favorites:
            "Favorites"
        case .currentWorkspace:
            "Current Workspace"
        case .anyWorkspace:
            "Any Workspace"
        case .unassigned:
            "Unassigned"
        case .usedInOtherWorkspace:
            "Other Workspace"
        case .groups:
            "Groups"
        case .newItems:
            "New Items"
        case .visible:
            "Visible"
        case .hidden:
            "Hidden"
        case .alwaysHidden:
            "Always Hidden"
        case .stale:
            "Stale"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .alwaysHidden:
            "Always"
        case .currentWorkspace:
            "Current"
        case .anyWorkspace:
            "Workspace"
        case .usedInOtherWorkspace:
            "Other"
        case .newItems:
            "New"
        default:
            displayName
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            "square.grid.2x2"
        case .recent:
            "clock"
        case .favorites:
            "star"
        case .currentWorkspace:
            "rectangle.3.group"
        case .anyWorkspace:
            "square.stack.3d.up"
        case .unassigned:
            "tray"
        case .usedInOtherWorkspace:
            "arrow.left.arrow.right"
        case .groups:
            "person.2"
        case .newItems:
            "sparkle"
        case .visible:
            "eye"
        case .hidden:
            "eye.slash"
        case .alwaysHidden:
            "lock"
        case .stale:
            "clock.badge.exclamationmark"
        }
    }

    func includes(
        _ snapshot: MenuBarItemSnapshot,
        memoryStore: MenuBarItemMemoryStore?,
        rankingContext: SearchRankingContext = .init()
    ) -> Bool {
        switch self {
        case .all:
            true
        case .recent:
            memoryStore?.isRecent(snapshot) == true
        case .favorites:
            memoryStore?.isFavorite(snapshot) == true
        case .currentWorkspace:
            rankingContext.workspaceUsage(for: snapshot).isUsedInActiveWorkspace
        case .anyWorkspace:
            !rankingContext.workspaceUsage(for: snapshot).workspaceIDs.isEmpty
        case .unassigned:
            rankingContext.workspaceUsage(for: snapshot).isUnassigned
        case .usedInOtherWorkspace:
            rankingContext.isUsedInOtherWorkspace(snapshot)
        case .groups:
            !rankingContext.workspaceUsage(for: snapshot).groupIDs.isEmpty
        case .newItems:
            rankingContext.isNewItem(snapshot)
        case .visible:
            snapshot.zone == .visible
        case .hidden:
            snapshot.zone == .hidden
        case .alwaysHidden:
            snapshot.zone == .alwaysHidden
        case .stale:
            rankingContext.isStale(snapshot)
        }
    }
}
