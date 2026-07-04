import Foundation

enum SettingsCommandPaletteAction: String, CaseIterable, Hashable, Identifiable {
    case showOnboarding
    case showDragHint
    case runHealthCheck
    case fixHealthIssues
    case expand
    case revealAll
    case recreateStatusItems
    case disableAutoRehideTemporarily
    case disableHoverRevealTemporarily
    case openTroubleshootingGuide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .showOnboarding:
            "Show Onboarding"
        case .showDragHint:
            "Show Command-Drag Hint"
        case .runHealthCheck:
            "Run Health Check"
        case .fixHealthIssues:
            "Fix Health Issues"
        case .expand:
            "Expand Menu Bar Items"
        case .revealAll:
            "Reveal All Items"
        case .recreateStatusItems:
            "Recreate Status Items"
        case .disableAutoRehideTemporarily:
            "Disable Auto-Rehide Temporarily"
        case .disableHoverRevealTemporarily:
            "Disable Hover Reveal Temporarily"
        case .openTroubleshootingGuide:
            "Open Troubleshooting Guide"
        }
    }

    var subtitle: String {
        switch self {
        case .showOnboarding:
            "Open the first-run walkthrough again."
        case .showDragHint:
            "Show the local Command-drag placement helper."
        case .runHealthCheck:
            "Refresh local diagnostics and health status."
        case .fixHealthIssues:
            "Run available local recovery actions."
        case .expand:
            "Show the expanded menu bar area."
        case .revealAll:
            "Temporarily reveal hidden menu bar items."
        case .recreateStatusItems:
            "Refresh MenuBarDeclutter status items."
        case .disableAutoRehideTemporarily:
            "Pause automatic rehiding for this session."
        case .disableHoverRevealTemporarily:
            "Pause hover reveal for this session."
        case .openTroubleshootingGuide:
            "Open the bundled local troubleshooting guide."
        }
    }

    var systemImage: String {
        switch self {
        case .showOnboarding:
            "sparkles"
        case .showDragHint:
            "cursorarrow.motionlines"
        case .runHealthCheck:
            "stethoscope"
        case .fixHealthIssues:
            "cross.case"
        case .expand:
            "arrow.left.and.right"
        case .revealAll:
            "eye"
        case .recreateStatusItems:
            "arrow.clockwise"
        case .disableAutoRehideTemporarily:
            "pause.circle"
        case .disableHoverRevealTemporarily:
            "hand.raised"
        case .openTroubleshootingGuide:
            "questionmark.circle"
        }
    }

    var searchKeywords: String {
        "\(title) \(subtitle) recovery diagnostics local action"
    }
}

enum SettingsCommandPaletteEntryKind: String, Hashable {
    case setting
    case action
}

enum SettingsCommandPaletteEntrySource: String, Hashable {
    case visibleSettings
    case advancedSettings
    case advancedAlias
    case action
}

struct SettingsCommandPaletteEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let kind: SettingsCommandPaletteEntryKind
    let source: SettingsCommandPaletteEntrySource
    let destination: SettingsSection?
    let action: SettingsCommandPaletteAction?
    let keywords: [String]

    var isPrivacySafeLocalOnly: Bool { true }

    var searchableText: String {
        ([title, subtitle] + keywords)
            .joined(separator: " ")
    }

    func matches(_ query: String) -> Bool {
        let tokens = SettingsCommandPaletteIndex.searchTokens(in: query)
        guard !tokens.isEmpty else { return true }

        return tokens.allSatisfy { token in
            searchableText.localizedStandardContains(token)
        }
    }
}

struct SettingsCommandPaletteIndex {
    let entries: [SettingsCommandPaletteEntry]

    init(entries: [SettingsCommandPaletteEntry]) {
        self.entries = entries
    }

