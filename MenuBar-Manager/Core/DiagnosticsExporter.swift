import AppKit
import Foundation

/// Exports a privacy-safe diagnostics bundle to `.txt` or `.json`.
///
/// The bundle intentionally excludes:
/// - screenshots or screen contents (only screen *frames* are reported),
/// - personal file paths (the diagnostics directory path is included only when
///   the caller explicitly opts in via `includeAppSupportPath`),
/// - network data,
/// - individual icon identities.
///
/// Only the minimal information needed to support the user is included.
struct DiagnosticsExporter {
    enum Format: String, CaseIterable, Identifiable {
        case txt
        case json

        var id: String { rawValue }

        var fileExtension: String { rawValue }

        var contentType: String {
            switch self {
            case .txt: return "public.plain-text"
            case .json: return "public.json"
            }
        }
    }

    struct ScreenSnapshot: Codable, Equatable, Sendable {
        let index: Int
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let isMain: Bool

        init(
            index: Int,
            x: Double = 0,
            y: Double = 0,
            width: Double,
            height: Double,
            isMain: Bool
        ) {
            self.index = index
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            self.isMain = isMain
        }
    }

    /// Provider closures kept injectable for unit tests.
    let appVersionProvider: () -> String
    let marketingVersionProvider: () -> String
    let buildNumberProvider: () -> String
    let bundleIdentifierProvider: () -> String
    let macOSVersionProvider: () -> String
    let architectureProvider: () -> String
    let screensProvider: () -> [ScreenSnapshot]
    let dateProvider: () -> Date

    init(
        appVersionProvider: @escaping () -> String = { AppConstants.appVersion },
        marketingVersionProvider: @escaping () -> String = { AppConstants.marketingVersion },
        buildNumberProvider: @escaping () -> String = { AppConstants.buildNumber },
        bundleIdentifierProvider: @escaping () -> String = { AppConstants.bundleIdentifier },
        macOSVersionProvider: @escaping () -> String = { ProcessInfo.processInfo.operatingSystemVersionString },
        architectureProvider: @escaping () -> String = { Self.currentArchitecture() },
        screensProvider: @escaping () -> [ScreenSnapshot] = { Self.currentScreens() },
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.appVersionProvider = appVersionProvider
        self.marketingVersionProvider = marketingVersionProvider
        self.buildNumberProvider = buildNumberProvider
        self.bundleIdentifierProvider = bundleIdentifierProvider
        self.macOSVersionProvider = macOSVersionProvider
        self.architectureProvider = architectureProvider
        self.screensProvider = screensProvider
        self.dateProvider = dateProvider
    }

    // MARK: Snapshot assembly

    /// A serializable, privacy-safe diagnostics snapshot.
    struct Snapshot {
        let generatedAt: Date
        let appVersion: String
        let marketingVersion: String
        let buildNumber: String
        let bundleIdentifier: String
        let macOSVersion: String
        let architecture: String
        let screens: [ScreenSnapshot]
        let settings: SettingsSnapshot
        let events: [DiagnosticEvent]
        let dogfood: DogfoodDiagnosticsMetadata?
    }

