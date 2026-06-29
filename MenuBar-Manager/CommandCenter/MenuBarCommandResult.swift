import Foundation

nonisolated enum MenuBarCommandResultStatus: String, Equatable, Hashable, Sendable {
    case success
    case unavailable
    case blocked
    case requiresPermission
    case requiresUnlock
    case requiresPro
    case requiresLabs
    case dryRunOnly
    case failed
    case noOp
}

nonisolated struct MenuBarCommandResult: Equatable, Sendable {
    let status: MenuBarCommandResultStatus
    let message: String
    let diagnosticReason: String
    let commandName: String
    let targetKind: String

    var didRun: Bool {
        status == .success || status == .noOp || status == .dryRunOnly
    }

    static func success(
        _ command: MenuBarCommand,
        message: String,
        diagnosticReason: String = "success"
    ) -> MenuBarCommandResult {
        MenuBarCommandResult(
            status: .success,
            message: message,
            diagnosticReason: diagnosticReason,
            commandName: command.action.diagnosticName,
            targetKind: command.target.diagnosticKind
        )
    }

    static func stopped(
        _ command: MenuBarCommand,
        status: MenuBarCommandResultStatus,
        message: String,
        diagnosticReason: String
    ) -> MenuBarCommandResult {
        MenuBarCommandResult(
            status: status,
            message: message,
            diagnosticReason: diagnosticReason,
            commandName: command.action.diagnosticName,
            targetKind: command.target.diagnosticKind
        )
    }
}
