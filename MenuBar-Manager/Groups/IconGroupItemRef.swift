import Foundation

/// A reference to a menu bar item within a group. Supports multiple matching
/// strategies: bundle identifier, stable snapshot ID, title/app name contains,
/// zone, or a manual label.
nonisolated struct IconGroupItemRef: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var bundleIdentifier: String?
    var appName: String?
    var snapshotStableID: String?
    var titleContains: String?
    var zone: MenuBarZone?
    var manualLabel: String?

    init(
        id: UUID = UUID(),
        bundleIdentifier: String? = nil,
        appName: String? = nil,
        snapshotStableID: String? = nil,
        titleContains: String? = nil,
        zone: MenuBarZone? = nil,
        manualLabel: String? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.snapshotStableID = snapshotStableID
        self.titleContains = titleContains
        self.zone = zone
        self.manualLabel = manualLabel
    }

    /// Whether this ref has any usable matching criteria.
    var hasMatchableCriteria: Bool {
        (bundleIdentifier?.isEmpty == false)
            || (snapshotStableID?.isEmpty == false)
            || (titleContains?.isEmpty == false)
            || (appName?.isEmpty == false)
            || zone != nil
    }

    /// Human-readable display label for UI.
    var displayLabel: String {
        if let manualLabel, !manualLabel.isEmpty { return manualLabel }
        if let bundleIdentifier, !bundleIdentifier.isEmpty { return bundleIdentifier }
        if let appName, !appName.isEmpty { return appName }
        if let titleContains, !titleContains.isEmpty { return titleContains }
        if let snapshotStableID, !snapshotStableID.isEmpty { return snapshotStableID }
        return "Unknown"
    }
}
