import Foundation

nonisolated struct MenuBarCommandDiagnostics: Equatable, Sendable {
    static func metadata(for result: MenuBarCommandResult, source: MenuBarCommandSource) -> [String: String] {
        [
            "command": result.commandName,
            "source": source.rawValue,
            "target": result.targetKind,
            "status": result.status.rawValue,
            "reason": result.diagnosticReason
        ]
    }
}
