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

    var id: String { snapshot.id }

    var appName: String {
        firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.bundleIdentifier,
            snapshot.title
        ]) ?? "Unknown App"
    }

    var displayTitle: String {
        firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }

    var displaySubtitle: String {
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

        return details.first { $0 != displayTitle } ?? snapshot.zone.displayName
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed?.isEmpty == false ? trimmed : nil
            }
            .first
    }
}

struct SearchService {
    func results(
        from snapshots: [MenuBarItemSnapshot],
        query: String,
        limit: Int = 20
    ) -> [MenuBarSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = normalize(trimmedQuery)

        let results = snapshots.compactMap { snapshot -> MenuBarSearchResult? in
            if normalizedQuery.isEmpty {
                return MenuBarSearchResult(
                    snapshot: snapshot,
                    score: 100 + zoneBoost(for: snapshot.zone),
                    matchReason: .recent
                )
            }

            guard let match = bestMatch(for: snapshot, normalizedQuery: normalizedQuery) else {
                return nil
            }

            return MenuBarSearchResult(
                snapshot: snapshot,
                score: match.score + zoneBoost(for: snapshot.zone),
                matchReason: match.reason
            )
        }

        return results
            .sorted(by: isHigherRanked)
            .prefix(max(0, limit))
            .map { $0 }
    }

    private func bestMatch(
        for snapshot: MenuBarItemSnapshot,
        normalizedQuery: String
    ) -> (score: Int, reason: MenuBarSearchMatchReason)? {
        let appName = normalize(snapshot.owningApplicationName)
        let title = normalize(snapshot.title)
        let bundleIdentifier = normalize(snapshot.bundleIdentifier)

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

        let leftName = lhs.displayTitle
        let rightName = rhs.displayTitle
        let comparison = leftName.localizedStandardCompare(rightName)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }

    private func normalize(_ value: String?) -> String {
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
}
