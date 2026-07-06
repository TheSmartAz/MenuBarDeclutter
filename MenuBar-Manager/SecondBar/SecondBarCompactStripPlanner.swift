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
}

nonisolated struct SecondBarCompactStripPlan: Equatable, Sendable {
    let visibleItems: [MenuBarItemSnapshot]
    let hiddenOverflowCount: Int
    let needsAccurateIconCount: Int
    let scanState: SecondBarCompactStripScanState

    var totalAdditionalCount: Int {
        hiddenOverflowCount + needsAccurateIconCount
    }

    var hasAdditionalItems: Bool {
        totalAdditionalCount > 0
    }
}

nonisolated enum SecondBarCompactStripPlanner {
    static let staleScanThreshold: TimeInterval = 300

    static func plan(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<MenuBarItemSnapshot.ID>,
        maxVisibleItems: Int,
        lastScanTime: Date? = Date(),
        now: Date = Date()
    ) -> SecondBarCompactStripPlan {
        let hiddenItems = snapshots.filter { $0.zone == .hidden }
        let readyItems = hiddenItems.filter { accurateIconReadyIDs.contains($0.id) }
        let visibleLimit = max(0, maxVisibleItems)
        let visibleItems = Array(readyItems.prefix(visibleLimit))

        return SecondBarCompactStripPlan(
            visibleItems: visibleItems,
            hiddenOverflowCount: max(0, readyItems.count - visibleItems.count),
            needsAccurateIconCount: hiddenItems.count - readyItems.count,
            scanState: scanState(lastScanTime: lastScanTime, now: now)
        )
    }

    private static func scanState(
        lastScanTime: Date?,
        now: Date
    ) -> SecondBarCompactStripScanState {
        guard let lastScanTime else { return .noScan }
        return now.timeIntervalSince(lastScanTime) > staleScanThreshold ? .stale : .fresh
    }
}
