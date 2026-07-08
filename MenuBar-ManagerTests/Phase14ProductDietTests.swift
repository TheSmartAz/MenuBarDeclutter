import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Phase 14 product diet")
struct Phase14ProductDietTests {
    @Test func visibleSidebarUsesFocusedSectionsWithWorkspacesPreviewPromoted() {
        #expect(SettingsSection.visibleSidebarSections == [
            .general,
            .hideReveal,
            .arrange,
            .findRescue,
            .workspacesPreview,
            .privacy,
            .recovery,
            .advanced
        ])
        #expect(SettingsSection.visibleSidebarSections.count == 8)
    }

    @Test func visibleSidebarTitlesExcludeHeavyAdvancedSurfaces() {
        let titles = SettingsSection.visibleSidebarSections.map(\.title)
        #expect(titles == [
            "General",
            "Hide & Reveal",
            "Arrange",
            "Find & Rescue",
            "Workspaces",
            "Privacy",
            "Recovery",
            "Advanced"
        ])

        let heavySurfaces = [
            "Private Access",
            "Groups",
            "Hotkeys",
            "Profiles",
            "Automation",
            "Import / Export",
            "Spacing Labs",
            "Icon Moving",
            "Dogfood"
        ]
        #expect(heavySurfaces.allSatisfy { !titles.contains($0) })
    }

    @Test func hiddenSettingsRoutesAreDerivedFromAllNonSidebarSections() {
        let visible = Set(SettingsSection.visibleSidebarSections)
        let hidden = Set(SettingsSection.allCases).subtracting(visible)

        #expect(hidden == [
            .menuBarItems,
            .behavior,
            .layout,
            .search,
            .secondBar,
            .privateAccess,
            .groups,
            .hotkeys,
            .profiles,
            .automation,
            .importExport,
            .diagnostics
        ])

        for section in hidden {
            #expect(!visible.contains(section))
            #expect(!SettingsSection.visibleSidebarSections.map(\.rawValue).contains(section.rawValue))
        }
    }

    @Test func moreSidebarGroupsKeepAdvancedSurfacesOrganized() {
        #expect(SettingsSection.moreSidebarGroups.map(\.title) == [
            "Surfaces",
            "Control",
            "System"
        ])

        #expect(SettingsSection.moreSidebarGroups.map(\.sections) == [
            [.menuBarItems, .search, .secondBar, .groups],
            [.hotkeys, .profiles, .privateAccess, .automation],
            [.importExport, .diagnostics, .layout]
        ])

        let groupedSections = SettingsSection.moreSidebarGroups.flatMap(\.sections)
        #expect(groupedSections == SettingsSection.moreSidebarSections)
        #expect(Set(groupedSections).count == groupedSections.count)
    }

    @Test func advancedDirectoryExcludesSidebarDuplicatePages() {
        let entries = AdvancedFeatureDirectory.visibleEntries(showDogfood: true)
        let sidebarSections = Set(SettingsSection.visibleSidebarSections + SettingsSection.moreSidebarSections)
        let duplicateTitles = [
            "Workspaces",
            "Profiles",
            "Smart Triggers",
            "Dynamic Hotkeys",
            "Private Access",
            "Groups",
            "Automation",
            "Import / Export",
            "Diagnostics",
            "Dogfood",
            "Spacing Labs"
        ]

        #expect(entries.compactMap(\.destination).allSatisfy { !sidebarSections.contains($0) })
        #expect(duplicateTitles.allSatisfy { !entries.map(\.title).contains($0) })
        #expect(entries.first { $0.title == "Icon Moving" }?.destination == nil)
        #expect(entries.map(\.title) == [
            "Icon Moving",
            "Stable Bulk Moving",
            "Visual Item Capture"
        ])
    }

    @Test func advancedSearchAliasesHideDogfoodUntilDogfoodStateExists() {
        let defaultEntries = AdvancedFeatureDirectory.searchAliasEntries(showDogfood: false)
        #expect(!defaultEntries.map(\.title).contains("Dogfood"))

        let dogfoodEntries = AdvancedFeatureDirectory.searchAliasEntries(showDogfood: true)
        #expect(dogfoodEntries.map(\.title).contains("Dogfood"))
        #expect(dogfoodEntries.first { $0.title == "Dogfood" }?.destination == .diagnostics)
    }

    @Test func featureVisibilityClassifiesGuidedPlannerAndAssistedMove() {
        let guided = FeatureVisibility.visibility(for: .guidedManualArrange)
        #expect(guided.area == .arrange)
        #expect(guided.status == .stable)
        #expect(guided.isVisibleInMainFlow)

        let planner = FeatureVisibility.visibility(for: .placementPlanner)
        #expect(planner.area == .arrange)
        #expect(planner.status == .preview)

        let assisted = FeatureVisibility.visibility(for: .assistedMove)
        #expect(assisted.area == .arrange)
        #expect(assisted.status == .experimental)

        let spacing = FeatureVisibility.visibility(for: .spacingLabs)
        #expect(spacing.area == .advanced)
        #expect(spacing.status == .labs)
        #expect(!spacing.isVisibleInMainFlow)
    }

    @Test func deferredFeatureCopyTargetsCurrentReleaseLine() {
        let bulkMoving = FeatureVisibility.visibility(for: .stableBulkMoving)

        #expect(containsReleaseToken(bulkMoving.summary, "v0.1.10"))
        #expect(!containsReleaseToken(bulkMoving.summary, "v0.1.1"))
    }

    private func containsReleaseToken(_ summary: String, _ release: String) -> Bool {
        let escapedRelease = NSRegularExpression.escapedPattern(for: release)
        let pattern = "(^|[^A-Za-z0-9])\(escapedRelease)($|[^A-Za-z0-9])"
        return summary.range(of: pattern, options: .regularExpression) != nil
    }

    @Test func guidedArrangeStepsMatchPhase15Cards() {
        #expect(ArrangeStep.guidedManualSteps.map(\.title) == [
            "How menu bar hiding works",
            "Step 1: place the control item",
            "Step 2: place the separator",
            "Step 3: move clutter into the hidden area",
            "Step 4: test collapse",
            "Step 5: test reveal",
            "Optional: always-hidden area",
            "Need help? Reset layout or open Recovery"
        ])
    }
}

