import Foundation

nonisolated struct WorkspaceIntegrationDiagnosticsSnapshot: Codable, Equatable, Sendable {
    var integrationEnabled: Bool
    var workspaceCount: Int
    var activeWorkspacePresent: Bool
    var indexedItemReferenceCount: Int
    var assignedItemReferenceCount: Int
    var unassignedItemReferenceCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var newItemAssignableCount: Int
    var missingWorkspaceReferenceCount: Int
    var missingGroupReferenceCount: Int
    var missingProfileBindingCount: Int
    var functionBarFallbackEnabled: Bool
    var physicalProfileBindingCount: Int
    var lastAssignmentResult: String?
    var lastCrowdedRescueWorkspaceDecision: String?

    @MainActor
    static func make(
        settingsStore: SettingsStore,
        usageSnapshot: WorkspaceUsageIndexSnapshot,
        newItemInbox: NewMenuBarItemInbox?,
        missingProfileBindingCount: Int = 0,
        functionBarFallbackEnabled: Bool = false,
        physicalProfileBindingCount: Int = 0,
        lastAssignmentResult: WorkspaceAssignmentResult? = nil,
        lastCrowdedRescueWorkspaceDecision: CrowdedRevealDecision? = nil
    ) -> WorkspaceIntegrationDiagnosticsSnapshot {
        let assigned = usageSnapshot.usagesByItemHash.values.filter { !$0.isUnassigned }.count
        let unassigned = usageSnapshot.usagesByItemHash.values.filter(\.isUnassigned).count
        let linked = usageSnapshot.usagesByItemHash.values.reduce(0) { $0 + $1.linkedGroupReferenceCount }
        let detached = usageSnapshot.usagesByItemHash.values.reduce(0) { $0 + $1.detachedGroupReferenceCount }

        return WorkspaceIntegrationDiagnosticsSnapshot(
            integrationEnabled: settingsStore.workspacesPreviewEnabled,
            workspaceCount: usageSnapshot.indexedWorkspaceCount,
            activeWorkspacePresent: usageSnapshot.activeWorkspaceID != nil,
            indexedItemReferenceCount: usageSnapshot.usagesByItemHash.count,
            assignedItemReferenceCount: assigned,
            unassignedItemReferenceCount: unassigned,
            linkedGroupReferenceCount: linked,
            detachedGroupReferenceCount: detached,
            newItemAssignableCount: newItemInbox?.reviewCount ?? 0,
            missingWorkspaceReferenceCount: 0,
            missingGroupReferenceCount: usageSnapshot.missingGroupReferenceCount,
            missingProfileBindingCount: missingProfileBindingCount,
            functionBarFallbackEnabled: functionBarFallbackEnabled,
            physicalProfileBindingCount: physicalProfileBindingCount,
            lastAssignmentResult: lastAssignmentResult.map {
                WorkspaceIntegrationDiagnosticsRedactor.redactedAssignmentStatus($0)
            },
            lastCrowdedRescueWorkspaceDecision: lastCrowdedRescueWorkspaceDecision.map {
                WorkspaceIntegrationDiagnosticsRedactor.redactedDecision($0)
            }
        )
    }
}
