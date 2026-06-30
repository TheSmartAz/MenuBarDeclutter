import Foundation

/// Export package for MenuBarDeclutter settings, groups, profiles, hotkeys,
/// and layout preferences.
nonisolated struct SettingsExportPackage: Codable, Equatable, Sendable {
    let packageVersion: Int
    let appVersion: String
    let exportKind: SettingsExportKind
    let createdAt: Date
    let redactionMode: SettingsExportRedactionMode
    let settings: [String: String]
    let omittedSettings: [String]
    let profiles: [ProfileModel]
    let groups: [IconGroup]
    let hotkeyBindings: [HotkeyBinding]
    let spacerItems: [SpacerItemModel]
    let privateAccessPolicy: PrivateAccessPolicyExport?
    let includeAXSnapshots: Bool

    init(
        packageVersion: Int = 1,
        appVersion: String,
        exportKind: SettingsExportKind = .fullSettings,
        createdAt: Date = Date(),
        redactionMode: SettingsExportRedactionMode = .privacySafe,
        settings: [String: String],
        omittedSettings: [String] = [],
        profiles: [ProfileModel] = [],
        groups: [IconGroup] = [],
        hotkeyBindings: [HotkeyBinding] = [],
        spacerItems: [SpacerItemModel] = [],
        privateAccessPolicy: PrivateAccessPolicyExport? = nil,
        includeAXSnapshots: Bool = false
    ) {
        self.packageVersion = packageVersion
        self.appVersion = appVersion
        self.exportKind = exportKind
        self.createdAt = createdAt
        self.redactionMode = redactionMode
        self.settings = settings
        self.omittedSettings = omittedSettings
        self.profiles = profiles
        self.groups = groups
        self.hotkeyBindings = hotkeyBindings
        self.spacerItems = spacerItems
        self.privateAccessPolicy = privateAccessPolicy
        self.includeAXSnapshots = includeAXSnapshots
    }

    private enum CodingKeys: String, CodingKey {
        case packageVersion
        case appVersion
        case exportKind
        case createdAt
        case redactionMode
        case settings
        case omittedSettings
        case profiles
        case groups
        case hotkeyBindings
        case spacerItems
        case privateAccessPolicy
        case includeAXSnapshots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageVersion = try container.decode(Int.self, forKey: .packageVersion)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.exportKind = try container.decodeIfPresent(SettingsExportKind.self, forKey: .exportKind) ?? .fullSettings
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.redactionMode = try container.decodeIfPresent(SettingsExportRedactionMode.self, forKey: .redactionMode) ?? .privacySafe
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
    let protectedGroupsRequireAuth: Bool
    let unlockDurationSeconds: Double
    let allowDevicePasswordFallback: Bool
}
