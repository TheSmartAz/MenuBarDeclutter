import Foundation

enum MenuBarItemCollectionFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case recent
    case favorites
    case visible
    case hidden
    case alwaysHidden

    var id: String { rawValue }

    static let searchFilters: [MenuBarItemCollectionFilter] = [
        .all,
        .recent,
        .favorites,
        .visible,
        .hidden,
        .alwaysHidden
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
        case .visible:
            "Visible"
        case .hidden:
            "Hidden"
        case .alwaysHidden:
            "Always Hidden"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .alwaysHidden:
            "Always"
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
        case .visible:
            "eye"
        case .hidden:
            "eye.slash"
        case .alwaysHidden:
            "lock"
        }
    }

    func includes(
        _ snapshot: MenuBarItemSnapshot,
        memoryStore: MenuBarItemMemoryStore?
    ) -> Bool {
        switch self {
        case .all:
            true
        case .recent:
            memoryStore?.isRecent(snapshot) == true
        case .favorites:
            memoryStore?.isFavorite(snapshot) == true
        case .visible:
            snapshot.zone == .visible
        case .hidden:
            snapshot.zone == .hidden
        case .alwaysHidden:
            snapshot.zone == .alwaysHidden
        }
    }
}
