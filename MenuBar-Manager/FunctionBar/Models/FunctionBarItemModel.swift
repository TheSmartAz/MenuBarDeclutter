import Foundation

nonisolated struct FunctionBarItemModel: Identifiable, Equatable, Sendable {
    var id: UUID
    var kind: FunctionBarItemKind
    var title: String
    var subtitle: String?
    var icon: FunctionBarIcon
    var status: FunctionBarItemStatus
    var availability: FunctionBarActionAvailability
    var badge: FunctionBarItemBadge?
}

nonisolated enum FunctionBarItemKind: Equatable, Sendable {
    case command(WorkspaceCommandReference)
    case menuBarItem(MenuBarItemReference)
    case group(WorkspaceGroupReference)
    case spacer
    case divider
    case infoTilePlaceholder
}

nonisolated enum FunctionBarProxyAction: String, CaseIterable, Identifiable, Equatable, Sendable {
    case reveal
    case highlight
    case showInSecondBar
    case openOwningApp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reveal: "Reveal"
        case .highlight: "Highlight"
        case .showInSecondBar: "Show in Second Bar"
        case .openOwningApp: "Open Owning App"
        }
    }

    var systemImage: String {
        switch self {
        case .reveal: "eye"
        case .highlight: "scope"
        case .showInSecondBar: "rectangle.bottomthird.inset.filled"
        case .openOwningApp: "app"
        }
    }

    var commandAction: MenuBarCommandAction {
        switch self {
        case .reveal: .revealItem
        case .highlight: .highlightItem
        case .showInSecondBar: .showItemInSecondBar
        case .openOwningApp: .openOwningApp
        }
    }
}

nonisolated struct FunctionBarIcon: Equatable, Sendable {
    var systemName: String
}

nonisolated enum FunctionBarItemStatus: String, Equatable, Sendable {
    case available
    case unavailable
    case missingReference
    case requiresPro
    case requiresAccessibility
    case stale
    case protected
    case previewOnly
    case deferred

    var displayText: String {
        switch self {
        case .available: "Available"
        case .unavailable: "Unavailable"
        case .missingReference: "Missing"
        case .requiresPro: "Requires Pro"
        case .requiresAccessibility: "Requires Accessibility"
        case .stale: "Stale"
        case .protected: "Protected"
        case .previewOnly: "Preview"
        case .deferred: "Deferred"
        }
    }
}

nonisolated struct FunctionBarItemBadge: Equatable, Sendable {
    var title: String
}

nonisolated struct FunctionBarActionAvailability: Equatable, Sendable {
    var isAvailable: Bool
    var reason: FunctionBarUnavailableReason?

    static let available = FunctionBarActionAvailability(isAvailable: true, reason: nil)

    static func unavailable(_ reason: FunctionBarUnavailableReason) -> FunctionBarActionAvailability {
        FunctionBarActionAvailability(isAvailable: false, reason: reason)
    }
}

nonisolated enum FunctionBarDisplayState: Equatable, Sendable {
    case closed
    case opening
    case visible(workspaceID: UUID)
    case switching(from: UUID?, to: UUID)
    case unavailable(FunctionBarUnavailableReason)
    case suspendedBySafeMode

    var isVisible: Bool {
        if case .visible = self { return true }
        return false
    }
}

nonisolated enum FunctionBarUnavailableReason: String, Equatable, Sendable {
    case previewDisabled
    case noActiveWorkspace
    case workspaceStoreUnavailable
    case safeModeActive
    case noDisplayAvailable
    case settingsDisabled
    case itemUnavailable
    case missingReference
    case requiresPro
    case requiresAccessibility

    var message: String {
        switch self {
        case .previewDisabled:
            "Function Bar Preview is disabled."
        case .noActiveWorkspace:
            "No active workspace is available."
        case .workspaceStoreUnavailable:
            "Workspace data is unavailable."
        case .safeModeActive:
            "Safe Mode disables Function Bar so recovery stays simple."
        case .noDisplayAvailable:
            "No display is available for placement."
        case .settingsDisabled:
            "Workspace previews are disabled."
        case .itemUnavailable:
            "This item is unavailable."
        case .missingReference:
            "This item references something that no longer exists."
        case .requiresPro:
            "This item needs Pro Discovery to resolve."
        case .requiresAccessibility:
            "This item needs Accessibility permission."
        }
    }
}

nonisolated enum FunctionBarShowSource: String, Equatable, Sendable {
    case settings
    case statusMenu
    case commandCenter
    case setSwitcher
    case workspaceDisplay
}

nonisolated enum FunctionBarHideSource: String, Equatable, Sendable {
    case settings
    case statusMenu
    case commandCenter
    case closeButton
    case safeMode
    case workspaceDisplay
}

nonisolated enum FunctionBarRefreshReason: String, Equatable, Sendable {
    case workspaceChanged
    case settingsChanged
    case itemReferencesChanged
    case displayChanged
    case manual
}
