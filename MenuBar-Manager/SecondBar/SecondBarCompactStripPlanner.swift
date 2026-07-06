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
        let visibleLimit = max(0, maxVisibleItems)
        let visibleItems = Array(hiddenItems.prefix(visibleLimit))

        return SecondBarCompactStripPlan(
            visibleItems: visibleItems,
            hiddenOverflowCount: max(0, hiddenItems.count - visibleItems.count),
            needsAccurateIconCount: hiddenItems.filter { !accurateIconReadyIDs.contains($0.id) }.count,
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