@Suite("PlacementPlanner")
struct PlacementPlannerTests {
    @Test func gatesReturnDegradedStatesWithoutItems() {
        let planner = PlacementPlanner()
        let base = PlacementPlannerContext(
            proModeEnabled: false,
            accessibilityDiscoveryEnabled: false,
            accessibilityPermissionGranted: false,
            safeModeActive: false,
            snapshots: [Self.snapshot(id: "item", zone: .visible)],
            lastScanDate: Date(),
            now: Date(),
            alwaysHiddenEnabled: false
        )

        #expect(planner.plan(context: base).state == .proModeOff)
        #expect(planner.plan(context: base).items.isEmpty)

        let safeMode = PlacementPlannerContext(
            proModeEnabled: true,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermissionGranted: true,
            safeModeActive: true,
            snapshots: [Self.snapshot(id: "item", zone: .visible)],
            lastScanDate: Date(),
            now: Date(),
            alwaysHiddenEnabled: false
        )
        #expect(planner.plan(context: safeMode).state == .safeMode)
    }

    @Test func recommendationsRespectZoneNewItemsAndSystemCaution() {
        let now = Date(timeIntervalSince1970: 1_000)
        let visible = Self.snapshot(id: "visible", zone: .visible)
        let hidden = Self.snapshot(id: "hidden", zone: .hidden)
        let system = Self.snapshot(id: "system", zone: .visible, isLikelySystemItem: true)
        let newlySeen = Self.snapshot(id: "new", zone: .unknown)

        let plan = PlacementPlanner().plan(context: PlacementPlannerContext(
            proModeEnabled: true,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermissionGranted: true,
            safeModeActive: false,
            snapshots: [visible, hidden, system, newlySeen],
            lastScanDate: now,
            now: now,
            alwaysHiddenEnabled: true,
            newItemIDs: [newlySeen.id],
            favoriteItemIDs: [visible.id]
        ))

        #expect(plan.state == .ready)
        #expect(plan.items.first { $0.id == visible.id }?.recommendation == .keepVisible)
        #expect(plan.items.first { $0.id == hidden.id }?.recommendation == .moveToHidden)
        #expect(plan.items.first { $0.id == system.id }?.recommendation == .likelySystemItem)
        #expect(plan.items.first { $0.id == newlySeen.id }?.recommendation == .reviewNewItem)
        #expect(plan.items.map(\.isDiagnosticsRedacted).allSatisfy { $0 })
    }

