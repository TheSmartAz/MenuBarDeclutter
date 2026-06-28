import AppKit
import Foundation

/// Kind of status bar item the controller owns. Each kind carries its
/// accessibility label and SF Symbol preferences so the factory can build
/// them uniformly.
enum StatusItemKind {
    case control
    case primarySeparator
    case alwaysHiddenSeparator

    var accessibilityLabel: String {
        switch self {
        case .control:
            return AppConstants.controlItemAccessibilityLabel
        case .primarySeparator:
            return AppConstants.separatorAccessibilityLabel
        case .alwaysHiddenSeparator:
            return AppConstants.alwaysHiddenSeparatorAccessibilityLabel
        }
    }

    /// SF Symbol shown when the menu bar is expanded.
    var expandedSymbolName: String {
        switch self {
        case .control:
            return "chevron.left"
        case .primarySeparator:
            return "chevron.left.2"
        case .alwaysHiddenSeparator:
            return "circle.dashed"
        }
    }

    /// SF Symbol shown when the menu bar is collapsed.
    var collapsedSymbolName: String {
        switch self {
        case .control:
            return "chevron.right"
        case .primarySeparator:
            return "chevron.right.2"
        case .alwaysHiddenSeparator:
            return "circle.fill"
        }
    }
}