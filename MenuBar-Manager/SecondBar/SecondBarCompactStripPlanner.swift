import CoreGraphics
import Foundation

nonisolated enum SecondBarCompactStripScanState: Equatable, Sendable {
    case fresh
    case stale
    case noScan

    var needsAttention: Bool {
        switch self {
        case .fresh:
            false
        case .stale, .noScan:
            true
        }
    }

    var diagnosticsLabel: String {
        switch self {
        case .fresh:
            "Fresh"
        case .stale:
            "Stale"
        case .noScan:
            "No Scan"
        }
    }
}

nonisolated struct SecondBarCompactStripPlan: Equatable, Sendable {
    let visibleItems: [MenuBarItemSnapshot]
    let hiddenOverflowCount: Int
    let needsAccurateIconCount: Int
    let scanState: SecondBarCompactStripScanState

    var totalAdditionalCount: Int {
        hiddenOverflowCount
    }

    var hasAdditionalItems: Bool {
        hiddenOverflowCount > 0
    }
}

nonisolated struct SecondBarCompactStripItemMetrics: Equatable, Sendable {
    let imageSize: CGSize
    let slotSize: CGSize
    let cornerRadius: CGFloat
}

nonisolated enum SecondBarCompactStripPlanner {
    static let staleScanThreshold: TimeInterval = 300
    static let interItemSpacing: CGFloat = 4

    private static let fallbackImageSize = CGSize(width: 22, height: 22)
    private static let minimumImageSize = CGSize(width: 12, height: 12)
    private static let minimumSlotSize = CGSize(width: 28, height: 28)
    private static let maximumImageWidth: CGFloat = 220
    private static let maximumImageHeight: CGFloat = 30
    private static let touchPadding = CGSize(width: 4, height: 4)

    static func plan(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<MenuBarItemSnapshot.ID>,
        maxVisibleItems: Int,
        lastScanTime: Date? = Date(),
        now: Date = Date()
    ) -> SecondBarCompactStripPlan {
        let hiddenItems = compactItemCandidates(
            snapshots: snapshots,
            screen: nil,
            enforceRightSideStatusArea: false
        )
        let visibleLimit = max(0, maxVisibleItems)
        let visibleItems = Array(hiddenItems.prefix(visibleLimit))

        return SecondBarCompactStripPlan(
            visibleItems: visibleItems,
            hiddenOverflowCount: max(0, hiddenItems.count - visibleItems.count),
            needsAccurateIconCount: hiddenItems.filter { !accurateIconReadyIDs.contains($0.id) }.count,
            scanState: scanState(lastScanTime: lastScanTime, now: now)
        )
    }

    static func plan(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<MenuBarItemSnapshot.ID>,
        availableItemWidth: CGFloat,
        screen: SecondBarScreenSnapshot,
        lastScanTime: Date? = Date(),
        now: Date = Date()
    ) -> SecondBarCompactStripPlan {
        let hiddenItems = compactItemCandidates(
            snapshots: snapshots,
            screen: screen,
            enforceRightSideStatusArea: true
        )
        let visibleItems = itemsThatFit(hiddenItems, availableWidth: availableItemWidth)

        return SecondBarCompactStripPlan(
            visibleItems: visibleItems,
            hiddenOverflowCount: max(0, hiddenItems.count - visibleItems.count),
            needsAccurateIconCount: hiddenItems.filter { !accurateIconReadyIDs.contains($0.id) }.count,
            scanState: scanState(lastScanTime: lastScanTime, now: now)
        )
    }

    static func itemMetrics(for snapshot: MenuBarItemSnapshot) -> SecondBarCompactStripItemMetrics {
        let imageSize: CGSize
        if let frame = snapshot.frame,
           isUsableMenuBarItemFrame(frame) {
            imageSize = CGSize(
                width: min(max(frame.width.rounded(), minimumImageSize.width), maximumImageWidth),
                height: min(max(frame.height.rounded(), minimumImageSize.height), maximumImageHeight)
            )
        } else {
            imageSize = fallbackImageSize
        }

        let slotSize = CGSize(
            width: max(minimumSlotSize.width, imageSize.width + touchPadding.width),
            height: max(minimumSlotSize.height, imageSize.height + touchPadding.height)
        )
        return SecondBarCompactStripItemMetrics(
            imageSize: imageSize,
            slotSize: slotSize,
            cornerRadius: min(6, min(imageSize.width, imageSize.height) / 4)
        )
    }

    static func compactItemCandidates(
        snapshots: [MenuBarItemSnapshot],
        screen: SecondBarScreenSnapshot
    ) -> [MenuBarItemSnapshot] {
        compactItemCandidates(
            snapshots: snapshots,
            screen: screen,
            enforceRightSideStatusArea: true
        )
    }

    private static func scanState(
        lastScanTime: Date?,
        now: Date
    ) -> SecondBarCompactStripScanState {
        guard let lastScanTime else { return .noScan }
        return now.timeIntervalSince(lastScanTime) > staleScanThreshold ? .stale : .fresh
    }

    private static func compactItemCandidates(
        snapshots: [MenuBarItemSnapshot],
        screen: SecondBarScreenSnapshot?,
        enforceRightSideStatusArea: Bool
    ) -> [MenuBarItemSnapshot] {
        snapshots.enumerated()
            .filter { _, snapshot in
                isCompactItemCandidate(
                    snapshot,
                    screen: screen,
                    enforceRightSideStatusArea: enforceRightSideStatusArea
                )
            }
            .sorted { lhs, rhs in
                menuBarOrder(lhs, rhs)
            }
            .map(\.element)
    }

    private static func isCompactItemCandidate(
        _ snapshot: MenuBarItemSnapshot,
        screen: SecondBarScreenSnapshot?,
        enforceRightSideStatusArea: Bool
    ) -> Bool {
        guard snapshot.zone == .hidden,
              !snapshot.isLikelySystemItem else {
            return false
        }

        guard enforceRightSideStatusArea else {
            return true
        }

        guard let screen else { return false }
        return isInRightSideStatusArea(snapshot, screen: screen)
    }

    private static func itemsThatFit(
        _ snapshots: [MenuBarItemSnapshot],
        availableWidth: CGFloat
    ) -> [MenuBarItemSnapshot] {
        guard availableWidth > 0 else { return [] }

        var usedWidth: CGFloat = 0
        var visibleItems: [MenuBarItemSnapshot] = []
        for snapshot in snapshots {
            let metrics = itemMetrics(for: snapshot)
            let addedWidth = metrics.slotSize.width
                + (visibleItems.isEmpty ? 0 : interItemSpacing)
            guard usedWidth + addedWidth <= availableWidth else {
                break
            }
            visibleItems.append(snapshot)
            usedWidth += addedWidth
        }
        return visibleItems
    }

    private static func menuBarOrder(
        _ lhs: EnumeratedSequence<[MenuBarItemSnapshot]>.Element,
        _ rhs: EnumeratedSequence<[MenuBarItemSnapshot]>.Element
    ) -> Bool {
        if let leftFrame = lhs.element.frame,
           let rightFrame = rhs.element.frame,
           leftFrame.minX.rounded() != rightFrame.minX.rounded() {
            return leftFrame.minX < rightFrame.minX
        }
        return lhs.offset < rhs.offset
    }

    private static func isInRightSideStatusArea(
        _ snapshot: MenuBarItemSnapshot,
        screen: SecondBarScreenSnapshot
    ) -> Bool {
        guard let frame = snapshot.frame,
              isUsableMenuBarItemFrame(frame),
              screen.frame.intersects(frame) || screen.visibleFrame.intersects(frame) else {
            return false
        }

        let modeledMenuBarHeight = max(CGFloat(22), screen.frame.maxY - screen.visibleFrame.maxY)
        let bottomOriginMenuBarBand = CGRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - modeledMenuBarHeight - 4,
            width: screen.frame.width,
            height: modeledMenuBarHeight + 12
        )
        let topOriginMenuBarBand = CGRect(
            x: screen.frame.minX,
            y: screen.frame.minY - 4,
            width: screen.frame.width,
            height: modeledMenuBarHeight + 12
        )
        let rightSideBoundary = screen.notchAvoidanceRect?.maxX ?? screen.frame.midX

        return (bottomOriginMenuBarBand.intersects(frame) || topOriginMenuBarBand.intersects(frame))
            && frame.midX > rightSideBoundary
    }

    private static func isUsableMenuBarItemFrame(_ frame: CGRect) -> Bool {
        frame.origin.x.isFinite
            && frame.origin.y.isFinite
            && frame.width.isFinite
            && frame.height.isFinite
            && frame.width >= 4
            && frame.height >= 4
            && frame.width <= 320
            && frame.height <= 44
    }
}
