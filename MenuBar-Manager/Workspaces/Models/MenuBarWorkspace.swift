import Foundation

nonisolated struct MenuBarWorkspace: Identifiable, Codable, Equatable, Sendable {
    static let currentSchemaVersion = 3

    var id: UUID
    var schemaVersion: Int
    var name: String
    var iconName: String
    var functionItems: [WorkspaceItem]
    var infoItems: [InfoTileConfiguration]
    /// Level-2: desired real-item visibility for this workspace (see
    /// `WorkspaceItemTarget`). Empty means "config only; do not move real icons".
    var itemTargets: [WorkspaceItemTarget]
    var functionBarConfig: WorkspaceFunctionBarConfig
    var infoStripConfig: WorkspaceInfoStripConfig
    var displayMode: WorkspaceDisplayMode
    var hoverBehavior: WorkspaceHoverBehavior
    var clickBehavior: WorkspaceClickBehavior
    var physicalProfileBinding: WorkspacePhysicalProfileBinding?
    var isProtected: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        schemaVersion: Int = Self.currentSchemaVersion,
        name: String,
        iconName: String = "rectangle.3.group",
        functionItems: [WorkspaceItem] = [],
        infoItems: [InfoTileConfiguration] = [],
        itemTargets: [WorkspaceItemTarget] = [],
        functionBarConfig: WorkspaceFunctionBarConfig = .default,
        infoStripConfig: WorkspaceInfoStripConfig = .default,
        displayMode: WorkspaceDisplayMode = .functionBar,
        hoverBehavior: WorkspaceHoverBehavior = .noChange,
        clickBehavior: WorkspaceClickBehavior = .openWorkspacePreview,
        physicalProfileBinding: WorkspacePhysicalProfileBinding? = nil,
        isProtected: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.name = name
        self.iconName = iconName
        self.functionItems = functionItems
        self.infoItems = infoItems
        self.itemTargets = itemTargets
        self.functionBarConfig = functionBarConfig
        self.infoStripConfig = infoStripConfig
        self.displayMode = displayMode
        self.hoverBehavior = hoverBehavior
        self.clickBehavior = clickBehavior
        self.physicalProfileBinding = physicalProfileBinding
        self.isProtected = isProtected
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case schemaVersion
        case name
        case iconName
        case functionItems
        case infoItems
        case itemTargets
        case functionBarConfig
        case infoStripConfig
        case displayMode
        case hoverBehavior
        case clickBehavior
        case physicalProfileBinding
        case isProtected
        case isArchived
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1,
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "Workspace",
            iconName: try container.decodeIfPresent(String.self, forKey: .iconName) ?? "rectangle.3.group",
            functionItems: try container.decodeIfPresent([WorkspaceItem].self, forKey: .functionItems) ?? [],
            infoItems: try container.decodeIfPresent([InfoTileConfiguration].self, forKey: .infoItems) ?? [],
            itemTargets: try container.decodeIfPresent([WorkspaceItemTarget].self, forKey: .itemTargets) ?? [],
            functionBarConfig: try container.decodeIfPresent(WorkspaceFunctionBarConfig.self, forKey: .functionBarConfig) ?? .default,
            infoStripConfig: try container.decodeIfPresent(WorkspaceInfoStripConfig.self, forKey: .infoStripConfig) ?? .default,
            displayMode: try container.decodeIfPresent(WorkspaceDisplayMode.self, forKey: .displayMode) ?? .functionBar,
            hoverBehavior: try container.decodeIfPresent(WorkspaceHoverBehavior.self, forKey: .hoverBehavior) ?? .noChange,
            clickBehavior: try container.decodeIfPresent(WorkspaceClickBehavior.self, forKey: .clickBehavior) ?? .openWorkspacePreview,
            physicalProfileBinding: try container.decodeIfPresent(WorkspacePhysicalProfileBinding.self, forKey: .physicalProfileBinding),
            isProtected: try container.decodeIfPresent(Bool.self, forKey: .isProtected) ?? false,
            isArchived: try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false,
            createdAt: try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date(),
            updatedAt: try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        )
    }

    static func defaultWorkspaces(now: Date = Date()) -> [MenuBarWorkspace] {
        [
            MenuBarWorkspace(
                name: "Default",
                iconName: "menubar.rectangle",
                functionItems: [
                    .command(.findIcon, now: now),
                    .command(.showSecondBar, now: now),
                    .divider(now: now),
                    .command(.revealAll, now: now)
                ],
                createdAt: now,
                updatedAt: now
            ),
            MenuBarWorkspace(
                name: "Focus",
                iconName: "moon",
                functionItems: [
                    .command(.findIcon, now: now),
                    .command(.showSecondBar, now: now),
                    .divider(now: now),
                    .command(.collapse, now: now)
                ],
                createdAt: now,
                updatedAt: now
            ),
            MenuBarWorkspace(
                name: "Meeting",
                iconName: "person.2.wave.2",
                functionItems: [
                    .command(.revealAll, now: now),
                    .command(.showSecondBar, now: now),
                    .spacer(now: now)
                ],
                createdAt: now,
                updatedAt: now
            )
        ]
    }
}

