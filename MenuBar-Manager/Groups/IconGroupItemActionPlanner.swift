import Foundation

/// Pure helpers for turning discovered menu bar items into group membership
/// references. Keeps item identity logic local-only and testable.
nonisolated struct IconGroupItemActionPlanner {
    static func itemRef(from snapshot: MenuBarItemSnapshot) -> IconGroupItemRef {
        IconGroupItemRef(
            bundleIdentifier: cleaned(snapshot.bundleIdentifier),
            appName: cleaned(snapshot.owningApplicationName),
            snapshotStableID: cleaned(snapshot.id),
            titleContains: cleaned(snapshot.title),
            zone: snapshot.zone,
            manualLabel: displayName(for: snapshot)
        )
    }

    static func defaultGroupName(
        for snapshot: MenuBarItemSnapshot,
        existingGroups: [IconGroup]
    ) -> String {
        let baseName = displayName(for: snapshot) ?? "Menu Bar Item"
        let existingNames = Set(existingGroups.map { normalizedName($0.name) })
        guard existingNames.contains(normalizedName(baseName)) else {
            return baseName
        }

        var suffix = 2
        while existingNames.contains(normalizedName("\(baseName) \(suffix)")) {
            suffix += 1
        }
        return "\(baseName) \(suffix)"
    }

    static func adding(
        snapshot: MenuBarItemSnapshot,
        to group: IconGroup
    ) -> (group: IconGroup, didAdd: Bool) {
        guard !group.itemRefs.contains(where: { itemRef($0, matches: snapshot) }) else {
            return (group, false)
        }

        var updated = group
        updated.itemRefs.append(itemRef(from: snapshot))
        return (updated, true)
    }

    static func itemRef(
        _ ref: IconGroupItemRef,
        matches snapshot: MenuBarItemSnapshot
    ) -> Bool {
        if let refStableID = cleaned(ref.snapshotStableID),
           normalizedName(refStableID) == normalizedName(snapshot.id) {
            return true
        }

        if let refBundleID = cleaned(ref.bundleIdentifier),
           let snapshotBundleID = cleaned(snapshot.bundleIdentifier),
           normalizedName(refBundleID) == normalizedName(snapshotBundleID) {
            return true
        }

        if let refAppName = cleaned(ref.appName),
           let snapshotAppName = cleaned(snapshot.owningApplicationName),
           normalizedName(refAppName) == normalizedName(snapshotAppName),
           let refTitle = cleaned(ref.titleContains),
           let snapshotTitle = cleaned(snapshot.title),
           normalizedName(refTitle) == normalizedName(snapshotTitle) {
            return true
        }

        return false
    }

    private static func displayName(for snapshot: MenuBarItemSnapshot) -> String? {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ])
    }

    private static func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
