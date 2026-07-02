import Foundation

enum MenuBarSearchMatchReason: String, Sendable {
    case recent
    case exactAppName
    case exactTitle
    case prefix
    case fuzzyContains
    case bundleIdentifier

    var displayName: String {
        switch self {
        case .recent:
            "Recent"
        case .exactAppName:
            "Exact App Match"
        case .exactTitle:
            "Exact Title Match"
        case .prefix:
            "Prefix Match"
        case .fuzzyContains:
            "Contains"
        case .bundleIdentifier:
            "Bundle ID"
        }
    }
}

struct MenuBarSearchResult: Identifiable, Equatable, Sendable {
    let snapshot: MenuBarItemSnapshot
    let score: Int
    let matchReason: MenuBarSearchMatchReason

    /// Pre-computed display fields. The previous implementation rebuilt these on every
    /// read — and the sort comparator (`isHigherRanked`) re-derived `displayTitle`
    /// for both sides of each comparison, allocating 1-3 trimmed strings per call.
    /// Storing them once at construction time reduces the comparator to a single
    /// `localizedStandardCompare` and makes view reads O(1).
    let appName: String
    let displayTitle: String
    let displaySubtitle: String

    var id: String { snapshot.id }

    init(
        snapshot: MenuBarItemSnapshot,
        score: Int,
        matchReason: MenuBarSearchMatchReason
    ) {
        self.snapshot = snapshot
        self.score = score
        self.matchReason = matchReason
        self.appName = DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.bundleIdentifier,
            snapshot.title
        ]) ?? "Unknown App"

        let displayTitle = DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
        self.displayTitle = displayTitle

        let details = [
            snapshot.title,
            snapshot.bundleIdentifier,
            snapshot.role,
            snapshot.subrole
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        self.displaySubtitle = details.first { $0 != displayTitle } ?? snapshot.zone.displayName
    }
}

/// Pre-normalized per-snapshot index for `SearchService`. Building this once per
/// accessibility scan and querying it across keystrokes avoids the dominant
/// `String.folding(options: [.caseInsensitive, .diacriticInsensitive])` per-keystroke
/// allocation churn identified by the refactoring audit.
struct SearchIndex: Sendable {
    struct Entry: Sendable {
        let snapshot: MenuBarItemSnapshot
        let normalizedName: String
        let normalizedTitle: String
        let normalizedBundleID: String
    }

    private(set) var entries: [Entry] = []

    init(snapshots: [MenuBarItemSnapshot] = []) {
        var entries: [Entry] = []
        entries.reserveCapacity(snapshots.count)
        for snapshot in snapshots {
            entries.append(
                Entry(
                    snapshot: snapshot,
                    normalizedName: SearchService.normalize(snapshot.owningApplicationName),
                    normalizedTitle: SearchService.normalize(snapshot.title),
                    normalizedBundleID: SearchService.normalize(snapshot.bundleIdentifier)
                )
            )
        }
        self.entries = entries
    }

    var isEmpty: Bool { entries.isEmpty }
    var count: Int { entries.count }
}

struct SearchService {
    func results(
        from snapshots: [MenuBarItemSnapshot],
        query: String,
        filter: MenuBarItemCollectionFilter = .all,
        memoryStore: MenuBarItemMemoryStore? = nil,
        rankingContext: SearchRankingContext = .init(),
        limit: Int = 20
    ) -> [MenuBarSearchResult] {
        return results(
            from: SearchIndex(snapshots: snapshots),
            query: query,
            filter: filter,
            memoryStore: memoryStore,
            rankingContext: rankingContext,
            limit: limit
        )
    }

    func results(
        from index: SearchIndex,
        query: String,
        filter: MenuBarItemCollectionFilter = .all,
        memoryStore: MenuBarItemMemoryStore? = nil,
        rankingContext: SearchRankingContext = .init(),
        limit: Int = 20
    ) -> [MenuBarSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = Self.normalize(trimmedQuery)

        let entries = index.entries.filter { entry in
            filter.includes(entry.snapshot, memoryStore: memoryStore)
        }

        let results = entries.compactMap { entry -> MenuBarSearchResult? in
            if normalizedQuery.isEmpty {
                return MenuBarSearchResult(
                    snapshot: entry.snapshot,
                    score: 100 + rankingBoost(for: entry.snapshot, memoryStore: memoryStore, context: rankingContext),
                    matchReason: .recent
                )
            }

            guard let match = bestMatch(
                entry: entry,
                normalizedQuery: normalizedQuery
            ) else {
                return nil
            }

            return MenuBarSearchResult(
                snapshot: entry.snapshot,
                score: match.score + rankingBoost(for: entry.snapshot, memoryStore: memoryStore, context: rankingContext),
                matchReason: match.reason
            )
        }

        return Array(sorted(results, filter: filter, memoryStore: memoryStore).prefix(max(0, limit)))
    }

    private func sorted(
        _ results: [MenuBarSearchResult],
        filter: MenuBarItemCollectionFilter,
        memoryStore: MenuBarItemMemoryStore?
    ) -> [MenuBarSearchResult] {
        guard filter == .recent,
              let memoryStore else {
            return results.sorted(by: isHigherRanked)
        }

        return results.sorted { lhs, rhs in
            let leftRank = memoryStore.recentRank(for: lhs.snapshot) ?? Int.max
            let rightRank = memoryStore.recentRank(for: rhs.snapshot) ?? Int.max
            if leftRank != rightRank {
                return leftRank < rightRank
            }
            return isHigherRanked(lhs, rhs)
        }
    }

