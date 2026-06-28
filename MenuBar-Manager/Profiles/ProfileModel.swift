import Foundation

struct ProfileModel: Identifiable, Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
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
        notes: String = ""
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

        schemaVersion = decodedSchemaVersion
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
    }
}
