import Foundation

nonisolated enum WorkspaceAssignmentCommandID: String, CaseIterable, Sendable {
    case assignCurrent = "workspace.assign.current"
    case assignSelected = "workspace.assign.selected"
    case assignGroup = "workspace.assign.group"
    case assignNewGroup = "workspace.assign.newGroup"
    case removeFromWorkspace = "workspace.item.removeFromWorkspace"
    case showUsage = "workspace.item.showUsage"
    case markUnassignedReviewed = "workspace.item.markUnassignedReviewed"
    case profileBindingDryRun = "workspace.profileBinding.dryRun"
    case profileBindingApplySafe = "workspace.profileBinding.applySafe"
    case crowdedRescueOpenFunctionBar = "crowdedRescue.openFunctionBar"
    case findIconFilterWorkspace = "findIcon.filter.workspace"
    case placementPlannerWorkspaceRecommendation = "placementPlanner.workspaceRecommendation"
}

nonisolated struct WorkspaceAssignmentCommandAdapter: Sendable {
    func isPublicAutomationCommand(_ commandID: WorkspaceAssignmentCommandID) -> Bool {
        false
    }
}
