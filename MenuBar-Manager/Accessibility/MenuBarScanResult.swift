import Foundation

struct MenuBarScanResult: Equatable, Sendable {
    let snapshots: [MenuBarItemSnapshot]
    let scanTimestamp: Date
    let axFailuresCount: Int

    init(
        snapshots: [MenuBarItemSnapshot],
        scanTimestamp: Date,
        axFailuresCount: Int
    ) {
        self.snapshots = Self.deduplicated(snapshots)
        self.scanTimestamp = scanTimestamp
        self.axFailuresCount = max(0, axFailuresCount)
    }

    static var empty: MenuBarScanResult {
        MenuBarScanResult(snapshots: [], scanTimestamp: Date(timeIntervalSince1970: 0), axFailuresCount: 0)
    }

    var visibleCount: Int {
        snapshots.filter { $0.zone == .visible }.count
    }

    var hiddenCount: Int {
        snapshots.filter { $0.zone == .hidden }.count
    }

    var alwaysHiddenCount: Int {
        snapshots.filter { $0.zone == .alwaysHidden }.count
    }

    var unknownCount: Int {
        snapshots.filter { $0.zone == .unknown }.count
    }

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
