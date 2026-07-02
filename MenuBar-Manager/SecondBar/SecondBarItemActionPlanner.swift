import Foundation

nonisolated enum SecondBarItemCommandAction: String, CaseIterable, Sendable {
    case reveal
    case highlight
    case showInFindIcon
    case openOwningApp
    case dryRunAssistedMove
    case tryAssistedMove

    var commandAction: MenuBarCommandAction {
        switch self {
        case .reveal:
            .revealItem
        case .highlight:
            .highlightItem
        case .showInFindIcon:
            .showFindIcon
        case .openOwningApp:
            .openOwningApp
        case .dryRunAssistedMove:
            .dryRunMoveItem
        case .tryAssistedMove:
            .tryAssistedMoveItem
        }
    }
}

nonisolated struct SecondBarItemActionPlanner {
    static func command(
        for action: SecondBarItemCommandAction,
        snapshot: MenuBarItemSnapshot,
        experimentalConfirmationSatisfied: Bool = false
    ) -> MenuBarCommand {
        MenuBarCommand(
            action: action.commandAction,
            target: .menuBarItem(id: snapshot.id),
            source: .secondBar,
            experimentalConfirmationSatisfied: experimentalConfirmationSatisfied
        )
    }
}
