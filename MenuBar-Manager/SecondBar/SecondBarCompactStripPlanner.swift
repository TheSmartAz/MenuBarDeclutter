import Foundation

nonisolated struct SecondBarCompactStripPlan: Equatable, Sendable {
    let visibleItems: [MenuBarItemSnapshot]
    let hiddenOverflowCount: Int
    let needsAccurateIconCount: Int

    var totalAdditionalCount: Int {
        hiddenOverflowCount + needsAccurateIconCount
    }

    var hasAdditionalItems: Bool {
        totalAdditionalCount > 0
    }
}

nonisolated enum SecondBarCompactStripPlanner {
    static func plan(
        snapshots: [MenuBarItemSnapshot],
        accurateIconReadyIDs: Set<MenuBarItemSnapshot.ID>,
        maxVisibleItems: Int
    ) -> SecondBarCompactStripPlan {
        let hiddenItems = snapshots.filter { $0.zone == .hidden }
        let readyItems = hiddenItems.filter { accurateIconReadyIDs.contains($0.id) }
        let visibleLimit = max(0, maxVisibleItems)
        let visibleItems = Array(readyItems.prefix(visibleLimit))

        return SecondBarCompactStripPlan(
            visibleItems: visibleItems,
            hiddenOverflowCount: max(0, readyItems.count - visibleItems.count),
            needsAccurateIconCount: hiddenItems.count - readyItems.count
        )
    }
}