nonisolated struct WorkspaceItem: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var kind: WorkspaceItemKind
    var displayNameOverride: String?
    var iconOverride: String?
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        kind: WorkspaceItemKind,
        displayNameOverride: String? = nil,
        iconOverride: String? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.displayNameOverride = displayNameOverride
        self.iconOverride = iconOverride
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func command(_ command: WorkspaceCommandReference, now: Date = Date()) -> WorkspaceItem {
        WorkspaceItem(kind: .command(command), createdAt: now, updatedAt: now)
    }

    static func spacer(now: Date = Date()) -> WorkspaceItem {
        WorkspaceItem(kind: .spacer, createdAt: now, updatedAt: now)
    }

    static func divider(now: Date = Date()) -> WorkspaceItem {
        WorkspaceItem(kind: .divider, createdAt: now, updatedAt: now)
    }
}

nonisolated enum WorkspaceItemKind: Codable, Equatable, Sendable {
    case menuBarItem(MenuBarItemReference)
    case group(WorkspaceGroupReference)
    case command(WorkspaceCommandReference)
    case infoTile(InfoTileReference)
    case spacer
    case divider
}

nonisolated struct MenuBarItemReference: Codable, Equatable, Hashable, Sendable {
    var stableHash: String
    var source: MenuBarItemReferenceSource
    var lastKnownDisplayName: String?
    var lastKnownBundleIdentifier: String?
    var redactionPolicy: ItemReferenceRedactionPolicy

    init(
        stableHash: String,
        source: MenuBarItemReferenceSource = .accessibilitySnapshot,
        lastKnownDisplayName: String? = nil,
        lastKnownBundleIdentifier: String? = nil,
        redactionPolicy: ItemReferenceRedactionPolicy = .redactByDefault
    ) {
        self.stableHash = stableHash
        self.source = source
        self.lastKnownDisplayName = lastKnownDisplayName
        self.lastKnownBundleIdentifier = lastKnownBundleIdentifier
        self.redactionPolicy = redactionPolicy
    }
}

nonisolated enum MenuBarItemReferenceSource: String, Codable, Equatable, Hashable, Sendable {
    case accessibilitySnapshot
    case itemMemory
    case manual
    case imported
}

nonisolated enum ItemReferenceRedactionPolicy: String, Codable, Equatable, Hashable, Sendable {
    case redactByDefault
    case safeDisplayName
    case protected
}

