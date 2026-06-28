import AppKit
import Foundation

/// Builds and configures `NSStatusItem` instances for the menu bar.
///
/// The factory is intentionally thin: it owns the AppKit details (template
/// images, accessibility labels, length mode) so the controller stays readable.
@MainActor
final class StatusItemFactory {
    private let diagnosticsLogger: DiagnosticsLogger

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Creates a square-length status item (the control toggle).
    func makeControlItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configure(item, kind: .control, length: NSStatusItem.squareLength)
        return item
    }

    /// Creates a variable-length status item used as the separator.
    func makeSeparatorItem(length: Double, kind: StatusItemKind = .primarySeparator) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: length)
        configure(item, kind: kind, length: length)
        return item
    }

    /// Updates the button symbol for a separator/control item. When
    /// `showVisualMarker` is `false` the button is left blank but the
    /// underlying `NSStatusItem` keeps its length — used by the Phase 2
    /// `showSeparators` toggle.
    func updateSymbol(
        for item: NSStatusItem,
        kind: StatusItemKind,
        state hiding: HidingState,
        showVisualMarker: Bool = true
    ) {
        guard let button = item.button else { return }

        guard showVisualMarker else {
            button.image = nil
            button.title = ""
            return
        }

        let symbolName = hiding.isCollapsed ? kind.collapsedSymbolName : kind.expandedSymbolName
        if let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: kind.accessibilityLabel
        ) {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = kind == .control ? (hiding.isCollapsed ? ">" : "<") : "|"
        }
    }

    func updateLength(for item: NSStatusItem, length: Double) {
        item.length = length
    }

    // MARK: Private

    private func configure(_ item: NSStatusItem, kind: StatusItemKind, length: Double) {
        guard let button = item.button else { return }

        button.toolTip = AppConstants.displayName
        button.setAccessibilityLabel(kind.accessibilityLabel)

        switch kind {
        case .control:
            if let image = NSImage(
                systemSymbolName: kind.expandedSymbolName,
                accessibilityDescription: kind.accessibilityLabel
            ) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "MBD"
            }
        case .primarySeparator, .alwaysHiddenSeparator:
            if let image = NSImage(
                systemSymbolName: kind.expandedSymbolName,
                accessibilityDescription: kind.accessibilityLabel
            ) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "|"
            }
        }

        diagnosticsLogger.log("Installed status item (kind=\(kind), length=\(length)).")
    }
}