    /// A minimal, human-readable settings snapshot. Never embeds file paths or
    /// network configuration.
    struct SettingsSnapshot: Encodable {
        let appMode: String
        let isCollapsed: Bool
        let hasCompletedOnboarding: Bool
        let launchAtLoginEnabled: Bool
        let proModeEnabled: Bool
        let accessibilityDiscoveryEnabled: Bool
        let lastAccessibilityPermissionStatus: String?
        let menuBarScanIntervalSeconds: Double
        let searchEnabled: Bool
        let searchHotkeyEnabled: Bool
        let searchHotkeyDisplayName: String
        let searchRevealOnSelection: Bool
        let searchHighlightOnSelection: Bool
        let secondBarEnabled: Bool
        let secondBarShowHiddenItems: Bool
        let secondBarShowAlwaysHiddenItems: Bool
        let secondBarAutoCloseAfterSelection: Bool
        let secondBarPositionMode: String
        let secondBarIconSize: Double
        let secondBarShowLabels: Bool
        let secondBarCloseOnOutsideClick: Bool
        let secondBarActivateOwningAppOnSelection: Bool
        let iconMovingEnabled: Bool
        let iconMovingRequireConfirmation: Bool
        let iconMovingMaxRetries: Int
        let iconMovingDragDuration: Double
        let iconMovingAllowSystemItems: Bool
        let smartTriggersEnabled: Bool
        let automationPaused: Bool
        let dogfoodModeEnabled: Bool
        let dogfoodNotesEnabled: Bool
        let showPrimarySeparator: Bool
        let showSeparators: Bool
        let autoRehideEnabled: Bool
        let autoRehideDelaySeconds: Double
        let hoverRevealEnabled: Bool
        let hoverRevealPollingIntervalSeconds: Double
        let alwaysHiddenEnabled: Bool
        let globalHotkeyEnabled: Bool
        let globalHotkeyDisplayName: String
        let revealAllOnOptionClick: Bool
        let expandedSeparatorLength: Double
        let collapsedSeparatorLengthOverride: Double?
        let layoutFeaturesEnabled: Bool
        let fullMenuBarModeEnabled: Bool
        let crowdedRevealRescueEnabled: Bool
        let layoutSuggestionsEnabled: Bool
        let showCapacityWarnings: Bool
        let fullMenuBarModeAutoExitEnabled: Bool
        let fullMenuBarModeAutoExitSeconds: Double
        let fullMenuBarModeShowsSecondBar: Bool
        let fullMenuBarModeSuspendsAutoRehide: Bool
        let fullMenuBarModeShowsSpacerMarkers: Bool
        let crowdedRevealAutoOpenSecondBar: Bool
        let crowdedRevealThresholdRatio: Double
        let crowdedRevealRequireProEstimate: Bool
        let spacerItemsEnabled: Bool
        let showSpacerMarkers: Bool
        let spacerItemsJSONVersion: Int
        let menuBarSpacingLabsEnabled: Bool
        let menuBarSpacingPreset: String
        let menuBarSpacingCustomItemSpacing: Int
        let menuBarSpacingCustomSelectionPadding: Int
        let menuBarSpacingHasBackup: Bool
        let menuBarSpacingLastApplyStatus: String?
        let menuBarSpacingLastApplyDate: String?
        let groupsEnabled: Bool
        let groupStatusItemsEnabled: Bool
        let protectedGroupsRequireAuth: Bool
        let groupsJSONVersion: Int
        let privateAccessEnabled: Bool
        let privateAccessProtectAlwaysHidden: Bool
        let privateAccessProtectSecondBar: Bool
        let privateAccessProtectFindIcon: Bool
        let privateAccessProtectIconMoving: Bool
        let privateAccessProtectSpacingLabs: Bool
        let privateAccessProtectProfileApply: Bool
        let privateAccessProtectAutomationCommands: Bool
        let privateAccessUnlockDurationSeconds: Double
        let privateAccessLastAuthStatus: String?
        let privateAccessAllowDevicePasswordFallback: Bool
        let appIntentsEnabled: Bool
        let appIntentsCanApplyProfiles: Bool
        let appIntentsCanAccessLabs: Bool
        let dynamicHotkeysEnabled: Bool
        let maxDynamicHotkeys: Int

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for field in DiagnosticsExporter.settingsFields {
                try field.encode(snapshot: self, to: &container)
            }
        }
    }

    func makeSnapshot(
        settingsStore: SettingsStore,
        logger: DiagnosticsLogger,
        events: [DiagnosticEvent]? = nil
    ) -> Snapshot {
        Snapshot(
            generatedAt: dateProvider(),
            appVersion: appVersionProvider(),
            marketingVersion: marketingVersionProvider(),
            buildNumber: buildNumberProvider(),
            bundleIdentifier: bundleIdentifierProvider(),
            macOSVersion: macOSVersionProvider(),
            architecture: architectureProvider(),
            screens: screensProvider(),
            settings: makeSettingsSnapshot(settingsStore),
            events: events ?? logger.events,
            dogfood: makeDogfoodMetadata(settingsStore)
        )
    }

    func makeSettingsSnapshot(_ store: SettingsStore) -> SettingsSnapshot {
        SettingsSnapshot(
            appMode: store.appMode.rawValue,
            isCollapsed: store.isCollapsed,
            hasCompletedOnboarding: store.hasCompletedOnboarding,
            launchAtLoginEnabled: store.launchAtLoginEnabled,
            proModeEnabled: store.proModeEnabled,
            accessibilityDiscoveryEnabled: store.accessibilityDiscoveryEnabled,
            lastAccessibilityPermissionStatus: store.lastAccessibilityPermissionStatus,
            menuBarScanIntervalSeconds: store.menuBarScanIntervalSeconds,
            searchEnabled: store.searchEnabled,
            searchHotkeyEnabled: store.searchHotkeyEnabled,
            searchHotkeyDisplayName: store.effectiveSearchHotkey().displayName,
            searchRevealOnSelection: store.searchRevealOnSelection,
            searchHighlightOnSelection: store.searchHighlightOnSelection,
            secondBarEnabled: store.secondBarEnabled,
            secondBarShowHiddenItems: store.secondBarShowHiddenItems,
            secondBarShowAlwaysHiddenItems: store.secondBarShowAlwaysHiddenItems,
            secondBarAutoCloseAfterSelection: store.secondBarAutoCloseAfterSelection,
            secondBarPositionMode: store.effectiveSecondBarPositionMode().rawValue,
            secondBarIconSize: store.secondBarIconSize,
            secondBarShowLabels: store.secondBarShowLabels,
            secondBarCloseOnOutsideClick: store.secondBarCloseOnOutsideClick,
            secondBarActivateOwningAppOnSelection: store.secondBarActivateOwningAppOnSelection,
            iconMovingEnabled: store.iconMovingEnabled,
            iconMovingRequireConfirmation: store.iconMovingRequireConfirmation,
            iconMovingMaxRetries: store.iconMovingMaxRetries,
            iconMovingDragDuration: store.iconMovingDragDuration,
            iconMovingAllowSystemItems: store.iconMovingAllowSystemItems,
            smartTriggersEnabled: store.smartTriggersEnabled,
            automationPaused: store.automationPaused,
            dogfoodModeEnabled: store.dogfoodModeEnabled,
            dogfoodNotesEnabled: store.dogfoodNotesEnabled,
            showPrimarySeparator: store.showPrimarySeparator,
            showSeparators: store.showSeparators,
            autoRehideEnabled: store.autoRehideEnabled,
            autoRehideDelaySeconds: store.autoRehideDelaySeconds,
            hoverRevealEnabled: store.hoverRevealEnabled,
            hoverRevealPollingIntervalSeconds: store.hoverRevealPollingIntervalSeconds,
            alwaysHiddenEnabled: store.alwaysHiddenEnabled,
            globalHotkeyEnabled: store.globalHotkeyEnabled,
            globalHotkeyDisplayName: store.effectiveGlobalHotkey().displayName,
            revealAllOnOptionClick: store.revealAllOnOptionClick,
            expandedSeparatorLength: store.expandedSeparatorLength,
            collapsedSeparatorLengthOverride: store.collapsedSeparatorLengthOverride,
            layoutFeaturesEnabled: store.layoutFeaturesEnabled,
            fullMenuBarModeEnabled: store.fullMenuBarModeEnabled,
            crowdedRevealRescueEnabled: store.crowdedRevealRescueEnabled,
            layoutSuggestionsEnabled: store.layoutSuggestionsEnabled,
            showCapacityWarnings: store.showCapacityWarnings,
            fullMenuBarModeAutoExitEnabled: store.fullMenuBarModeAutoExitEnabled,
            fullMenuBarModeAutoExitSeconds: store.fullMenuBarModeAutoExitSeconds,
            fullMenuBarModeShowsSecondBar: store.fullMenuBarModeShowsSecondBar,
            fullMenuBarModeSuspendsAutoRehide: store.fullMenuBarModeSuspendsAutoRehide,
            fullMenuBarModeShowsSpacerMarkers: store.fullMenuBarModeShowsSpacerMarkers,
            crowdedRevealAutoOpenSecondBar: store.crowdedRevealAutoOpenSecondBar,
            crowdedRevealThresholdRatio: store.crowdedRevealThresholdRatio,
            crowdedRevealRequireProEstimate: store.crowdedRevealRequireProEstimate,
            spacerItemsEnabled: store.spacerItemsEnabled,
            showSpacerMarkers: store.showSpacerMarkers,
            spacerItemsJSONVersion: store.spacerItemsJSONVersion,
            menuBarSpacingLabsEnabled: store.menuBarSpacingLabsEnabled,
            menuBarSpacingPreset: store.menuBarSpacingPreset,
            menuBarSpacingCustomItemSpacing: store.menuBarSpacingCustomItemSpacing,
            menuBarSpacingCustomSelectionPadding: store.menuBarSpacingCustomSelectionPadding,
            menuBarSpacingHasBackup: store.menuBarSpacingHasBackup,
            menuBarSpacingLastApplyStatus: store.menuBarSpacingLastApplyStatus,
            menuBarSpacingLastApplyDate: store.menuBarSpacingLastApplyDate.map(Self.iso),
            groupsEnabled: store.groupsEnabled,
            groupStatusItemsEnabled: store.groupStatusItemsEnabled,
            protectedGroupsRequireAuth: store.protectedGroupsRequireAuth,
            groupsJSONVersion: store.groupsJSONVersion,
            privateAccessEnabled: store.privateAccessEnabled,
            privateAccessProtectAlwaysHidden: store.privateAccessProtectAlwaysHidden,
            privateAccessProtectSecondBar: store.privateAccessProtectSecondBar,
            privateAccessProtectFindIcon: store.privateAccessProtectFindIcon,
            privateAccessProtectIconMoving: store.privateAccessProtectIconMoving,
            privateAccessProtectSpacingLabs: store.privateAccessProtectSpacingLabs,
            privateAccessProtectProfileApply: store.privateAccessProtectProfileApply,
            privateAccessProtectAutomationCommands: store.privateAccessProtectAutomationCommands,
            privateAccessUnlockDurationSeconds: store.privateAccessUnlockDurationSeconds,
            privateAccessLastAuthStatus: store.privateAccessLastAuthStatus,
            privateAccessAllowDevicePasswordFallback: store.privateAccessAllowDevicePasswordFallback,
            appIntentsEnabled: store.appIntentsEnabled,
            appIntentsCanApplyProfiles: store.appIntentsCanApplyProfiles,
            appIntentsCanAccessLabs: store.appIntentsCanAccessLabs,
            dynamicHotkeysEnabled: store.dynamicHotkeysEnabled,
            maxDynamicHotkeys: store.maxDynamicHotkeys
        )
    }

    func makeDogfoodMetadata(_ store: SettingsStore) -> DogfoodDiagnosticsMetadata? {
        guard store.dogfoodModeEnabled,
              let runID = store.dogfoodRunID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !runID.isEmpty else {
            return nil
        }
        return DogfoodDiagnosticsMetadata(runID: runID)
    }

    // MARK: Serialization

    /// Serializes the snapshot to the requested format. `includeAppSupportPath`
    /// is intentionally `false` by default: callers that explicitly need the
    /// diagnostics directory path (e.g. for display in a save panel) pass `true`.
    func serialize(
        _ snapshot: Snapshot,
        format: Format,
        includeAppSupportPath: Bool = false,
        appSupportPath: URL? = nil
    ) throws -> Data {
        switch format {
        case .txt:
            return try plainText(snapshot: snapshot, includeAppSupportPath: includeAppSupportPath, appSupportPath: appSupportPath)
        case .json:
            return try json(snapshot: snapshot, includeAppSupportPath: includeAppSupportPath, appSupportPath: appSupportPath)
        }
    }

    // MARK: Plain text

    private func plainText(snapshot: Snapshot, includeAppSupportPath: Bool, appSupportPath: URL?) throws -> Data {
        var lines: [String] = []
        let formatter = Self.sharedISOFormatter
        lines.append("MenuBarDeclutter Diagnostics")
        lines.append("Generated: \(formatter.string(from: snapshot.generatedAt))")
        lines.append("")
        lines.append("== Application ==")
        lines.append("Name: \(AppConstants.displayName)")
        lines.append("Bundle Identifier: \(snapshot.bundleIdentifier)")
        lines.append("Marketing Version: \(snapshot.marketingVersion.isEmpty ? "—" : snapshot.marketingVersion)")
        lines.append("Build Number: \(snapshot.buildNumber.isEmpty ? "—" : snapshot.buildNumber)")
        lines.append("App Version: \(snapshot.appVersion)")
        if let dogfood = snapshot.dogfood {
            lines.append("Dogfood Run ID: \(dogfood.runID)")
        }
        lines.append("")
        lines.append("== System ==")
        lines.append("macOS Version: \(snapshot.macOSVersion)")
        lines.append("Architecture: \(snapshot.architecture)")
        lines.append("")
        lines.append("== Screens ==")
        lines.append("Screen Count: \(snapshot.screens.count)")
        if snapshot.screens.isEmpty {
            lines.append("(none)")
        } else {
            for screen in snapshot.screens {
                let marker = screen.isMain ? " (main)" : ""
                lines.append(
                    "Screen \(screen.index)\(marker): \(Int(screen.width)) x \(Int(screen.height)) at (\(Int(screen.x)), \(Int(screen.y)))"
                )
            }
        }
        lines.append("")
        lines.append("== Settings ==")
        lines.append(contentsOf: Self.settingsPlainTextLines(for: snapshot.settings))
        lines.append("")
        if includeAppSupportPath, let path = appSupportPath {
            lines.append("== App Support ==")
            lines.append("Diagnostics Directory: \(path.path)")
            lines.append("")
        }
        lines.append("== Logs (last \(snapshot.events.count)) ==")
        if snapshot.events.isEmpty {
            lines.append("(none)")
        } else {
            for event in snapshot.events {
                let metadata = event.metadata.isEmpty ? "" : " metadata=\(event.metadata)"
                lines.append(
                    "[\(event.level.rawValue.uppercased())] [\(event.category.displayName)] \(formatter.string(from: event.timestamp)) - \(event.message)\(metadata)"
                )
            }
        }
        lines.append("")
        lines.append("== Excluded by design ==")
        lines.append("Screenshots, screen contents, live search text, selected item identity, personal file paths, network data.")
        let text = lines.joined(separator: "\n")
        guard let data = text.data(using: .utf8) else {
            throw DiagnosticsExportError.encodingFailed
        }
        return data
    }

    // MARK: JSON

    private func json(snapshot: Snapshot, includeAppSupportPath: Bool, appSupportPath: URL?) throws -> Data {
        let document = ExportDocument(
            snapshot: snapshot,
            includeAppSupportPath: includeAppSupportPath,
            appSupportPath: appSupportPath
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        do {
            return try encoder.encode(document)
        } catch {
            throw DiagnosticsExportError.encodingFailed
        }
    }

    private struct ExportDocument: Encodable {
        let generatedAt: String
        let application: Application
        let system: System
        let screens: [ScreenSnapshot]
        let settings: SettingsSnapshot
        let logs: [Log]
        let excludedByDesign: [String]
        let appSupport: AppSupport?
        let dogfood: DogfoodDiagnosticsMetadata?

        init(snapshot: Snapshot, includeAppSupportPath: Bool, appSupportPath: URL?) {
            self.generatedAt = DiagnosticsExporter.iso(snapshot.generatedAt)
            self.application = Application(snapshot: snapshot)
            self.system = System(snapshot: snapshot)
            self.screens = snapshot.screens
            self.settings = snapshot.settings
            self.logs = snapshot.events.map(Log.init(event:))
            self.excludedByDesign = DiagnosticsExporter.excludedByDesign
            self.appSupport = includeAppSupportPath
                ? appSupportPath.map { AppSupport(diagnosticsDirectory: $0.path) }
                : nil
            self.dogfood = snapshot.dogfood
        }

        enum CodingKeys: String, CodingKey {
            case generatedAt
            case application
            case system
            case screens
            case settings
            case logs
            case excludedByDesign
            case appSupport
            case dogfood
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(generatedAt, forKey: .generatedAt)
            try container.encode(application, forKey: .application)
            try container.encode(system, forKey: .system)
            try container.encode(screens, forKey: .screens)
            try container.encode(settings, forKey: .settings)
            try container.encode(logs, forKey: .logs)
            try container.encode(excludedByDesign, forKey: .excludedByDesign)
            try container.encodeIfPresent(appSupport, forKey: .appSupport)
            try container.encodeIfPresent(dogfood, forKey: .dogfood)
        }

        struct Application: Encodable {
            let name: String
            let bundleIdentifier: String
            let marketingVersion: String
            let buildNumber: String
            let appVersion: String

            init(snapshot: Snapshot) {
                self.name = AppConstants.displayName
                self.bundleIdentifier = snapshot.bundleIdentifier
                self.marketingVersion = snapshot.marketingVersion
                self.buildNumber = snapshot.buildNumber
                self.appVersion = snapshot.appVersion
            }
        }

        struct System: Encodable {
            let macOSVersion: String
            let architecture: String
            let screenCount: Int

            init(snapshot: Snapshot) {
                self.macOSVersion = snapshot.macOSVersion
                self.architecture = snapshot.architecture
                self.screenCount = snapshot.screens.count
            }
        }

        struct Log: Encodable {
            let category: String
            let level: String
            let severity: String
            let timestamp: String
            let message: String
            let metadata: [String: String]

            init(event: DiagnosticEvent) {
                self.category = event.category.rawValue
                self.level = event.level.rawValue
                self.severity = event.level.rawValue
                self.timestamp = DiagnosticsExporter.iso(event.timestamp)
                self.message = event.message
                self.metadata = event.metadata
            }
        }

        struct AppSupport: Encodable {
            let diagnosticsDirectory: String
        }
    }

    private struct DynamicCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    private enum SettingsFieldValue {
        case bool(Bool)
        case double(Double)
        case int(Int)
        case string(String)
        case optionalDouble(Double?, emptyText: String)
        case optionalString(String?, emptyText: String)

        var plainText: String {
            switch self {
            case let .bool(value):
                "\(value)"
            case let .double(value):
                "\(value)"
            case let .int(value):
                "\(value)"
            case let .string(value):
                value
            case let .optionalDouble(value, emptyText):
                value.map { "\($0)" } ?? emptyText
            case let .optionalString(value, emptyText):
                value ?? emptyText
            }
        }

        func encode(
            to container: inout KeyedEncodingContainer<DynamicCodingKey>,
            forKey key: DynamicCodingKey
        ) throws {
            switch self {
            case let .bool(value):
                try container.encode(value, forKey: key)
            case let .double(value):
                try container.encode(value, forKey: key)
            case let .int(value):
                try container.encode(value, forKey: key)
            case let .string(value):
                try container.encode(value, forKey: key)
            case let .optionalDouble(value, _):
                if let value {
                    try container.encode(value, forKey: key)
                } else {
                    try container.encodeNil(forKey: key)
                }
            case let .optionalString(value, _):
                if let value {
                    try container.encode(value, forKey: key)
                } else {
                    try container.encodeNil(forKey: key)
                }
            }
        }
    }

    private struct SettingsField {
        let key: String
        let label: String
        let value: (SettingsSnapshot) -> SettingsFieldValue

        func plainTextLine(for snapshot: SettingsSnapshot) -> String {
            "\(label): \(value(snapshot).plainText)"
        }

        func encode(
            snapshot: SettingsSnapshot,
            to container: inout KeyedEncodingContainer<DynamicCodingKey>
        ) throws {
            try value(snapshot).encode(to: &container, forKey: DynamicCodingKey(stringValue: key))
        }
    }

    private static let settingsFields: [SettingsField] = [
        SettingsField(key: "appMode", label: "App Mode") { .string($0.appMode) },
        SettingsField(key: "isCollapsed", label: "Collapsed") { .bool($0.isCollapsed) },
        SettingsField(key: "hasCompletedOnboarding", label: "Onboarding Completed") { .bool($0.hasCompletedOnboarding) },
        SettingsField(key: "launchAtLoginEnabled", label: "Launch at Login") { .bool($0.launchAtLoginEnabled) },
        SettingsField(key: "proModeEnabled", label: "Pro Mode Enabled") { .bool($0.proModeEnabled) },
        SettingsField(key: "accessibilityDiscoveryEnabled", label: "Accessibility Discovery Enabled") { .bool($0.accessibilityDiscoveryEnabled) },
        SettingsField(key: "lastAccessibilityPermissionStatus", label: "Last Accessibility Permission Status") {
            .optionalString($0.lastAccessibilityPermissionStatus, emptyText: "(none)")
        },
        SettingsField(key: "menuBarScanIntervalSeconds", label: "Menu Bar Scan Interval (s)") { .double($0.menuBarScanIntervalSeconds) },
        SettingsField(key: "searchEnabled", label: "Find Icon Enabled") { .bool($0.searchEnabled) },
        SettingsField(key: "searchHotkeyEnabled", label: "Find Icon Hotkey Enabled") { .bool($0.searchHotkeyEnabled) },
        SettingsField(key: "searchHotkeyDisplayName", label: "Find Icon Hotkey") { .string($0.searchHotkeyDisplayName) },
        SettingsField(key: "searchRevealOnSelection", label: "Find Icon Reveal on Selection") { .bool($0.searchRevealOnSelection) },
        SettingsField(key: "searchHighlightOnSelection", label: "Find Icon Highlight on Selection") { .bool($0.searchHighlightOnSelection) },
        SettingsField(key: "secondBarEnabled", label: "Second Bar Enabled") { .bool($0.secondBarEnabled) },
        SettingsField(key: "secondBarShowHiddenItems", label: "Second Bar Show Hidden Items") { .bool($0.secondBarShowHiddenItems) },
        SettingsField(key: "secondBarShowAlwaysHiddenItems", label: "Second Bar Show Always-Hidden Items") { .bool($0.secondBarShowAlwaysHiddenItems) },
        SettingsField(key: "secondBarAutoCloseAfterSelection", label: "Second Bar Auto-close") { .bool($0.secondBarAutoCloseAfterSelection) },
        SettingsField(key: "secondBarPositionMode", label: "Second Bar Position Mode") { .string($0.secondBarPositionMode) },
        SettingsField(key: "secondBarIconSize", label: "Second Bar Icon Size") { .double($0.secondBarIconSize) },
        SettingsField(key: "secondBarShowLabels", label: "Second Bar Show Labels") { .bool($0.secondBarShowLabels) },
        SettingsField(key: "secondBarCloseOnOutsideClick", label: "Second Bar Close Outside") { .bool($0.secondBarCloseOnOutsideClick) },
        SettingsField(key: "secondBarActivateOwningAppOnSelection", label: "Second Bar Activate Owning App") {
            .bool($0.secondBarActivateOwningAppOnSelection)
        },
        SettingsField(key: "iconMovingEnabled", label: "Icon Moving Enabled") { .bool($0.iconMovingEnabled) },
        SettingsField(key: "iconMovingRequireConfirmation", label: "Icon Moving Require Confirmation") {
            .bool($0.iconMovingRequireConfirmation)
        },
        SettingsField(key: "iconMovingMaxRetries", label: "Icon Moving Max Retries") { .int($0.iconMovingMaxRetries) },
        SettingsField(key: "iconMovingDragDuration", label: "Icon Moving Drag Duration") { .double($0.iconMovingDragDuration) },
        SettingsField(key: "iconMovingAllowSystemItems", label: "Icon Moving Allow System Items") {
            .bool($0.iconMovingAllowSystemItems)
        },
        SettingsField(key: "smartTriggersEnabled", label: "Smart Triggers Enabled") { .bool($0.smartTriggersEnabled) },
        SettingsField(key: "automationPaused", label: "Automation Paused") { .bool($0.automationPaused) },
        SettingsField(key: "dogfoodModeEnabled", label: "Dogfood Mode Enabled") { .bool($0.dogfoodModeEnabled) },
        SettingsField(key: "dogfoodNotesEnabled", label: "Dogfood Notes Enabled") { .bool($0.dogfoodNotesEnabled) },
        SettingsField(key: "showSeparators", label: "Show Separators") { .bool($0.showSeparators) },
        SettingsField(key: "autoRehideEnabled", label: "Auto-Rehide Enabled") { .bool($0.autoRehideEnabled) },
        SettingsField(key: "autoRehideDelaySeconds", label: "Auto-Rehide Delay (s)") { .double($0.autoRehideDelaySeconds) },
        SettingsField(key: "hoverRevealEnabled", label: "Hover Reveal Enabled") { .bool($0.hoverRevealEnabled) },
        SettingsField(key: "hoverRevealPollingIntervalSeconds", label: "Hover Polling Interval (s)") {
            .double($0.hoverRevealPollingIntervalSeconds)
        },
        SettingsField(key: "alwaysHiddenEnabled", label: "Always-Hidden Enabled") { .bool($0.alwaysHiddenEnabled) },
        SettingsField(key: "globalHotkeyEnabled", label: "Global Hotkey Enabled") { .bool($0.globalHotkeyEnabled) },
        SettingsField(key: "globalHotkeyDisplayName", label: "Global Hotkey") { .string($0.globalHotkeyDisplayName) },
        SettingsField(key: "revealAllOnOptionClick", label: "Reveal All on Option-Click") { .bool($0.revealAllOnOptionClick) },
        SettingsField(key: "expandedSeparatorLength", label: "Expanded Separator Length") { .double($0.expandedSeparatorLength) },
        SettingsField(key: "collapsedSeparatorLengthOverride", label: "Collapsed Separator Override") {
            .optionalDouble($0.collapsedSeparatorLengthOverride, emptyText: "(none — auto)")
        },
        SettingsField(key: "layoutFeaturesEnabled", label: "Layout Features Enabled") { .bool($0.layoutFeaturesEnabled) },
        SettingsField(key: "fullMenuBarModeEnabled", label: "Full Menu Bar Mode Enabled") { .bool($0.fullMenuBarModeEnabled) },
        SettingsField(key: "crowdedRevealRescueEnabled", label: "Crowded Reveal Rescue Enabled") { .bool($0.crowdedRevealRescueEnabled) },
        SettingsField(key: "layoutSuggestionsEnabled", label: "Layout Suggestions Enabled") { .bool($0.layoutSuggestionsEnabled) },
        SettingsField(key: "showCapacityWarnings", label: "Show Capacity Warnings") { .bool($0.showCapacityWarnings) },
        SettingsField(key: "fullMenuBarModeAutoExitEnabled", label: "Full Menu Bar Auto-exit Enabled") {
            .bool($0.fullMenuBarModeAutoExitEnabled)
        },
        SettingsField(key: "fullMenuBarModeAutoExitSeconds", label: "Full Menu Bar Auto-exit (s)") {
            .double($0.fullMenuBarModeAutoExitSeconds)
        },
        SettingsField(key: "fullMenuBarModeShowsSecondBar", label: "Full Menu Bar Shows Second Bar") {
            .bool($0.fullMenuBarModeShowsSecondBar)
        },
        SettingsField(key: "fullMenuBarModeSuspendsAutoRehide", label: "Full Menu Bar Suspends Auto-Rehide") {
            .bool($0.fullMenuBarModeSuspendsAutoRehide)
        },
        SettingsField(key: "fullMenuBarModeShowsSpacerMarkers", label: "Full Menu Bar Shows Spacer Markers") {
            .bool($0.fullMenuBarModeShowsSpacerMarkers)
        },
        SettingsField(key: "crowdedRevealAutoOpenSecondBar", label: "Crowded Reveal Opens Second Bar") {
            .bool($0.crowdedRevealAutoOpenSecondBar)
        },
        SettingsField(key: "crowdedRevealThresholdRatio", label: "Crowded Reveal Threshold Ratio") {
            .double($0.crowdedRevealThresholdRatio)
        },
        SettingsField(key: "crowdedRevealRequireProEstimate", label: "Crowded Reveal Requires Pro Estimate") {
            .bool($0.crowdedRevealRequireProEstimate)
        },
        SettingsField(key: "spacerItemsEnabled", label: "Spacer Items Enabled") { .bool($0.spacerItemsEnabled) },
        SettingsField(key: "showSpacerMarkers", label: "Show Spacer Markers") { .bool($0.showSpacerMarkers) },
        SettingsField(key: "spacerItemsJSONVersion", label: "Spacer Items JSON Version") { .int($0.spacerItemsJSONVersion) },
        SettingsField(key: "menuBarSpacingLabsEnabled", label: "Menu Bar Spacing Labs Enabled") {
            .bool($0.menuBarSpacingLabsEnabled)
        },
        SettingsField(key: "menuBarSpacingPreset", label: "Menu Bar Spacing Preset") { .string($0.menuBarSpacingPreset) },
        SettingsField(key: "menuBarSpacingCustomItemSpacing", label: "Menu Bar Spacing Custom Item Spacing") {
            .int($0.menuBarSpacingCustomItemSpacing)
        },
        SettingsField(key: "menuBarSpacingCustomSelectionPadding", label: "Menu Bar Spacing Custom Selection Padding") {
            .int($0.menuBarSpacingCustomSelectionPadding)
        },
        SettingsField(key: "menuBarSpacingHasBackup", label: "Menu Bar Spacing Has Backup") { .bool($0.menuBarSpacingHasBackup) },
        SettingsField(key: "menuBarSpacingLastApplyStatus", label: "Menu Bar Spacing Last Apply Status") {
            .optionalString($0.menuBarSpacingLastApplyStatus, emptyText: "(none)")
        },
        SettingsField(key: "menuBarSpacingLastApplyDate", label: "Menu Bar Spacing Last Apply Date") {
            .optionalString($0.menuBarSpacingLastApplyDate, emptyText: "(none)")
        },
        SettingsField(key: "groupsEnabled", label: "Groups Enabled") { .bool($0.groupsEnabled) },
        SettingsField(key: "groupStatusItemsEnabled", label: "Group Status Items Enabled") { .bool($0.groupStatusItemsEnabled) },
        SettingsField(key: "protectedGroupsRequireAuth", label: "Protected Groups Require Auth") {
            .bool($0.protectedGroupsRequireAuth)
        },
        SettingsField(key: "groupsJSONVersion", label: "Groups JSON Version") { .int($0.groupsJSONVersion) },
        SettingsField(key: "privateAccessEnabled", label: "Private Access Enabled") { .bool($0.privateAccessEnabled) },
        SettingsField(key: "privateAccessProtectAlwaysHidden", label: "Private Access Protect Always-Hidden") {
            .bool($0.privateAccessProtectAlwaysHidden)
        },
        SettingsField(key: "privateAccessProtectSecondBar", label: "Private Access Protect Second Bar") {
            .bool($0.privateAccessProtectSecondBar)
        },
        SettingsField(key: "privateAccessProtectFindIcon", label: "Private Access Protect Find Icon") {
            .bool($0.privateAccessProtectFindIcon)
        },
        SettingsField(key: "privateAccessProtectIconMoving", label: "Private Access Protect Icon Moving") {
            .bool($0.privateAccessProtectIconMoving)
        },
        SettingsField(key: "privateAccessProtectSpacingLabs", label: "Private Access Protect Spacing Labs") {
            .bool($0.privateAccessProtectSpacingLabs)
        },
        SettingsField(key: "privateAccessProtectProfileApply", label: "Private Access Protect Profile Apply") {
            .bool($0.privateAccessProtectProfileApply)
        },
        SettingsField(key: "privateAccessProtectAutomationCommands", label: "Private Access Protect Automation Commands") {
            .bool($0.privateAccessProtectAutomationCommands)
        },
        SettingsField(key: "privateAccessUnlockDurationSeconds", label: "Private Access Unlock Duration (s)") {
            .double($0.privateAccessUnlockDurationSeconds)
        },
        SettingsField(key: "privateAccessLastAuthStatus", label: "Private Access Last Auth Status") {
            .optionalString($0.privateAccessLastAuthStatus, emptyText: "(none)")
        },
        SettingsField(key: "privateAccessAllowDevicePasswordFallback", label: "Private Access Allows Device Password Fallback") {
            .bool($0.privateAccessAllowDevicePasswordFallback)
        },
        SettingsField(key: "appIntentsEnabled", label: "App Intents Enabled") { .bool($0.appIntentsEnabled) },
        SettingsField(key: "appIntentsCanApplyProfiles", label: "App Intents Can Apply Profiles") {
            .bool($0.appIntentsCanApplyProfiles)
        },
        SettingsField(key: "appIntentsCanAccessLabs", label: "App Intents Can Access Labs") {
            .bool($0.appIntentsCanAccessLabs)
        },
        SettingsField(key: "dynamicHotkeysEnabled", label: "Dynamic Hotkeys Enabled") { .bool($0.dynamicHotkeysEnabled) },
        SettingsField(key: "maxDynamicHotkeys", label: "Max Dynamic Hotkeys") { .int($0.maxDynamicHotkeys) }
    ]

    private static let excludedByDesign = [
        "screenshots",
        "screenContents",
        "liveSearchText",
        "selectedItemIdentity",
        "protectedGroupNames",
        "protectedHotkeyTargets",
        "importExportFilePaths",
        "personalFilePaths",
        "networkData"
    ]

    private static func settingsPlainTextLines(for snapshot: SettingsSnapshot) -> [String] {
        settingsFields.map { $0.plainTextLine(for: snapshot) }
    }

    // MARK: Helpers

    /// Cached ISO8601 formatter (with `.withInternetDateTime` options) shared by all
    /// `plainText` and `json` formatting passes. `ISO8601DateFormatter` is documented
    /// as thread-safe, and the only configuration mutating the formatter (its
    /// `formatOptions`) happens once at construction.
    private static let sharedISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func iso(_ date: Date) -> String {
        sharedISOFormatter.string(from: date)
    }

    static func currentArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    static func currentScreens() -> [ScreenSnapshot] {
        NSScreen.screens.enumerated().map { index, screen in
            ScreenSnapshot(
                index: index,
                x: Double(screen.frame.minX),
                y: Double(screen.frame.minY),
                width: Double(screen.frame.width),
                height: Double(screen.frame.height),
                isMain: screen == NSScreen.main
            )
        }
    }
}

enum DiagnosticsExportError: Error {
    case encodingFailed
}
