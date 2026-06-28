import AppKit
import Foundation

/// Owns a single separator `NSStatusItem` and the logic that translates
/// ``HidingState`` into a concrete `length` value. The same controller type
/// is used for both the primary separator and the always-hidden separator;
/// the kind (``StatusItemKind``) parameter carries the symbol/label variants.
@MainActor
final class SeparatorController {
    let kind: StatusItemKind
    private let factory: StatusItemFactory
    private let settingsStore: SettingsStore
    private let screenGeometry: ScreenGeometryService
    private let diagnosticsLogger: DiagnosticsLogger

    private(set) var statusItem: NSStatusItem?

    init(
        kind: StatusItemKind,
        factory: StatusItemFactory,
        settingsStore: SettingsStore,
        screenGeometry: ScreenGeometryService,
        diagnosticsLogger: DiagnosticsLogger
    ) {
        self.kind = kind
        self.factory = factory
        self.settingsStore = settingsStore
        self.screenGeometry = screenGeometry
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Current expanded length, sourced from user settings.
    var expandedLength: Double {
        settingsStore.expandedSeparatorLength
    }

    /// Collapsed length either honoured from the user override or recommended
    /// from the widest screen.
    var collapsedLength: Double {
        if let override = settingsStore.collapsedSeparatorLengthOverride, override > 0 {
            return override
        }
        return screenGeometry.recommendedCollapsedSeparatorLength()
    }

    /// Length value expected for a given hiding state.
    func length(for state: HidingState) -> Double {
        switch state {
        case .expanded:
            return expandedLength
        case .collapsed:
            return collapsedLength
        }
    }

    /// Current length the controller would apply. Surfaced in Diagnostics.
    var currentLength: Double {
        guard let statusItem else { return 0 }
        return statusItem.length
    }

    /// Current screen-space frame of the separator button, when AppKit has
    /// attached it to a window. Used by Pro Mode discovery for zone mapping.
    var screenFrame: CGRect? {
        guard let button = statusItem?.button,
              let window = button.window else {
            return nil
        }

        let windowFrame = button.convert(button.bounds, to: nil)
        return window.convertToScreen(windowFrame)
    }

    /// Installs the status item. When `enableItem` is `false`, the controller
    /// skips installation entirely (used by `SettingsStore.showPrimarySeparator`
    /// for the primary separator).
    func install(enableItem: Bool = true) {
        guard statusItem == nil else { return }
        guard enableItem else {
            diagnosticsLogger.log("\(kind) separator hidden by user preference (not installed).")
            return
        }

        let length = expandedLength
        let item = factory.makeSeparatorItem(length: length, kind: kind)
        statusItem = item
        // Apply the current `showSeparators` preference on first install.
        applyVisualMarkerEnabled(settingsStore.showSeparators)
    }

    func apply(state: HidingState) {
        guard let statusItem else { return }

        let length = length(for: state)
        factory.updateLength(for: statusItem, length: length)
        factory.updateSymbol(
            for: statusItem,
            kind: kind,
            state: state,
            showVisualMarker: settingsStore.showSeparators
        )
    }

    /// Updates the separator's visible marker (icon/title) without removing
    /// the underlying `NSStatusItem`. Used when the user toggles
    /// `SettingsStore.showSeparators`.
    func applyVisualMarkerEnabled(_ enabled: Bool) {
        guard let statusItem else { return }
        factory.updateSymbol(
            for: statusItem,
            kind: kind,
            state: hidingStateFromCurrentLength(),
            showVisualMarker: enabled
        )
    }

    /// Heuristically maps the current length back to a `HidingState` so the
    /// separator symbol can be refreshed after `showSeparators` toggles
    /// without changing the actual length.
    private func hidingStateFromCurrentLength() -> HidingState {
        guard let statusItem else { return .expanded }
        // Collapsed length is at least an order of magnitude larger than the
        // expanded length; treat anything above the midpoint as collapsed.
        let midpoint = (expandedLength + collapsedLength) / 2
        return statusItem.length >= midpoint ? .collapsed : .expanded
    }

    func refreshSymbol(state: HidingState) {
        guard let statusItem else { return }
        factory.updateSymbol(
            for: statusItem,
            kind: kind,
            state: state,
            showVisualMarker: settingsStore.showSeparators
        )
    }

    func resetOverride() {
        settingsStore.collapsedSeparatorLengthOverride = nil
    }

    func remove() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        diagnosticsLogger.log("Removing \(kind) separator status item.")
        self.statusItem = nil
    }
}