    @Test func hashedInboxAndFavoriteKeysDecoratePlannerRows() {
        let now = Date(timeIntervalSince1970: 1_000)
        let favorite = Self.snapshot(id: "favorite", zone: .hidden)
        let newItem = Self.snapshot(id: "hashed-new", zone: .unknown)
        let favoriteKey = NewMenuBarItemInboxDetector.storageKey(for: favorite)
        let newItemKey = NewMenuBarItemInboxDetector.storageKey(for: newItem)

        let plan = PlacementPlanner().plan(context: PlacementPlannerContext(
            proModeEnabled: true,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermissionGranted: true,
            safeModeActive: false,
            snapshots: [favorite, newItem],
            lastScanDate: now,
            now: now,
            alwaysHiddenEnabled: true,
            newItemIDs: [newItemKey],
            favoriteItemIDs: [favoriteKey]
        ))

        let favoriteRow = try! #require(plan.items.first { $0.id == favorite.id })
        #expect(favoriteRow.storageKey == favoriteKey)
        #expect(favoriteRow.isFavorite)
        #expect(!favoriteRow.isNewItem)
        #expect(favoriteRow.recommendation == .keepVisible)
        #expect(favoriteRow.recommendedZone == .visible)
        #expect(favoriteRow.actionHints.contains(.highlight))
        #expect(favoriteRow.actionHints.contains(.showInSecondBar))

        let newItemRow = try! #require(plan.items.first { $0.id == newItem.id })
        #expect(newItemRow.storageKey == newItemKey)
        #expect(newItemRow.isNewItem)
        #expect(!newItemRow.isFavorite)
        #expect(newItemRow.recommendation == .reviewNewItem)
        #expect(newItemRow.recommendedZone == nil)
        #expect(newItemRow.displayTitle == "hashed-new")
        #expect(newItemRow.isDiagnosticsRedacted)
    }

    @Test func staleScanProducesRefreshRecommendations() {
        let now = Date(timeIntervalSince1970: 1_000)
        let plan = PlacementPlanner().plan(context: PlacementPlannerContext(
            proModeEnabled: true,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermissionGranted: true,
            safeModeActive: false,
            snapshots: [Self.snapshot(id: "old", zone: .hidden)],
            lastScanDate: now.addingTimeInterval(-600),
            now: now,
            staleInterval: 300,
            alwaysHiddenEnabled: true
        ))

        #expect(plan.state == .staleScan)
        #expect(plan.items.map(\.recommendation) == [.staleMetadata])
    }

    @Test func itemPreferencesInfluencePlannerWithoutMutatingInput() throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let hidden = Self.snapshot(id: "prefer-visible", zone: .hidden)
        let alwaysHidden = Self.snapshot(id: "prefer-always-hidden", zone: .visible)
        let hiddenKey = NewMenuBarItemInboxDetector.storageKey(for: hidden)
        let alwaysHiddenKey = NewMenuBarItemInboxDetector.storageKey(for: alwaysHidden)
        let preferences: [String: PlacementItemPreference] = [
            hiddenKey: .keepVisible,
            alwaysHiddenKey: .alwaysHide
        ]

        let plan = PlacementPlanner().plan(context: PlacementPlannerContext(
            proModeEnabled: true,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermissionGranted: true,
            safeModeActive: false,
            snapshots: [hidden, alwaysHidden],
            lastScanDate: now,
            now: now,
            alwaysHiddenEnabled: true,
            itemPreferences: preferences
        ))

        let hiddenRow = try #require(plan.items.first { $0.id == hidden.id })
        #expect(hiddenRow.preference == .keepVisible)
        #expect(hiddenRow.recommendation == .keepVisible)
        #expect(hiddenRow.reason == "You marked this item to stay visible.")
        #expect(hiddenRow.manualInstruction == "Keep this item to the right of the primary separator.")

