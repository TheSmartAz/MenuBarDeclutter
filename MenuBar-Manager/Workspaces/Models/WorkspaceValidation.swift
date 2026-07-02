import Foundation

nonisolated enum WorkspaceValidationConstants {
    static let maxWorkspaces = 50
    static let maxFunctionItems = 64
    static let maxInfoItems = 32
    static let maxWorkspaceNameLength = 80
    static let minRotationIntervalSeconds = 3
    static let maxRotationIntervalSeconds = 300
    static let minIdleDelaySeconds = 1
    static let maxIdleDelaySeconds = 120
    static let maxSelectedInfoTileProviderIDs = 20
}

nonisolated struct WorkspaceValidationResult: Equatable, Sendable {
    var repairedWorkspaces: [MenuBarWorkspace]
    var issues: [WorkspaceValidationIssue]
    var selectedActiveWorkspaceID: UUID
    var didRepair: Bool
}

nonisolated struct WorkspaceValidationIssue: Codable, Equatable, Sendable {
    var kind: WorkspaceValidationIssueKind
    var count: Int

    init(_ kind: WorkspaceValidationIssueKind, count: Int = 1) {
        self.kind = kind
        self.count = count
    }
}

nonisolated enum WorkspaceValidationIssueKind: String, Codable, Equatable, Sendable {
    case emptyNameRepaired
    case nameClamped
    case iconDefaulted
    case unsupportedSchemaRepaired
    case tooManyWorkspacesClamped
    case tooManyFunctionItemsClamped
    case tooManyInfoItemsClamped
    case duplicateItemIDRepaired
    case archivedActiveWorkspaceRepaired
    case missingActiveWorkspaceRepaired
    case allWorkspacesRecreated
    case invalidInfoStripTimingRepaired
    case tooManySelectedInfoTilesClamped
    case unsupportedCommandReference
    case missingGroupReference
    case missingProfileBinding
}

