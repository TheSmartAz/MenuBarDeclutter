import Foundation
import Observation

@MainActor
@Observable
final class SetBuilderViewModel {
    var workspaces: [MenuBarWorkspace] = []
    var selectedWorkspaceID: UUID?
    var draft: SetBuilderDraft?
    var selection: SetBuilderSelection = .none
    var lastCommitResult: String?

    @ObservationIgnored private let switchingService: WorkspaceSwitchingService
    @ObservationIgnored private let groupStore: IconGroupStore?
    @ObservationIgnored private let newItemInboxStore: NewMenuBarItemInboxStore?
    @ObservationIgnored private let snapshotsProvider: () -> [MenuBarItemSnapshot]
    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var draftStore = SetBuilderDraftStore()
    @ObservationIgnored private var pendingDetachedGroupIDs: Set<UUID> = []
    @ObservationIgnored var onCommitted: (() -> Void)?
    @ObservationIgnored var onPreviewFunctionBar: (() -> Void)?

    init(
        switchingService: WorkspaceSwitchingService,
        groupStore: IconGroupStore?,
        newItemInboxStore: NewMenuBarItemInboxStore? = nil,
        snapshotsProvider: @escaping () -> [MenuBarItemSnapshot],
        settingsStore: SettingsStore,
        now: @escaping () -> Date = { Date() }
    ) {
        self.switchingService = switchingService
        self.groupStore = groupStore
        self.newItemInboxStore = newItemInboxStore
        self.snapshotsProvider = snapshotsProvider
        self.settingsStore = settingsStore
        self.now = now
        refresh()
    }

    func refresh() {
        let snapshot = switchingService.currentSnapshot()
        workspaces = snapshot.workspaces.filter { !$0.isArchived }
        selectedWorkspaceID = selectedWorkspaceID ?? snapshot.activeWorkspaceID ?? workspaces.first?.id
        if draft == nil, let selected = selectedWorkspace {
            draft = draftForWorkspace(selected)
        }
    }

    var selectedWorkspace: MenuBarWorkspace? {
        workspaces.first { $0.id == selectedWorkspaceID }
    }

    var groups: [IconGroup] {
        groupStore?.groups ?? []
    }

    var commandLibrary: [SetBuilderLibraryItem] {
        CommandLibraryProvider(showAdvancedItems: settingsStore.setBuilderShowAdvancedLibraryItems).items()
    }

    var groupLibrary: [SetBuilderLibraryItem] {
        GroupLibraryProvider(groups: groups).items()
    }

    var proxyLibrary: [SetBuilderLibraryItem] {
        MenuBarItemLibraryProvider(
            snapshots: snapshotsProvider(),
            proDiscoveryAvailable: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled,
            accessibilityAvailable: settingsStore.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue
        ).items()
    }

    var newItemLibrary: [SetBuilderLibraryItem] {
        NewItemLibraryProvider(inbox: newItemInboxStore?.inbox).items()
    }

    var unassignedItemLibrary: [SetBuilderLibraryItem] {
        UnassignedMenuBarItemLibraryProvider(
            snapshots: snapshotsProvider(),
            workspaceSnapshot: switchingService.currentSnapshot(),
            groups: groups,
            proDiscoveryAvailable: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled,
            accessibilityAvailable: settingsStore.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue
        ).items()
    }

    var layoutLibrary: [SetBuilderLibraryItem] {
        SpacerLibraryProvider().items()
    }

    var infoTileLibrary: [SetBuilderLibraryItem] {
        InfoTileLibraryProvider().items()
    }

    var diagnosticsSnapshot: SetBuilderDiagnosticsSnapshot {
        SetBuilderDiagnosticsSnapshot.make(
            previewEnabled: settingsStore.setBuilderPreviewEnabled,
            workspaces: switchingService.currentSnapshot().workspaces,
            groups: groups,
            lastCommitResult: lastCommitResult,
            lastValidationIssueCount: draft?.validationIssues.count ?? 0,
            availableMenuBarItemHashes: availableMenuBarItemHashesForDiagnostics
        )
    }

    var canPreviewFunctionBar: Bool {
        settingsStore.workspacesPreviewEnabled
            && settingsStore.functionBarPreviewEnabled
            && settingsStore.setBuilderShowFunctionBarPreview
    }

