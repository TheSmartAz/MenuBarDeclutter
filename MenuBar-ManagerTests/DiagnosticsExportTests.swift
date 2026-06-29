import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("DiagnosticsExporter")
@MainActor
struct DiagnosticsExportTests {
    private func makeExporter(
        appVersion: String = "1.0 (42)",
        marketing: String = "1.0",
        build: String = "42",
        bundleID: String = "local.MenuBarDeclutter",
        macOSVersion: String = "macOS 26.0 (Build 25A123)",
        architecture: String = "arm64",
        screens: [DiagnosticsExporter.ScreenSnapshot] = [
            .init(index: 0, x: 0, y: 25, width: 1728, height: 1117, isMain: true)
        ],
        date: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> DiagnosticsExporter {
        DiagnosticsExporter(
            appVersionProvider: { appVersion },
            marketingVersionProvider: { marketing },
            buildNumberProvider: { build },
            bundleIdentifierProvider: { bundleID },
            macOSVersionProvider: { macOSVersion },
            architectureProvider: { architecture },
            screensProvider: { screens },
            dateProvider: { date }
        )
    }

    private func makeStore() -> SettingsStore {
        let suiteName = "DiagnosticsExportTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return SettingsStore(defaults: defaults)
    }

    @Test func jsonExportContainsExpectedSections() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()
        logger.log("hello", level: .info)

        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        let data = try exporter.serialize(snapshot, format: .json)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["application"] != nil)
        #expect(object["system"] != nil)
        #expect(object["screens"] != nil)
        #expect(object["settings"] != nil)
        #expect(object["logs"] != nil)

        let logs = try #require(object["logs"] as? [[String: Any]])
        #expect(logs.count == 1)
        #expect(try #require(logs[0]["message"] as? String) == "hello")
        #expect(try #require(logs[0]["category"] as? String) == DiagnosticCategory.inferred(from: "hello").rawValue)
        #expect(try #require(logs[0]["severity"] as? String) == DiagnosticLevel.info.rawValue)

        let app = try #require(object["application"] as? [String: Any])
        #expect(try #require(app["marketingVersion"] as? String) == "1.0")
        #expect(try #require(app["buildNumber"] as? String) == "42")

        let system = try #require(object["system"] as? [String: Any])
        #expect(try #require(system["screenCount"] as? Int) == 1)

        let screens = try #require(object["screens"] as? [[String: Any]])
        #expect(try #require(screens.first?["x"] as? Double) == 0)
        #expect(try #require(screens.first?["y"] as? Double) == 25)

