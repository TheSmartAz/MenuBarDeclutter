import CoreGraphics
import Foundation

/// Source of the capacity estimate data.
nonisolated enum LayoutCapacitySource: String, CaseIterable, Sendable {
    case basicGeometryOnly
    case proAXSnapshot
    case mixed
}

/// Warning produced during capacity estimation.
nonisolated enum LayoutCapacityWarning: String, CaseIterable, Sendable {
    case staleAXSnapshot
    case notchConstrained
    case noAXSnapshot
    case invalidScreenGeometry
    case extremelyCrowded

    var message: String {
        switch self {
        case .staleAXSnapshot:
            "Accessibility snapshot is stale; capacity estimate may be inaccurate."
        case .notchConstrained:
            "This display may have a notch or constrained center area; Second Bar is recommended if inline reveal fails."
        case .noAXSnapshot:
            "No Accessibility snapshot available; using approximate item width fallback."
        case .invalidScreenGeometry:
            "Screen geometry could not be determined; capacity estimate is approximate."
        case .extremelyCrowded:
            "Menu bar is extremely crowded; inline reveal is likely to fail."
        }
    }
}

/// Estimate of how crowded the user's menu bar is and whether normal inline
/// reveal is likely to fail. Produced by ``LayoutCapacityService``.
nonisolated struct LayoutCapacityEstimate: Equatable, Sendable {
    let screenID: String
    let screenFrame: CGRect
    let visibleFrame: CGRect
    let estimatedMenuBarWidth: Double
    let estimatedUsableRightSideWidth: Double
    let knownItemCount: Int
    let knownVisibleItemCount: Int
    let knownHiddenItemCount: Int
    let knownAlwaysHiddenItemCount: Int
    let estimatedItemSlots: Int
    let estimatedUsedSlots: Int
    let usedCapacityRatio: Double
    let isLikelyCrowded: Bool
    let isLikelyNotchConstrained: Bool
    let source: LayoutCapacitySource
    let warnings: [LayoutCapacityWarning]
    let generatedAt: Date

    init(
        screenID: String,
        screenFrame: CGRect,
        visibleFrame: CGRect,
        estimatedMenuBarWidth: Double,
        estimatedUsableRightSideWidth: Double,
        knownItemCount: Int,
        knownVisibleItemCount: Int,
        knownHiddenItemCount: Int,
        knownAlwaysHiddenItemCount: Int,
        estimatedItemSlots: Int,
        estimatedUsedSlots: Int,
        usedCapacityRatio: Double,
        isLikelyCrowded: Bool,
        isLikelyNotchConstrained: Bool,
        source: LayoutCapacitySource,
        warnings: [LayoutCapacityWarning],
        generatedAt: Date
    ) {
        self.screenID = screenID
        self.screenFrame = screenFrame
        self.visibleFrame = visibleFrame
        self.estimatedMenuBarWidth = estimatedMenuBarWidth
        self.estimatedUsableRightSideWidth = estimatedUsableRightSideWidth
        self.knownItemCount = knownItemCount
        self.knownVisibleItemCount = knownVisibleItemCount
        self.knownHiddenItemCount = knownHiddenItemCount
        self.knownAlwaysHiddenItemCount = knownAlwaysHiddenItemCount
        self.estimatedItemSlots = estimatedItemSlots
        self.estimatedUsedSlots = estimatedUsedSlots
        self.usedCapacityRatio = usedCapacityRatio
        self.isLikelyCrowded = isLikelyCrowded
        self.isLikelyNotchConstrained = isLikelyNotchConstrained
        self.source = source
        self.warnings = warnings
        self.generatedAt = generatedAt
    }
}