    var showsLinkedGroupWarnings: Bool {
        settingsStore.setBuilderWarnBeforeLinkedGroupEdits
    }

    var linkedGroupUsageCountsByItemID: [UUID: Int] {
        guard let draft else { return [:] }
        let usageIndex = WorkspaceGroupUsageIndex(workspaces: workspacesIncludingDraft(draft))

        return Dictionary(uniqueKeysWithValues: draft.editedWorkspace.functionItems.compactMap { item in
            guard case .group(let reference) = item.kind,
                  reference.referenceMode == .linked else {
                return nil
            }
            return (item.id, usageIndex.referenceCount(groupID: reference.groupID))
        })
    }

    func linkedGroupUsageCount(for item: WorkspaceItem) -> Int? {
        guard case .group(let reference) = item.kind,
              reference.referenceMode == .linked else {
            return nil
        }

        guard let draft else { return nil }

        return WorkspaceGroupUsageIndex(workspaces: workspacesIncludingDraft(draft))
            .referenceCount(groupID: reference.groupID)
    }

    func selectWorkspace(id: UUID) {
        saveCurrentDraftIfNeeded()
        selectedWorkspaceID = id
        if let workspace = workspaces.first(where: { $0.id == id }) {
            draft = draftForWorkspace(workspace)
        }
        selection = .workspace(id)
    }

    func createWorkspace() {
        let result = switchingService.createWorkspace(WorkspaceDraft(name: "New Workspace"))
        lastCommitResult = result.message
        refresh()
        selectedWorkspaceID = result.activeWorkspaceID
        if let selectedWorkspace {
            draft = SetBuilderDraft(workspace: selectedWorkspace)
        }
    }

    func duplicateSelectedWorkspace() {
        guard let id = selectedWorkspaceID else { return }
        let result = switchingService.duplicateWorkspace(id: id)
        lastCommitResult = result.message
        refresh()
        selectedWorkspaceID = result.activeWorkspaceID
        if let selectedWorkspace {
            draft = SetBuilderDraft(workspace: selectedWorkspace)
        }
    }

    func archiveSelectedWorkspace() {
        guard let id = selectedWorkspaceID else { return }
        let result = switchingService.archiveWorkspace(id: id)
        lastCommitResult = result.message
        selectedWorkspaceID = result.activeWorkspaceID
        draft = nil
        refresh()
    }

    func switchSelectedWorkspace() {
        guard let id = selectedWorkspaceID else { return }
        let result = switchingService.switchWorkspace(id: id, source: .setBuilder)
        lastCommitResult = result.message
        refresh()
    }

    func renameDraft(_ name: String) {
        guard var draft else { return }
        draft.editedWorkspace.name = name
        draft.editedWorkspace.updatedAt = now()
        draft.pendingChanges.append(.renameWorkspace(name))
        draft.isDirty = true
        setDraft(draft)
    }

    func addLibraryItem(_ item: SetBuilderLibraryItem) {
        guard var draft, item.isEnabled else { return }
        let workspaceItem: WorkspaceItem?
        switch item.kind {
        case .command(let command):
            workspaceItem = WorkspaceItem.command(command, now: now())
        case .group(let groupID):
            let reference = WorkspaceGroupReference(
                groupID: groupID,
                referenceMode: settingsStore.effectiveSetBuilderDefaultGroupReferenceMode(),
                createdAt: now()
            )
            workspaceItem = WorkspaceItem(kind: .group(reference), createdAt: now(), updatedAt: now())
        case .menuBarItem(let reference):
            workspaceItem = WorkspaceItem(kind: .menuBarItem(reference), createdAt: now(), updatedAt: now())
        case .spacer:
            workspaceItem = .spacer(now: now())
        case .divider:
            workspaceItem = .divider(now: now())
        case .infoTile(let providerID):
            addInfoTile(providerID)
            return
        }
        guard let workspaceItem else { return }
        draft.editedWorkspace.functionItems.append(workspaceItem)
        draft.editedWorkspace.updatedAt = now()
        draft.pendingChanges.append(.addItem(workspaceItem))
        draft.isDirty = true
        setDraft(draft)
    }