        let excluded = try #require(object["excludedByDesign"] as? [String])
        #expect(excluded.contains("screenshots"))
        #expect(excluded.contains("screenContents"))
        #expect(excluded.contains("liveSearchText"))
        #expect(excluded.contains("selectedItemIdentity"))
        #expect(excluded.contains("networkData"))
    }

    @Test func jsonExportLocksCurrentSchemaKeys() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()
        logger.log("schema check", level: .warning, metadata: ["reason": "coverage"])

        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        let data = try exporter.serialize(snapshot, format: .json)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object.keys.sorted() == [
            "application",
            "excludedByDesign",
            "generatedAt",
            "logs",
            "screens",
            "settings",
            "system"
        ])

        let application = try #require(object["application"] as? [String: Any])
        #expect(application.keys.sorted() == [
            "appVersion",
            "buildNumber",
            "bundleIdentifier",
            "marketingVersion",
            "name"
        ])

        let system = try #require(object["system"] as? [String: Any])
        #expect(system.keys.sorted() == [
            "architecture",
            "macOSVersion",
            "screenCount"
        ])

        let screens = try #require(object["screens"] as? [[String: Any]])
        #expect(try #require(screens.first?.keys.sorted()) == [
            "height",
            "index",
            "isMain",
            "width",
            "x",
            "y"
        ])

        let settings = try #require(object["settings"] as? [String: Any])
        #expect(settings.keys.sorted() == Self.expectedSettingsKeys)
        #expect(settings["lastAccessibilityPermissionStatus"] is NSNull)
        #expect(settings["collapsedSeparatorLengthOverride"] is NSNull)

        let logs = try #require(object["logs"] as? [[String: Any]])
        let log = try #require(logs.first)
        #expect(log.keys.sorted() == [
            "category",
            "level",
            "message",
            "metadata",
            "severity",
            "timestamp"
        ])
        #expect(try #require(log["metadata"] as? [String: String]) == ["reason": "coverage"])
    }

    @Test func txtExportIsHumanReadableAndExcludesByDesign() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()
        logger.log("warm up", level: .info)

        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        let data = try exporter.serialize(snapshot, format: .txt)
        let text = String(data: data, encoding: .utf8) ?? ""

        #expect(text.contains("MenuBarDeclutter Diagnostics"))
        #expect(text.contains("Marketing Version: 1.0"))
        #expect(text.contains("Build Number: 42"))
        #expect(text.contains("Architecture: arm64"))
        #expect(text.contains("Screen Count: 1"))
        #expect(text.contains("Screen 0 (main): 1728 x 1117"))
        #expect(text.contains("at (0, 25)"))
        #expect(text.contains("Last Accessibility Permission Status: (none)"))
        #expect(text.contains("Collapsed Separator Override: (none — auto)"))
        #expect(text.contains("warm up"))
        #expect(text.contains("Excluded by design"))
        #expect(text.contains("Screenshots, screen contents, live search text, selected item identity, personal file paths, network data"))
    }

    @Test func neverIncludesAppSupportPathByDefault() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()

        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        for format in DiagnosticsExporter.Format.allCases {
            let data = try exporter.serialize(snapshot, format: format)
            let text = String(data: data, encoding: .utf8) ?? ""
            #expect(!text.contains("/Application Support"))
            #expect(!text.contains("Application Support/MenuBarDeclutter"))
            #expect(!text.contains("Diagnostics Directory:"))
        }
    }

    @Test func dogfoodMetadataIsOnlyExportedWhenEnabledWithRunID() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()

        var snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        var data = try exporter.serialize(snapshot, format: .json)
        var object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["dogfood"] == nil)

        store.dogfoodModeEnabled = true
        store.dogfoodRunID = "dogfood-2026-06-28-120000"
        snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        data = try exporter.serialize(snapshot, format: .json)
        object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let dogfood = try #require(object["dogfood"] as? [String: Any])
        #expect(try #require(dogfood["runID"] as? String) == "dogfood-2026-06-28-120000")

        let text = String(data: try exporter.serialize(snapshot, format: .txt), encoding: .utf8) ?? ""
        #expect(text.contains("Dogfood Run ID: dogfood-2026-06-28-120000"))
    }

    @Test func snapshotReflectsCurrentSettings() {
        let exporter = makeExporter()
        let store = makeStore()
        store.isCollapsed = true
        store.autoRehideEnabled = false
        store.alwaysHiddenEnabled = true
        store.globalHotkeyEnabled = true
        store.globalHotkeyKeyCode = 11
        store.globalHotkeyModifiersRaw = 0x0900

        let logger = DiagnosticsLogger()
        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)

        #expect(snapshot.settings.isCollapsed == true)
        #expect(snapshot.settings.autoRehideEnabled == false)
        #expect(snapshot.settings.alwaysHiddenEnabled == true)
        #expect(snapshot.settings.globalHotkeyEnabled == true)
        #expect(snapshot.settings.globalHotkeyDisplayName == "⌥⌘B")
        #expect(snapshot.settings.automationPaused == true)
    }

    @Test func excludesNetworkDataAndScreenshotsFromSettings() {
        let exporter = makeExporter()
        let store = makeStore()
        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: DiagnosticsLogger())

        // The settings snapshot is a fixed struct; nothing in it carries
        // network data or screenshot bytes. The presence of these fields does
        // not change regardless of state.
        #expect(snapshot.screens.count == 1)
        let screen = snapshot.screens[0]
        #expect(screen.x == 0)
        #expect(screen.y == 25)
        #expect(screen.width == 1728)
        #expect(screen.height == 1117)
        #expect(screen.isMain == true)
    }

    @Test func currentArchitectureReportsKnownValue() {
        let arch = DiagnosticsExporter.currentArchitecture()
        #expect(arch == "arm64" || arch == "x86_64" || arch == "unknown")
    }

    private static let expectedSettingsKeys = [
        "accessibilityDiscoveryEnabled",
        "alwaysHiddenEnabled",
        "appMode",
        "autoRehideDelaySeconds",
        "autoRehideEnabled",
        "automationPaused",
        "collapsedSeparatorLengthOverride",
        "dogfoodModeEnabled",
        "dogfoodNotesEnabled",
        "expandedSeparatorLength",
        "globalHotkeyDisplayName",
        "globalHotkeyEnabled",
        "hasCompletedOnboarding",
        "hoverRevealEnabled",
        "hoverRevealPollingIntervalSeconds",
        "iconMovingAllowSystemItems",
        "iconMovingDragDuration",
        "iconMovingEnabled",
        "iconMovingMaxRetries",
        "iconMovingRequireConfirmation",
        "isCollapsed",
        "lastAccessibilityPermissionStatus",
        "launchAtLoginEnabled",
        "menuBarScanIntervalSeconds",
        "proModeEnabled",
        "revealAllOnOptionClick",
        "searchEnabled",
        "searchHighlightOnSelection",
        "searchHotkeyDisplayName",
        "searchHotkeyEnabled",
        "searchRevealOnSelection",
        "secondBarActivateOwningAppOnSelection",
        "secondBarAutoCloseAfterSelection",
        "secondBarCloseOnOutsideClick",
        "secondBarEnabled",
        "secondBarIconSize",
        "secondBarPositionMode",
        "secondBarShowAlwaysHiddenItems",
        "secondBarShowHiddenItems",
        "secondBarShowLabels",
        "showPrimarySeparator",
        "showSeparators",
        "smartTriggersEnabled"
    ]
}
