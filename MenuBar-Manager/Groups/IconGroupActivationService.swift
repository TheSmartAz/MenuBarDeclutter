import Foundation

nonisolated enum IconGroupActivationDecision: Equatable, Sendable {
    case highlightVisible
    case revealHidden
    case revealAlwaysHidden
    case selectUnknown

    init(zone: MenuBarZone) {
        switch zone {
        case .visible:
            self = .highlightVisible
        case .hidden:
            self = .revealHidden
        case .alwaysHidden:
            self = .revealAlwaysHidden
        case .unknown:
            self = .selectUnknown
        }
    }
}

@MainActor
final class IconGroupActivationService {
    private let activator: MenuItemActivator
    private let diagnosticsLogger: DiagnosticsLogger

    init(
        activator: MenuItemActivator,
        diagnosticsLogger: DiagnosticsLogger
    ) {
        self.activator = activator
        self.diagnosticsLogger = diagnosticsLogger
    }

    func decision(for snapshot: MenuBarItemSnapshot) -> IconGroupActivationDecision {
        IconGroupActivationDecision(zone: snapshot.zone)
    }

    func activate(snapshot: MenuBarItemSnapshot) -> MenuItemActivationResult {
        let result = activator.activate(
            MenuBarSearchResult(
                snapshot: snapshot,
                score: 0,
                matchReason: .recent
            )
        )
        diagnosticsLogger.log("Group item activation: \(result.message)", category: .layout)
        return result
    }
}
