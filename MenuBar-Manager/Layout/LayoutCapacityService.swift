import CoreGraphics
import Foundation

/// Estimates how crowded the user's menu bar is and whether normal inline
/// reveal is likely to fail.
///
/// This service is designed to work without Accessibility permission
/// (Basic geometry only) and to produce more accurate estimates when
/// Pro Mode + Accessibility snapshots are available.
nonisolated struct LayoutCapacityService {
    /// Conservative average menu bar item width in points used when no
    /// Accessibility snapshot is available.
    static let fallbackAverageItemWidth: Double = 30

    /// Maximum staleness for an AX snapshot before it triggers a warning.
    static let axSnapshotStaleThreshold: TimeInterval = 120

    var now: () -> Date = { Date() }

    /// Produce a capacity estimate for the given screen using geometry only.
    /// This is the Basic Mode path — no Accessibility required.
    func estimateFromGeometry(
        screenID: String,
        screenFrame: CGRect,
        visibleFrame: CGRect,
        separatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?,
        thresholdRatio: Double
    ) -> LayoutCapacityEstimate {
        let menuBarWidth = screenFrame.width
        let menuBarHeight = max(0, screenFrame.maxY - visibleFrame.maxY)

        // Estimate the usable right-side width (from the leftmost system item
        // to the right edge). Without AX we cannot know the exact start, so
        // we use a conservative fraction of the menu bar width.
        let usableWidth = max(0, menuBarWidth * 0.5)

        let averageItemWidth = Self.fallbackAverageItemWidth
        let estimatedSlots = max(0, Int(usableWidth / averageItemWidth))

        var warnings: [LayoutCapacityWarning] = [.noAXSnapshot]

        let isNotchConstrained = screenFrame.width > 1440 && menuBarHeight > 24
        if isNotchConstrained {
            warnings.append(.notchConstrained)
        }

        if !screenFrame.width.isFinite || screenFrame.width <= 0 {
            warnings.append(.invalidScreenGeometry)
        }

        let ratio = estimatedSlots > 0 ? min(1.0, Double(estimatedSlots) / Double(max(1, estimatedSlots))) : 0
        let isCrowded = ratio >= thresholdRatio

        // Without AX, we assume a moderate usage estimate.
        let estimatedUsedSlots = estimatedSlots
        let usedRatio = min(1.0, Double(estimatedUsedSlots) / Double(max(1, estimatedSlots)))

        return LayoutCapacityEstimate(
            screenID: screenID,
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            estimatedMenuBarWidth: menuBarWidth,
            estimatedUsableRightSideWidth: usableWidth,
            knownItemCount: 0,
            knownVisibleItemCount: 0,
            knownHiddenItemCount: 0,
            knownAlwaysHiddenItemCount: 0,
            estimatedItemSlots: estimatedSlots,
            estimatedUsedSlots: estimatedUsedSlots,
            usedCapacityRatio: usedRatio,
            isLikelyCrowded: isCrowded,
            isLikelyNotchConstrained: isNotchConstrained,
            source: .basicGeometryOnly,
            warnings: warnings,
            generatedAt: now()
        )
    }

    /// Produce a capacity estimate using AX snapshots when available.
    /// Falls back to geometry-only if the snapshot is missing.
    func estimate(
        screenID: String,
        screenFrame: CGRect,
        visibleFrame: CGRect,
        scanResult: MenuBarScanResult?,
        thresholdRatio: Double,
        proModeEnabled: Bool
    ) -> LayoutCapacityEstimate {
        guard proModeEnabled, let scanResult, !scanResult.snapshots.isEmpty else {
            return estimateFromGeometry(
                screenID: screenID,
                screenFrame: screenFrame,
                visibleFrame: visibleFrame,
                separatorFrame: nil,
                alwaysHiddenSeparatorFrame: nil,
                thresholdRatio: thresholdRatio
            )
        }

        let menuBarWidth = screenFrame.width
        let usableWidth = max(0, menuBarWidth * 0.5)

        // Count items by zone using the scan result.
        let visibleCount = scanResult.visibleCount
        let hiddenCount = scanResult.hiddenCount
        let alwaysHiddenCount = scanResult.alwaysHiddenCount
        let totalCount = scanResult.snapshots.count

        // Calculate occupied width from AX frames.
        let occupiedWidth = scanResult.snapshots.compactMap { $0.frame?.width }.reduce(0, +)
        let estimatedSlots = max(0, Int(usableWidth / Self.fallbackAverageItemWidth))
        let estimatedUsedSlots = max(totalCount, Int(occupiedWidth / Self.fallbackAverageItemWidth))

        var warnings: [LayoutCapacityWarning] = []
        let isStale = now().timeIntervalSince(scanResult.scanTimestamp) > Self.axSnapshotStaleThreshold
        if isStale {
            warnings.append(.staleAXSnapshot)
        }

        let isNotchConstrained = screenFrame.width > 1440 && max(0, screenFrame.maxY - visibleFrame.maxY) > 24
        if isNotchConstrained {
            warnings.append(.notchConstrained)
        }

        let usedRatio = estimatedSlots > 0 ? min(1.0, Double(estimatedUsedSlots) / Double(estimatedSlots)) : 1.0
        let isCrowded = usedRatio >= thresholdRatio

        if isCrowded {
            warnings.append(.extremelyCrowded)
        }

        return LayoutCapacityEstimate(
            screenID: screenID,
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            estimatedMenuBarWidth: menuBarWidth,
            estimatedUsableRightSideWidth: usableWidth,
            knownItemCount: totalCount,
            knownVisibleItemCount: visibleCount,
            knownHiddenItemCount: hiddenCount,
            knownAlwaysHiddenItemCount: alwaysHiddenCount,
            estimatedItemSlots: estimatedSlots,
            estimatedUsedSlots: estimatedUsedSlots,
            usedCapacityRatio: usedRatio,
            isLikelyCrowded: isCrowded,
            isLikelyNotchConstrained: isNotchConstrained,
            source: isStale ? .mixed : .proAXSnapshot,
            warnings: warnings,
            generatedAt: now()
        )
    }
}
