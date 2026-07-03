import AppKit
import Foundation

nonisolated enum InfoStripPlacementPreference: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case alignWithFunctionBar
    case belowMenuBarIcon
    case belowMenuBar
    case nearMouse
    case lastPosition
    case centeredBelowMenuBar

    var id: String { rawValue }
}

nonisolated struct InfoStripPlacement: Equatable, Sendable {
    var origin: CGPoint
    var displayID: String?
    var placementMode: InfoStripPlacementPreference
    var didClampToVisibleFrame: Bool
}

@MainActor
struct InfoStripPlacementService {
    var functionBarPlacementService = FunctionBarPlacementService()

    func placement(
        panelSize: CGSize,
        preference: InfoStripPlacementPreference,
        statusItemAnchor: CGRect? = nil,
        lastPosition: CGPoint? = nil
    ) -> InfoStripPlacement? {
        let mappedPreference: FunctionBarPlacementPreference = {
            switch preference {
            case .alignWithFunctionBar, .belowMenuBarIcon: .belowMenuBarIcon
            case .belowMenuBar: .belowMenuBar
            case .nearMouse: .nearMouse
            case .lastPosition: .lastPosition
            case .centeredBelowMenuBar: .centeredBelowMenuBar
            }
        }()
        guard let placement = functionBarPlacementService.placement(
            panelSize: panelSize,
            preference: mappedPreference,
            statusItemAnchor: statusItemAnchor,
            lastPosition: lastPosition
        ) else {
            return nil
        }
        return InfoStripPlacement(
            origin: placement.origin,
            displayID: placement.displayID,
            placementMode: preference,
            didClampToVisibleFrame: placement.didClampToVisibleFrame
        )
    }
}
