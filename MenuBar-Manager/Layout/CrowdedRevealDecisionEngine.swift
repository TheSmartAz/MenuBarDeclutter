import Foundation

nonisolated enum CrowdedRevealIntent: String, Equatable, Sendable {
    case expand
    case revealAll
    case revealItem
    case revealGroup
}

nonisolated enum CrowdedRevealDecision: Equatable, Sendable {
    case inlineReveal
    case secondBar
    case fullMenuBarMode
    case showLayoutSuggestion
    case noOp
}

nonisolated struct CrowdedRevealDecisionInput: Equatable, Sendable {
    let intent: CrowdedRevealIntent
    let currentVisibility: HidingVisibilityState
    let estimate: LayoutCapacityEstimate
    let rescueEnabled: Bool
    let autoOpenSecondBar: Bool
    let requireProEstimate: Bool
    let secondBarAvailable: Bool
    let fullMenuBarModeAvailable: Bool
    let layoutSuggestionsAvailable: Bool
    let safeModeActive: Bool
}

/// Pure decision policy for crowded reveal fallback selection.
///
/// The engine intentionally avoids app identities, item identities, search
/// queries, and protected names. It only consumes aggregate capacity and gate
/// booleans so diagnostics can stay privacy-safe.
nonisolated struct CrowdedRevealDecisionEngine {
    func decide(_ input: CrowdedRevealDecisionInput) -> CrowdedRevealDecision {
        if input.intent == .expand, input.currentVisibility == .expanded {
            return .noOp
        }

        if input.intent.requiresRevealAll, input.currentVisibility == .revealAll {
            return .noOp
        }

        guard input.rescueEnabled else {
            return .inlineReveal
        }

        // Safe Mode must not run automated fallback surfaces; direct reveal
        // remains available for recovery.
        guard !input.safeModeActive else {
            return .inlineReveal
        }

        guard input.estimate.isLikelyCrowded else {
            return .inlineReveal
        }

        if input.requireProEstimate, input.estimate.source == .basicGeometryOnly {
            return .inlineReveal
        }

        // Geometry-only estimates are intentionally conservative. Do not
        // intercept a normal expand without AX-derived item counts.
        if input.intent == .expand, input.estimate.source == .basicGeometryOnly {
            return .inlineReveal
        }

        if input.autoOpenSecondBar, input.secondBarAvailable {
            return .secondBar
        }

        if input.fullMenuBarModeAvailable {
            return .fullMenuBarMode
        }

        if input.layoutSuggestionsAvailable {
            return .showLayoutSuggestion
        }

        return .inlineReveal
    }
}

private extension CrowdedRevealIntent {
    nonisolated var requiresRevealAll: Bool {
        switch self {
        case .revealAll:
            true
        case .expand, .revealItem, .revealGroup:
            false
        }
    }
}
