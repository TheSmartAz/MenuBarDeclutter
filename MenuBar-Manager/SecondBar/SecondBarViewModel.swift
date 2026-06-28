import Foundation
import Observation

@MainActor
@Observable
final class SecondBarViewModel {
    var selectedID: MenuBarItemSnapshot.ID?

    func items(
        from snapshots: [MenuBarItemSnapshot],
        settingsStore: SettingsStore,
        query: String = ""
    ) -> [MenuBarItemSnapshot] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return snapshots
            .filter { snapshot in
                switch snapshot.zone {
                case .hidden:
                    settingsStore.secondBarShowHiddenItems
                case .alwaysHidden:
                    settingsStore.secondBarShowAlwaysHiddenItems
                case .visible, .unknown:
                    false
                }
            }
            .filter { snapshot in
                guard !normalizedQuery.isEmpty else { return true }
                return searchableText(for: snapshot)
                    .localizedStandardContains(normalizedQuery)
            }
            .sorted(by: sortSnapshots)
    }

    func selectFirstItemIfNeeded(_ items: [MenuBarItemSnapshot]) {
        if let selectedID, items.contains(where: { $0.id == selectedID }) {
            return
        }
        selectedID = items.first?.id
    }

    func moveSelection(by delta: Int, in items: [MenuBarItemSnapshot]) {
        guard !items.isEmpty else {
            selectedID = nil
            return
        }

        let ids = items.map(\.id)
        let currentIndex = selectedID.flatMap { ids.firstIndex(of: $0) } ?? -1
        let proposed = currentIndex + delta
        let clamped = min(max(proposed, 0), ids.count - 1)
        selectedID = ids[clamped]
    }

    private func sortSnapshots(_ lhs: MenuBarItemSnapshot, _ rhs: MenuBarItemSnapshot) -> Bool {
        if lhs.zone != rhs.zone {
            return zoneSortIndex(lhs.zone) < zoneSortIndex(rhs.zone)
        }

        let leftName = displayTitle(for: lhs)
        let rightName = displayTitle(for: rhs)
        let comparison = leftName.localizedStandardCompare(rightName)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }

    private func zoneSortIndex(_ zone: MenuBarZone) -> Int {
        switch zone {
        case .hidden:
            0
        case .alwaysHidden:
            1
        case .visible:
            2
        case .unknown:
            3
        }
    }

    private func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        [
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .first ?? "Menu Bar Item"
    }

    private func searchableText(for snapshot: MenuBarItemSnapshot) -> String {
        [
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier,
            snapshot.role,
            snapshot.subrole
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}
