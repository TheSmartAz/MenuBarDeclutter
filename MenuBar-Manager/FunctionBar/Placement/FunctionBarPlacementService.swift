import AppKit
import Foundation

nonisolated enum FunctionBarPlacementPreference: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case belowMenuBarIcon
    case belowMenuBar
    case nearMouse
    case lastPosition
    case centeredBelowMenuBar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .belowMenuBarIcon: "Below Menu Bar Icon"
        case .belowMenuBar: "Below Menu Bar"
        case .nearMouse: "Near Mouse"
        case .lastPosition: "Last Position"
        case .centeredBelowMenuBar: "Centered Below Menu Bar"
        }
    }
}

nonisolated struct FunctionBarPlacement: Equatable, Sendable {
    var origin: CGPoint
    var displayID: String?
    var placementMode: FunctionBarPlacementPreference
    var didClampToVisibleFrame: Bool
    var reason: FunctionBarPlacementReason
}

nonisolated enum FunctionBarPlacementReason: String, Equatable, Sendable {
    case preferred
    case anchorUnavailable
    case lastPositionInvalid
    case clamped
    case noDisplay
}

@MainActor
struct FunctionBarPlacementService {
    var screensProvider: () -> [NSScreen] = { NSScreen.screens }
    var mouseLocationProvider: () -> CGPoint = { NSEvent.mouseLocation }

    func placement(
        panelSize: CGSize,
        preference: FunctionBarPlacementPreference,
        statusItemAnchor: CGRect? = nil,
        lastPosition: CGPoint? = nil
    ) -> FunctionBarPlacement? {
        guard let screen = preferredScreen(anchor: statusItemAnchor, lastPosition: lastPosition) else {
            return nil
        }

        let visibleFrame = screen.visibleFrame
        let origin: CGPoint
        let reason: FunctionBarPlacementReason

        switch preference {
        case .belowMenuBarIcon:
            if let statusItemAnchor {
                origin = CGPoint(
                    x: statusItemAnchor.midX - panelSize.width / 2,
                    y: visibleFrame.maxY - panelSize.height - 8
                )
                reason = .preferred
            } else {
                origin = CGPoint(x: visibleFrame.midX - panelSize.width / 2, y: visibleFrame.maxY - panelSize.height - 8)
                reason = .anchorUnavailable
            }
        case .belowMenuBar:
            origin = CGPoint(x: visibleFrame.minX + 16, y: visibleFrame.maxY - panelSize.height - 8)
            reason = .preferred
        case .nearMouse:
            let mouse = mouseLocationProvider()
            origin = CGPoint(x: mouse.x - panelSize.width / 2, y: mouse.y - panelSize.height - 12)
            reason = .preferred
        case .lastPosition:
            if let lastPosition, visibleFrame.contains(lastPosition) {
                origin = lastPosition
                reason = .preferred
            } else {
                origin = CGPoint(x: visibleFrame.midX - panelSize.width / 2, y: visibleFrame.maxY - panelSize.height - 8)
                reason = .lastPositionInvalid
            }
        case .centeredBelowMenuBar:
            origin = CGPoint(x: visibleFrame.midX - panelSize.width / 2, y: visibleFrame.maxY - panelSize.height - 8)
            reason = .preferred
        }

        let clamped = clamp(origin: origin, panelSize: panelSize, visibleFrame: visibleFrame)
        return FunctionBarPlacement(
            origin: clamped.origin,
            displayID: screen.localizedName,
            placementMode: preference,
            didClampToVisibleFrame: clamped.didClamp,
            reason: clamped.didClamp ? .clamped : reason
        )
    }

    private func preferredScreen(anchor: CGRect?, lastPosition: CGPoint?) -> NSScreen? {
        let screens = screensProvider()
        guard !screens.isEmpty else { return nil }
        if let anchor,
           let screen = screens.first(where: { $0.frame.intersects(anchor) }) {
            return screen
        }
        if let lastPosition,
           let screen = screens.first(where: { $0.visibleFrame.contains(lastPosition) }) {
            return screen
        }
        let mouse = mouseLocationProvider()
        return screens.first(where: { $0.frame.contains(mouse) }) ?? screens.first
    }

    private func clamp(origin: CGPoint, panelSize: CGSize, visibleFrame: CGRect) -> (origin: CGPoint, didClamp: Bool) {
        let x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - panelSize.width - 8)
        let y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - panelSize.height - 8)
        let clamped = CGPoint(x: x, y: y)
        return (clamped, clamped != origin)
    }
}