nonisolated struct WorkspaceCommandReference: Codable, Equatable, Hashable, Sendable {
    var actionID: String
    var targetKind: String?
    var targetID: String?

    init(actionID: String, targetKind: String? = nil, targetID: String? = nil) {
        self.actionID = actionID
        self.targetKind = targetKind
        self.targetID = targetID
    }

    static let findIcon = WorkspaceCommandReference(actionID: "findIcon.open")
    static let showSecondBar = WorkspaceCommandReference(actionID: "secondBar.show")
    static let revealAll = WorkspaceCommandReference(actionID: "visibility.revealAll")
    static let expand = WorkspaceCommandReference(actionID: "visibility.expand")
    static let collapse = WorkspaceCommandReference(actionID: "visibility.collapse")
    static let toggle = WorkspaceCommandReference(actionID: "visibility.toggle")
    static let openSettings = WorkspaceCommandReference(actionID: "settings.open")
    static let openRecovery = WorkspaceCommandReference(actionID: "recovery.open")
    static let showWorkspacePreview = WorkspaceCommandReference(actionID: "workspace.preview.open")
    static let showFunctionBar = WorkspaceCommandReference(actionID: "functionBar.show")
    static let hideFunctionBar = WorkspaceCommandReference(actionID: "functionBar.hide")
    static let showInfoStrip = WorkspaceCommandReference(actionID: "infoStrip.show")
    static let hideInfoStrip = WorkspaceCommandReference(actionID: "infoStrip.hide")
    static let nextInfoStripTile = WorkspaceCommandReference(actionID: "infoStrip.nextTile")
    static let openInfoStripSettings = WorkspaceCommandReference(actionID: "infoStrip.openSettings")
    static let showFunctionBarFromInfoStrip = WorkspaceCommandReference(actionID: "infoStrip.showFunctionBar")

    static let supportedActionIDs: Set<String> = [
        findIcon.actionID,
        showSecondBar.actionID,
        revealAll.actionID,
        expand.actionID,
        collapse.actionID,
        toggle.actionID,
        openSettings.actionID,
        openRecovery.actionID,
        showWorkspacePreview.actionID,
        showFunctionBar.actionID,
        hideFunctionBar.actionID,
        showInfoStrip.actionID,
        hideInfoStrip.actionID,
        nextInfoStripTile.actionID,
        openInfoStripSettings.actionID,
        showFunctionBarFromInfoStrip.actionID
    ]

    var isSupported: Bool {
        Self.supportedActionIDs.contains(actionID)
    }

    var displayTitle: String {
        switch actionID {
        case Self.findIcon.actionID: "Find Icon"
        case Self.showSecondBar.actionID: "Show Second Bar"
        case Self.revealAll.actionID: "Reveal All"
        case Self.expand.actionID: "Expand"
        case Self.collapse.actionID: "Collapse"
        case Self.toggle.actionID: "Toggle"
        case Self.openSettings.actionID: "Open Settings"
        case Self.openRecovery.actionID: "Open Recovery"
        case Self.showWorkspacePreview.actionID: "Workspace Preview"
        case Self.showFunctionBar.actionID: "Show Function Bar"
        case Self.hideFunctionBar.actionID: "Hide Function Bar"
        case Self.showInfoStrip.actionID: "Show Info Strip"
        case Self.hideInfoStrip.actionID: "Hide Info Strip"
        case Self.nextInfoStripTile.actionID: "Next Info Strip Tile"
        case Self.openInfoStripSettings.actionID: "Info Strip Settings"
        case Self.showFunctionBarFromInfoStrip.actionID: "Show Function Bar from Info Strip"
        default: "Unknown Command"
        }
    }

    var menuBarCommand: MenuBarCommand? {
        switch actionID {
        case Self.findIcon.actionID:
            MenuBarCommand(action: .showFindIcon, source: .settings)
        case Self.showSecondBar.actionID:
            MenuBarCommand(action: .showSecondBar, target: .secondBar, source: .settings)
        case Self.revealAll.actionID:
            MenuBarCommand(action: .revealAll, target: .globalVisibility, source: .settings)
        case Self.expand.actionID:
            MenuBarCommand(action: .expand, target: .globalVisibility, source: .settings)
        case Self.collapse.actionID:
            MenuBarCommand(action: .collapse, target: .globalVisibility, source: .settings)
        case Self.toggle.actionID:
            MenuBarCommand(action: .toggle, target: .globalVisibility, source: .settings)
        case Self.showFunctionBar.actionID:
            MenuBarCommand(action: .showFunctionBar, target: .functionBar, source: .settings)
        case Self.hideFunctionBar.actionID:
            MenuBarCommand(action: .hideFunctionBar, target: .functionBar, source: .settings)
        case Self.showInfoStrip.actionID:
            MenuBarCommand(action: .showInfoStrip, target: .infoStrip, source: .settings)
        case Self.hideInfoStrip.actionID:
            MenuBarCommand(action: .hideInfoStrip, target: .infoStrip, source: .settings)
        case Self.nextInfoStripTile.actionID:
            MenuBarCommand(action: .nextInfoStripTile, target: .infoStrip, source: .settings)
        case Self.openInfoStripSettings.actionID:
            MenuBarCommand(action: .openInfoStripSettings, target: .infoStrip, source: .settings)
        case Self.showFunctionBarFromInfoStrip.actionID:
            MenuBarCommand(action: .showFunctionBarFromInfoStrip, target: .infoStrip, source: .settings)
        default:
            nil
        }
    }
}

