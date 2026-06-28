import Foundation

struct MenuBarScanResult: Equatable, Sendable {
    let snapshots: [MenuBarItemSnapshot]
    let scanTimestamp: Date
    let axFailuresCount: Int

    /// Per-zone counts computed once at construction time. Previously each
    /// `visibleCount` / `hiddenCount` / `alwaysHiddenCount` / `unknownCount` accessor
    /// performed a separate O(n) `.filter { ... }.count` pass — and callers like
    /// `MenuBarScanCoordinator.apply` read all four after every scan. Caching the
    /// counts at the value-type's immutable boundary keeps the public accessors O(1)
    /// and avoids 3 redundant passes per scan.
    private let zoneCountsCache: [MenuBarZone: Int]

    init(
        snapshots: [MenuBarItemSnapshot],
        scanTimestamp: Date,
        axFailuresCount: Int
    ) {
        let deduplicated = Self.deduplicated(snapshots)
        self.snapshots = deduplicated
        self.scanTimestamp = scanTimestamp
        self.axFailuresCount = max(0, axFailuresCount)

        var counts: [MenuBarZone: Int] = [:]
        for snapshot in deduplicated {
            counts[snapshot.zone, default: 0] += 1
        }
        self.zoneCountsCache = counts
    }

    static var empty: MenuBarScanResult {
        MenuBarScanResult(snapshots: [], scanTimestamp: Date(timeIntervalSince1970: 0), axFailuresCount: 0)
    }

    var visibleCount: Int { zoneCountsCache[.visible] ?? 0 }
    var hiddenCount: Int { zoneCountsCache[.hidden] ?? 0 }
    var alwaysHiddenCount: Int { zoneCountsCache[.alwaysHidden] ?? 0 }
    var unknownCount: Int { zoneCountsCache[.unknown] ?? 0 }

    static func merge(
        previous: MenuBarScanResult?,
        current: MenuBarScanResult
    ) -> MenuBarScanResult {
        guard let previous else { return current }
        return MenuBarScanResult(
            snapshots: previous.snapshots + current.snapshots,
            scanTimestamp: current.scanTimestamp,
            axFailuresCount: current.axFailuresCount
        )
    }

    static func deduplicated(_ snapshots: [MenuBarItemSnapshot]) -> [MenuBarItemSnapshot] {
        var orderedIDs: [String] = []
        var latestByID: [String: MenuBarItemSnapshot] = [:]

        for snapshot in snapshots {
            if latestByID[snapshot.id] == nil {
                orderedIDs.append(snapshot.id)
                latestByID[snapshot.id] = snapshot
                continue
            }

            if let existing = latestByID[snapshot.id],
               snapshot.scanTimestamp >= existing.scanTimestamp {
                latestByID[snapshot.id] = snapshot
            }
        }

        return orderedIDs.compactMap { latestByID[$0] }
    }
}
