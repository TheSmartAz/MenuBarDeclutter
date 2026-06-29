import Foundation

struct ProfileModel: Identifiable, Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    private static let firstSchemaVersion = 1

    let schemaVersion: Int
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var preferredVisibilityState: HidingVisibilityState
    var showSecondBar: Bool
    var autoRehideEnabled: Bool
    var hoverRevealEnabled: Bool
    var targetZonesByBundleID: [String: MenuBarZone]
    var notes: String
    var groupVisibilityPreferences: [UUID: Bool]
    var protectedGroupIDs: Set<UUID>
    var dynamicHotkeyPreferences: [UUID]?
    var layoutModePreference: LayoutMode?
    var fullMenuBarModePreference: Bool?
    var spacingPresetPreference: String?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        preferredVisibilityState: HidingVisibilityState = .expanded,
        showSecondBar: Bool = false,
        autoRehideEnabled: Bool = true,
        hoverRevealEnabled: Bool = false,
        targetZonesByBundleID: [String: MenuBarZone] = [:],
        notes: String = "",
        groupVisibilityPreferences: [UUID: Bool] = [:],
        protectedGroupIDs: Set<UUID> = [],
        dynamicHotkeyPreferences: [UUID]? = nil,
        layoutModePreference: LayoutMode? = nil,
        fullMenuBarModePreference: Bool? = nil,
        spacingPresetPreference: String? = nil
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.preferredVisibilityState = preferredVisibilityState
        self.showSecondBar = showSecondBar
        self.autoRehideEnabled = autoRehideEnabled
        self.hoverRevealEnabled = hoverRevealEnabled
        self.targetZonesByBundleID = targetZonesByBundleID
        self.notes = notes
        self.groupVisibilityPreferences = groupVisibilityPreferences
        self.protectedGroupIDs = protectedGroupIDs
        self.dynamicHotkeyPreferences = dynamicHotkeyPreferences
        self.layoutModePreference = layoutModePreference
        self.fullMenuBarModePreference = fullMenuBarModePreference
        self.spacingPresetPreference = spacingPresetPreference
    }

    static func makeDefault(name: String = "New Profile", now: Date = Date()) -> ProfileModel {
        ProfileModel(
            name: name,
            createdAt: now,
            updatedAt: now
        )
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case id
        case name
        case createdAt
        case updatedAt
        case preferredVisibilityState
        case showSecondBar
        case autoRehideEnabled
        case hoverRevealEnabled
        case targetZonesByBundleID
        case notes
        case groupVisibilityPreferences
        case protectedGroupIDs
        case dynamicHotkeyPreferences
        case layoutModePreference
        case fullMenuBarModePreference
        case spacingPresetPreference
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSchemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
            ?? Self.firstSchemaVersion
        guard (Self.firstSchemaVersion...Self.currentSchemaVersion).contains(decodedSchemaVersion) else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported profile schema version \(decodedSchemaVersion)."
            )
        }

        schemaVersion = Self.currentSchemaVersion
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        preferredVisibilityState = try container.decode(HidingVisibilityState.self, forKey: .preferredVisibilityState)
        showSecondBar = try container.decode(Bool.self, forKey: .showSecondBar)
        autoRehideEnabled = try container.decode(Bool.self, forKey: .autoRehideEnabled)
        hoverRevealEnabled = try container.decode(Bool.self, forKey: .hoverRevealEnabled)
        targetZonesByBundleID = try container.decode([String: MenuBarZone].self, forKey: .targetZonesByBundleID)
        notes = try container.decode(String.self, forKey: .notes)
        groupVisibilityPreferences = try container.decodeIfPresent([UUID: Bool].self, forKey: .groupVisibilityPreferences) ?? [:]
        protectedGroupIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .protectedGroupIDs) ?? []
        dynamicHotkeyPreferences = try container.decodeIfPresent([UUID].self, forKey: .dynamicHotkeyPreferences)
        layoutModePreference = try container.decodeIfPresent(LayoutMode.self, forKey: .layoutModePreference)
        fullMenuBarModePreference = try container.decodeIfPresent(Bool.self, forKey: .fullMenuBarModePreference)
        spacingPresetPreference = try container.decodeIfPresent(String.self, forKey: .spacingPresetPreference)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(preferredVisibilityState, forKey: .preferredVisibilityState)
        try container.encode(showSecondBar, forKey: .showSecondBar)
        try container.encode(autoRehideEnabled, forKey: .autoRehideEnabled)
        try container.encode(hoverRevealEnabled, forKey: .hoverRevealEnabled)
        try container.encode(targetZonesByBundleID, forKey: .targetZonesByBundleID)
        try container.encode(notes, forKey: .notes)
        try container.encode(groupVisibilityPreferences, forKey: .groupVisibilityPreferences)
        try container.encode(protectedGroupIDs, forKey: .protectedGroupIDs)
        try container.encodeIfPresent(dynamicHotkeyPreferences, forKey: .dynamicHotkeyPreferences)
        try container.encodeIfPresent(layoutModePreference, forKey: .layoutModePreference)
        try container.encodeIfPresent(fullMenuBarModePreference, forKey: .fullMenuBarModePreference)
        try container.encodeIfPresent(spacingPresetPreference, forKey: .spacingPresetPreference)
    }
}
