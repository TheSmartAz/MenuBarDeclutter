import Foundation

@MainActor
struct FunctionBarActionDispatcher {
    var routeCommand: (MenuBarCommand) -> MenuBarCommandResult
    var openSettings: () -> Void
    var openRecovery: () -> Void
    var openWorkspacePreview: () -> Void
    var showFunctionBar: () -> Void
    var hideFunctionBar: () -> Void
    var showInfoStrip: () -> Void
    var hideInfoStrip: () -> Void

    func activate(_ item: FunctionBarItemModel) -> MenuBarCommandResult {
        switch item.kind {
        case .command(let command):
            return activate(command)
        case .menuBarItem(let reference):
            return routeCommand(MenuBarCommand(
                action: .revealItem,
                target: .menuBarItem(id: reference.stableHash),
                source: .secondBar
            ))
        case .group(let reference):
            return routeCommand(MenuBarCommand(
                action: .showGroupPanel,
                target: .group(reference.groupID),
                source: .groupPanel
            ))
        case .spacer, .divider, .infoTilePlaceholder:
            return MenuBarCommandResult.stopped(
                MenuBarCommand(action: .toggle, source: .settings),
                status: .noOp,
                message: "This Function Bar item has no direct action.",
                diagnosticReason: "nonActionItem"
            )
        }
    }

    func activate(_ item: FunctionBarItemModel, proxyAction: FunctionBarProxyAction) -> MenuBarCommandResult {
        guard case .menuBarItem(let reference) = item.kind else {
            return MenuBarCommandResult.stopped(
                MenuBarCommand(action: .toggle, source: .settings),
                status: .noOp,
                message: "This Function Bar item does not support proxy actions.",
                diagnosticReason: "nonProxyItem"
            )
        }

        return routeCommand(MenuBarCommand(
            action: proxyAction.commandAction,
            target: .menuBarItem(id: reference.stableHash),
            source: .settings
        ))
    }

    private func activate(_ command: WorkspaceCommandReference) -> MenuBarCommandResult {
        if let menuBarCommand = command.menuBarCommand {
            return routeCommand(menuBarCommand)
        }

        switch command.actionID {
        case WorkspaceCommandReference.openSettings.actionID:
            openSettings()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Settings opened.")
        case WorkspaceCommandReference.openRecovery.actionID:
            openRecovery()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Recovery opened.")
        case WorkspaceCommandReference.showWorkspacePreview.actionID:
            openWorkspacePreview()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Workspace Preview opened.")
        case WorkspaceCommandReference.showFunctionBar.actionID:
            showFunctionBar()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Function Bar shown.")
        case WorkspaceCommandReference.hideFunctionBar.actionID:
            hideFunctionBar()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Function Bar hidden.")
        case WorkspaceCommandReference.showInfoStrip.actionID:
            showInfoStrip()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Info Strip shown.")
        case WorkspaceCommandReference.hideInfoStrip.actionID:
            hideInfoStrip()
            return .success(MenuBarCommand(action: .toggle, source: .settings), message: "Info Strip hidden.")
        case WorkspaceCommandReference.nextInfoStripTile.actionID:
            return routeCommand(MenuBarCommand(action: .nextInfoStripTile, target: .infoStrip, source: .settings))
        case WorkspaceCommandReference.openInfoStripSettings.actionID:
            return routeCommand(MenuBarCommand(action: .openInfoStripSettings, target: .infoStrip, source: .settings))
        case WorkspaceCommandReference.showFunctionBarFromInfoStrip.actionID:
            return routeCommand(MenuBarCommand(action: .showFunctionBarFromInfoStrip, target: .infoStrip, source: .settings))
        default:
            return MenuBarCommandResult.stopped(
                MenuBarCommand(action: .toggle, source: .settings),
                status: .unavailable,
                message: "Workspace command is unavailable.",
                diagnosticReason: "workspaceCommandUnavailable"
            )
        }
    }
}
