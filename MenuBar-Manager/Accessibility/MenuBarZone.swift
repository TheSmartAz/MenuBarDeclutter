import CoreGraphics
import Foundation

nonisolated enum MenuBarZone: String, CaseIterable, Identifiable, Codable, Sendable {
    case visible
    case hidden
    case alwaysHidden
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .visible:
            "Visible"
        case .hidden:
            "Hidden"
        case .alwaysHidden:
            "Always Hidden"
        case .unknown:
            "Unknown"
        }
    }

    static func classify(
        itemFrame: CGRect?,
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?
    ) -> MenuBarZone {
        guard let itemFrame, let primarySeparatorFrame else {
            return .unknown
        }

        let itemX = itemFrame.midX
        if itemX > primarySeparatorFrame.midX {
            return .visible
        }

        guard let alwaysHiddenSeparatorFrame else {
            return .hidden
        }

        if itemX > alwaysHiddenSeparatorFrame.midX {
            return .hidden
        }

        return .alwaysHidden
    }
}
