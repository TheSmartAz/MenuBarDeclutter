import Foundation

nonisolated struct WorkspacePhysicalProfilePlanner: Sendable {
    func plan(
        for workspace: MenuBarWorkspace,
        availableProfileIDs: Set<UUID>
    ) -> WorkspacePhysicalPlan {
        guard let binding = workspace.physicalProfileBinding else {
            return WorkspacePhysicalPlan(
                workspaceID: workspace.id,
                profileID: nil,
                applyMode: .none,
                safeChanges: [],
                ignoredRiskyChanges: [],
                diagnosticReason: "noPhysicalProfileBinding"
            )
        }

        guard availableProfileIDs.contains(binding.profileID) else {
            return WorkspacePhysicalPlan(
                workspaceID: workspace.id,
                profileID: binding.profileID,
                applyMode: binding.applyMode,
                safeChanges: [],
                ignoredRiskyChanges: ["Profile reference is missing; no settings will be applied."],
                diagnosticReason: "missingProfileBinding"
            )
        }

        switch binding.applyMode {
        case .none:
            return WorkspacePhysicalPlan(
                workspaceID: workspace.id,
                profileID: binding.profileID,
                applyMode: .none,
                safeChanges: [],
                ignoredRiskyChanges: [],
                diagnosticReason: "physicalProfileApplyDisabled"
            )
        case .dryRunOnly:
            return WorkspacePhysicalPlan(
                workspaceID: workspace.id,
                profileID: binding.profileID,
                applyMode: .dryRunOnly,
                safeChanges: ["Preview the linked Profile without applying settings."],
                ignoredRiskyChanges: ["Physical menu bar item movement remains manual."],
                diagnosticReason: "dryRunOnly"
            )
        case .applySafeBasicSettings:
            return WorkspacePhysicalPlan(
                workspaceID: workspace.id,
                profileID: binding.profileID,
                applyMode: .applySafeBasicSettings,
                safeChanges: ["Apply safe Basic settings from the linked Profile."],
                ignoredRiskyChanges: ["Menu bar item movement is never applied automatically."],
                diagnosticReason: "safeBasicSettingsOnly"
            )
        }
    }
}
