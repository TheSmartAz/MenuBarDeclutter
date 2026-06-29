import Foundation

/// Internal constants for the experimental menu bar spacing defaults keys.
///
/// These keys are isolated behind the spacing service and not scattered
/// through the codebase. They may rely on user defaults behavior that can
/// vary by macOS release; the feature is Labs-only, explicit, and reversible.
nonisolated enum MenuBarSpacingDefaultsKeys {
    /// User defaults key for status item spacing.
    static let itemSpacing = "NSStatusItemSpacing"
    /// User defaults key for status item selection padding.
    static let selectionPadding = "NSStatusItemSelectionPadding"
}
