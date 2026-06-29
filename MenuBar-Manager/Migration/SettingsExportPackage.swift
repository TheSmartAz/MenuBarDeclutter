import Foundation

/// Export package for MenuBarDeclutter settings, groups, profiles, hotkeys,
/// and layout preferences.
nonisolated struct SettingsExportPackage: Codable, Equatable, Sendable {
    let packageVersion: Int
    let appVersion: String
    let createdAt: Date
    let settings: [String: String]
    let profiles: [ProfileExportEntry]
    let groups: [IconGroup]
    let hotkeyBindings: [HotkeyBinding]
    let spacerItems: [SpacerItemModel]
    let privateAccessPolicy: PrivateAccessPolicyExport?
    let includeAXSnapshots: Bool

    init(
        packageVersion: Int = 1,
        appVersion: String,
        createdAt: Date = Date(),
        settings: [String: String],
        profiles: [ProfileExportEntry] = [],
        groups: [IconGroup] = [],
        hotkeyBindings: [HotkeyBinding] = [],
        spacerItems: [SpacerItemModel] = [],
        privateAccessPolicy: PrivateAccessPolicyExport? = nil,
        includeAXSnapshots: Bool = false
    ) {
        self.packageVersion = packageVersion
        self.appVersion = appVersion
        self.createdAt = createdAt
        self.settings = settings
        self.profiles = profiles
        self.groups = groups
        self.hotkeyBindings = hotkeyBindings
        self.spacerItems = spacerItems
        self.privateAccessPolicy = privateAccessPolicy
        self.includeAXSnapshots = includeAXSnapshots
    }
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
