import AppKit
import Foundation
import CoreGraphics
import Testing
@testable import MenuBarDeclutter

@Suite("Workspaces, Function Bar, and Info Strip")
@MainActor
struct WorkspacesFunctionBarInfoStripTests {
    @Test func previewFeatureDefaultsMatchPhasePlans() {
        let suiteName = "PreviewDefaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(!store.workspacesPreviewEnabled)
        #expect(!store.functionBarPreviewEnabled)
        #expect(!store.functionBarPrimaryClickEnabled)
        #expect(store.functionBarPlacementPreference == FunctionBarPlacementPreference.belowMenuBarIcon.rawValue)
        #expect(store.functionBarShowSetSwitcher)
        #expect(store.functionBarShowLabels)
        #expect(store.functionBarDensity == "regular")
        #expect(store.functionBarCloseOnOutsideClick)
        #expect(store.functionBarKeyboardNavigationEnabled)
        #expect(!store.setBuilderPreviewEnabled)
        #expect(store.setBuilderDragDropEnabled)
        #expect(!store.setBuilderShowAdvancedLibraryItems)
        #expect(store.setBuilderDefaultGroupReferenceMode == WorkspaceGroupReferenceMode.linked.rawValue)
        #expect(store.setBuilderShowFunctionBarPreview)
        #expect(store.setBuilderAutosaveDrafts)
        #expect(store.setBuilderWarnBeforeLinkedGroupEdits)
        #expect(!store.infoStripPreviewEnabled)
        #expect(!store.infoStripAutoShowEnabled)
        #expect(store.infoStripHoverToFunctionBarEnabled)
        #expect(store.infoStripCloseOnOutsideClick)
        #expect(store.infoStripPauseWhenFunctionBarPinned)
        #expect(store.infoStripKeyboardNavigationEnabled)
        #expect(store.infoStripShowPreviewBadge)
    }

    @Test func functionBarDensityOptionsMatchPreviewSettingsControl() {
        #expect(FunctionBarDensity.allCases.map(\.rawValue) == ["compact", "regular"])
        #expect(FunctionBarDensity.compact.displayName == "Compact")
        #expect(FunctionBarDensity.regular.displayName == "Regular")
    }