    func addDetachedGroup(groupID: UUID) {
        guard let source = groupStore?.groups.first(where: { $0.id == groupID }) else { return }
        let copyName = source.isProtected ? "Protected Group Copy" : "\(source.name) Copy"
        let copy = groupStore?.createGroup(name: copyName)
        guard let copy else { return }
        groupStore?.updateGroup(id: copy.id) { group in
            group.symbolName = source.symbolName
            group.colorName = source.colorName
            group.itemRefs = source.itemRefs
        }
        let reference = WorkspaceGroupReference(
            groupID: copy.id,
            referenceMode: .detached,
            sourceGroupID: groupID,
            createdAt: now()
        )
        pendingDetachedGroupIDs.insert(copy.id)
        addWorkspaceItem(WorkspaceItem(kind: .group(reference), createdAt: now(), updatedAt: now()))
    }

    func removeItem(id: UUID) {
        guard var draft else { return }
        let removedItems = draft.editedWorkspace.functionItems.filter { $0.id == id }
        draft.editedWorkspace.functionItems.removeAll { $0.id == id }
        draft.editedWorkspace.updatedAt = now()
        draft.pendingChanges.append(.removeItem(id))
        draft.isDirty = true
        if selection == .item(id) {
            selection = .none
        }
        setDraft(draft)
        removePendingDetachedGroups(referencedBy: removedItems)
    }

    func moveItem(id: UUID, direction: Int) {
        guard var draft,
              let index = draft.editedWorkspace.functionItems.firstIndex(where: { $0.id == id }) else { return }
        let newIndex = index + direction
        guard draft.editedWorkspace.functionItems.indices.contains(newIndex) else { return }
        let item = draft.editedWorkspace.functionItems.remove(at: index)
        draft.editedWorkspace.functionItems.insert(item, at: newIndex)
        draft.editedWorkspace.updatedAt = now()
        draft.pendingChanges.append(.moveItem(itemID: id, from: index, to: newIndex))
        draft.isDirty = true
        setDraft(draft)
    }