nonisolated struct InfoTileReference: Codable, Equatable, Hashable, Sendable {
    var providerID: String
    var configurationID: UUID?
}

nonisolated struct InfoTileConfiguration: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: UUID
    var providerID: String
    var isEnabled: Bool

    init(id: UUID = UUID(), providerID: String, isEnabled: Bool = true) {
        self.id = id
        self.providerID = providerID
        self.isEnabled = isEnabled
    }
}

nonisolated struct WorkspaceGroupReference: Codable, Equatable, Hashable, Sendable {
    var groupID: UUID
    var referenceMode: WorkspaceGroupReferenceMode
    var sourceGroupID: UUID?
    var createdAt: Date?

    init(
        groupID: UUID,
        referenceMode: WorkspaceGroupReferenceMode = .linked,
        sourceGroupID: UUID? = nil,
        createdAt: Date? = nil
    ) {
        self.groupID = groupID
        self.referenceMode = referenceMode
        self.sourceGroupID = sourceGroupID
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case groupID
        case referenceMode
        case sourceGroupID
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            groupID: try container.decode(UUID.self, forKey: .groupID),
            referenceMode: try container.decodeIfPresent(WorkspaceGroupReferenceMode.self, forKey: .referenceMode) ?? .linked,
            sourceGroupID: try container.decodeIfPresent(UUID.self, forKey: .sourceGroupID),
            createdAt: try container.decodeIfPresent(Date.self, forKey: .createdAt)
        )
    }
}

nonisolated enum WorkspaceGroupReferenceMode: String, Codable, Equatable, Hashable, CaseIterable, Identifiable, Sendable {
    case linked
    case detached

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .linked: "Linked"
        case .detached: "Detached Copy"
        }
    }
}

nonisolated struct WorkspacePhysicalProfileBinding: Codable, Equatable, Sendable {
    var profileID: UUID
    var applyMode: WorkspacePhysicalProfileApplyMode
}

nonisolated enum WorkspacePhysicalProfileApplyMode: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case none
    case dryRunOnly
    case applySafeBasicSettings

    var id: String { rawValue }
}

nonisolated enum WorkspaceDisplayMode: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case functionBar
    case infoStrip
    case lastUsed

    var id: String { rawValue }
}

nonisolated enum WorkspaceHoverBehavior: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case noChange
    case showFunctionBar
    case pinFunctionBar

    var id: String { rawValue }
}

nonisolated enum WorkspaceClickBehavior: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case openWorkspacePreview
    case showFunctionBar
    case showSetSwitcher
    case openSettings

    var id: String { rawValue }
}