    @Test func functionBarShowFailsClosedWhenPlacementHasNoDisplay() {
        let suiteName = "FunctionBarNoDisplay.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.workspacesPreviewEnabled = true
        settings.functionBarPreviewEnabled = true
        let workspace = MenuBarWorkspace(
            name: "Focus",
            functionItems: [.command(.revealAll)]
        )
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])
        let switchingService = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let resolver = FunctionBarItemResolver(
            groupsProvider: { [] },
            snapshotsProvider: { [] },
            proDiscoveryAvailable: { false },
            accessibilityAvailable: { false }
        )
        let dispatcher = FunctionBarActionDispatcher(
            routeCommand: { .success($0, message: "Routed.") },
            openSettings: {},
            openRecovery: {},
            openWorkspacePreview: {},
            showFunctionBar: {},
            hideFunctionBar: {},
            showInfoStrip: {},
            hideInfoStrip: {}
        )
        let controller = FunctionBarController(
            settingsStore: settings,
            switchingService: switchingService,
            resolver: resolver,
            dispatcher: dispatcher,
            placementService: FunctionBarPlacementService(
                screensProvider: { [] },
                mouseLocationProvider: { .zero }
            ),
            safeModeActive: { false }
        )

        controller.show(source: .settings)

        #expect(controller.activeState() == .unavailable(.noDisplayAvailable))
        #expect(controller.lastShowResult == FunctionBarUnavailableReason.noDisplayAvailable.rawValue)
    }

    @Test func placementServicesUseStatusItemAnchorWhenAvailable() throws {
        let screen = try #require(NSScreen.screens.first)
        let visibleFrame = screen.visibleFrame
        let panelSize = CGSize(width: 200, height: 80)
        let anchor = CGRect(x: visibleFrame.midX + 60, y: visibleFrame.maxY - 24, width: 24, height: 18)
        let expectedX = anchor.midX - panelSize.width / 2
        let functionPlacementService = FunctionBarPlacementService(
            screensProvider: { [screen] },
            mouseLocationProvider: { CGPoint(x: visibleFrame.midX, y: visibleFrame.midY) }
        )
        let functionPlacement = try #require(functionPlacementService.placement(
            panelSize: panelSize,
            preference: .belowMenuBarIcon,
            statusItemAnchor: anchor
        ))
        let infoStripPlacement = try #require(InfoStripPlacementService(
            functionBarPlacementService: functionPlacementService
        ).placement(
            panelSize: panelSize,
            preference: .alignWithFunctionBar,
            statusItemAnchor: anchor
        ))

        #expect(functionPlacement.reason == .preferred)
        #expect(functionPlacement.origin.x == expectedX)
        #expect(infoStripPlacement.origin.x == expectedX)
        #expect(infoStripPlacement.placementMode == .alignWithFunctionBar)
    }

    @Test func validationRecreatesDefaultWorkspacesWhenStoreIsEmpty() {
        let result = WorkspaceValidation.validate(workspaces: [], activeWorkspaceID: nil)

        #expect(result.didRepair)
        #expect(result.repairedWorkspaces.count == 3)
        #expect(result.repairedWorkspaces.contains { $0.id == result.selectedActiveWorkspaceID })
        #expect(result.issues.contains { $0.kind == .allWorkspacesRecreated })
    }

    @Test func validationReportsUnsupportedCommandsAndMissingReferences() {
        let missingGroupID = UUID()
        let missingProfileID = UUID()
        let workspace = MenuBarWorkspace(
            name: "References",
            functionItems: [
                WorkspaceItem(kind: .command(WorkspaceCommandReference(actionID: "unsupported.command"))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: missingGroupID, referenceMode: .linked))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: UUID(), referenceMode: .detached)))
            ],
            physicalProfileBinding: WorkspacePhysicalProfileBinding(
                profileID: missingProfileID,
                applyMode: .dryRunOnly
            )
        )

        let result = WorkspaceValidation.validate(
            workspaces: [workspace],
            activeWorkspaceID: workspace.id,
            knownGroupIDs: [],
            knownProfileIDs: []
        )

        #expect(result.issues.contains { $0.kind == .unsupportedCommandReference })
        #expect(result.issues.contains { $0.kind == .missingGroupReference })
        #expect(result.issues.contains { $0.kind == .missingProfileBinding })
        #expect(result.issues.filter { $0.kind == .missingGroupReference }.count == 1)
    }

    @Test func workspaceDiagnosticsUsesKnownReferenceIDs() {
        let suiteName = "WorkspaceDiagnosticsReferences.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let groupID = UUID()
        let profileID = UUID()
        let settingsStore = SettingsStore(defaults: defaults)
        let workspace = MenuBarWorkspace(
            name: "References",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .linked)))
            ],
            physicalProfileBinding: WorkspacePhysicalProfileBinding(
                profileID: profileID,
                applyMode: .dryRunOnly
            )
        )
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])

        let missing = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: [],
            knownProfileIDs: []
        )
        let resolved = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: [groupID],
            knownProfileIDs: [profileID]
        )

        #expect(missing.missingGroupReferenceCount == 1)
        #expect(missing.missingProfileBindingCount == 1)
        #expect(resolved.missingGroupReferenceCount == 0)
        #expect(resolved.missingProfileBindingCount == 0)
    }

    @Test func workspaceDiagnosticsCountsDetachedSourcesAndUnresolvedProxiesWithoutNames() {
        let suiteName = "WorkspaceDiagnosticsUnresolved.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let sourceGroupID = UUID()
        let detachedCopyGroup = IconGroup(name: "Detached Copy")
        let workspace = MenuBarWorkspace(
            name: "References",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(
                    groupID: detachedCopyGroup.id,
                    referenceMode: .detached,
                    sourceGroupID: sourceGroupID
                ))),
                WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(
                    stableHash: "missing-proxy",
                    lastKnownDisplayName: "Private Item",
                    lastKnownBundleIdentifier: "com.example.private"
                ))),
                WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "live-proxy")))
            ]
        )
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])
        let diagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: SettingsStore(defaults: defaults),
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: [detachedCopyGroup.id],
            availableMenuBarItemHashes: ["live-proxy"]
        )
        let unavailableProxyDiagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: SettingsStore(defaults: defaults),
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: [detachedCopyGroup.id],
            availableMenuBarItemHashes: nil
        )

        #expect(diagnostics.detachedSourceGroupMissingCount == 1)
        #expect(diagnostics.menuBarItemReferenceCount == 2)
        #expect(diagnostics.unresolvedMenuBarItemReferenceCount == 1)
        #expect(unavailableProxyDiagnostics.unresolvedMenuBarItemReferenceCount == 0)
    }

    @Test func commandLibraryIncludesInfoStripCommands() {
        let itemIDs = Set(CommandLibraryProvider().items().map(\.id))

        #expect(itemIDs.contains("command.\(WorkspaceCommandReference.showInfoStrip.actionID)"))
        #expect(itemIDs.contains("command.\(WorkspaceCommandReference.hideInfoStrip.actionID)"))
        #expect(itemIDs.contains("command.\(WorkspaceCommandReference.nextInfoStripTile.actionID)"))
        #expect(itemIDs.contains("command.\(WorkspaceCommandReference.openInfoStripSettings.actionID)"))
        #expect(itemIDs.contains("command.\(WorkspaceCommandReference.showFunctionBarFromInfoStrip.actionID)"))
    }

    @Test func setBuilderExposesNewAndUnassignedItemLibrariesWithoutMovingIcons() throws {
        let suiteName = "SetBuilderNewUnassigned.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.proModeEnabled = true
        settings.accessibilityDiscoveryEnabled = true
        settings.lastAccessibilityPermissionStatus = AccessibilityPermissionStatus.granted.rawValue

        let inboxStore = NewMenuBarItemInboxStore(fileURL: nil)
        let newItem = NewMenuBarItem(
            id: "new-item-hash",
            firstSeenAt: Date(timeIntervalSince1970: 1),
            lastSeenAt: Date(timeIntervalSince1970: 2),
            seenCount: 2
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

        var workspace = MenuBarWorkspace(name: "Builder")
        workspace.functionItems = [
            WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "assigned"))),
            WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "grouped")))
        ]

        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])
        let service = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let discovered = [
            TestSnapshots.makeSnapshot(id: "assigned", title: "Assigned", owningApplicationName: "Assigned"),
            TestSnapshots.makeSnapshot(id: "grouped", title: "Grouped", owningApplicationName: "Grouped"),
            TestSnapshots.makeSnapshot(id: "free", title: "Free", owningApplicationName: "Free")
        ]
        let viewModel = SetBuilderViewModel(
            switchingService: service,
            groupStore: nil,
            newItemInboxStore: inboxStore,
            snapshotsProvider: { discovered },
            settingsStore: settings
        )

        let newLibraryItem = try #require(viewModel.newItemLibrary.first)
        #expect(newLibraryItem.badge == "New")
        #expect(newLibraryItem.subtitle?.contains("no icon is moved") == true)
        if case .menuBarItem(let reference) = newLibraryItem.kind {
            #expect(reference.stableHash == "new-item-hash")
            #expect(reference.source == .itemMemory)
        } else {
            Issue.record("Expected New Item library entry to create a menu bar item proxy.")
        }

        let unassignedLibraryItems = viewModel.unassignedItemLibrary
        #expect(unassignedLibraryItems.map(\.id) == ["unassigned.free"])
        #expect(unassignedLibraryItems.first?.badge == "Unassigned")
        #expect(unassignedLibraryItems.first?.subtitle?.contains("no icon is moved") == true)
    }

    @Test func functionBarBadgesExposeWorkspaceReferenceState() {
        let group = IconGroup(name: "Utilities")
        let snapshot = TestSnapshots.makeSnapshot(id: "proxy", title: "Proxy", owningApplicationName: "Proxy")
        let resolver = FunctionBarItemResolver(
            groupsProvider: { [group] },
            snapshotsProvider: { [snapshot] },
            proDiscoveryAvailable: { true },
            accessibilityAvailable: { true }
        )

        let linkedGroup = resolver.resolve(item: WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: group.id, referenceMode: .linked))))
        let detachedGroup = resolver.resolve(item: WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: group.id, referenceMode: .detached))))
        let missingGroup = resolver.resolve(item: WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: UUID(), referenceMode: .linked))))
        let newProxy = resolver.resolve(item: WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(
            stableHash: "proxy",
            source: .itemMemory
        ))))
        let protectedProxy = resolver.resolve(item: WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(
            stableHash: "proxy",
            redactionPolicy: .protected
        ))))
        let missingProxy = resolver.resolve(item: WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "missing"))))
        let gatedResolver = FunctionBarItemResolver(
            groupsProvider: { [] },
            snapshotsProvider: { [] },
            proDiscoveryAvailable: { false },
            accessibilityAvailable: { false }
        )
        let proGatedProxy = gatedResolver.resolve(item: WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "proxy"))))

        #expect(linkedGroup.badge?.title == "Linked Group")
        #expect(detachedGroup.badge?.title == "Detached")
        #expect(missingGroup.badge?.title == "Missing")
        #expect(newProxy.badge?.title == "New Item")
        #expect(protectedProxy.badge?.title == "Protected")
        #expect(missingProxy.badge?.title == "Missing")
        #expect(proGatedProxy.badge?.title == "Requires Pro")
    }

    @Test func validationClampsInfoStripTimingToPhase20Bounds() throws {
        var workspace = MenuBarWorkspace(name: "Timing")
        workspace.infoStripConfig.rotationIntervalSeconds = 500
        workspace.infoStripConfig.idleDelaySeconds = 0

        let result = WorkspaceValidation.validate(
            workspaces: [workspace],
            activeWorkspaceID: workspace.id
        )

        let repaired = try #require(result.repairedWorkspaces.first)
        #expect(repaired.infoStripConfig.rotationIntervalSeconds == 300)
        #expect(repaired.infoStripConfig.idleDelaySeconds == 1)
        #expect(result.issues.contains { $0.kind == .invalidInfoStripTimingRepaired })
    }

    @Test func workspacesPreviewSettingsExposePhase20InfoStripControls() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let settingsView = root.appendingPathComponent("MenuBar-Manager/Settings/WorkspacePreviewSettingsView.swift")
        let text = try String(contentsOf: settingsView, encoding: .utf8)

        #expect(text.contains("Info Strip Preview"))
        #expect(text.contains("Enable Info Strip for active Workspace"))
        #expect(text.contains("Idle delay:"))
        #expect(text.contains("Rotation:"))
        #expect(text.contains("Tile Picker"))
        #expect(text.contains("Hover behavior"))
        #expect(text.contains("Compact mode"))
        #expect(text.contains("Show preview badge"))
        #expect(text.contains("Open Info Strip Preview"))
        #expect(text.contains("Info Strip is app-owned UI, not a system menu bar replacement"))
    }

    @Test func workspaceGroupResolverReportsProtectedMissingAndUnavailableReferences() {
        let protectedGroup = IconGroup(name: "Private", isProtected: true)
        let disabledGroup = IconGroup(name: "Disabled", isEnabled: false)
        let normalGroup = IconGroup(name: "Normal")

        #expect(WorkspaceGroupResolver.resolve(
            reference: WorkspaceGroupReference(groupID: protectedGroup.id),
            groups: [protectedGroup, disabledGroup, normalGroup]
        ).status == .protected)
        #expect(WorkspaceGroupResolver.resolve(
            reference: WorkspaceGroupReference(groupID: disabledGroup.id),
            groups: [protectedGroup, disabledGroup, normalGroup]
        ).status == .unavailable)
        #expect(WorkspaceGroupResolver.resolve(
            reference: WorkspaceGroupReference(groupID: normalGroup.id),
            groups: [protectedGroup, disabledGroup, normalGroup]
        ).status == .resolved)
        #expect(WorkspaceGroupResolver.resolve(
            reference: WorkspaceGroupReference(groupID: UUID()),
            groups: [protectedGroup, disabledGroup, normalGroup]
        ).status == .missing)
    }

    @Test func workspaceDiagnosticsCountsGroupReferenceModesWithoutNames() {
        let linkedProtectedGroup = IconGroup(name: "Secret", isProtected: true)
        let detachedGroup = IconGroup(name: "Detached")
        let missingGroupID = UUID()
        let workspace = MenuBarWorkspace(
            name: "Diagnostics",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: linkedProtectedGroup.id, referenceMode: .linked))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: detachedGroup.id, referenceMode: .detached))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: missingGroupID, referenceMode: .linked)))
            ]
        )
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])
        let store = SettingsStore(defaults: UserDefaults(suiteName: "WorkspaceDiagnostics.\(UUID().uuidString)")!)

        let diagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: store,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: [linkedProtectedGroup.id, detachedGroup.id],
            protectedGroupIDs: [linkedProtectedGroup.id]
        )

        #expect(diagnostics.groupReferenceCount == 3)
        #expect(diagnostics.linkedGroupReferenceCount == 2)
        #expect(diagnostics.detachedGroupReferenceCount == 1)
        #expect(diagnostics.missingGroupReferenceCount == 1)
        #expect(diagnostics.protectedGroupReferenceCount == 1)
    }

    @Test func workspaceDiagnosticsHashIsStableAndRedacted() {
        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

        let first = WorkspaceDiagnosticsRedactor.hash(id: id)
        let second = WorkspaceDiagnosticsRedactor.hash(id: id)

        #expect(first == second)
        #expect(first.hasPrefix("workspace-"))
        #expect(!first.contains(id.uuidString))
    }

    @Test func workspaceStoreCreatesDefaultsAndPersistsSwitches() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("WorkspaceStoreTests.\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = WorkspaceStore(
            fileURL: tempRoot.appendingPathComponent("Workspaces/workspaces.json"),
            backupsDirectory: tempRoot.appendingPathComponent("Workspaces/backups", isDirectory: true)
        )
        let snapshot = try store.load()
        let service = WorkspaceSwitchingService(
            store: store,
            initialSnapshot: snapshot
        )
        let target = try #require(snapshot.workspaces.dropFirst().first)

        let result = service.switchWorkspace(id: target.id, source: .settings)
        let reloaded = try store.load()

        #expect(result.status == .success)
        #expect(reloaded.activeWorkspaceID == target.id)
        #expect(store.lastLoadStatus == .loaded)
    }

    @Test func workspaceSwitchingBlocksCreateAndDuplicateAtWorkspaceLimit() throws {
        let workspaces = (0..<WorkspaceValidationConstants.maxWorkspaces).map { index in
            MenuBarWorkspace(name: "Workspace \(index)")
        }
        let snapshot = WorkspaceStoreSnapshot(
            activeWorkspaceID: workspaces[0].id,
            workspaces: workspaces
        )
        let store = MemoryWorkspaceStore(snapshot: snapshot)
        let service = WorkspaceSwitchingService(
            store: store,
            initialSnapshot: snapshot
        )

        let createResult = service.createWorkspace(WorkspaceDraft(name: "Overflow"))
        let duplicateResult = service.duplicateWorkspace(id: workspaces[0].id)
        let savedSnapshot = try store.load()

        #expect(createResult.status == .invalidWorkspace)
        #expect(createResult.diagnosticReason == .tooManyWorkspaces)
        #expect(duplicateResult.status == .invalidWorkspace)
        #expect(duplicateResult.diagnosticReason == .tooManyWorkspaces)
        #expect(service.currentSnapshot().workspaces.count == WorkspaceValidationConstants.maxWorkspaces)
        #expect(savedSnapshot.workspaces.count == WorkspaceValidationConstants.maxWorkspaces)
    }

    @Test func workspaceRecoveryRepairsMissingGroupsAndCurrentLayoutOnly() throws {
        let knownGroupID = UUID()
        let missingGroupID = UUID()
        let missingDetachedGroupID = UUID()
        let activeWorkspace = MenuBarWorkspace(
            name: "Damaged",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: knownGroupID, referenceMode: .linked))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: missingGroupID, referenceMode: .linked))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: missingDetachedGroupID, referenceMode: .detached))),
                WorkspaceItem(kind: .command(.showInfoStrip))
            ],
            physicalProfileBinding: WorkspacePhysicalProfileBinding(profileID: UUID(), applyMode: .dryRunOnly)
        )
        let otherWorkspace = MenuBarWorkspace(
            name: "Other",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: knownGroupID, referenceMode: .linked)))
            ]
        )
        let snapshot = WorkspaceStoreSnapshot(
            activeWorkspaceID: activeWorkspace.id,
            workspaces: [activeWorkspace, otherWorkspace]
        )
        let store = MemoryWorkspaceStore(snapshot: snapshot)
        let service = WorkspaceSwitchingService(store: store, initialSnapshot: snapshot)

        let removeResult = service.removeMissingGroupReferences(knownGroupIDs: [knownGroupID])
        let repairedSnapshot = try store.load()
        let repairedActive = try #require(repairedSnapshot.workspaces.first { $0.id == activeWorkspace.id })
        let repairedOther = try #require(repairedSnapshot.workspaces.first { $0.id == otherWorkspace.id })

        #expect(removeResult.status == .success)
        #expect(repairedActive.functionItems.count == 2)
        #expect(repairedActive.functionItems.contains { item in
            if case .group(let reference) = item.kind {
                return reference.groupID == knownGroupID
            }
            return false
        })
        #expect(repairedOther.functionItems == otherWorkspace.functionItems)

        let resetResult = service.resetActiveWorkspaceLayoutToDefaults()
        let resetSnapshot = try store.load()
        let resetActive = try #require(resetSnapshot.workspaces.first { $0.id == activeWorkspace.id })
        let unchangedOther = try #require(resetSnapshot.workspaces.first { $0.id == otherWorkspace.id })
        let defaultItemKinds = MenuBarWorkspace.defaultWorkspaces().first?.functionItems.map(\.kind) ?? []

        #expect(resetResult.status == .success)
        #expect(resetActive.functionItems.map(\.kind) == defaultItemKinds)
        #expect(resetActive.physicalProfileBinding == nil)
        #expect(unchangedOther.functionItems == otherWorkspace.functionItems)
    }

    @Test func workspaceStoreMigratesLegacyWorkspaceFieldsWithoutResettingToDefaults() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("WorkspaceLegacyMigrationTests.\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let groupID = UUID()
        let fileURL = tempRoot.appendingPathComponent("Workspaces/workspaces.json")
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let legacyWorkspace = MenuBarWorkspace(
            schemaVersion: 1,
            name: "Legacy",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID)))
            ]
        )
        let legacySnapshot = WorkspaceStoreSnapshot(
            schemaVersion: 1,
            activeWorkspaceID: legacyWorkspace.id,
            workspaces: [legacyWorkspace]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(legacySnapshot)
        let object = try JSONSerialization.jsonObject(with: encoded)
        let legacyObject = removeKeys(
            [
                "referenceMode",
                "infoItems",
                "functionBarConfig",
                "infoStripConfig",
                "displayMode",
                "hoverBehavior",
                "clickBehavior"
            ],
            from: object
        )
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        try legacyData.write(to: fileURL)

        let store = WorkspaceStore(
            fileURL: fileURL,
            backupsDirectory: tempRoot.appendingPathComponent("Workspaces/backups", isDirectory: true)
        )
        let snapshot = try store.load()
        let migratedWorkspace = try #require(snapshot.workspaces.first)
        let migratedItem = try #require(migratedWorkspace.functionItems.first)

        #expect(store.lastLoadStatus == .repaired)
        #expect(migratedWorkspace.name == "Legacy")
        #expect(migratedWorkspace.schemaVersion == MenuBarWorkspace.currentSchemaVersion)
        #expect(!migratedWorkspace.infoStripConfig.isEnabled)
        if case .group(let reference) = migratedItem.kind {
            #expect(reference.groupID == groupID)
            #expect(reference.referenceMode == .linked)
        } else {
            Issue.record("Expected migrated group reference.")
        }
    }

    private func removeKeys(_ keys: Set<String>, from value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, entry in
                guard !keys.contains(entry.key) else { return }
                result[entry.key] = removeKeys(keys, from: entry.value)
            }
        }
        if let array = value as? [Any] {
            return array.map { removeKeys(keys, from: $0) }
        }
        return value
    }

    @Test func commandRouterGatesFunctionBarBehindPreviewSettings() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: "FunctionBarGate.\(UUID().uuidString)")!)
        var didShow = false
        var handlers = MenuBarCommandHandlers()
        handlers.showFunctionBar = { didShow = true }
        let router = MenuBarCommandRouter(settingsStore: store, handlers: handlers)

        var result = router.route(MenuBarCommand(action: .showFunctionBar, target: .functionBar))
        #expect(result.status == .unavailable)
        #expect(result.diagnosticReason == "functionBarDisabled")
        #expect(!didShow)

        store.workspacesPreviewEnabled = true
        store.functionBarPreviewEnabled = true
        result = router.route(MenuBarCommand(action: .showFunctionBar, target: .functionBar))
        #expect(result.status == .success)
        #expect(didShow)
    }

    @Test func setBuilderPreviewActionRespectsLivePreviewSetting() {
        let suiteName = "SetBuilderPreviewGate.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.workspacesPreviewEnabled = true
        settings.functionBarPreviewEnabled = true
        settings.setBuilderShowFunctionBarPreview = false
        let workspace = MenuBarWorkspace(name: "Builder")
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])
        let service = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let viewModel = SetBuilderViewModel(
            switchingService: service,
            groupStore: nil,
            snapshotsProvider: { [] },
            settingsStore: settings
        )
        var didPreview = false
        viewModel.onPreviewFunctionBar = {
            didPreview = true
        }

        #expect(!viewModel.canPreviewFunctionBar)
        viewModel.previewFunctionBar()
        #expect(!didPreview)
        #expect(viewModel.lastCommitResult == "Function Bar preview is disabled.")

        settings.setBuilderShowFunctionBarPreview = true
        #expect(viewModel.canPreviewFunctionBar)
        viewModel.previewFunctionBar()
        #expect(didPreview)
    }

    @Test func setBuilderAutosavesDraftsWhileSwitchingWorkspaces() {
        let suiteName = "SetBuilderAutosave.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.setBuilderAutosaveDrafts = true
        let work = MenuBarWorkspace(name: "Work")
        let focus = MenuBarWorkspace(name: "Focus")
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: work.id, workspaces: [work, focus])
        let service = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let viewModel = SetBuilderViewModel(
            switchingService: service,
            groupStore: nil,
            snapshotsProvider: { [] },
            settingsStore: settings,
            now: { Date(timeIntervalSince1970: 123) }
        )

        viewModel.selectWorkspace(id: work.id)
        viewModel.renameDraft("Work Draft")
        viewModel.selectWorkspace(id: focus.id)
        viewModel.selectWorkspace(id: work.id)

        #expect(viewModel.draft?.editedWorkspace.name == "Work Draft")
        #expect(viewModel.draft?.isDirty == true)
        #expect(viewModel.draft?.lastAutosavedAt == Date(timeIntervalSince1970: 123))
    }

    @Test func workspaceGroupUsageIndexCountsDistinctLinkedWorkspaces() {
        let groupID = UUID()
        var work = MenuBarWorkspace(name: "Work")
        work.functionItems = [
            WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .linked))),
            WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .linked)))
        ]
        var focus = MenuBarWorkspace(name: "Focus")
        focus.functionItems = [
            WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .linked)))
        ]
        var detached = MenuBarWorkspace(name: "Detached")
        detached.functionItems = [
            WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .detached)))
        ]

        let index = WorkspaceGroupUsageIndex(workspaces: [work, focus, detached])

        #expect(index.referenceCount(groupID: groupID) == 2)
        #expect(Set(index.workspacesReferencing(groupID: groupID)) == Set([work.id, focus.id]))
    }

    @Test func setBuilderLinkedGroupWarningsRespectSetting() {
        let suiteName = "SetBuilderLinkedWarning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        let groupID = UUID()
        let item = WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .linked)))
        var work = MenuBarWorkspace(name: "Work")
        work.functionItems = [item]
        var focus = MenuBarWorkspace(name: "Focus")
        focus.functionItems = [
            WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: groupID, referenceMode: .linked)))
        ]
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: work.id, workspaces: [work, focus])
        let service = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let viewModel = SetBuilderViewModel(
            switchingService: service,
            groupStore: nil,
            snapshotsProvider: { [] },
            settingsStore: settings
        )

        #expect(viewModel.linkedGroupUsageCount(for: item) == 2)
        #expect(viewModel.linkedGroupUsageCountsByItemID[item.id] == 2)
        #expect(viewModel.showsLinkedGroupWarnings)

        settings.setBuilderWarnBeforeLinkedGroupEdits = false

        #expect(!viewModel.showsLinkedGroupWarnings)
        #expect(viewModel.linkedGroupUsageCount(for: item) == 2)
        #expect(viewModel.linkedGroupUsageCountsByItemID[item.id] == 2)
    }

    @Test func functionBarStateMachineSuppressesSafeMode() {
        var machine = FunctionBarStateMachine()
        let workspaceID = UUID()

        let safeModeState = machine.show(workspaceID: workspaceID, previewEnabled: true, safeModeActive: true)
        let disabledState = machine.show(workspaceID: workspaceID, previewEnabled: false, safeModeActive: false)
        let visibleState = machine.show(workspaceID: workspaceID, previewEnabled: true, safeModeActive: false)

        #expect(safeModeState == .suspendedBySafeMode)
        #expect(disabledState == .unavailable(.previewDisabled))
        #expect(visibleState == .visible(workspaceID: workspaceID))
    }

    @Test func infoTileRegistryExcludesProTilesWhenDiscoveryIsUnavailable() {
        let workspace = MenuBarWorkspace.defaultWorkspaces()[0]
        let context = InfoTileContext(
            activeWorkspace: workspace,
            functionBarVisible: false,
            hiddenItemCount: 2,
            alwaysHiddenItemCount: 1,
            newItemCount: 4,
            healthWarningCount: 0,
            latestScanAgeSeconds: 20,
            proDiscoveryAvailable: false,
            safeModeActive: false,
            currentDate: Date(timeIntervalSince1970: 0)
        )
        let registry = InfoTileProviderRegistry()

        let snapshots = registry.snapshots(
            for: [
                InfoTileProviderID.currentWorkspace.rawValue,
                InfoTileProviderID.hiddenCount.rawValue,
                InfoTileProviderID.newItemCount.rawValue,
                InfoTileProviderID.staleScanWarning.rawValue
            ],
            context: context
        )
        let providerIDs = Set(snapshots.map(\.providerID))

        #expect(providerIDs.contains(InfoTileProviderID.currentWorkspace.rawValue))
        #expect(providerIDs.contains(InfoTileProviderID.hiddenCount.rawValue))
        #expect(!providerIDs.contains(InfoTileProviderID.newItemCount.rawValue))
        #expect(!providerIDs.contains(InfoTileProviderID.staleScanWarning.rawValue))
    }

    @Test func infoStripDiagnosticsCountsSelectedUnavailableProviders() {
        let suiteName = "InfoStripDiagnostics.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = SettingsStore(defaults: defaults)
        var workspace = MenuBarWorkspace(name: "Diagnostics")
        workspace.infoStripConfig.selectedTileProviderIDs = [
            InfoTileProviderID.currentWorkspace.rawValue,
            InfoTileProviderID.newItemCount.rawValue
        ]
        let context = InfoTileContext(
            activeWorkspace: workspace,
            functionBarVisible: false,
            hiddenItemCount: 0,
            alwaysHiddenItemCount: 0,
            newItemCount: nil,
            healthWarningCount: 0,
            latestScanAgeSeconds: nil,
            proDiscoveryAvailable: false,
            safeModeActive: false,
            currentDate: Date(timeIntervalSince1970: 0)
        )

        let snapshot = InfoStripDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            controller: nil,
            registry: InfoTileProviderRegistry(),
            context: context
        )

        #expect(snapshot.selectedTileProviderCount == 2)
        #expect(snapshot.availableTileProviderCount == 1)
        #expect(snapshot.unavailableTileProviderCount == 1)
    }

    @Test func infoTileLibraryLabelsProDiscoveryRequirements() {
        let items = InfoTileLibraryProvider().items()
        let newItems = items.first { $0.id == "info.\(InfoTileProviderID.newItemCount.rawValue)" }
        let staleScan = items.first { $0.id == "info.\(InfoTileProviderID.staleScanWarning.rawValue)" }
        let clock = items.first { $0.id == "info.\(InfoTileProviderID.clock.rawValue)" }

        #expect(newItems?.isEnabled == true)
        #expect(newItems?.badge == "Requires Pro")
        #expect(newItems?.subtitle?.contains("Requires Pro Discovery") == true)
        #expect(staleScan?.badge == "Requires Pro")
        #expect(staleScan?.subtitle?.contains("Requires Pro Discovery") == true)
        #expect(clock?.badge == "Info Strip")
        #expect(clock?.subtitle == "Local Info Strip tile")
    }

    @Test func batteryTileUsesLocalPowerSummaryAndDegradesWhenUnavailable() {
        let context = InfoTileContext(
            activeWorkspace: MenuBarWorkspace.defaultWorkspaces()[0],
            functionBarVisible: false,
            hiddenItemCount: 0,
            alwaysHiddenItemCount: 0,
            newItemCount: 0,
            healthWarningCount: 0,
            latestScanAgeSeconds: 0,
            proDiscoveryAvailable: false,
            safeModeActive: false,
            currentDate: Date(timeIntervalSince1970: 0)
        )
        let availableProvider = BatteryTileProvider(batterySummaryProvider: { "82% charging" })
        let unavailableProvider = BatteryTileProvider(batterySummaryProvider: { nil })

        #expect(availableProvider.availability(context: context) == .available)
        #expect(availableProvider.snapshot(context: context)?.subtitle == "82% charging")
        #expect(unavailableProvider.availability(context: context) == .unavailable("Battery status is unavailable on this Mac."))
        #expect(unavailableProvider.snapshot(context: context) == nil)
    }

    @Test func infoStripHoverPolicyRequiresGlobalAndWorkspaceOptIn() {
        #expect(InfoStripHoverPolicy.shouldShowFunctionBar(
            globalEnabled: true,
            workspaceBehavior: .showFunctionBar
        ))
        #expect(!InfoStripHoverPolicy.shouldShowFunctionBar(
            globalEnabled: false,
            workspaceBehavior: .showFunctionBar
        ))
        #expect(!InfoStripHoverPolicy.shouldShowFunctionBar(
            globalEnabled: true,
            workspaceBehavior: .keepInfoStrip
        ))
        #expect(!InfoStripHoverPolicy.shouldShowFunctionBar(
            globalEnabled: true,
            workspaceBehavior: .pinInfoStrip
        ))
    }

    @Test func workspaceDisplayIdleCountdownRequiresGlobalAndWorkspaceOptIn() {
        var workspace = MenuBarWorkspace.defaultWorkspaces()[0]

        #expect(!WorkspaceDisplayCoordinator.shouldStartIdleCountdown(
            globalAutoShowEnabled: false,
            workspace: workspace
        ))
        #expect(!WorkspaceDisplayCoordinator.shouldStartIdleCountdown(
            globalAutoShowEnabled: true,
            workspace: workspace
        ))

        workspace.infoStripConfig.isEnabled = true
        #expect(WorkspaceDisplayCoordinator.shouldStartIdleCountdown(
            globalAutoShowEnabled: true,
            workspace: workspace
        ))
    }

    @Test func workspaceDisplayDoesNotMarkInfoStripVisibleWhenWorkspaceDisabled() {
        let suiteName = "WorkspaceDisplayInfoStripDisabled.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.workspacesPreviewEnabled = true
        settings.functionBarPreviewEnabled = true
        settings.infoStripPreviewEnabled = true
        let workspace = MenuBarWorkspace(name: "No Strip")
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])
        let switchingService = WorkspaceSwitchingService(
            store: MemoryWorkspaceStore(snapshot: snapshot),
            initialSnapshot: snapshot
        )
        let functionBar = FunctionBarController(
            settingsStore: settings,
            switchingService: switchingService,
            resolver: FunctionBarItemResolver(
                groupsProvider: { [] },
                snapshotsProvider: { [] },
                proDiscoveryAvailable: { false },
                accessibilityAvailable: { false }
            ),
            dispatcher: FunctionBarActionDispatcher(
                routeCommand: { .success($0, message: "Routed.") },
                openSettings: {},
                openRecovery: {},
                openWorkspacePreview: {},
                showFunctionBar: {},
                hideFunctionBar: {},
                showInfoStrip: {},
                hideInfoStrip: {}
            ),
            safeModeActive: { false }
        )
        let infoStrip = InfoStripController(
            settingsStore: settings,
            switchingService: switchingService,
            safeModeActive: { false },
            contextBuilder: { InfoTileContext.empty },
            actionDispatcher: { _ in },
            showFunctionBar: {}
        )
        let coordinator = WorkspaceDisplayCoordinator(
            functionBarController: functionBar,
            infoStripController: infoStrip,
            switchingService: switchingService,
            safeModeActive: { false },
            infoStripAutoShowEnabled: { true }
        )

        coordinator.showInfoStrip()

        #expect(infoStrip.displayState == .unavailable(.workspaceDisabled))
        #expect(coordinator.state == .unavailable(.infoStripUnavailable))
    }

    @Test func functionBarResolverUsesValidInfoStripCommandIcon() {
        let resolver = FunctionBarItemResolver(
            groupsProvider: { [] },
            snapshotsProvider: { [] },
            proDiscoveryAvailable: { false },
            accessibilityAvailable: { false }
        )
        let item = WorkspaceItem.command(.showInfoStrip)
        let model = resolver.resolve(item: item)

        #expect(model.icon.systemName == "info.circle")
    }

    @Test func functionBarProxyActionsRouteThroughCommandCenter() {
        var routedCommands: [MenuBarCommand] = []
        let dispatcher = FunctionBarActionDispatcher(
            routeCommand: { command in
                routedCommands.append(command)
                return .success(command, message: "Routed.")
            },
            openSettings: {},
            openRecovery: {},
            openWorkspacePreview: {},
            showFunctionBar: {},
            hideFunctionBar: {},
            showInfoStrip: {},
            hideInfoStrip: {}
        )
        let item = FunctionBarItemModel(
            id: UUID(),
            kind: .menuBarItem(MenuBarItemReference(stableHash: "proxy-hash")),
            title: "Proxy",
            subtitle: nil,
            icon: FunctionBarIcon(systemName: "app"),
            status: .available,
            availability: .available,
            badge: nil
        )

        for action in FunctionBarProxyAction.allCases {
            let result = dispatcher.activate(item, proxyAction: action)
            #expect(result.status == .success)
        }

        #expect(routedCommands.map(\.action) == [
            .revealItem,
            .highlightItem,
            .showItemInSecondBar,
            .openOwningApp
        ])
        #expect(routedCommands.allSatisfy { $0.target == .menuBarItem(id: "proxy-hash") })
    }

    @Test func functionBarProxyActionsRejectNonProxyItems() {
        let dispatcher = FunctionBarActionDispatcher(
            routeCommand: { command in .success(command, message: "Unexpected route.") },
            openSettings: {},
            openRecovery: {},
            openWorkspacePreview: {},
            showFunctionBar: {},
            hideFunctionBar: {},
            showInfoStrip: {},
            hideInfoStrip: {}
        )
        let item = FunctionBarItemModel(
            id: UUID(),
            kind: .command(.showFunctionBar),
            title: "Show Function Bar",
            subtitle: nil,
            icon: FunctionBarIcon(systemName: "rectangle.bottomthird.inset.filled"),
            status: .available,
            availability: .available,
            badge: nil
        )

        let result = dispatcher.activate(item, proxyAction: .reveal)

        #expect(result.status == .noOp)
        #expect(result.diagnosticReason == "nonProxyItem")
    }

    @Test func setBuilderDiagnosticsSnapshotUsesRedactedAggregateCounts() {
        let knownGroup = IconGroup(name: "Utilities")
        let detachedCopy = IconGroup(name: "Detached")
        let missingGroupID = UUID()
        let missingSourceID = UUID()
        let workspace = MenuBarWorkspace(
            name: "Diagnostics",
            functionItems: [
                WorkspaceItem(kind: .group(WorkspaceGroupReference(groupID: knownGroup.id, referenceMode: .linked))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(
                    groupID: missingGroupID,
                    referenceMode: .detached,
                    sourceGroupID: knownGroup.id
                ))),
                WorkspaceItem(kind: .group(WorkspaceGroupReference(
                    groupID: detachedCopy.id,
                    referenceMode: .detached,
                    sourceGroupID: missingSourceID
                ))),
                WorkspaceItem(kind: .menuBarItem(MenuBarItemReference(stableHash: "proxy-hash"))),
                .command(.showFunctionBar),
                .spacer(),
                .divider()
            ]
        )
        let emptyWorkspace = MenuBarWorkspace(name: "Empty")

        let snapshot = SetBuilderDiagnosticsSnapshot.make(
            previewEnabled: true,
            workspaces: [workspace, emptyWorkspace],
            groups: [knownGroup, detachedCopy],
            lastCommitResult: "Saved.",
            lastValidationIssueCount: 2,
            availableMenuBarItemHashes: []
        )

        #expect(snapshot.previewEnabled)
        #expect(snapshot.workspaceCount == 2)
        #expect(snapshot.workspaceWithItemsCount == 1)
        #expect(snapshot.totalWorkspaceItemCount == 7)
        #expect(snapshot.linkedGroupReferenceCount == 1)
        #expect(snapshot.detachedGroupReferenceCount == 2)
        #expect(snapshot.missingGroupReferenceCount == 1)
        #expect(snapshot.detachedSourceGroupMissingCount == 1)
        #expect(snapshot.menuBarProxyReferenceCount == 1)
        #expect(snapshot.unresolvedMenuBarProxyReferenceCount == 1)
        #expect(snapshot.commandItemCount == 1)
        #expect(snapshot.spacerDividerCount == 2)
        #expect(snapshot.lastCommitResult == "Saved.")
        #expect(snapshot.lastValidationIssueCount == 2)
    }

    @Test func setBuilderDropValidatorCoversPhase19Guardrails() {
        let workspace = MenuBarWorkspace(name: "Builder")
        let group = IconGroup(name: "Utilities")
        let validator = SetBuilderDropValidator()

        let commandPayload = SetBuilderDragPayload(
            payloadID: UUID(),
            payloadKind: .command(WorkspaceCommandReference.findIcon.actionID),
            sourceKind: .library
        )
        let groupPayload = SetBuilderDragPayload(
            payloadID: UUID(),
            payloadKind: .group(group.id),
            sourceKind: .library
        )
        let proxyPayload = SetBuilderDragPayload(
            payloadID: UUID(),
            payloadKind: .menuBarItemHash("stable-hash"),
            sourceKind: .library
        )
        let target = SetBuilderDropTarget.workspaceCanvas(workspaceID: workspace.id, index: 0)

        #expect(validator.validate(
            payload: commandPayload,
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true
        ).isAccepted)
        #expect(validator.validate(
            payload: groupPayload,
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true
        ).isAccepted)
        #expect(!validator.validate(
            payload: commandPayload,
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true,
            safeModeActive: true
        ).isAccepted)
        #expect(!validator.validate(
            payload: SetBuilderDragPayload(payloadID: UUID(), payloadKind: .command("unsupported.command"), sourceKind: .library),
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true
        ).isAccepted)
        #expect(!validator.validate(
            payload: proxyPayload,
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true,
            proDiscoveryAvailable: false
        ).isAccepted)
        #expect(!validator.validate(
            payload: proxyPayload,
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true,
            availableMenuBarItemHashes: ["other-hash"]
        ).isAccepted)
        #expect(validator.validate(
            payload: proxyPayload,
            target: target,
            workspace: workspace,
            groups: [group],
            dragDropEnabled: true,
            availableMenuBarItemHashes: ["stable-hash"]
        ).isAccepted)
    }
}

@MainActor
private final class MemoryWorkspaceStore: WorkspaceStoreProtocol {
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
