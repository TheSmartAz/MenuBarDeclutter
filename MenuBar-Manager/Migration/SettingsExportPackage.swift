import Foundation

/// Export package for MenuBarDeclutter settings, groups, profiles, hotkeys,
/// and layout preferences.
nonisolated struct SettingsExportPackage: Codable, Equatable, Sendable {
    let packageVersion: Int
    let schemaVersion: Int
    let appName: String
    let appVersion: String
    let exportKind: SettingsExportKind
    let createdAt: Date
    let redactionMode: SettingsExportRedactionMode
    let includedSections: [SettingsExportSection]
    let settings: [String: String]
    let omittedSettings: [String]
    let profiles: [ProfileModel]
    let groups: [IconGroup]
    let hotkeyBindings: [HotkeyBinding]
    let spacerItems: [SpacerItemModel]
    let workspaceSnapshot: WorkspaceStoreSnapshot?
    let privateAccessPolicy: PrivateAccessPolicyExport?
    let includeAXSnapshots: Bool

    init(
        packageVersion: Int = 1,
        schemaVersion: Int = 1,
        appName: String = "MenuBarDeclutter",
        appVersion: String,
        exportKind: SettingsExportKind = .fullSettings,
        createdAt: Date = Date(),
        redactionMode: SettingsExportRedactionMode = .privacySafe,
        includedSections: [SettingsExportSection] = SettingsExportSection.defaultIncludedSections,
        settings: [String: String],
        omittedSettings: [String] = [],
        profiles: [ProfileModel] = [],
        groups: [IconGroup] = [],
        hotkeyBindings: [HotkeyBinding] = [],
        spacerItems: [SpacerItemModel] = [],
        workspaceSnapshot: WorkspaceStoreSnapshot? = nil,
        privateAccessPolicy: PrivateAccessPolicyExport? = nil,
        includeAXSnapshots: Bool = false
    ) {
        self.packageVersion = packageVersion
        self.schemaVersion = schemaVersion
        self.appName = appName
        self.appVersion = appVersion
        self.exportKind = exportKind
        self.createdAt = createdAt
        self.redactionMode = redactionMode
        self.includedSections = includedSections
        self.settings = settings
        self.omittedSettings = omittedSettings
        self.profiles = profiles
        self.groups = groups
        self.hotkeyBindings = hotkeyBindings
        self.spacerItems = spacerItems
        self.workspaceSnapshot = workspaceSnapshot
        self.privateAccessPolicy = privateAccessPolicy
        self.includeAXSnapshots = includeAXSnapshots
    }

    private enum CodingKeys: String, CodingKey {
        case packageVersion
        case schemaVersion
        case appName
        case appVersion
        case exportKind
        case createdAt
        case redactionMode
        case includedSections
        case settings
        case omittedSettings
        case profiles
        case groups
        case hotkeyBindings
        case spacerItems
        case workspaceSnapshot
        case privateAccessPolicy
        case includeAXSnapshots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageVersion = try container.decode(Int.self, forKey: .packageVersion)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? self.packageVersion
        self.appName = try container.decodeIfPresent(String.self, forKey: .appName) ?? "MenuBarDeclutter"
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.exportKind = try container.decodeIfPresent(SettingsExportKind.self, forKey: .exportKind) ?? .fullSettings
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.redactionMode = try container.decodeIfPresent(SettingsExportRedactionMode.self, forKey: .redactionMode) ?? .privacySafe
        self.includedSections = try container.decodeIfPresent(
            [SettingsExportSection].self,
            forKey: .includedSections
        ) ?? SettingsExportSection.defaultIncludedSections
        self.settings = try container.decode([String: String].self, forKey: .settings)
        self.omittedSettings = try container.decodeIfPresent([String].self, forKey: .omittedSettings) ?? []
        do {
            self.profiles = try container.decodeIfPresent([ProfileModel].self, forKey: .profiles) ?? []
        } catch {
            _ = try? container.decodeIfPresent([ProfileExportEntry].self, forKey: .profiles)
            self.profiles = []
        }
        self.groups = try container.decodeIfPresent([IconGroup].self, forKey: .groups) ?? []
        self.hotkeyBindings = try container.decodeIfPresent([HotkeyBinding].self, forKey: .hotkeyBindings) ?? []
        self.spacerItems = try container.decodeIfPresent([SpacerItemModel].self, forKey: .spacerItems) ?? []
        self.workspaceSnapshot = try container.decodeIfPresent(WorkspaceStoreSnapshot.self, forKey: .workspaceSnapshot)
        self.privateAccessPolicy = try container.decodeIfPresent(PrivateAccessPolicyExport.self, forKey: .privateAccessPolicy)
        self.includeAXSnapshots = try container.decodeIfPresent(Bool.self, forKey: .includeAXSnapshots) ?? false
    }
}

nonisolated enum SettingsExportKind: String, Codable, Equatable, Sendable {
    case fullSettings
}

nonisolated enum SettingsExportRedactionMode: String, Codable, Equatable, Sendable {
    case privacySafe
}

nonisolated enum SettingsExportSection: String, CaseIterable, Codable, Equatable, Hashable, Identifiable, Sendable {
    case settings
    case profiles
    case groups
    case hotkeys
    case spacers
    case workspaces
    case privateAccessPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .settings:
            "Settings"
        case .profiles:
            "Profiles"
        case .groups:
            "Groups"
        case .hotkeys:
            "Hotkeys"
        case .spacers:
            "Spacers"
        case .workspaces:
            "Workspaces"
        case .privateAccessPolicy:
            "Private Access policy"
        }
    }

    static let restorableSections: Set<SettingsExportSection> = [
        .settings,
        .profiles,
        .groups,
        .hotkeys,
        .spacers,
        .workspaces
    ]

    static let defaultIncludedSections: [SettingsExportSection] = [
        .settings,
        .profiles,
        .groups,
        .hotkeys,
        .spacers,
        .workspaces,
        .privateAccessPolicy
    ]
}

/// Profile export entry.
nonisolated struct ProfileExportEntry: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let isReadOnly: Bool
    let createdAt: Date
    let updatedAt: Date
}

/// Private access policy export (does not include active unlock session).
nonisolated struct PrivateAccessPolicyExport: Codable, Equatable, Sendable {
    let isEnabled: Bool
    let protectAlwaysHidden: Bool
    let protectSecondBar: Bool
    let protectFindIcon: Bool
    let protectIconMoving: Bool
    let protectSpacingLabs: Bool
    let protectProfileApply: Bool?
    let protectAutomationCommands: Bool?
    let protectedGroupsRequireAuth: Bool
    let unlockDurationSeconds: Double
    let allowDevicePasswordFallback: Bool
}