    func setInfoStripEnabled(_ isEnabled: Bool) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.isEnabled = isEnabled
        updateInfoStripConfigDraft(draft)
    }

    func setInfoStripIdleDelay(_ seconds: Int) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.idleDelaySeconds = seconds
        updateInfoStripConfigDraft(draft)
    }

    func setInfoStripRotationInterval(_ seconds: Int) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.rotationIntervalSeconds = seconds
        updateInfoStripConfigDraft(draft)
    }

    func setInfoStripShowTileLabels(_ showTileLabels: Bool) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.showTileLabels = showTileLabels
        updateInfoStripConfigDraft(draft)
    }

    func setInfoStripCompactMode(_ compactMode: Bool) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.compactMode = compactMode
        updateInfoStripConfigDraft(draft)
    }

    func setInfoStripHoverBehavior(_ behavior: WorkspaceInfoStripHoverBehavior) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.hoverBehavior = behavior
        updateInfoStripConfigDraft(draft)
    }

    func addInfoTile(_ providerID: String) {
        guard var draft else { return }
        if !draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.contains(providerID) {
            draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.append(providerID)
        }
        updateInfoStripConfigDraft(draft)
    }

    func removeInfoTile(_ providerID: String) {
        guard var draft else { return }
        draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.removeAll { $0 == providerID }
        updateInfoStripConfigDraft(draft)
    }

    func moveInfoTile(providerID: String, direction: Int) {
        guard var draft,
              let index = draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.firstIndex(of: providerID) else { return }
        let newIndex = index + direction
        guard draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.indices.contains(newIndex) else { return }
        let item = draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.remove(at: index)
        draft.editedWorkspace.infoStripConfig.selectedTileProviderIDs.insert(item, at: newIndex)
        updateInfoStripConfigDraft(draft)
    }

    private func updateInfoStripConfigDraft(_ updatedDraft: SetBuilderDraft) {
        var draft = updatedDraft
        draft.editedWorkspace.updatedAt = now()
        draft.pendingChanges.append(.updateInfoStripConfig(draft.editedWorkspace.infoStripConfig))
        draft.isDirty = true
        setDraft(draft)
    }

    func commitDraft() {
        guard var draft else { return }
        var issues: [WorkspaceValidationIssue] = []
        draft.editedWorkspace = WorkspaceValidation.repair(draft.editedWorkspace, issues: &issues, now: now())
        if !issues.isEmpty {
            draft.validationIssues = issues.map { SetBuilderValidationIssue(message: $0.kind.rawValue) }
        }
        let result = switchingService.updateWorkspace(draft.editedWorkspace)
        lastCommitResult = result.message
        pendingDetachedGroupIDs.removeAll()
        draftStore.discard(workspaceID: draft.workspaceID)
        self.draft = SetBuilderDraft(workspace: draft.editedWorkspace)
        refresh()
        onCommitted?()
    }

    func revertDraft() {
        guard let draft else { return }
        discardPendingDetachedGroups()
        draftStore.discard(workspaceID: draft.workspaceID)
        self.draft = SetBuilderDraft(workspace: draft.originalWorkspace)
        lastCommitResult = "Draft reverted."
    }

    func previewFunctionBar() {
        guard canPreviewFunctionBar else {
            lastCommitResult = "Function Bar preview is disabled."
            return
        }
        onPreviewFunctionBar?()
    }

    private func addWorkspaceItem(_ item: WorkspaceItem) {
        guard var draft else { return }
        draft.editedWorkspace.functionItems.append(item)
        draft.editedWorkspace.updatedAt = now()
        draft.pendingChanges.append(.addItem(item))
        draft.isDirty = true
        setDraft(draft)
    }

    private var availableMenuBarItemHashesForDiagnostics: Set<String>? {
        guard settingsStore.proModeEnabled,
              settingsStore.accessibilityDiscoveryEnabled,
              settingsStore.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue else {
            return nil
        }
        return Set(snapshotsProvider().map(\.id))
    }

    private func draftForWorkspace(_ workspace: MenuBarWorkspace) -> SetBuilderDraft {
        if settingsStore.setBuilderAutosaveDrafts,
           let saved = draftStore.draft(workspaceID: workspace.id) {
            return saved
        }
        return SetBuilderDraft(workspace: workspace)
    }

    private func workspacesIncludingDraft(_ draft: SetBuilderDraft) -> [MenuBarWorkspace] {
        switchingService.currentSnapshot().workspaces
            .filter { !$0.isArchived }
            .map { workspace in
                workspace.id == draft.editedWorkspace.id ? draft.editedWorkspace : workspace
            }
    }

    private func setDraft(_ draft: SetBuilderDraft) {
        var updatedDraft = draft
        if settingsStore.setBuilderAutosaveDrafts, updatedDraft.isDirty {
            updatedDraft.lastAutosavedAt = now()
            draftStore.save(updatedDraft)
        }
        self.draft = updatedDraft
    }

    private func saveCurrentDraftIfNeeded() {
        guard settingsStore.setBuilderAutosaveDrafts,
              let draft,
              draft.isDirty else {
            return
        }
        draftStore.save(draft)
    }

    private func removePendingDetachedGroups(referencedBy items: [WorkspaceItem]) {
        for item in items {
            guard case .group(let reference) = item.kind,
                  reference.referenceMode == .detached,
                  pendingDetachedGroupIDs.contains(reference.groupID) else {
                continue
            }
            groupStore?.removeGroup(id: reference.groupID)
            pendingDetachedGroupIDs.remove(reference.groupID)
        }
    }

    private func discardPendingDetachedGroups() {
        for groupID in pendingDetachedGroupIDs {
            groupStore?.removeGroup(id: groupID)
        }
        pendingDetachedGroupIDs.removeAll()
    }
}

@MainActor
struct SetBuilderCommitService {
    func commit(_ draft: SetBuilderDraft, switchingService: WorkspaceSwitchingService) -> WorkspaceSwitchResult {
        switchingService.updateWorkspace(draft.editedWorkspace)
    }
}

@MainActor
struct SetBuilderDraftStore {
    private(set) var drafts: [UUID: SetBuilderDraft] = [:]

    func draft(workspaceID: UUID) -> SetBuilderDraft? {
        drafts[workspaceID]
    }

    mutating func save(_ draft: SetBuilderDraft) {
        drafts[draft.workspaceID] = draft
    }

    mutating func discard(workspaceID: UUID) {
        drafts.removeValue(forKey: workspaceID)
    }
}

@MainActor
struct SetBuilderValidationService {
    func validate(_ draft: SetBuilderDraft) -> [SetBuilderValidationIssue] {
        var issues: [WorkspaceValidationIssue] = []
        _ = WorkspaceValidation.repair(draft.editedWorkspace, issues: &issues)
        return issues.map { SetBuilderValidationIssue(message: $0.kind.rawValue) }
    }
}
