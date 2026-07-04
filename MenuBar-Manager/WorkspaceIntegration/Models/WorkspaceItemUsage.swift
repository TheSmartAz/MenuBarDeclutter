import Foundation

nonisolated struct WorkspaceItemUsage: Equatable, Sendable {
    var itemHash: String
    var workspaceIDs: [UUID]
    var groupIDs: [UUID]
    var directWorkspaceCount: Int
    var groupReferenceCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var isUsedInActiveWorkspace: Bool
    var isUnassigned: Bool

    static func empty(itemHash: String, isUnassigned: Bool = true) -> WorkspaceItemUsage {
        WorkspaceItemUsage(
            itemHash: itemHash,
            workspaceIDs: [],
            groupIDs: [],
            directWorkspaceCount: 0,
            groupReferenceCount: 0,
            linkedGroupReferenceCount: 0,
            detachedGroupReferenceCount: 0,
            isUsedInActiveWorkspace: false,
            isUnassigned: isUnassigned
        )
    }
}

nonisolated struct WorkspaceUsageIndexSnapshot: Equatable, Sendable {
    var activeWorkspaceID: UUID?
    var usagesByItemHash: [String: WorkspaceItemUsage]
    var workspaceIDsByGroupID: [UUID: [UUID]]
    var groupIDsByItemHash: [String: [UUID]]
    var missingGroupReferenceCount: Int
    var indexedWorkspaceCount: Int

    static let empty = WorkspaceUsageIndexSnapshot(
        activeWorkspaceID: nil,
        usagesByItemHash: [:],
        workspaceIDsByGroupID: [:],
        groupIDsByItemHash: [:],
        missingGroupReferenceCount: 0,
        indexedWorkspaceCount: 0
    )

    func usage(for itemHash: String) -> WorkspaceItemUsage {
        usagesByItemHash[itemHash] ?? .empty(itemHash: itemHash)
    }
}

nonisolated enum WorkspaceReferenceStatus: String, Codable, Equatable, Sendable {
    case available
    case unassigned
    case missingReference
    case stale
    case protected
}

nonisolated enum WorkspaceIntegrationFeatureStatus: String, Codable, Equatable, Sendable {
    case stable
    case preview
    case labs
    case experimental
    case deferred
    case internalOnly

    var displayName: String {
        switch self {
        case .stable: "Stable"
        case .preview: "Preview"
        case .labs: "Labs"
        case .experimental: "Labs"
        case .deferred: "Deferred"
        case .internalOnly: "Internal"
        }
    }
}

nonisolated enum WorkspaceUsageBadge: String, Equatable, Sendable {
    case currentWorkspace
    case usedInWorkspaces
    case unassigned
    case new
    case linkedGroup
    case detachedGroup
    case missingReference
    case stale
    case protected
    case profileBoundWorkspace

    var title: String {
        switch self {
        case .currentWorkspace: "Current Workspace"
        case .usedInWorkspaces: "Used in Workspaces"
        case .unassigned: "Unassigned"
        case .new: "New"
        case .linkedGroup: "Linked Group"
        case .detachedGroup: "Detached"
        case .missingReference: "Missing"
        case .stale: "Stale"
        case .protected: "Protected"
        case .profileBoundWorkspace: "Profile Bound"
        }
    }
}

nonisolated struct WorkspacePhysicalPlan: Equatable, Sendable {
    var workspaceID: UUID
    var profileID: UUID?
    var applyMode: WorkspacePhysicalProfileApplyMode
    var safeChanges: [String]
    var ignoredRiskyChanges: [String]
    var diagnosticReason: String?

    var mutatesPhysicalLayout: Bool { false }
}
