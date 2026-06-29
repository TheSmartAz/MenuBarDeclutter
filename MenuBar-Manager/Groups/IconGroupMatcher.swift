import Foundation

/// Matches `IconGroupItemRef` values against `MenuBarItemSnapshot` values.
///
/// Matching rules (in priority order):
/// 1. Prefer bundleIdentifier.
/// 2. Then snapshotStableID.
/// 3. Then title/appName fallback.
/// If multiple items match, preserve deterministic ordering.
/// Unknown/missing items are shown as unavailable, not deleted.
nonisolated struct IconGroupMatcher {
    /// Match a single item ref against snapshots.
    func match(ref: IconGroupItemRef, snapshots: [MenuBarItemSnapshot]) -> [MenuBarItemSnapshot] {
        // 1. Bundle identifier
        if let bundleID = ref.bundleIdentifier, !bundleID.isEmpty {
            let matches = snapshots.filter { $0.bundleIdentifier == bundleID }
            if !matches.isEmpty { return matches }
        }

        // 2. Snapshot stable ID
        if let stableID = ref.snapshotStableID, !stableID.isEmpty {
            let matches = snapshots.filter { $0.id == stableID }
            if !matches.isEmpty { return matches }
        }

        // 3. Title contains
        if let titleContains = ref.titleContains, !titleContains.isEmpty {
            let matches = snapshots.filter { snapshot in
                snapshot.title?.localizedCaseInsensitiveContains(titleContains) == true
            }
            if !matches.isEmpty { return matches }
        }

        // 4. App name
        if let appName = ref.appName, !appName.isEmpty {
            let matches = snapshots.filter {
                $0.owningApplicationName?.localizedCaseInsensitiveContains(appName) == true
            }
            if !matches.isEmpty { return matches }
        }

        // 5. Zone
        if let zone = ref.zone {
            let matches = snapshots.filter { $0.zone == zone }
            if !matches.isEmpty { return matches }
        }

        return []
    }

    /// Match all item refs in a group against snapshots.
    func matchGroup(_ group: IconGroup, snapshots: [MenuBarItemSnapshot]) -> IconGroupMatchResult {
        var matched: [(ref: IconGroupItemRef, snapshots: [MenuBarItemSnapshot])] = []
        var unavailable: [IconGroupItemRef] = []

        for ref in group.itemRefs {
            let matches = match(ref: ref, snapshots: snapshots)
            if matches.isEmpty {
                unavailable.append(ref)
            } else {
                matched.append((ref, matches))
            }
        }

        return IconGroupMatchResult(
            groupID: group.id,
            matchedItems: matched,
            unavailableRefs: unavailable
        )
    }
}

/// Result of matching a group against snapshots.
nonisolated struct IconGroupMatchResult: Equatable {
    let groupID: UUID
    let matchedItems: [(ref: IconGroupItemRef, snapshots: [MenuBarItemSnapshot])]
    let unavailableRefs: [IconGroupItemRef]

    var totalRefs: Int { matchedItems.count + unavailableRefs.count }
    var matchedCount: Int { matchedItems.count }
    var unavailableCount: Int { unavailableRefs.count }
    var allAvailable: Bool { unavailableRefs.isEmpty }

    static func == (lhs: IconGroupMatchResult, rhs: IconGroupMatchResult) -> Bool {
        lhs.groupID == rhs.groupID
            && lhs.unavailableRefs == rhs.unavailableRefs
            && lhs.matchedItems.count == rhs.matchedItems.count
    }
}
