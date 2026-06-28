import Foundation

struct ProfileModel: Identifiable, Codable, Equatable, Sendable {
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
}
