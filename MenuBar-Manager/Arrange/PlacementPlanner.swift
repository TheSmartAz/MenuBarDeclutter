import Foundation

nonisolated enum PlacementRecommendation: String, CaseIterable, Identifiable, Sendable {
    case keepVisible
    case moveToHidden
    case moveToAlwaysHidden
    case reviewNewItem
    case staleMetadata
    case likelySystemItem
    case noRecommendation
    case needsManualPlacement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepVisible:
            "Keep Visible"
        case .moveToHidden:
            "Move to Hidden"
        case .moveToAlwaysHidden:
            "Move to Always Hidden"
        case .reviewNewItem:
            "Review New Item"
        case .staleMetadata:
            "Refresh Scan"
        case .likelySystemItem:
            "Handle Carefully"
        case .noRecommendation:
            "No Recommendation"
        case .needsManualPlacement:
            "Place Manually"
        }
    }

    var recommendedZone: MenuBarZone? {
        switch self {
        case .keepVisible:
            .visible
        case .moveToHidden:
            .hidden
        case .moveToAlwaysHidden:
            .alwaysHidden
        default:
            nil
        }
    }
}

nonisolated enum PlacementItemPreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case keepVisible
    case hide
    case alwaysHide
    case reviewLater

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepVisible:
            "Keep Visible"
        case .hide:
            "Hide"
        case .alwaysHide:
            "Always Hide"
        case .reviewLater:
            "Review Later"
        }
    }

    var systemImage: String {
        switch self {
        case .keepVisible:
            "eye"
        case .hide:
            "eye.slash"
        case .alwaysHide:
            "lock"
        case .reviewLater:
            "tray"
        }
    }
}

nonisolated enum PlacementPlanActionHint: String, CaseIterable, Identifiable, Sendable {
    case highlight
    case showInSecondBar
    case openOwningApp
    case createGroup
    case dryRunAssistedMove

    var id: String { rawValue }
}

nonisolated struct PlacementPlanItem: Identifiable, Equatable, Sendable {
    let id: String
    let storageKey: String
    let displayTitle: String
    let displaySubtitle: String
    let currentZone: MenuBarZone
    let recommendation: PlacementRecommendation
    let recommendedZone: MenuBarZone?
    let preference: PlacementItemPreference?
    let isNewItem: Bool
    let isFavorite: Bool
    let reason: String
    let manualInstruction: String
    let actionHints: [PlacementPlanActionHint]
    let isDiagnosticsRedacted: Bool
}

nonisolated struct PlacementPlan: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case ready
        case proModeOff
        case accessibilityDiscoveryOff
        case accessibilityPermissionMissing
        case safeMode
        case noScan
        case staleScan
    }

    let state: State
    let items: [PlacementPlanItem]
    let generatedAt: Date

    var recommendationCounts: [PlacementRecommendation: Int] {
        items.reduce(into: [:]) { counts, item in
            counts[item.recommendation, default: 0] += 1
        }
    }
}

nonisolated struct PlacementPlannerContext: Equatable, Sendable {
    let proModeEnabled: Bool
    let accessibilityDiscoveryEnabled: Bool
    let accessibilityPermissionGranted: Bool
    let safeModeActive: Bool
    let snapshots: [MenuBarItemSnapshot]
    let lastScanDate: Date?
    let now: Date
    let staleInterval: TimeInterval
    let alwaysHiddenEnabled: Bool
    let newItemIDs: Set<String>
    let favoriteItemIDs: Set<String>
    let itemPreferences: [String: PlacementItemPreference]

    init(
        proModeEnabled: Bool,
        accessibilityDiscoveryEnabled: Bool,
        accessibilityPermissionGranted: Bool,
        safeModeActive: Bool,
        snapshots: [MenuBarItemSnapshot],
        lastScanDate: Date?,
        now: Date = Date(),
        staleInterval: TimeInterval = 300,
        alwaysHiddenEnabled: Bool,
        newItemIDs: Set<String> = [],
        favoriteItemIDs: Set<String> = [],
        itemPreferences: [String: PlacementItemPreference] = [:]
    ) {
        self.proModeEnabled = proModeEnabled
        self.accessibilityDiscoveryEnabled = accessibilityDiscoveryEnabled
        self.accessibilityPermissionGranted = accessibilityPermissionGranted
        self.safeModeActive = safeModeActive
        self.snapshots = snapshots
        self.lastScanDate = lastScanDate
        self.now = now
        self.staleInterval = staleInterval
        self.alwaysHiddenEnabled = alwaysHiddenEnabled
        self.newItemIDs = newItemIDs
        self.favoriteItemIDs = favoriteItemIDs
        self.itemPreferences = itemPreferences
    }
}