        let alwaysHiddenRow = try #require(plan.items.first { $0.id == alwaysHidden.id })
        #expect(alwaysHiddenRow.preference == .alwaysHide)
        #expect(alwaysHiddenRow.recommendation == .moveToAlwaysHidden)
        #expect(alwaysHiddenRow.recommendedZone == .alwaysHidden)
        #expect(preferences[hiddenKey] == .keepVisible)
        #expect(preferences[alwaysHiddenKey] == .alwaysHide)
    }

    @MainActor
    @Test func itemPreferenceStorePersistsHashedPreferencesAndRecoversFromCorruption() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("placement-item-preferences.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = PlacementItemPreferenceStore(fileURL: fileURL)
        store.setPreference(.hide, for: "hashed-item")

        let reloaded = PlacementItemPreferenceStore(fileURL: fileURL)
        #expect(reloaded.preference(for: "hashed-item") == .hide)
        #expect(reloaded.preferences == ["hashed-item": .hide])
        #expect(!String(data: try Data(contentsOf: fileURL), encoding: .utf8)!.contains("Example"))

        try "not-json".write(to: fileURL, atomically: true, encoding: .utf8)
        let recovered = PlacementItemPreferenceStore(fileURL: fileURL)
        #expect(recovered.preferences.isEmpty)
    }

    static func snapshot(
        id: String,
        zone: MenuBarZone,
        isLikelySystemItem: Bool = false,
        frame: CGRect? = CGRect(x: 100, y: 0, width: 24, height: 24)
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: id,
            title: id,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 42,
            owningApplicationName: "Example",
            bundleIdentifier: isLikelySystemItem ? "com.apple.systemuiserver" : "com.example.\(id)",
            zone: zone,
            isLikelySystemItem: isLikelySystemItem,
            scanTimestamp: Date()
        )
    }
}

@Suite("NewMenuBarItemInbox")
struct NewMenuBarItemInboxTests {
    @Test func detectsNewItemsOnceAndRespectsDismissal() {
        let detector = NewMenuBarItemInboxDetector()
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = PlacementPlannerTests.snapshot(id: "new-item", zone: .visible)

        let first = detector.update(
            inbox: .empty,
            snapshots: [snapshot],
            now: now,
            isScanningAllowed: true
        )
        #expect(first.addedItemIDs == [snapshot.id])
        #expect(first.inbox.reviewCount == 1)

        let second = detector.update(
            inbox: first.inbox,
            snapshots: [snapshot],
            now: now.addingTimeInterval(10),
            isScanningAllowed: true
        )
        #expect(second.addedItemIDs.isEmpty)
        #expect(second.inbox.reviewCount == 1)
        #expect(second.inbox.items.first?.seenCount == 2)

        let storedID = try! #require(second.inbox.items.first?.id)
        let dismissed = detector.dismiss(itemID: storedID, in: second.inbox)
        #expect(dismissed.reviewCount == 0)
        #expect(dismissed.dismissedItemKeys.contains(storedID))
    }

    @Test func renamedStableIdentityDoesNotCreateDuplicateReviewItem() throws {
        let detector = NewMenuBarItemInboxDetector()
        let firstSnapshot = stableIdentitySnapshot(id: "before-rename", title: "Before")
        let renamedSnapshot = stableIdentitySnapshot(id: "after-rename", title: "After")

        let first = detector.update(
            inbox: .empty,
            snapshots: [firstSnapshot],
            now: Date(timeIntervalSince1970: 1_000),
            isScanningAllowed: true
        )
        let second = detector.update(
            inbox: first.inbox,
            snapshots: [renamedSnapshot],
            now: Date(timeIntervalSince1970: 1_100),
            isScanningAllowed: true
        )

        #expect(first.addedItemIDs == [firstSnapshot.id])
        #expect(second.addedItemIDs.isEmpty)
        #expect(second.inbox.reviewCount == 1)
        #expect(second.inbox.items.first?.id == NewMenuBarItemInboxDetector.reviewID(for: renamedSnapshot))
        #expect(second.inbox.items.first?.seenCount == 2)
    }

