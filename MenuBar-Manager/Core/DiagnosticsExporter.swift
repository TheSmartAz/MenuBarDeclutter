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

    struct ScreenSnapshot: Equatable, Sendable {
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
    }

    /// A minimal, human-readable settings snapshot. Never embeds file paths or
    /// network configuration.
    struct SettingsSnapshot {
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
            events: events ?? logger.events
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
            collapsedSeparatorLengthOverride: store.collapsedSeparatorLengthOverride
        )
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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        lines.append("MenuBarDeclutter Diagnostics")
        lines.append("Generated: \(formatter.string(from: snapshot.generatedAt))")
        lines.append("")
        lines.append("== Application ==")
        lines.append("Name: \(AppConstants.displayName)")
        lines.append("Bundle Identifier: \(snapshot.bundleIdentifier)")
        lines.append("Marketing Version: \(snapshot.marketingVersion.isEmpty ? "—" : snapshot.marketingVersion)")
        lines.append("Build Number: \(snapshot.buildNumber.isEmpty ? "—" : snapshot.buildNumber)")
        lines.append("App Version: \(snapshot.appVersion)")
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
        let s = snapshot.settings
        lines.append("App Mode: \(s.appMode)")
        lines.append("Collapsed: \(s.isCollapsed)")
        lines.append("Onboarding Completed: \(s.hasCompletedOnboarding)")
        lines.append("Launch at Login: \(s.launchAtLoginEnabled)")
        lines.append("Pro Mode Enabled: \(s.proModeEnabled)")
        lines.append("Accessibility Discovery Enabled: \(s.accessibilityDiscoveryEnabled)")
        lines.append("Last Accessibility Permission Status: \(s.lastAccessibilityPermissionStatus ?? "(none)")")
        lines.append("Menu Bar Scan Interval (s): \(s.menuBarScanIntervalSeconds)")
        lines.append("Find Icon Enabled: \(s.searchEnabled)")
        lines.append("Find Icon Hotkey Enabled: \(s.searchHotkeyEnabled)")
        lines.append("Find Icon Hotkey: \(s.searchHotkeyDisplayName)")
        lines.append("Find Icon Reveal on Selection: \(s.searchRevealOnSelection)")
        lines.append("Find Icon Highlight on Selection: \(s.searchHighlightOnSelection)")
        lines.append("Second Bar Enabled: \(s.secondBarEnabled)")
        lines.append("Second Bar Show Hidden Items: \(s.secondBarShowHiddenItems)")
        lines.append("Second Bar Show Always-Hidden Items: \(s.secondBarShowAlwaysHiddenItems)")
        lines.append("Second Bar Auto-close: \(s.secondBarAutoCloseAfterSelection)")
        lines.append("Second Bar Position Mode: \(s.secondBarPositionMode)")
        lines.append("Second Bar Icon Size: \(s.secondBarIconSize)")
        lines.append("Second Bar Show Labels: \(s.secondBarShowLabels)")
        lines.append("Second Bar Close Outside: \(s.secondBarCloseOnOutsideClick)")
        lines.append("Second Bar Activate Owning App: \(s.secondBarActivateOwningAppOnSelection)")
        lines.append("Icon Moving Enabled: \(s.iconMovingEnabled)")
        lines.append("Icon Moving Require Confirmation: \(s.iconMovingRequireConfirmation)")
        lines.append("Icon Moving Max Retries: \(s.iconMovingMaxRetries)")
        lines.append("Icon Moving Drag Duration: \(s.iconMovingDragDuration)")
        lines.append("Icon Moving Allow System Items: \(s.iconMovingAllowSystemItems)")
        lines.append("Smart Triggers Enabled: \(s.smartTriggersEnabled)")
        lines.append("Automation Paused: \(s.automationPaused)")
        lines.append("Show Primary Separator: \(s.showPrimarySeparator)")
        lines.append("Show Separators: \(s.showSeparators)")
        lines.append("Auto-Rehide Enabled: \(s.autoRehideEnabled)")
        lines.append("Auto-Rehide Delay (s): \(s.autoRehideDelaySeconds)")
        lines.append("Hover Reveal Enabled: \(s.hoverRevealEnabled)")
        lines.append("Hover Polling Interval (s): \(s.hoverRevealPollingIntervalSeconds)")
        lines.append("Always-Hidden Enabled: \(s.alwaysHiddenEnabled)")
        lines.append("Global Hotkey Enabled: \(s.globalHotkeyEnabled)")
        lines.append("Global Hotkey: \(s.globalHotkeyDisplayName)")
        lines.append("Reveal All on Option-Click: \(s.revealAllOnOptionClick)")
        lines.append("Expanded Separator Length: \(s.expandedSeparatorLength)")
        if let override = s.collapsedSeparatorLengthOverride {
            lines.append("Collapsed Separator Override: \(override)")
        } else {
            lines.append("Collapsed Separator Override: (none — auto)")
        }
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
        var dict: [String: Any] = [
            "generatedAt": Self.iso(snapshot.generatedAt),
            "application": [
                "name": AppConstants.displayName,
                "bundleIdentifier": snapshot.bundleIdentifier,
                "marketingVersion": snapshot.marketingVersion,
                "buildNumber": snapshot.buildNumber,
                "appVersion": snapshot.appVersion
            ],
            "system": [
                "macOSVersion": snapshot.macOSVersion,
                "architecture": snapshot.architecture,
                "screenCount": snapshot.screens.count
            ],
            "screens": snapshot.screens.map { screen in
                [
                    "index": screen.index,
                    "x": screen.x,
                    "y": screen.y,
                    "width": screen.width,
                    "height": screen.height,
                    "isMain": screen.isMain
                ] as [String: Any]
            },
            "settings": [
                "appMode": snapshot.settings.appMode,
                "isCollapsed": snapshot.settings.isCollapsed,
                "hasCompletedOnboarding": snapshot.settings.hasCompletedOnboarding,
                "launchAtLoginEnabled": snapshot.settings.launchAtLoginEnabled,
                "proModeEnabled": snapshot.settings.proModeEnabled,
                "accessibilityDiscoveryEnabled": snapshot.settings.accessibilityDiscoveryEnabled,
                "lastAccessibilityPermissionStatus": snapshot.settings.lastAccessibilityPermissionStatus ?? NSNull(),
                "menuBarScanIntervalSeconds": snapshot.settings.menuBarScanIntervalSeconds,
                "searchEnabled": snapshot.settings.searchEnabled,
                "searchHotkeyEnabled": snapshot.settings.searchHotkeyEnabled,
                "searchHotkeyDisplayName": snapshot.settings.searchHotkeyDisplayName,
                "searchRevealOnSelection": snapshot.settings.searchRevealOnSelection,
                "searchHighlightOnSelection": snapshot.settings.searchHighlightOnSelection,
                "secondBarEnabled": snapshot.settings.secondBarEnabled,
                "secondBarShowHiddenItems": snapshot.settings.secondBarShowHiddenItems,
                "secondBarShowAlwaysHiddenItems": snapshot.settings.secondBarShowAlwaysHiddenItems,
                "secondBarAutoCloseAfterSelection": snapshot.settings.secondBarAutoCloseAfterSelection,
                "secondBarPositionMode": snapshot.settings.secondBarPositionMode,
                "secondBarIconSize": snapshot.settings.secondBarIconSize,
                "secondBarShowLabels": snapshot.settings.secondBarShowLabels,
                "secondBarCloseOnOutsideClick": snapshot.settings.secondBarCloseOnOutsideClick,
                "secondBarActivateOwningAppOnSelection": snapshot.settings.secondBarActivateOwningAppOnSelection,
                "iconMovingEnabled": snapshot.settings.iconMovingEnabled,
                "iconMovingRequireConfirmation": snapshot.settings.iconMovingRequireConfirmation,
                "iconMovingMaxRetries": snapshot.settings.iconMovingMaxRetries,
                "iconMovingDragDuration": snapshot.settings.iconMovingDragDuration,
                "iconMovingAllowSystemItems": snapshot.settings.iconMovingAllowSystemItems,
                "smartTriggersEnabled": snapshot.settings.smartTriggersEnabled,
                "automationPaused": snapshot.settings.automationPaused,
                "showPrimarySeparator": snapshot.settings.showPrimarySeparator,
                "showSeparators": snapshot.settings.showSeparators,
                "autoRehideEnabled": snapshot.settings.autoRehideEnabled,
                "autoRehideDelaySeconds": snapshot.settings.autoRehideDelaySeconds,
                "hoverRevealEnabled": snapshot.settings.hoverRevealEnabled,
                "hoverRevealPollingIntervalSeconds": snapshot.settings.hoverRevealPollingIntervalSeconds,
                "alwaysHiddenEnabled": snapshot.settings.alwaysHiddenEnabled,
                "globalHotkeyEnabled": snapshot.settings.globalHotkeyEnabled,
                "globalHotkeyDisplayName": snapshot.settings.globalHotkeyDisplayName,
                "revealAllOnOptionClick": snapshot.settings.revealAllOnOptionClick,
                "expandedSeparatorLength": snapshot.settings.expandedSeparatorLength,
                "collapsedSeparatorLengthOverride": snapshot.settings.collapsedSeparatorLengthOverride ?? NSNull()
            ] as [String: Any],
            "logs": snapshot.events.map { event in
                [
                    "category": event.category.rawValue,
                    "level": event.level.rawValue,
                    "severity": event.level.rawValue,
                    "timestamp": Self.iso(event.timestamp),
                    "message": event.message,
                    "metadata": event.metadata
                ] as [String: Any]
            },
            "excludedByDesign": [
                "screenshots",
                "screenContents",
                "liveSearchText",
                "selectedItemIdentity",
                "personalFilePaths",
                "networkData"
            ]
        ]
        if includeAppSupportPath, let path = appSupportPath {
            dict["appSupport"] = ["diagnosticsDirectory": path.path]
        }

        do {
            return try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        } catch {
            throw DiagnosticsExportError.encodingFailed
        }
    }

    // MARK: Helpers

    private static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
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