nonisolated struct PlacementPlanner {
    func plan(context: PlacementPlannerContext) -> PlacementPlan {
        let state = state(for: context)
        guard state == .ready || state == .staleScan else {
            return PlacementPlan(state: state, items: [], generatedAt: context.now)
        }

        let items = context.snapshots.map { snapshot in
            planItem(for: snapshot, context: context, forceStale: state == .staleScan)
        }

        return PlacementPlan(state: state, items: items, generatedAt: context.now)
    }

    private func state(for context: PlacementPlannerContext) -> PlacementPlan.State {
        if context.safeModeActive {
            return .safeMode
        }

        if !context.proModeEnabled {
            return .proModeOff
        }

        if !context.accessibilityDiscoveryEnabled {
            return .accessibilityDiscoveryOff
        }

        if !context.accessibilityPermissionGranted {
            return .accessibilityPermissionMissing
        }

        guard let lastScanDate = context.lastScanDate,
              !context.snapshots.isEmpty else {
            return .noScan
        }

        if context.now.timeIntervalSince(lastScanDate) > context.staleInterval {
            return .staleScan
        }

        return .ready
    }

    private func planItem(
        for snapshot: MenuBarItemSnapshot,
        context: PlacementPlannerContext,
        forceStale: Bool
    ) -> PlacementPlanItem {
        let recommendation: PlacementRecommendation
        let reason: String
        let storageKey = NewMenuBarItemInboxDetector.storageKey(for: snapshot)
        let reviewID = NewMenuBarItemInboxDetector.reviewID(for: snapshot)
        let isNewItem = context.newItemIDs.contains(snapshot.id)
            || context.newItemIDs.contains(storageKey)
            || context.newItemIDs.contains(reviewID)
        let isFavorite = context.favoriteItemIDs.contains(snapshot.id) || context.favoriteItemIDs.contains(storageKey)
        let preference = context.itemPreferences[reviewID]
            ?? context.itemPreferences[storageKey]
            ?? context.itemPreferences[snapshot.id]

        if forceStale {
            recommendation = .staleMetadata
            reason = "The last scan is stale. Refresh before changing placement."
        } else if snapshot.isLikelySystemItem {
            recommendation = .likelySystemItem
            reason = "Likely system items should be adjusted in Apple settings when possible."
        } else if let preference {
            (recommendation, reason) = recommendationForPreference(
                preference,
                alwaysHiddenEnabled: context.alwaysHiddenEnabled
            )
        } else if isNewItem {
            recommendation = .reviewNewItem
            reason = "This item is newly discovered and needs a placement decision."
        } else if isFavorite {
            recommendation = .keepVisible
            reason = "Favorite or recent workflow items should stay easy to reach."
        } else {
            switch snapshot.zone {
            case .visible:
                recommendation = .keepVisible
                reason = "This item is already on the visible side."
            case .hidden:
                recommendation = .moveToHidden
                reason = "This item is already in the normal hidden zone."
            case .alwaysHidden:
                recommendation = context.alwaysHiddenEnabled ? .moveToAlwaysHidden : .needsManualPlacement
                reason = context.alwaysHiddenEnabled
                    ? "This item is already in the always-hidden zone."
                    : "Always-hidden placement is off; choose a manual destination."
            case .unknown:
                recommendation = .needsManualPlacement
                reason = "The item does not have enough geometry for an automatic zone recommendation."
            }
        }

        return PlacementPlanItem(
            id: snapshot.id,
            storageKey: storageKey,
            displayTitle: Self.displayTitle(for: snapshot),
            displaySubtitle: Self.displaySubtitle(for: snapshot),
            currentZone: snapshot.zone,
            recommendation: recommendation,
            recommendedZone: recommendation.recommendedZone,
            preference: preference,
            isNewItem: isNewItem,
            isFavorite: isFavorite,
            reason: reason,
            manualInstruction: instruction(for: snapshot, recommendation: recommendation),
            actionHints: actionHints(for: snapshot, recommendation: recommendation),
            isDiagnosticsRedacted: true
        )
    }

    private static func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        let candidates = [
            snapshot.title,
            snapshot.owningApplicationName,
            snapshot.bundleIdentifier
        ]

        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Menu bar item"
    }

    private static func displaySubtitle(for snapshot: MenuBarItemSnapshot) -> String {
        var parts: [String] = []
        if let owner = snapshot.owningApplicationName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !owner.isEmpty,
           owner != displayTitle(for: snapshot) {
            parts.append(owner)
        }
        parts.append(snapshot.zone.displayName)

        if snapshot.frame == nil {
            parts.append("Missing frame")
        }

        return parts.joined(separator: " - ")
    }

    private func actionHints(
        for snapshot: MenuBarItemSnapshot,
        recommendation: PlacementRecommendation
    ) -> [PlacementPlanActionHint] {
        guard recommendation != .staleMetadata else { return [] }

        var hints: [PlacementPlanActionHint] = []
        if snapshot.frame != nil {
            hints.append(.highlight)
        }
        hints.append(.showInSecondBar)
        if snapshot.owningProcessIdentifier != nil {
            hints.append(.openOwningApp)
        }
        if !snapshot.isLikelySystemItem {
            hints.append(.createGroup)
            hints.append(.dryRunAssistedMove)
        }
        return hints
    }

    private func instruction(
        for snapshot: MenuBarItemSnapshot,
        recommendation: PlacementRecommendation
    ) -> String {
        switch recommendation {
        case .keepVisible:
            "Keep this item to the right of the primary separator."
        case .moveToHidden:
            "Hold Command and drag this item to the hidden side of the primary separator."
        case .moveToAlwaysHidden:
            "Hold Command and drag this item beyond the always-hidden separator."
        case .reviewNewItem:
            "Review this item, then choose visible, hidden, or always-hidden placement manually."
        case .staleMetadata:
            "Refresh Pro Discovery before following placement instructions."
        case .likelySystemItem:
            "Prefer Apple settings or Control Center for this item before moving it manually."
        case .needsManualPlacement:
            "Use the Arrange guide and choose a manual destination."
        case .noRecommendation:
            "No placement change is suggested."
        }
    }

    private func recommendationForPreference(
        _ preference: PlacementItemPreference,
        alwaysHiddenEnabled: Bool
    ) -> (PlacementRecommendation, String) {
        switch preference {
        case .keepVisible:
            (.keepVisible, "You marked this item to stay visible.")
        case .hide:
            (.moveToHidden, "You marked this item for the hidden area.")
        case .alwaysHide:
            alwaysHiddenEnabled
                ? (.moveToAlwaysHidden, "You marked this item for the always-hidden area.")
                : (.needsManualPlacement, "You marked this item always-hidden, but the always-hidden area is off.")
        case .reviewLater:
            (.reviewNewItem, "You marked this item for later review.")
        }
    }
}