    private func bestMatch(
        entry: SearchIndex.Entry,
        normalizedQuery: String
    ) -> (score: Int, reason: MenuBarSearchMatchReason)? {
        let appName = entry.normalizedName
        let title = entry.normalizedTitle
        let bundleIdentifier = entry.normalizedBundleID

        if appName == normalizedQuery, !appName.isEmpty {
            return (1000, .exactAppName)
        }

        if title == normalizedQuery, !title.isEmpty {
            return (930, .exactTitle)
        }

        let prefixFields = [appName, title].filter { !$0.isEmpty }
        if prefixFields.contains(where: { $0.hasPrefix(normalizedQuery) }) {
            return (820, .prefix)
        }

        if !bundleIdentifier.isEmpty, bundleIdentifier.hasPrefix(normalizedQuery) {
            return (760, .bundleIdentifier)
        }

        let fuzzyFields = [appName, title].filter { !$0.isEmpty }
        if fuzzyFields.contains(where: { $0.contains(normalizedQuery) }) {
            return (620, .fuzzyContains)
        }

        if !bundleIdentifier.isEmpty, bundleIdentifier.contains(normalizedQuery) {
            return (540, .bundleIdentifier)
        }

        if fuzzyFields.contains(where: { containsCharactersInOrder(normalizedQuery, in: $0) }) {
            return (420, .fuzzyContains)
        }

        return nil
    }

    private func isHigherRanked(_ lhs: MenuBarSearchResult, _ rhs: MenuBarSearchResult) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }

        if lhs.snapshot.scanTimestamp != rhs.snapshot.scanTimestamp {
            return lhs.snapshot.scanTimestamp > rhs.snapshot.scanTimestamp
        }

        // `displayTitle` is now a pre-computed `let` field; this comparator
        // no longer allocates per comparison.
        let comparison = lhs.displayTitle.localizedStandardCompare(rhs.displayTitle)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }

    static func normalize(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            ?? ""
    }

    private func containsCharactersInOrder(_ query: String, in candidate: String) -> Bool {
        guard !query.isEmpty else { return true }

        var remaining = query[...]
        for character in candidate {
            if remaining.first == character {
                remaining.removeFirst()
                if remaining.isEmpty {
                    return true
                }
            }
        }
        return false
    }

    private func zoneBoost(for zone: MenuBarZone) -> Int {
        switch zone {
        case .alwaysHidden:
            60
        case .hidden:
            50
        case .visible:
            0
        case .unknown:
            -10
        }
    }

    private func rankingBoost(
        for snapshot: MenuBarItemSnapshot,
        memoryStore: MenuBarItemMemoryStore?,
        context: SearchRankingContext
    ) -> Int {
        var boost = zoneBoost(for: snapshot.zone)

        if memoryStore?.isFavorite(snapshot) == true {
            boost += 90
        }

        if let recentRank = memoryStore?.recentRank(for: snapshot) {
            boost += max(20, 75 - min(recentRank, 10) * 5)
        }

        if context.isNewItem(snapshot) {
            boost += 70
        }

        if context.isStale(snapshot) {
            boost -= 160
        }

        return boost
    }
}

nonisolated struct SearchRankingContext: Equatable, Sendable {
    var newItemStorageKeys: Set<String>
    var staleBefore: Date?

    init(
        newItemStorageKeys: Set<String> = [],
        staleBefore: Date? = nil
    ) {
        self.newItemStorageKeys = newItemStorageKeys
        self.staleBefore = staleBefore
    }

    func isNewItem(_ snapshot: MenuBarItemSnapshot) -> Bool {
        newItemStorageKeys.contains(snapshot.id)
            || newItemStorageKeys.contains(NewMenuBarItemInboxDetector.storageKey(for: snapshot))
    }

    func isStale(_ snapshot: MenuBarItemSnapshot) -> Bool {
        guard let staleBefore else { return false }
        return snapshot.scanTimestamp < staleBefore
    }
}

nonisolated enum SearchKeyboardAction: Equatable, Sendable {
    case revealSelected
    case showSelectedInSecondBar
    case openOwningApp
    case revealRelevantZone
}

nonisolated struct SearchKeyboardModifiers: OptionSet, Equatable, Sendable {
    let rawValue: Int

    static let command = SearchKeyboardModifiers(rawValue: 1 << 0)
    static let option = SearchKeyboardModifiers(rawValue: 1 << 1)
    static let shift = SearchKeyboardModifiers(rawValue: 1 << 2)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

nonisolated struct SearchKeyboardActionRouter: Sendable {
    func returnAction(for modifiers: SearchKeyboardModifiers) -> SearchKeyboardAction {
        if modifiers.contains(.command) {
            return .showSelectedInSecondBar
        }

        if modifiers.contains(.option) {
            return .openOwningApp
        }

        if modifiers.contains(.shift) {
            return .revealRelevantZone
        }

        return .revealSelected
    }
}