    @Test func bundledStableIdentitySurvivesRelaunchProcessChanges() {
        let detector = NewMenuBarItemInboxDetector()
        let firstSnapshot = stableIdentitySnapshot(id: "before-relaunch", title: "Stable", processIdentifier: 100)
        let relaunchedSnapshot = stableIdentitySnapshot(id: "after-relaunch", title: "Stable", processIdentifier: 200)

        let first = detector.update(
            inbox: .empty,
            snapshots: [firstSnapshot],
            now: Date(timeIntervalSince1970: 1_000),
            isScanningAllowed: true
        )
        let second = detector.update(
            inbox: first.inbox,
            snapshots: [relaunchedSnapshot],
            now: Date(timeIntervalSince1970: 1_100),
            isScanningAllowed: true
        )

        #expect(NewMenuBarItemInboxDetector.reviewID(for: firstSnapshot) == NewMenuBarItemInboxDetector.reviewID(for: relaunchedSnapshot))
        #expect(second.addedItemIDs.isEmpty)
        #expect(second.inbox.reviewCount == 1)
    }

    @Test func dismissedStableIdentityDoesNotReturnAfterRename() throws {
        let detector = NewMenuBarItemInboxDetector()
        let firstSnapshot = stableIdentitySnapshot(id: "dismiss-before", title: "Before")
        let renamedSnapshot = stableIdentitySnapshot(id: "dismiss-after", title: "After")
        let first = detector.update(
            inbox: .empty,
            snapshots: [firstSnapshot],
            now: Date(timeIntervalSince1970: 1_000),
            isScanningAllowed: true
        )
        let storedID = try #require(first.inbox.items.first?.id)
        let dismissed = detector.dismiss(itemID: storedID, in: first.inbox)

        let update = detector.update(
            inbox: dismissed,
            snapshots: [renamedSnapshot],
            now: Date(timeIntervalSince1970: 1_100),
            isScanningAllowed: true
        )

        #expect(update.addedItemIDs.isEmpty)
        #expect(update.inbox.reviewCount == 0)
        #expect(update.inbox.dismissedItemKeys.contains(NewMenuBarItemInboxDetector.reviewID(for: renamedSnapshot)))
    }

    @Test func safeModeOrMissingProGateSuppressesUpdates() {
        let snapshot = PlacementPlannerTests.snapshot(id: "suppressed", zone: .hidden)
        let update = NewMenuBarItemInboxDetector().update(
            inbox: .empty,
            snapshots: [snapshot],
            now: Date(),
            isScanningAllowed: false
        )
        #expect(update.addedItemIDs.isEmpty)
        #expect(update.inbox == .empty)
    }

    @Test func storePersistsReloadsAndRecoversFromCorruptFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("new-menu-bar-item-inbox.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let snapshot = PlacementPlannerTests.snapshot(id: "persisted", zone: .visible)
        let update = NewMenuBarItemInboxDetector().update(
            inbox: .empty,
            snapshots: [snapshot],
            now: Date(timeIntervalSince1970: 2_000),
            isScanningAllowed: true
        )

        let store = NewMenuBarItemInboxStore(fileURL: fileURL)
        store.apply(update: update)

        let reloaded = NewMenuBarItemInboxStore(fileURL: fileURL)
        #expect(reloaded.inbox.reviewCount == 1)
        #expect(reloaded.inbox.knownItemKeys == update.inbox.knownItemKeys)

        try "not-json".write(to: fileURL, atomically: true, encoding: .utf8)
        let recovered = NewMenuBarItemInboxStore(fileURL: fileURL)
        #expect(recovered.inbox == .empty)
    }

    @Test func resetClearsKnownDismissedAndReviewItems() {
        let detector = NewMenuBarItemInboxDetector()
        let snapshot = PlacementPlannerTests.snapshot(id: "reset-me", zone: .visible)
        let update = detector.update(
            inbox: .empty,
            snapshots: [snapshot],
            now: Date(timeIntervalSince1970: 2_000),
            isScanningAllowed: true
        )
        let storedID = update.inbox.items.first?.id ?? ""
        let dismissed = detector.dismiss(itemID: storedID, in: update.inbox)

        let reset = detector.reset(dismissed)

        #expect(reset.knownItemKeys.isEmpty)
        #expect(reset.dismissedItemKeys.isEmpty)
        #expect(reset.items.isEmpty)
    }