nonisolated enum WorkspaceValidation {
    static func validate(
        workspaces input: [MenuBarWorkspace],
        activeWorkspaceID: UUID?,
        knownGroupIDs: Set<UUID>? = nil,
        knownProfileIDs: Set<UUID>? = nil,
        now: Date = Date()
    ) -> WorkspaceValidationResult {
        var issues: [WorkspaceValidationIssue] = []
        var workspaces = Array(input.prefix(WorkspaceValidationConstants.maxWorkspaces))
        if input.count > workspaces.count {
            issues.append(.init(.tooManyWorkspacesClamped, count: input.count - workspaces.count))
        }

        workspaces = workspaces.map { workspace in
            repair(
                workspace,
                issues: &issues,
                knownGroupIDs: knownGroupIDs,
                knownProfileIDs: knownProfileIDs,
                now: now
            )
        }

        let nonArchived = workspaces.filter { !$0.isArchived }
        if nonArchived.isEmpty {
            let defaults = MenuBarWorkspace.defaultWorkspaces(now: now)
            issues.append(.init(.allWorkspacesRecreated))
            return WorkspaceValidationResult(
                repairedWorkspaces: defaults,
                issues: issues,
                selectedActiveWorkspaceID: defaults[0].id,
                didRepair: true
            )
        }

        let selectedID: UUID
        if let activeWorkspaceID,
           let active = workspaces.first(where: { $0.id == activeWorkspaceID }) {
            if active.isArchived {
                selectedID = nonArchived[0].id
                issues.append(.init(.archivedActiveWorkspaceRepaired))
            } else {
                selectedID = activeWorkspaceID
            }
        } else {
            selectedID = nonArchived[0].id
            if activeWorkspaceID != nil {
                issues.append(.init(.missingActiveWorkspaceRepaired))
            }
        }

        return WorkspaceValidationResult(
            repairedWorkspaces: workspaces,
            issues: issues,
            selectedActiveWorkspaceID: selectedID,
            didRepair: !issues.isEmpty
        )
    }

    static func repair(
        _ workspace: MenuBarWorkspace,
        issues: inout [WorkspaceValidationIssue],
        knownGroupIDs: Set<UUID>? = nil,
        knownProfileIDs: Set<UUID>? = nil,
        now: Date = Date()
    ) -> MenuBarWorkspace {
        var repaired = workspace

        if repaired.schemaVersion < 1 || repaired.schemaVersion > MenuBarWorkspace.currentSchemaVersion {
            repaired.schemaVersion = MenuBarWorkspace.currentSchemaVersion
            issues.append(.init(.unsupportedSchemaRepaired))
        } else {
            repaired.schemaVersion = MenuBarWorkspace.currentSchemaVersion
        }

        let trimmedName = repaired.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            repaired.name = "Workspace"
            issues.append(.init(.emptyNameRepaired))
        } else if trimmedName.count > WorkspaceValidationConstants.maxWorkspaceNameLength {
            repaired.name = String(trimmedName.prefix(WorkspaceValidationConstants.maxWorkspaceNameLength))
            issues.append(.init(.nameClamped))
        } else {
            repaired.name = trimmedName
        }

        if repaired.iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            repaired.iconName = "rectangle.3.group"
            issues.append(.init(.iconDefaulted))
        }

        if repaired.functionItems.count > WorkspaceValidationConstants.maxFunctionItems {
            repaired.functionItems = Array(repaired.functionItems.prefix(WorkspaceValidationConstants.maxFunctionItems))
            issues.append(.init(.tooManyFunctionItemsClamped))
        }

        if repaired.infoItems.count > WorkspaceValidationConstants.maxInfoItems {
            repaired.infoItems = Array(repaired.infoItems.prefix(WorkspaceValidationConstants.maxInfoItems))
            issues.append(.init(.tooManyInfoItemsClamped))
        }

        if repaired.infoStripConfig.selectedTileProviderIDs.count > WorkspaceValidationConstants.maxSelectedInfoTileProviderIDs {
            repaired.infoStripConfig.selectedTileProviderIDs = Array(
                repaired.infoStripConfig.selectedTileProviderIDs.prefix(WorkspaceValidationConstants.maxSelectedInfoTileProviderIDs)
            )
            issues.append(.init(.tooManySelectedInfoTilesClamped))
        }

        var seenItemIDs: Set<UUID> = []
        repaired.functionItems = repaired.functionItems.map { item in
            var repairedItem = item
            if seenItemIDs.contains(item.id) {
                repairedItem.id = UUID()
                repairedItem.updatedAt = now
                issues.append(.init(.duplicateItemIDRepaired))
            }
            seenItemIDs.insert(repairedItem.id)
            return repairedItem
        }

        if let knownProfileIDs,
           let binding = repaired.physicalProfileBinding,
           !knownProfileIDs.contains(binding.profileID) {
            issues.append(.init(.missingProfileBinding))
        }

        for item in repaired.functionItems {
            switch item.kind {
            case .command(let command) where !command.isSupported:
                issues.append(.init(.unsupportedCommandReference))
            case .group(let reference):
                if let knownGroupIDs,
                   reference.referenceMode == .linked,
                   !knownGroupIDs.contains(reference.groupID) {
                    issues.append(.init(.missingGroupReference))
                }
            default:
                break
            }
        }

        let clampedIdle = min(
            max(repaired.infoStripConfig.idleDelaySeconds, WorkspaceValidationConstants.minIdleDelaySeconds),
            WorkspaceValidationConstants.maxIdleDelaySeconds
        )
        let clampedRotation = min(
            max(repaired.infoStripConfig.rotationIntervalSeconds, WorkspaceValidationConstants.minRotationIntervalSeconds),
            WorkspaceValidationConstants.maxRotationIntervalSeconds
        )
        if clampedIdle != repaired.infoStripConfig.idleDelaySeconds
            || clampedRotation != repaired.infoStripConfig.rotationIntervalSeconds {
            repaired.infoStripConfig.idleDelaySeconds = clampedIdle
            repaired.infoStripConfig.rotationIntervalSeconds = clampedRotation
            issues.append(.init(.invalidInfoStripTimingRepaired))
        }

        return repaired
    }
}
