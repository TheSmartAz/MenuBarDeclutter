import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Workspace Integration")
@MainActor
struct WorkspaceIntegrationTests {
    @Test func usageIndexConnectsDirectLinkedDetachedAndMissingReferences() {
        let activeID = UUID()
        let otherID = UUID()
        let archivedID = UUID()
        let missingGroupID = UUID()
        let linkedGroup = IconGroup(
            name: "Linked",
            itemRefs: [
                IconGroupItemRef(snapshotStableID: "linked-hash"),
                IconGroupItemRef(snapshotStableID: "shared-hash")
            ]
        )
        let detachedGroup = IconGroup(
            name: "Detached",
            itemRefs: [
                IconGroupItemRef(snapshotStableID: "detached-hash")
            ]
        )
        let active = MenuBarWorkspace(
            id: activeID,
            name: "Active",
            functionItems: [
                WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "direct-active"))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: linkedGroup.id, referenceMode: .linked))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: missingGroupID, referenceMode: .linked)))
            ]
        )
        let other = MenuBarWorkspace(
            id: otherID,
            name: "Other",
            functionItems: [
                WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "direct-other"))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: detachedGroup.id, referenceMode: .detached)))
            ]
        )
        let archived = MenuBarWorkspace(
            id: archivedID,
            name: "Archived",
            functionItems: [
                WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "archived-only")))
            ],
            isArchived: true
        )
        let snapshot = WorkspaceStoreSnapshot(
            activeWorkspaceID: activeID,
            workspaces: [active, other, archived]
        )

        let usage = WorkspaceUsageIndex().rebuild(
            snapshot: snapshot,
            groups: [linkedGroup, detachedGroup]
        )

        #expect(usage.indexedWorkspaceCount == 2)
        #expect(usage.missingGroupReferenceCount == 1)
        #expect(usage.usage(for: "direct-active").isUsedInActiveWorkspace)
        #expect(usage.usage(for: "direct-active").directWorkspaceCount == 1)
        #expect(usage.usage(for: "linked-hash").linkedGroupReferenceCount == 1)
        #expect(usage.usage(for: "linked-hash").groupIDs == [linkedGroup.id])
        #expect(usage.usage(for: "detached-hash").detachedGroupReferenceCount == 1)
        #expect(usage.usage(for: "archived-only").isUnassigned)
        #expect(usage.workspaceIDsByGroupID[linkedGroup.id] == [activeID])
        #expect(usage.workspaceIDsByGroupID[detachedGroup.id] == [otherID])
    }

    @Test func assignmentServiceAddsItemsGroupsAndHonorsGates() {
        let activeID = UUID()
        let workspace = MenuBarWorkspace(id: activeID, name: "Active")
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: activeID, workspaces: [workspace])
        let switchingService = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore21(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let assignment = WorkspaceAssignmentService(
            switchingService: switchingService,
            groupStore: nil
        )

        let reference = MenuBarItemReference(stableHash: "assign-me")
        let result = assignment.assignItemReference(reference, to: .currentWorkspace)
        #expect(result.status == .success)
        #expect(switchingService.activeWorkspace().functionItems.contains { item in
            if case .menuBarItem(let existing) = item.kind {
                return existing.stableHash == "assign-me"
            }
            return false
        })

        let duplicate = assignment.assignItemReference(reference, to: .currentWorkspace)
        #expect(duplicate.status == .noChange)

        let disabled = WorkspaceAssignmentService(
            switchingService: switchingService,
            groupStore: nil,
            previewEnabled: { false }
        )
        #expect(disabled.assignItemReference(.init(stableHash: "blocked"), to: .currentWorkspace).status == .unavailable)

        let safeMode = WorkspaceAssignmentService(
            switchingService: switchingService,
            groupStore: nil,
            safeModeActive: { true }
        )
        #expect(safeMode.assignItemReference(.init(stableHash: "safe"), to: .currentWorkspace).status == .blockedBySafeMode)
        #expect(safeMode.assignItemReference(.init(stableHash: "visible"), to: .visibleOnly).status == .success)
    }

    @Test func assignmentServiceCreatesGroupAndDismissesResolvedNewItems() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceIntegrationTests.\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }
        let groupsDirectory = tempRoot.appendingPathComponent("groups", isDirectory: true)
        let backupsDirectory = tempRoot.appendingPathComponent("backups", isDirectory: true)
        let groupStore = IconGroupStore(directory: groupsDirectory, backupsDirectory: backupsDirectory)
        groupStore.load()

        let activeID = UUID()
        let workspace = MenuBarWorkspace(id: activeID, name: "Active")
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: activeID, workspaces: [workspace])
        let switchingService = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore21(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let inboxStore = NewMenuBarItemInboxStore(fileURL: nil)
        let newItem = NewMenuBarItem(
            id: "new-item-hash",
            firstSeenAt: Date(timeIntervalSince1970: 1),
            lastSeenAt: Date(timeIntervalSince1970: 2)
        )
        inboxStore.apply(update: NewMenuBarItemInboxUpdate(
            inbox: NewMenuBarItemInbox(
                schemaVersion: 1,
                knownItemKeys: ["new-item-hash"],
                dismissedItemKeys: [],
                items: [newItem]
            ),
            addedItemIDs: ["new-item-hash"]
        ))

        let assignment = WorkspaceAssignmentService(
            switchingService: switchingService,
            groupStore: groupStore,
            newItemInboxStore: inboxStore
        )
        let result = assignment.assignNewItem(newItem, to: .newGroup(name: "Utilities", workspaceID: activeID))

        #expect(result.status == .success)
        #expect(groupStore.groups.count == 1)
        #expect(groupStore.groups.first?.itemRefs.first?.snapshotStableID == "new-item-hash")
        #expect(inboxStore.inbox.reviewCount == 0)
        #expect(switchingService.activeWorkspace().functionItems.contains { item in
            if case .group(let reference) = item.kind {
                return reference.groupID == groupStore.groups.first?.id && reference.referenceMode == .linked
            }
            return false
        })
    }

    @Test func searchUsesWorkspaceFiltersBadgesAndRankingBoosts() {
        let activeID = UUID()
        let otherID = UUID()
        let groupID = UUID()
        let current = TestSnapshots.makeSnapshot(id: "current", title: "Status", owningApplicationName: "Sync")
        let other = TestSnapshots.makeSnapshot(id: "other", title: "Status", owningApplicationName: "Sync", zone: .hidden)
        let grouped = TestSnapshots.makeSnapshot(id: "grouped", title: "Status", owningApplicationName: "Sync")
        let unassigned = TestSnapshots.makeSnapshot(id: "unassigned", title: "Status", owningApplicationName: "Sync")
        let usageSnapshot = WorkspaceUsageIndexSnapshot(
            activeWorkspaceID: activeID,
            usagesByItemHash: [
                "current": WorkspaceItemUsage(
                    itemHash: "current",
                    workspaceIDs: [activeID],
                    groupIDs: [],
                    directWorkspaceCount: 1,
                    groupReferenceCount: 0,
                    linkedGroupReferenceCount: 0,
                    detachedGroupReferenceCount: 0,
                    isUsedInActiveWorkspace: true,
                    isUnassigned: false
                ),
                "other": WorkspaceItemUsage(
                    itemHash: "other",
                    workspaceIDs: [otherID],
                    groupIDs: [],
                    directWorkspaceCount: 1,
                    groupReferenceCount: 0,
                    linkedGroupReferenceCount: 0,
                    detachedGroupReferenceCount: 0,
                    isUsedInActiveWorkspace: false,
                    isUnassigned: false
                ),
                "grouped": WorkspaceItemUsage(
                    itemHash: "grouped",
                    workspaceIDs: [activeID],
                    groupIDs: [groupID],
                    directWorkspaceCount: 0,
                    groupReferenceCount: 1,
                    linkedGroupReferenceCount: 1,
                    detachedGroupReferenceCount: 0,
                    isUsedInActiveWorkspace: true,
                    isUnassigned: false
                )
            ],
            workspaceIDsByGroupID: [groupID: [activeID]],
            groupIDsByItemHash: ["grouped": [groupID]],
            missingGroupReferenceCount: 0,
            indexedWorkspaceCount: 2
        )
        let context = SearchRankingContext(workspaceUsageSnapshot: usageSnapshot)
        let service = SearchService()
        let snapshots = [other, current, grouped, unassigned]

        #expect(service.results(from: snapshots, query: "Sync", rankingContext: context).first?.id == "grouped")
        #expect(service.results(from: snapshots, query: "Sync", filter: .currentWorkspace, rankingContext: context).map(\.id) == ["grouped", "current"])
        #expect(service.results(from: snapshots, query: "Sync", filter: .usedInOtherWorkspace, rankingContext: context).map(\.id) == ["other"])
        #expect(service.results(from: snapshots, query: "Sync", filter: .groups, rankingContext: context).map(\.id) == ["grouped"])
        #expect(service.results(from: snapshots, query: "Sync", filter: .unassigned, rankingContext: context).map(\.id) == ["unassigned"])
        #expect(service.results(from: [unassigned], query: "Sync", filter: .unassigned).isEmpty)

        let groupedBadges = service.results(from: [grouped], query: "Sync", rankingContext: context).first?.workspaceBadges ?? []
        #expect(groupedBadges.contains(.currentWorkspace))
        #expect(groupedBadges.contains(.linkedGroup))
    }

    @Test func placementAdapterSuggestsWorkspaceAwareActionsWithoutPhysicalMoves() {
        let activeUsage = WorkspaceItemUsage(
            itemHash: "active",
            workspaceIDs: [UUID()],
            groupIDs: [],
            directWorkspaceCount: 1,
            groupReferenceCount: 0,
            linkedGroupReferenceCount: 0,
            detachedGroupReferenceCount: 0,
            isUsedInActiveWorkspace: true,
            isUnassigned: false
        )
        let inactiveUsage = WorkspaceItemUsage(
            itemHash: "inactive",
            workspaceIDs: [UUID()],
            groupIDs: [],
            directWorkspaceCount: 1,
            groupReferenceCount: 0,
            linkedGroupReferenceCount: 0,
            detachedGroupReferenceCount: 0,
            isUsedInActiveWorkspace: false,
            isUnassigned: false
        )
        let unassignedUsage = WorkspaceItemUsage.empty(itemHash: "unassigned")
        let adapter = WorkspacePlacementRecommendationAdapter()

        let active = adapter.enrich(.keepVisible, usage: activeUsage)
        let inactive = adapter.enrich(.keepVisible, usage: inactiveUsage)
        let unassignedHidden = adapter.enrich(.moveToHidden, usage: unassignedUsage)

        #expect(active.workspaceReason == .currentWorkspace)
        #expect(active.suggestedWorkspaceAction == .noWorkspaceAction)
        #expect(inactive.workspaceReason == .inactiveWorkspaceOnly)
        #expect(inactive.suggestedWorkspaceAction == .addToCurrentWorkspace)
        #expect(unassignedHidden.workspaceReason == .unassigned)
        #expect(unassignedHidden.suggestedWorkspaceAction == .keepHiddenExposeInFunctionBar)
    }

    @Test func physicalProfilePlannerNeverPlansPhysicalLayoutMutation() {
        let profileID = UUID()
        let dryRunWorkspace = MenuBarWorkspace(
            name: "Dry Run",
            physicalProfileBinding: WorkspacePhysicalProfileBinding(
                profileID: profileID,
                applyMode: .dryRunOnly
            )
        )
        let safeBasicWorkspace = MenuBarWorkspace(
            name: "Safe Basic",
            physicalProfileBinding: WorkspacePhysicalProfileBinding(
                profileID: profileID,
                applyMode: .applySafeBasicSettings
            )
        )
        let missingProfileWorkspace = MenuBarWorkspace(
            name: "Missing",
            physicalProfileBinding: WorkspacePhysicalProfileBinding(
                profileID: UUID(),
                applyMode: .applySafeBasicSettings
            )
        )
        let planner = WorkspacePhysicalProfilePlanner()

        let dryRunPlan = planner.plan(for: dryRunWorkspace, availableProfileIDs: [profileID])
        let safeBasicPlan = planner.plan(for: safeBasicWorkspace, availableProfileIDs: [profileID])
        let missingPlan = planner.plan(for: missingProfileWorkspace, availableProfileIDs: [profileID])

        #expect(dryRunPlan.applyMode == .dryRunOnly)
        #expect(dryRunPlan.diagnosticReason == "dryRunOnly")
        #expect(!dryRunPlan.mutatesPhysicalLayout)
        #expect(safeBasicPlan.applyMode == .applySafeBasicSettings)
        #expect(safeBasicPlan.ignoredRiskyChanges.contains("Menu bar item movement is never applied automatically."))
        #expect(!safeBasicPlan.mutatesPhysicalLayout)
        #expect(missingPlan.diagnosticReason == "missingProfileBinding")
        #expect(missingPlan.safeChanges.isEmpty)
        #expect(!missingPlan.mutatesPhysicalLayout)
    }
}

@MainActor
private final class MemoryWorkspaceStore21: WorkspaceStoreProtocol {
    private var snapshot: WorkspaceStoreSnapshot

    init(snapshot: WorkspaceStoreSnapshot) {
        self.snapshot = snapshot
    }

    func load() throws -> WorkspaceStoreSnapshot {
        snapshot
    }

    func save(_ snapshot: WorkspaceStoreSnapshot) throws {
        self.snapshot = snapshot
    }

    func resetToDefaults() throws -> WorkspaceStoreSnapshot {
        snapshot = WorkspaceStoreSnapshot.defaults()
        return snapshot
    }

    func backupCurrentStore(reason: WorkspaceBackupReason) throws -> URL? {
        nil
    }
}
