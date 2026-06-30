import CoreGraphics
import Foundation

enum MenuItemActivationOutcome: String, Sendable {
    case visibleHighlighted
    case hiddenRevealed
    case alwaysHiddenRevealed
    case highlightedWithoutReveal
    case selectedWithoutHighlight
    case missingFrame

    var displayName: String {
        switch self {
        case .visibleHighlighted:
            "Visible item highlighted"
        case .hiddenRevealed:
            "Hidden item revealed"
        case .alwaysHiddenRevealed:
            "Always-hidden item revealed"
        case .highlightedWithoutReveal:
            "Highlighted without reveal"
        case .selectedWithoutHighlight:
            "Selected without highlight"
        case .missingFrame:
            "Missing frame"
        }
    }
}

struct MenuItemActivationResult: Equatable, Sendable {
    let outcome: MenuItemActivationOutcome
    let message: String
}

@MainActor
final class MenuItemActivator {
    private let settingsStore: SettingsStore
    private let hidingService: HidingService
    private let highlightOverlay: HighlightOverlayWindow
    private let diagnosticsLogger: DiagnosticsLogger
    private let expandHiddenItems: () -> Void
    private let revealAllItems: () -> Void

    init(
        settingsStore: SettingsStore,
        hidingService: HidingService,
        highlightOverlay: HighlightOverlayWindow,
        diagnosticsLogger: DiagnosticsLogger,
        expandHiddenItems: (() -> Void)? = nil,
        revealAllItems: (() -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.hidingService = hidingService
        self.highlightOverlay = highlightOverlay
        self.diagnosticsLogger = diagnosticsLogger
        self.expandHiddenItems = expandHiddenItems ?? { [weak hidingService] in
            hidingService?.expand()
        }
        self.revealAllItems = revealAllItems ?? { [weak hidingService] in
            hidingService?.revealAll()
        }
    }

    func activate(_ result: MenuBarSearchResult) -> MenuItemActivationResult {
        let snapshot = result.snapshot
        let didReveal = revealIfNeeded(for: snapshot.zone)
        let didHighlight = highlightIfPossible(frame: snapshot.frame)

        let activationResult: MenuItemActivationResult
        switch snapshot.zone {
        case .visible:
            activationResult = resultForVisibleItem(didHighlight: didHighlight, hasFrame: snapshot.frame != nil)
        case .hidden:
            activationResult = resultForHiddenItem(
                didReveal: didReveal,
                didHighlight: didHighlight,
                hasFrame: snapshot.frame != nil
            )
        case .alwaysHidden:
            activationResult = resultForAlwaysHiddenItem(
                didReveal: didReveal,
                didHighlight: didHighlight,
                hasFrame: snapshot.frame != nil
            )
        case .unknown:
            activationResult = resultForUnknownItem(didHighlight: didHighlight, hasFrame: snapshot.frame != nil)
        }

        diagnosticsLogger.log("Search activation: \(activationResult.message)")
        return activationResult
    }

    func highlight(_ snapshot: MenuBarItemSnapshot) -> MenuItemActivationResult {
        guard let frame = snapshot.frame else {
            let result = MenuItemActivationResult(
                outcome: .missingFrame,
                message: "No item frame was available to highlight."
            )
            diagnosticsLogger.log("Menu bar item highlight: \(result.message)")
            return result
        }

        highlightOverlay.show(around: frame)
        let result = MenuItemActivationResult(
            outcome: .highlightedWithoutReveal,
            message: "Highlighted the item's last known frame. Click the original icon manually."
        )
        diagnosticsLogger.log("Menu bar item highlight: \(result.message)")
        return result
    }

    private func revealIfNeeded(for zone: MenuBarZone) -> Bool {
        guard settingsStore.searchRevealOnSelection else { return false }

        switch zone {
        case .visible, .unknown:
            return false
        case .hidden:
            expandHiddenItems()
            return true
        case .alwaysHidden:
            revealAllItems()
            return true
        }
    }

    private func highlightIfPossible(frame: CGRect?) -> Bool {
        guard settingsStore.searchHighlightOnSelection, let frame else {
            return false
        }

        highlightOverlay.show(around: frame)
        return true
    }

    private func resultForVisibleItem(didHighlight: Bool, hasFrame: Bool) -> MenuItemActivationResult {
        if didHighlight {
            return MenuItemActivationResult(
                outcome: .visibleHighlighted,
                message: "Highlighted the visible menu bar item. Click it manually to open it."
            )
        }

        return MenuItemActivationResult(
            outcome: hasFrame ? .selectedWithoutHighlight : .missingFrame,
            message: hasFrame
                ? "Selected a visible item. Highlighting is disabled."
                : "Selected a visible item, but no frame was available to highlight."
        )
    }

    private func resultForHiddenItem(
        didReveal: Bool,
        didHighlight: Bool,
        hasFrame: Bool
    ) -> MenuItemActivationResult {
        if didReveal {
            return MenuItemActivationResult(
                outcome: .hiddenRevealed,
                message: didHighlight
                    ? "Revealed hidden items and highlighted the approximate item frame. Click it manually."
                    : "Revealed hidden items. Highlighting is disabled or no frame was available."
            )
        }

        return MenuItemActivationResult(
            outcome: didHighlight ? .highlightedWithoutReveal : (hasFrame ? .selectedWithoutHighlight : .missingFrame),
            message: didHighlight
                ? "Highlighted the hidden item's last known frame without changing visibility."
                : "Selected a hidden item without revealing or highlighting it."
        )
    }

    private func resultForAlwaysHiddenItem(
        didReveal: Bool,
        didHighlight: Bool,
        hasFrame: Bool
    ) -> MenuItemActivationResult {
        if didReveal {
            return MenuItemActivationResult(
                outcome: .alwaysHiddenRevealed,
                message: didHighlight
                    ? "Revealed all hidden items and highlighted the approximate item frame. Click it manually."
                    : "Revealed all hidden items. Highlighting is disabled or no frame was available."
            )
        }

        return MenuItemActivationResult(
            outcome: didHighlight ? .highlightedWithoutReveal : (hasFrame ? .selectedWithoutHighlight : .missingFrame),
            message: didHighlight
                ? "Highlighted the always-hidden item's last known frame without changing visibility."
                : "Selected an always-hidden item without revealing or highlighting it."
        )
    }

    private func resultForUnknownItem(didHighlight: Bool, hasFrame: Bool) -> MenuItemActivationResult {
        if didHighlight {
            return MenuItemActivationResult(
                outcome: .highlightedWithoutReveal,
                message: "Highlighted the item's last known frame. Zone is unknown, so visibility was unchanged."
            )
        }

        return MenuItemActivationResult(
            outcome: hasFrame ? .selectedWithoutHighlight : .missingFrame,
            message: hasFrame
                ? "Selected an item with unknown zone. Highlighting is disabled."
                : "Selected an item with unknown zone, but no frame was available to highlight."
        )
    }
}