    @Test func reviewStateUsesGenericRowsAndHidesWhenUnavailable() {
        let inbox = NewMenuBarItemInbox(
            schemaVersion: 1,
            knownItemKeys: ["sensitive-hash"],
            dismissedItemKeys: [],
            items: [
                NewMenuBarItem(
                    id: "sensitive-hash",
                    firstSeenAt: Date(timeIntervalSince1970: 1_000),
                    lastSeenAt: Date(timeIntervalSince1970: 2_000),
                    seenCount: 3
                )
            ]
        )

        let unavailable = NewMenuBarItemInboxReviewState(inbox: inbox, isAvailable: false)
        #expect(unavailable.status == .unavailable)
        #expect(unavailable.rows.isEmpty)

        let ready = NewMenuBarItemInboxReviewState(inbox: inbox, isAvailable: true)
        #expect(ready.status == .ready)
        #expect(ready.rows.count == 1)
        #expect(ready.rows[0].id == "sensitive-hash")
        #expect(ready.rows[0].title == "New menu bar item")
        #expect(!ready.rows[0].title.contains("sensitive-hash"))
        #expect(ready.rows[0].seenCountLabel == "Seen 3 times")
        #expect(ready.rows[0].actions == NewMenuBarItemReviewAction.defaultActions)
        #expect(NewMenuBarItemReviewAction.keepVisible.placementPreference == .keepVisible)
        #expect(NewMenuBarItemReviewAction.hideManually.placementPreference == .hide)
        #expect(NewMenuBarItemReviewAction.alwaysHideManually.placementPreference == .alwaysHide)
        #expect(NewMenuBarItemReviewAction.reviewLater.placementPreference == .reviewLater)
        #expect(NewMenuBarItemReviewAction.showInFindIcon.placementPreference == nil)

        let empty = NewMenuBarItemInboxReviewState(inbox: .empty, isAvailable: true)
        #expect(empty.status == .empty)
    }

    @Test func diagnosticsMetadataUsesAggregateRedactedCounts() {
        let snapshot = stableIdentitySnapshot(id: "private-id", title: "Private Title")
        let update = NewMenuBarItemInboxDetector().update(
            inbox: .empty,
            snapshots: [snapshot],
            now: Date(timeIntervalSince1970: 2_000),
            isScanningAllowed: true
        )

        let metadata = NewMenuBarItemInboxDiagnostics.metadata(update: update, inbox: update.inbox)
        let metadataText = metadata.values.joined(separator: " ")

        #expect(metadata["addedCount"] == "1")
        #expect(metadata["reviewCount"] == "1")
        #expect(metadata["redacted"] == "true")
        #expect(!metadataText.contains("private-id"))
        #expect(!metadataText.contains("Private Title"))
        #expect(!metadataText.contains("Private App"))
        #expect(!metadataText.contains("com.example.private"))
    }

    private func stableIdentitySnapshot(
        id: String,
        title: String,
        processIdentifier: pid_t = 4242
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: id,
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: CGRect(x: 100, y: 0, width: 24, height: 24),
            owningProcessIdentifier: processIdentifier,
            owningApplicationName: "Private App",
            bundleIdentifier: "com.example.private",
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1_000)
        )
    }
}

@Suite("AssistedMoveGate")
struct AssistedMoveGateTests {
    @Test func availableOnlyWhenEveryGatePasses() {
        let snapshot = PlacementPlannerTests.snapshot(id: "move", zone: .hidden)
        let result = AssistedMoveGate().evaluate(
            snapshot: snapshot,
            targetZone: .visible,
            context: AssistedMoveGateContext(
                proModeEnabled: true,
                accessibilityDiscoveryEnabled: true,
                accessibilityPermissionGranted: true,
                iconMovingEnabled: true,
                safeModeActive: false,
                allowSystemItems: false,
                firstUseConfirmationAccepted: true,
                perMoveConfirmationAccepted: true,
                appBundleIdentifier: AppConstants.bundleIdentifier
            )
        )
        #expect(result == .available)
    }