nonisolated struct WorkspaceFunctionBarConfig: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var density: WorkspaceFunctionBarDensity
    var showLabels: Bool

    static let `default` = WorkspaceFunctionBarConfig(
        isEnabled: false,
        density: .regular,
        showLabels: true
    )

    init(
        isEnabled: Bool,
        density: WorkspaceFunctionBarDensity,
        showLabels: Bool
    ) {
        self.isEnabled = isEnabled
        self.density = density
        self.showLabels = showLabels
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case density
        case showLabels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            isEnabled: try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? Self.default.isEnabled,
            density: try container.decodeIfPresent(WorkspaceFunctionBarDensity.self, forKey: .density) ?? Self.default.density,
            showLabels: try container.decodeIfPresent(Bool.self, forKey: .showLabels) ?? Self.default.showLabels
        )
    }
}

nonisolated enum WorkspaceFunctionBarDensity: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case compact
    case regular

    var id: String { rawValue }
}

nonisolated struct WorkspaceInfoStripConfig: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var idleDelaySeconds: Int
    var rotationIntervalSeconds: Int
    var selectedTileProviderIDs: [String]
    var showTileLabels: Bool
    var compactMode: Bool
    var hoverBehavior: WorkspaceInfoStripHoverBehavior

    static let defaultTileProviderIDs = [
        "workspace.current",
        "clock.local",
        "battery.status",
        "hidden.count",
        "newItems.count",
        "health.warning",
        "scan.stale"
    ]

    static let `default` = WorkspaceInfoStripConfig(
        isEnabled: false,
        idleDelaySeconds: 5,
        rotationIntervalSeconds: 8,
        selectedTileProviderIDs: defaultTileProviderIDs,
        showTileLabels: true,
        compactMode: true,
        hoverBehavior: .showFunctionBar
    )

    init(
        isEnabled: Bool,
        idleDelaySeconds: Int,
        rotationIntervalSeconds: Int,
        selectedTileProviderIDs: [String],
        showTileLabels: Bool,
        compactMode: Bool,
        hoverBehavior: WorkspaceInfoStripHoverBehavior
    ) {
        self.isEnabled = isEnabled
        self.idleDelaySeconds = idleDelaySeconds
        self.rotationIntervalSeconds = rotationIntervalSeconds
        self.selectedTileProviderIDs = selectedTileProviderIDs
        self.showTileLabels = showTileLabels
        self.compactMode = compactMode
        self.hoverBehavior = hoverBehavior
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case idleDelaySeconds
        case rotationIntervalSeconds
        case selectedTileProviderIDs
        case showTileLabels
        case compactMode
        case hoverBehavior
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            isEnabled: try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? Self.default.isEnabled,
            idleDelaySeconds: try container.decodeIfPresent(Int.self, forKey: .idleDelaySeconds) ?? Self.default.idleDelaySeconds,
            rotationIntervalSeconds: try container.decodeIfPresent(Int.self, forKey: .rotationIntervalSeconds) ?? Self.default.rotationIntervalSeconds,
            selectedTileProviderIDs: try container.decodeIfPresent([String].self, forKey: .selectedTileProviderIDs) ?? Self.default.selectedTileProviderIDs,
            showTileLabels: try container.decodeIfPresent(Bool.self, forKey: .showTileLabels) ?? Self.default.showTileLabels,
            compactMode: try container.decodeIfPresent(Bool.self, forKey: .compactMode) ?? Self.default.compactMode,
            hoverBehavior: try container.decodeIfPresent(WorkspaceInfoStripHoverBehavior.self, forKey: .hoverBehavior) ?? Self.default.hoverBehavior
        )
    }
}

nonisolated enum WorkspaceInfoStripHoverBehavior: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case showFunctionBar
    case keepInfoStrip
    case pinInfoStrip

    var id: String { rawValue }
}

nonisolated struct WorkspaceDraft: Equatable, Sendable {
    var name: String
    var iconName: String

    init(name: String, iconName: String = "rectangle.3.group") {
        self.name = name
        self.iconName = iconName
    }
}
