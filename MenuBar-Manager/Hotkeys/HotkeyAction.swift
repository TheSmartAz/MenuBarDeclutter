import Foundation

/// Actions that can be bound to dynamic hotkeys in Phase 11.
nonisolated enum HotkeyAction: Equatable, Hashable, Codable, Sendable {
    case revealAndHighlightItem(String) // item ref ID
    case openGroup(UUID)
    case openSecondBarFilteredToGroup(UUID)
    case openSecondBarFilteredToItem(String) // item ref ID
    case applyProfile(UUID)
    case enterFullMenuBarMode
    case exitFullMenuBarMode
    case pauseAutomation
    case resumeAutomation

    private enum CodingKeys: String, CodingKey {
        case kind
        case uuidValue
        case stringValue
    }

    private enum Kind: String, Codable {
        case revealAndHighlightItem
        case openGroup
        case openSecondBarFilteredToGroup
        case openSecondBarFilteredToItem
        case applyProfile
        case enterFullMenuBarMode
        case exitFullMenuBarMode
        case pauseAutomation
        case resumeAutomation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .revealAndHighlightItem:
            self = .revealAndHighlightItem(try container.decode(String.self, forKey: .stringValue))
        case .openGroup:
            self = .openGroup(try container.decode(UUID.self, forKey: .uuidValue))
        case .openSecondBarFilteredToGroup:
            self = .openSecondBarFilteredToGroup(try container.decode(UUID.self, forKey: .uuidValue))
        case .openSecondBarFilteredToItem:
            self = .openSecondBarFilteredToItem(try container.decode(String.self, forKey: .stringValue))
        case .applyProfile:
            self = .applyProfile(try container.decode(UUID.self, forKey: .uuidValue))
        case .enterFullMenuBarMode:
            self = .enterFullMenuBarMode
        case .exitFullMenuBarMode:
            self = .exitFullMenuBarMode
        case .pauseAutomation:
            self = .pauseAutomation
        case .resumeAutomation:
            self = .resumeAutomation
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .revealAndHighlightItem(let value):
            try container.encode(Kind.revealAndHighlightItem, forKey: .kind)
            try container.encode(value, forKey: .stringValue)
        case .openGroup(let uuid):
            try container.encode(Kind.openGroup, forKey: .kind)
            try container.encode(uuid, forKey: .uuidValue)
        case .openSecondBarFilteredToGroup(let uuid):
            try container.encode(Kind.openSecondBarFilteredToGroup, forKey: .kind)
            try container.encode(uuid, forKey: .uuidValue)
        case .openSecondBarFilteredToItem(let value):
            try container.encode(Kind.openSecondBarFilteredToItem, forKey: .kind)
            try container.encode(value, forKey: .stringValue)
        case .applyProfile(let uuid):
            try container.encode(Kind.applyProfile, forKey: .kind)
            try container.encode(uuid, forKey: .uuidValue)
        case .enterFullMenuBarMode:
            try container.encode(Kind.enterFullMenuBarMode, forKey: .kind)
        case .exitFullMenuBarMode:
            try container.encode(Kind.exitFullMenuBarMode, forKey: .kind)
        case .pauseAutomation:
            try container.encode(Kind.pauseAutomation, forKey: .kind)
        case .resumeAutomation:
            try container.encode(Kind.resumeAutomation, forKey: .kind)
        }
    }

    var displayLabel: String {
        switch self {
        case .revealAndHighlightItem:
            "Reveal and Highlight Item"
        case .openGroup:
            "Open Group"
        case .openSecondBarFilteredToGroup:
            "Open Second Bar (Group)"
        case .openSecondBarFilteredToItem:
            "Open Second Bar (Item)"
        case .applyProfile:
            "Apply Profile"
        case .enterFullMenuBarMode:
            "Enter Full Menu Bar Mode"
        case .exitFullMenuBarMode:
            "Exit Full Menu Bar Mode"
        case .pauseAutomation:
            "Pause Automation"
        case .resumeAutomation:
            "Resume Automation"
        }
    }

    var requiresProMode: Bool {
        switch self {
        case .revealAndHighlightItem, .openSecondBarFilteredToItem:
            true
        default:
            false
        }
    }
}