    @Test func reportsAllSafetyAndConfirmationFailures() {
        let snapshot = PlacementPlannerTests.snapshot(
            id: "own",
            zone: .unknown,
            isLikelySystemItem: true,
            frame: nil
        )
        let result = AssistedMoveGate().evaluate(
            snapshot: snapshot,
            targetZone: nil,
            context: AssistedMoveGateContext(
                proModeEnabled: false,
                accessibilityDiscoveryEnabled: false,
                accessibilityPermissionGranted: false,
                iconMovingEnabled: false,
                safeModeActive: true,
                allowSystemItems: false,
                firstUseConfirmationAccepted: false,
                perMoveConfirmationAccepted: false,
                appBundleIdentifier: "com.example.other"
            )
        )

        #expect(!result.isAvailable)
        #expect(result.failures.contains(.proModeOff))
        #expect(result.failures.contains(.accessibilityDiscoveryOff))
        #expect(result.failures.contains(.accessibilityPermissionMissing))
        #expect(result.failures.contains(.iconMovingOff))
        #expect(result.failures.contains(.safeMode))
        #expect(result.failures.contains(.missingFrame))
        #expect(result.failures.contains(.invalidTargetZone))
        #expect(result.failures.contains(.likelySystemItem))
        #expect(result.failures.contains(.firstUseConfirmationMissing))
        #expect(result.failures.contains(.perMoveConfirmationMissing))
    }

    @Test func dryRunPlanBlocksUntilConfirmationsAndRedactsDiagnostics() {
        let snapshot = PlacementPlannerTests.snapshot(id: "private-title", zone: .hidden)
        let builder = AssistedMoveDryRunBuilder()
        let blocked = builder.plan(
            snapshot: snapshot,
            targetZone: .visible,
            context: AssistedMoveFlowContext(
                proModeEnabled: true,
                accessibilityDiscoveryEnabled: true,
                accessibilityPermissionGranted: true,
                iconMovingEnabled: true,
                safeModeActive: false,
                allowSystemItems: false,
                firstUseConfirmationAccepted: false,
                perMoveConfirmationAccepted: false,
                appBundleIdentifier: AppConstants.bundleIdentifier
            )
        )

        #expect(!blocked.canExecute)
        #expect(blocked.gateResult.failures.contains(.firstUseConfirmationMissing))
        #expect(blocked.gateResult.failures.contains(.perMoveConfirmationMissing))
        #expect(blocked.isDiagnosticsRedacted)
        #expect(!blocked.diagnosticSummary.contains("private-title"))

        let ready = builder.plan(
            snapshot: snapshot,
            targetZone: .visible,
            context: AssistedMoveFlowContext(
                proModeEnabled: true,
                accessibilityDiscoveryEnabled: true,
                accessibilityPermissionGranted: true,
                iconMovingEnabled: true,
                safeModeActive: false,
                allowSystemItems: false,
                firstUseConfirmationAccepted: true,
                perMoveConfirmationAccepted: true,
                appBundleIdentifier: AppConstants.bundleIdentifier
            )
        )

        #expect(ready.canExecute)
        #expect(ready.command == .moveToZone(.visible))
        #expect(ready.steps.contains { $0.contains("No CGEvent is posted during dry-run") })
        #expect(ready.plannedDragDirection == "right")
        #expect(ready.riskReason == "Labs single-item Command-drag; verify after any attempt.")
    }

    @MainActor
    @Test func viewModelDryRunDoesNotEnterExecutionState() {
        let snapshot = PlacementPlannerTests.snapshot(id: "dry-run-only", zone: .hidden)
        let viewModel = AssistedMoveViewModel()
        viewModel.firstUseConfirmationAccepted = true
        viewModel.perMoveConfirmationAccepted = true

        let plan = viewModel.generateDryRun(
            snapshot: snapshot,
            context: AssistedMoveFlowContext(
                proModeEnabled: true,
                accessibilityDiscoveryEnabled: true,
                accessibilityPermissionGranted: true,
                iconMovingEnabled: true,
                safeModeActive: false,
                allowSystemItems: false,
                firstUseConfirmationAccepted: true,
                perMoveConfirmationAccepted: true,
                appBundleIdentifier: AppConstants.bundleIdentifier
            )
        )

        #expect(plan.canExecute)
        #expect(viewModel.lastDryRun == plan)
        #expect(viewModel.lastMoveResult == nil)
        #expect(!viewModel.isExecuting)
    }
}
