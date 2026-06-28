import Foundation

/// Discrete hidden-items visibility state used by ``HidingService``.
enum HidingState: String, CaseIterable, Sendable {
    /// All menu bar items are visible; separator occupies a small length.
    case expanded

    /// Items left of the separator are pushed off-screen by a very wide
    /// separator item.
    case collapsed

    var isCollapsed: Bool { self == .collapsed }

    var toggled: HidingState { isCollapsed ? .expanded : .collapsed }
}