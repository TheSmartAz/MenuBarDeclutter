import Foundation

nonisolated enum IconGroupRevealPlan: Equatable, Sendable {
    case noMatchingItems
    case noRevealNeeded
    case expandHiddenZone
    case revealAllHiddenItems
}

/// Resolves a group's matching rules into stable, de-duplicated snapshots.
///
/// The resolver intentionally works only with local menu bar snapshot metadata
/// already collected by Pro discovery. It does not request new permissions or
/// store app/item identities.
nonisolated struct IconGroupSnapshotResolver {
    private let matcher: IconGroupMatcher

    init(matcher: IconGroupMatcher = IconGroupMatcher()) {
        self.matcher = matcher
    }

    func matchedSnapshots(
        for group: IconGroup,
        snapshots: [MenuBarItemSnapshot],
        searchQuery: String = ""
    ) -> [MenuBarItemSnapshot] {
        let matchResult = matcher.matchGroup(group, snapshots: snapshots)
        let unique = uniqueSnapshots(from: matchResult)
        return filteredSnapshots(unique, searchQuery: searchQuery)
    }

    func revealPlan(
        for group: IconGroup,
        snapshots: [MenuBarItemSnapshot]
    ) -> IconGroupRevealPlan {
        revealPlan(for: matchedSnapshots(for: group, snapshots: snapshots))
    }

    func revealPlan(for snapshots: [MenuBarItemSnapshot]) -> IconGroupRevealPlan {
        guard !snapshots.isEmpty else { return .noMatchingItems }

        if snapshots.contains(where: { $0.zone == .alwaysHidden }) {
            return .revealAllHiddenItems
        }

        if snapshots.contains(where: { $0.zone == .hidden }) {
            return .expandHiddenZone
        }

        return .noRevealNeeded
    }

    private func uniqueSnapshots(from matchResult: IconGroupMatchResult) -> [MenuBarItemSnapshot] {
        let allSnapshots = matchResult.matchedItems.flatMap(\.snapshots)
        var seen: Set<MenuBarItemSnapshot.ID> = []
        return allSnapshots.filter { snapshot in
            seen.insert(snapshot.id).inserted
        }
    }

    private func filteredSnapshots(
        _ snapshots: [MenuBarItemSnapshot],
        searchQuery: String
    ) -> [MenuBarItemSnapshot] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return snapshots }

        return snapshots.filter { snapshot in
            searchableText(for: snapshot).localizedStandardContains(trimmed)
        }
    }

    private func searchableText(for snapshot: MenuBarItemSnapshot) -> String {
        [
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]
        .compactMap { value in
            DisplayString.firstNonEmpty([value])
        }
        .joined(separator: " ")
    }
}
