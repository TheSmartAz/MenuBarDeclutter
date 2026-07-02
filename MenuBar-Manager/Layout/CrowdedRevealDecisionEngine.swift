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

nonisolated enum CrowdedRevealMenuPressure: String, Equatable, Sendable {
    case unknown
    case normal
    case high
}

nonisolated struct CrowdedRevealDecisionInput: Equatable, Sendable {
    let intent: CrowdedRevealIntent
    let currentVisibility: HidingVisibilityState
    let estimate: LayoutCapacityEstimate
    let rescueEnabled: Bool
    let autoOpenSecondBar: Bool
    let askBeforeSwitching: Bool
    let requireProEstimate: Bool
    let proDiscoveryAvailable: Bool
    let secondBarAvailable: Bool
    let fullMenuBarModeAvailable: Bool
    let layoutSuggestionsAvailable: Bool
    let safeModeActive: Bool
    let activeDisplayID: String?
    let activeAppMenuPressure: CrowdedRevealMenuPressure
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

        guard input.needsCrowdedRescue else {
            return .inlineReveal
        }

        if input.estimateIsForDifferentDisplay {
            return input.layoutSuggestionsAvailable ? .showLayoutSuggestion : .inlineReveal
        }

        if input.requireProEstimate, input.estimate.source == .basicGeometryOnly {
            return .inlineReveal
        }

        // Geometry-only estimates are intentionally conservative. Do not
        // intercept a normal expand without AX-derived item counts.
        if input.intent == .expand, input.estimate.source == .basicGeometryOnly {
            return .inlineReveal
        }

        if input.askBeforeSwitching {
            return input.layoutSuggestionsAvailable ? .showLayoutSuggestion : .inlineReveal
        }

        if input.autoOpenSecondBar, input.proDiscoveryAvailable, input.secondBarAvailable {
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

private extension CrowdedRevealDecisionInput {
    nonisolated var estimateIsForDifferentDisplay: Bool {
        guard let activeDisplayID else { return false }
        return activeDisplayID != estimate.screenID
    }

    nonisolated var needsCrowdedRescue: Bool {
        if estimate.isLikelyCrowded {
            return true
        }

        if activeAppMenuPressure == .high {
            return true
        }

        return estimate.isLikelyNotchConstrained && knownRevealBacklogCount > 0
    }

    nonisolated var knownRevealBacklogCount: Int {
        max(0, estimate.knownHiddenItemCount) + max(0, estimate.knownAlwaysHiddenItemCount)
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
