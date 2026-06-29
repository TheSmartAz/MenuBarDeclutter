import Foundation

enum DogfoodGate: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case basicMode
    case proReadOnly
    case proAssisted
    case iconMovingExperimental
    case installedRelease

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basicMode:
            "Gate A: Basic Mode Daily Use"
        case .proReadOnly:
            "Gate B: Pro Read-only"
        case .proAssisted:
            "Gate C: Pro Assisted"
        case .iconMovingExperimental:
            "Gate D: Icon Moving Experimental"
        case .installedRelease:
            "Gate E: Installed Release"
        }
    }
}

enum DogfoodChecklistResult: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case notTested
    case pass
    case fail
    case blocked

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notTested:
            "NOT TESTED"
        case .pass:
            "PASS"
        case .fail:
            "FAIL"
        case .blocked:
            "BLOCKED"
        }
    }
}

struct DogfoodChecklistItem: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let gate: DogfoodGate
    let title: String
    var result: DogfoodChecklistResult
    var notes: String

    init(
        id: String,
        gate: DogfoodGate,
        title: String,
        result: DogfoodChecklistResult = .notTested,
        notes: String = ""
    ) {
        self.id = id
        self.gate = gate
        self.title = title
        self.result = result
        self.notes = notes
    }

    static let defaultItems: [DogfoodChecklistItem] = {
        var items: [DogfoodChecklistItem] = []
        for (gate, titles) in defaultTitles {
            items.append(contentsOf: titles.map { title in
                DogfoodChecklistItem(
                    id: "\(gate.rawValue).\(Self.slug(title))",
                    gate: gate,
                    title: title
                )
            })
        }
        return items
    }()

    private static let defaultTitles: [(DogfoodGate, [String])] = [
        (
            .basicMode,
            [
                "App starts cleanly",
                "Onboarding is understandable",
                "Separator can be Command-dragged",
                "Collapse/expand works with real icons",
                "Reveal all works",
                "Always-hidden works",
                "Auto-rehide does not collapse while interacting",
                "Hover reveal does not flicker",
                "Hotkey does not conflict",
                "App survives sleep/wake",
                "App survives display changes",
                "App recovers after force quit",
                "Safe Mode works",
                "Reset layout works",
                "Diagnostics export works",
                "No Accessibility prompt appears",
                "No network connection appears"
            ]
        ),
        (
            .proReadOnly,
            [
                "Enable Pro Mode",
                "Request Accessibility permission",
                "Grant Accessibility permission",
                "Revoke Accessibility permission",
                "Scan refresh",
                "Diagnostics table",
                "Find Icon",
                "Highlight overlay",
                "Permission degradation"
            ]
        ),
        (
            .proAssisted,
            [
                "Second Bar",
                "Profiles",
                "Triggers paused/resumed",
                "URL automation",
                "Conservative profile apply",
                "No silent bulk icon moves"
            ]
        ),
        (
            .iconMovingExperimental,
            [
                "Disabled by default",
                "First-use warning",
                "Local fixture item move",
                "Third-party item move only after fixture pass",
                "Own app item blocked",
                "System item blocked by default",
                "Failed move recovers cleanly"
            ]
        ),
        (
            .installedRelease,
            [
                "Archive",
                "Install to /Applications or private test location",
                "Launch at Login from installed app",
                "Restart login test",
                "Codesign verification",
                "Notarization placeholder or real notarization"
            ]
        )
    ]

    private static func slug(_ title: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let scalars = title.lowercased().unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(scalars)
            .split(separator: "-")
            .joined(separator: "-")
    }
}

struct DogfoodRun: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let startedAt: Date
    var endedAt: Date?
    var checklist: [DogfoodChecklistItem]

    init(
        id: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        checklist: [DogfoodChecklistItem] = DogfoodChecklistItem.defaultItems
    ) {
        self.startedAt = startedAt
        self.id = id ?? Self.makeRunID(date: startedAt)
        self.endedAt = endedAt
        self.checklist = checklist
    }

    var isActive: Bool {
        endedAt == nil
    }

    static func makeRunID(date: Date) -> String {
        "dogfood-\(timestamp(date: date))"
    }

    static func timestamp(date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        return String(
            format: "%04d-%02d-%02d-%02d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }
}

struct DogfoodNote: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let runID: String
    let createdAt: Date
    var text: String

    init(
        id: UUID = UUID(),
        runID: String,
        createdAt: Date = Date(),
        text: String
    ) {
        self.id = id
        self.runID = runID
        self.createdAt = createdAt
        self.text = text
    }
}

struct DogfoodDiagnosticsMetadata: Codable, Equatable, Sendable {
    let runID: String
}

struct DogfoodBundleMetadata: Codable, Equatable, Sendable {
    let generatedAt: Date
    let appVersion: String
    let marketingVersion: String
    let buildNumber: String
    let bundleIdentifier: String
    let macOSVersion: String
    let architecture: String
    let screens: [DiagnosticsExporter.ScreenSnapshot]
}