    static func make(
        includeDogfood: Bool,
        availableActions: Set<SettingsCommandPaletteAction> = []
    ) -> SettingsCommandPaletteIndex {
        var entries = SettingsSection.allCases.map(sectionEntry(for:))
        entries.append(contentsOf: advancedAliasEntries(includeDogfood: includeDogfood))
        entries.append(contentsOf: actionEntries(availableActions: availableActions))
        return SettingsCommandPaletteIndex(entries: entries)
    }

    func search(_ query: String, limit: Int? = nil) -> [SettingsCommandPaletteEntry] {
        let matches = entries.filter { $0.matches(query) }
        guard let limit else { return matches }
        return Array(matches.prefix(limit))
    }

    static func searchTokens(in query: String) -> [String] {
        query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)
    }

    private static func sectionEntry(for section: SettingsSection) -> SettingsCommandPaletteEntry {
        let source: SettingsCommandPaletteEntrySource = SettingsSection.visibleSidebarSections.contains(section)
            ? .visibleSettings
            : .advancedSettings

        return SettingsCommandPaletteEntry(
            id: "settings.section.\(section.rawValue)",
            title: section.commandPaletteTitle,
            subtitle: section.commandPaletteSubtitle,
            systemImage: section.systemImage,
            kind: .setting,
            source: source,
            destination: section,
            action: nil,
            keywords: [section.searchKeywords, source.rawValue, section.commandPaletteSidebarKeywords]
        )
    }

    private static func advancedAliasEntries(includeDogfood: Bool) -> [SettingsCommandPaletteEntry] {
        AdvancedFeatureDirectory.searchAliasEntries(showDogfood: includeDogfood)
            .compactMap { entry in
                let destination = entry.destination ?? SettingsSection.advanced
                guard entry.title != destination.title else { return nil }

                return SettingsCommandPaletteEntry(
                    id: "settings.advancedAlias.\(entry.id.slugifiedForCommandPalette)",
                    title: entry.title,
                    subtitle: entry.subtitle,
                    systemImage: entry.systemImage,
                    kind: .setting,
                    source: .advancedAlias,
                    destination: destination,
                    action: nil,
                    keywords: [
                        destination.title,
                        destination.helpText,
                        entry.status.title,
                        "advanced"
                    ]
                )
            }
    }

    private static func actionEntries(
        availableActions: Set<SettingsCommandPaletteAction>
    ) -> [SettingsCommandPaletteEntry] {
        SettingsCommandPaletteAction.allCases
            .filter(availableActions.contains)
            .map { action in
                SettingsCommandPaletteEntry(
                    id: "settings.action.\(action.rawValue)",
                    title: action.title,
                    subtitle: action.subtitle,
                    systemImage: action.systemImage,
                    kind: .action,
                    source: .action,
                    destination: nil,
                    action: action,
                    keywords: [action.searchKeywords]
                )
            }
    }
}

private extension SettingsSection {
    var commandPaletteTitle: String {
        switch self {
        case .behavior:
            "Hide & Reveal Legacy"
        case .layout:
            "Layout Labs"
        case .menuBarItems:
            "Menu Bar Item Inspector"
        case .search:
            "Find Icon Settings"
        case .secondBar:
            "Second Bar Settings"
        default:
            title
        }
    }

    var commandPaletteSubtitle: String {
        switch self {
        case .behavior:
            "Legacy route for reveal behavior. Use Hide & Reveal for the main workflow."
        case .layout:
            "Advanced capacity, spacer, Full Menu Bar Mode, and spacing lab controls."
        case .menuBarItems, .search, .secondBar, .groups, .hotkeys, .profiles, .automation, .privateAccess, .importExport:
            "\(helpText) Advanced surface."
        default:
            helpText
        }
    }

    var commandPaletteSidebarKeywords: String {
        if SettingsSection.visibleSidebarSections.contains(self) {
            return "primary settings sidebar"
        }

        if SettingsSection.moreSidebarSections.contains(self) {
            return "more settings sidebar"
        }

        return "hidden legacy route"
    }
}

private extension String {
    var slugifiedForCommandPalette: String {
        lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: "-")
    }
}
