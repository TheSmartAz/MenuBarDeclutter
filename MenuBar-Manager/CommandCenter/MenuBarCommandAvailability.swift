import Foundation

nonisolated enum MenuBarCommandGate: String, Equatable, Hashable, Sendable {
    case safeMode
    case appIntentsEnabled
    case automationPaused
    case profileAutomation
    case labsAutomation
    case proMode
    case accessibilityDiscovery
    case accessibilityPermission
    case featureEnabled
    case labs
    case privateAccess
    case targetAvailable
    case experimentalConfirmation
}

nonisolated struct MenuBarCommandAvailability: Equatable, Sendable {
    let status: MenuBarCommandResultStatus
    let message: String
    let diagnosticReason: String
    let failedGate: MenuBarCommandGate?

    var isAvailable: Bool { status == .success }

    static let available = MenuBarCommandAvailability(
        status: .success,
        message: "Available.",
        diagnosticReason: "available",
        failedGate: nil
    )

    static func unavailable(
        status: MenuBarCommandResultStatus = .unavailable,
        message: String,
        diagnosticReason: String,
        failedGate: MenuBarCommandGate
    ) -> MenuBarCommandAvailability {
        MenuBarCommandAvailability(
            status: status,
            message: message,
            diagnosticReason: diagnosticReason,
            failedGate: failedGate
        )
    }
}
