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
