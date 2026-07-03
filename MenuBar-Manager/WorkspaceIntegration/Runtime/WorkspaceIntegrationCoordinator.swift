import Foundation

@MainActor
final class WorkspaceIntegrationCoordinator {
    private let usageIndex = WorkspaceUsageIndex()
    private let switchingService: WorkspaceSwitchingService
    private let groupsProvider: () -> [IconGroup]
    private let settingsStore: SettingsStore
    private let newItemInboxStore: NewMenuBarItemInboxStore?

    init(
        switchingService: WorkspaceSwitchingService,
        groupsProvider: @escaping () -> [IconGroup],
        settingsStore: SettingsStore,
        newItemInboxStore: NewMenuBarItemInboxStore? = nil
    ) {
        self.switchingService = switchingService
        self.groupsProvider = groupsProvider
        self.settingsStore = settingsStore
        self.newItemInboxStore = newItemInboxStore
    }

    func rebuildUsageIndex() -> WorkspaceUsageIndexSnapshot {
        usageIndex.rebuild(snapshot: switchingService.currentSnapshot(), groups: groupsProvider())
    }

    func makeDiagnostics(
        missingProfileBindingCount: Int = 0,
        functionBarFallbackEnabled: Bool = false,
        lastAssignmentResult: WorkspaceAssignmentResult? = nil,
        lastCrowdedRescueWorkspaceDecision: CrowdedRevealDecision? = nil
    ) -> WorkspaceIntegrationDiagnosticsSnapshot {
        WorkspaceIntegrationDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            usageSnapshot: rebuildUsageIndex(),
            newItemInbox: newItemInboxStore?.inbox,
            missingProfileBindingCount: missingProfileBindingCount,
            functionBarFallbackEnabled: functionBarFallbackEnabled,
            physicalProfileBindingCount: switchingService.currentSnapshot().workspaces.filter { $0.physicalProfileBinding != nil }.count,
            lastAssignmentResult: lastAssignmentResult,
            lastCrowdedRescueWorkspaceDecision: lastCrowdedRescueWorkspaceDecision
        )
    }
}
