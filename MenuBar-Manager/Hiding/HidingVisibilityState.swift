import Foundation

/// High-level menu bar visibility state introduced in Phase 2.
///
/// `HidingState` continues to drive a *single* separator's collapsed-vs-
/// expanded presentation; ``HidingVisibilityState`` describes the whole menu
/// bar surface including the optional always-hidden separator. Each case
/// knows which separator states should be applied for its combination.
enum HidingVisibilityState: String, CaseIterable, Codable, Sendable {
    /// Both separators collapse: every user item left of the primary separator
    /// is hidden behind a very wide separator, and the always-hidden separator
    /// is also collapsed.
    case collapsed

    /// Primary separator expanded, always-hidden separator collapsed: items
    /// between the two separators are visible; items past the always-hidden
    /// separator stay pushed off-screen.
    case expanded

    /// Both separators expanded: every item, including the always-hidden zone,
    /// is visible.
    case revealAll

    /// Per-separator state used by the primary separator controller.
    var primarySeparatorState: HidingState {
        switch self {
        case .collapsed:
            return .collapsed
        case .expanded, .revealAll:
            return .expanded
        }
    }

    /// Per-separator state used by the always-hidden separator controller.
    var alwaysHiddenSeparatorState: HidingState {
        switch self {
        case .collapsed, .expanded:
            return .collapsed
        case .revealAll:
            return .expanded
        }
    }

    var isCollapsed: Bool { self == .collapsed }
    var isRevealAll: Bool { self == .revealAll }

    /// Toggle used by a normal click: collapses when expanded or revealed,
    /// expands when collapsed.
    var toggled: HidingVisibilityState { isCollapsed ? .expanded : .collapsed }

    /// Toggle used by Option-click when ``SettingsStore.revealAllOnOptionClick``
    /// is enabled: enters revealAll when not already revealing; otherwise
    /// collapses again.
    var optionToggled: HidingVisibilityState {
        switch self {
        case .collapsed, .expanded:
            return .revealAll
        case .revealAll:
            return .collapsed
        }
    }
}

/// Permission-free readiness summary for the Basic Mode placement test.
///
/// This model deliberately uses only MenuBarDeclutter-owned status item state:
/// separator lengths, the current visibility state, and whether the optional
/// always-hidden separator is installed. It does not inspect other apps' menu
/// bar items and does not depend on Accessibility discovery.
struct BasicModeReadiness: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case ready
        case runtimeUnavailable
        case primarySeparatorMissing
        case primarySeparatorTooShortForCollapsedState
        case alwaysHiddenSeparatorMissing
        case alwaysHiddenSeparatorTooShortForCollapsedState
    }

    enum Tone: Equatable, Sendable {
        case ready
        case info
        case warning
    }

    let status: Status
    let tone: Tone
    let systemImage: String
    let message: String

    static func evaluate(
        visibilityState: HidingVisibilityState?,
        primarySeparatorLength: Double?,
        alwaysHiddenEnabled: Bool,
        alwaysHiddenSeparatorInstalled: Bool,
        alwaysHiddenSeparatorLength: Double?
    ) -> BasicModeReadiness {
        guard let visibilityState,
              let primarySeparatorLength else {
            return BasicModeReadiness(
                status: .runtimeUnavailable,
                tone: .info,
                systemImage: "info.circle",
                message: "Launch-time status is still attaching. Basic Mode actions remain local and can be tested from the menu bar control after startup."
            )
        }

        guard primarySeparatorLength > 0 else {
            return BasicModeReadiness(
                status: .primarySeparatorMissing,
                tone: .warning,
                systemImage: "exclamationmark.triangle",
                message: "Primary separator status is missing. Use Reset Layout, then Show Drag Hint before testing collapse and reveal."
            )
        }

        if visibilityState.primarySeparatorState == .collapsed,
           !isCollapsedLength(primarySeparatorLength) {
            return BasicModeReadiness(
                status: .primarySeparatorTooShortForCollapsedState,
                tone: .warning,
                systemImage: "arrow.left.and.right",
                message: "Hidden items are marked collapsed, but the primary separator is still short. Use Reset Layout, then try Collapse again."
            )
        }

        if alwaysHiddenEnabled {
            guard alwaysHiddenSeparatorInstalled else {
                return BasicModeReadiness(
                    status: .alwaysHiddenSeparatorMissing,
                    tone: .warning,
                    systemImage: "lock.trianglebadge.exclamationmark",
                    message: "Always Hidden is enabled, but its separator is not installed. Toggle Always Hidden off/on or use Reset Layout before testing Reveal All."
                )
            }

            if visibilityState.alwaysHiddenSeparatorState == .collapsed,
               !isCollapsedLength(alwaysHiddenSeparatorLength ?? 0) {
                return BasicModeReadiness(
                    status: .alwaysHiddenSeparatorTooShortForCollapsedState,
                    tone: .warning,
                    systemImage: "lock.trianglebadge.exclamationmark",
                    message: "Always Hidden is enabled, but its separator is not covering the always-hidden zone. Use Reset Layout before relying on Reveal All."
                )
            }
        }

        return readyState(for: visibilityState, alwaysHiddenEnabled: alwaysHiddenEnabled)
    }

    private static func readyState(
        for visibilityState: HidingVisibilityState,
        alwaysHiddenEnabled: Bool
    ) -> BasicModeReadiness {
        let revealAllSuffix = alwaysHiddenEnabled ? " Reveal All should expose both Hidden and Always Hidden zones." : ""

        switch visibilityState {
        case .expanded:
            return BasicModeReadiness(
                status: .ready,
                tone: .ready,
                systemImage: "checkmark.shield",
                message: "Ready to test. Use Collapse to verify hidden-zone items move off the visible menu bar, then Expand to bring them back.\(revealAllSuffix)"
            )
        case .collapsed:
            return BasicModeReadiness(
                status: .ready,
                tone: .ready,
                systemImage: "eye.slash",
                message: "Hidden-zone items are collapsed. Use Expand to reveal them, or Reset Layout if the visible menu bar looks wrong.\(revealAllSuffix)"
            )
        case .revealAll:
            return BasicModeReadiness(
                status: .ready,
                tone: .ready,
                systemImage: "rectangle.expand.vertical",
                message: "Reveal All is active. Use Collapse when you are done checking every zone."
            )
        }
    }

    private static func isCollapsedLength(_ length: Double) -> Bool {
        length >= AppConstants.defaultExpandedSeparatorLength * 2
    }
}
