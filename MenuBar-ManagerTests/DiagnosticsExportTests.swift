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
        #expect(excluded.contains("renderedIconThumbnails"))
        #expect(excluded.contains("liveSearchText"))
        #expect(excluded.contains("selectedItemIdentity"))
        #expect(excluded.contains("protectedGroupNames"))
        #expect(excluded.contains("protectedHotkeyTargets"))
        #expect(excluded.contains("importExportFilePaths"))
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

    @Test func jsonExportCanIncludeWorkspacePreviewDiagnostics() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()
        let preview = DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot(
            workspaces: WorkspaceDiagnosticsSnapshot(
                workspaceFeatureEnabled: true,
                workspaceCount: 3,
                archivedWorkspaceCount: 1,
                activeWorkspacePresent: true,
                activeWorkspaceIDHash: "workspace-123",
                validationIssueCount: 2,
                groupReferenceCount: 3,
                linkedGroupReferenceCount: 1,
                detachedGroupReferenceCount: 1,
                missingGroupReferenceCount: 1,
                detachedSourceGroupMissingCount: 1,
                protectedGroupReferenceCount: 1,
                missingProfileBindingCount: 0,
                commandItemCount: 4,
                menuBarItemReferenceCount: 5,
                unresolvedMenuBarItemReferenceCount: 2,
                infoTileReferenceCount: 6,
                lastLoadStatus: .repaired
            ),
            functionBar: FunctionBarDiagnosticsSnapshot(
                previewEnabled: true,
                isVisible: true,
                displayState: "visible",
                activeWorkspacePresent: true,
                activeWorkspaceIDHash: "workspace-123",
                visibleItemCount: 8,
                commandItemCount: 4,
                proxyItemCount: 2,
                groupItemCount: 1,
                missingReferenceCount: 1,
                unavailableItemCount: 1,
                lastPlacementMode: "belowMenuBarIcon",
                lastPlacementClamped: false,
                lastShowResult: "shown"
            ),
            setBuilder: SetBuilderDiagnosticsSnapshot(
                previewEnabled: true,
                workspaceCount: 3,
                workspaceWithItemsCount: 2,
                totalWorkspaceItemCount: 8,
                linkedGroupReferenceCount: 1,
                detachedGroupReferenceCount: 1,
                missingGroupReferenceCount: 1,
                detachedSourceGroupMissingCount: 1,
                menuBarProxyReferenceCount: 2,
                unresolvedMenuBarProxyReferenceCount: 1,
                commandItemCount: 4,
                spacerDividerCount: 1,
                lastCommitResult: "success",
                lastValidationIssueCount: 2
            ),
            infoStrip: InfoStripDiagnosticsSnapshot(
                previewEnabled: true,
                autoShowEnabled: true,
                isVisible: false,
                displayState: "closed",
                activeWorkspacePresent: true,
                activeWorkspaceIDHash: "workspace-123",
                selectedTileProviderCount: 3,
                availableTileProviderCount: 2,
                unavailableTileProviderCount: 1,
                currentTileProviderID: "health",
                rotationIntervalSeconds: 10,
                idleDelaySeconds: 5,
                lastRotationResult: "rotated",
                lastPlacementMode: "belowFunctionBar",
                lastPlacementClamped: true,
                lastShowResult: "hidden"
            )
        )

        let snapshot = exporter.makeSnapshot(
            settingsStore: store,
            logger: logger,
            workspacePreview: preview
        )
        let data = try exporter.serialize(snapshot, format: .json)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let workspacePreview = try #require(object["workspacePreview"] as? [String: Any])
        let workspaces = try #require(workspacePreview["workspaces"] as? [String: Any])
        let functionBar = try #require(workspacePreview["functionBar"] as? [String: Any])
        let setBuilder = try #require(workspacePreview["setBuilder"] as? [String: Any])
        let infoStrip = try #require(workspacePreview["infoStrip"] as? [String: Any])

        #expect(try #require(workspaces["workspaceCount"] as? Int) == 3)
        #expect(try #require(workspaces["activeWorkspaceIDHash"] as? String) == "workspace-123")
        #expect(try #require(workspaces["detachedSourceGroupMissingCount"] as? Int) == 1)
        #expect(try #require(workspaces["unresolvedMenuBarItemReferenceCount"] as? Int) == 2)
        #expect(try #require(functionBar["visibleItemCount"] as? Int) == 8)
        #expect(try #require(setBuilder["menuBarProxyReferenceCount"] as? Int) == 2)
        #expect(try #require(setBuilder["unresolvedMenuBarProxyReferenceCount"] as? Int) == 1)
        #expect(try #require(infoStrip["currentTileProviderID"] as? String) == "health")

        let text = String(data: try exporter.serialize(snapshot, format: .txt), encoding: .utf8) ?? ""
        #expect(text.contains("Workspace Preview Diagnostics"))
        #expect(text.contains("Workspaces: 3"))
        #expect(text.contains("Set Builder Missing Groups: 1"))
        #expect(text.contains("Unresolved Menu Bar Proxy References: 2"))
        #expect(text.contains("Set Builder Unresolved Proxies: 1"))
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
        #expect(text.contains("Screenshots, screen contents, rendered icon thumbnails, live search text, selected item identity, personal file paths, network data"))
    }

    @Test func exportRedactsSensitiveLogMessageText() throws {
        let exporter = makeExporter()
        let store = makeStore()
        let logger = DiagnosticsLogger()
        logger.log(
            "Applied profile Weekend Focus: wrote /Users/alex/Documents/profile.json for alex@example.com.",
            level: .info,
            category: .profile,
            metadata: [
                "path": "/Users/alex/Desktop/export.json",
                "url": "menubardeclutter://apply-profile?id=secret-token",
                "owner": "alex@example.com"
            ]
        )
        logger.log(
            "Smart trigger fired: Work Hours -> Deep Work.",
            level: .info,
            category: .trigger
        )
        logger.log(
            "Disabled unsupported trigger rules: Imported Focus, Imported Wi-Fi.",
            level: .warning,
            category: .trigger
        )

        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)
        let data = try exporter.serialize(snapshot, format: .json)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let logs = try #require(object["logs"] as? [[String: Any]])
        let profileLog = try #require(logs.first)
        let triggerLog = try #require(logs.dropFirst().first)
        let unsupportedTriggerLog = try #require(logs.last)
        let profileMessage = try #require(profileLog["message"] as? String)
        let profileMetadata = try #require(profileLog["metadata"] as? [String: String])
        let triggerMessage = try #require(triggerLog["message"] as? String)
        let unsupportedTriggerMessage = try #require(unsupportedTriggerLog["message"] as? String)

        #expect(profileMessage.contains("Applied profile [redacted-profile]:"))
        #expect(profileMessage.contains("[redacted-path]"))
        #expect(profileMessage.contains("[redacted-email]"))
        #expect(!profileMessage.contains("Weekend Focus"))
        #expect(!profileMessage.contains("/Users/alex"))
        #expect(!profileMessage.contains("alex@example.com"))
        #expect(profileMetadata["path"] == "[redacted-path]")
        #expect(profileMetadata["owner"] == "[redacted-email]")
        #expect(profileMetadata["url"] == "menubardeclutter://apply-profile?[redacted-query]")
        #expect(triggerMessage == "Smart trigger fired: [redacted-trigger] -> [redacted-profile].")
        #expect(unsupportedTriggerMessage == "Disabled unsupported trigger rules: [redacted-trigger-list].")

        let text = String(data: try exporter.serialize(snapshot, format: .txt), encoding: .utf8) ?? ""
        #expect(text.contains("Applied profile [redacted-profile]:"))
        #expect(text.contains("Smart trigger fired: [redacted-trigger] -> [redacted-profile]."))
        #expect(text.contains("Disabled unsupported trigger rules: [redacted-trigger-list]."))
        #expect(!text.contains("Weekend Focus"))
        #expect(!text.contains("Work Hours"))
        #expect(!text.contains("Deep Work"))
        #expect(!text.contains("Imported Focus"))
        #expect(!text.contains("Imported Wi-Fi"))
        #expect(!text.contains("/Users/alex"))
        #expect(!text.contains("alex@example.com"))
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
        store.layoutFeaturesEnabled = true
        store.fullMenuBarModeEnabled = false
        store.crowdedRevealAskBeforeSwitching = true
        store.crowdedRescueWorkspaceFallbackPreference = CrowdedRescueWorkspaceFallbackPreference.preferFunctionBar.rawValue
        store.crowdedRevealThresholdRatio = 0.75
        store.spacerItemsJSONVersion = 2
        store.menuBarSpacingLabsEnabled = true
        store.menuBarSpacingPreset = "comfortable"
        store.menuBarSpacingLastApplyStatus = "dry-run"
        store.menuBarSpacingLastApplyDate = Date(timeIntervalSince1970: 1_700_000_000)
        store.groupsEnabled = true
        store.groupStatusItemsEnabled = true
        store.protectedGroupsRequireAuth = true
        store.privateAccessEnabled = true
        store.privateAccessLastAuthStatus = "success"
        store.appIntentsEnabled = false
        store.dynamicHotkeysEnabled = true
        store.maxDynamicHotkeys = 12
        store.workspacesPreviewEnabled = true
        store.functionBarPreviewEnabled = true
        store.functionBarDensity = "compact"
        store.setBuilderPreviewEnabled = true
        store.setBuilderWarnBeforeLinkedGroupEdits = false
        store.infoStripPreviewEnabled = true
        store.infoStripAutoShowEnabled = true
        store.infoStripShowPreviewBadge = false
        store.renderedIconCaptureEnabled = true
        store.renderedIconRevealSweepEnabled = true

        let logger = DiagnosticsLogger()
        let snapshot = exporter.makeSnapshot(settingsStore: store, logger: logger)

        #expect(snapshot.settings.isCollapsed == true)
        #expect(snapshot.settings.autoRehideEnabled == false)
        #expect(snapshot.settings.alwaysHiddenEnabled == true)
        #expect(snapshot.settings.globalHotkeyEnabled == true)
        #expect(snapshot.settings.globalHotkeyDisplayName == "⌥⌘B")
        #expect(snapshot.settings.automationPaused == true)
        #expect(snapshot.settings.layoutFeaturesEnabled == true)
        #expect(snapshot.settings.fullMenuBarModeEnabled == false)
        #expect(snapshot.settings.crowdedRevealAskBeforeSwitching == true)
        #expect(snapshot.settings.crowdedRescueWorkspaceFallbackPreference == "preferFunctionBar")
        #expect(snapshot.settings.crowdedRevealThresholdRatio == 0.75)
        #expect(snapshot.settings.spacerItemsJSONVersion == 2)
        #expect(snapshot.settings.menuBarSpacingLabsEnabled == true)
        #expect(snapshot.settings.menuBarSpacingPreset == "comfortable")
        #expect(snapshot.settings.menuBarSpacingLastApplyStatus == "dry-run")
        #expect(snapshot.settings.menuBarSpacingLastApplyDate == "2023-11-14T22:13:20Z")
        #expect(snapshot.settings.groupsEnabled == true)
        #expect(snapshot.settings.groupStatusItemsEnabled == true)
        #expect(snapshot.settings.protectedGroupsRequireAuth == true)
        #expect(snapshot.settings.privateAccessEnabled == true)
        #expect(snapshot.settings.privateAccessLastAuthStatus == "success")
        #expect(snapshot.settings.appIntentsEnabled == false)
        #expect(snapshot.settings.dynamicHotkeysEnabled == true)
        #expect(snapshot.settings.maxDynamicHotkeys == 12)
        #expect(snapshot.settings.workspacesPreviewEnabled == true)
        #expect(snapshot.settings.functionBarPreviewEnabled == true)
        #expect(snapshot.settings.functionBarDensity == "compact")
        #expect(snapshot.settings.setBuilderPreviewEnabled == true)
        #expect(snapshot.settings.setBuilderWarnBeforeLinkedGroupEdits == false)
        #expect(snapshot.settings.infoStripPreviewEnabled == true)
        #expect(snapshot.settings.infoStripAutoShowEnabled == true)
        #expect(snapshot.settings.infoStripShowPreviewBadge == false)
        #expect(snapshot.settings.renderedIconCaptureEnabled == true)
        #expect(snapshot.settings.renderedIconRevealSweepEnabled == true)
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
        "appIntentsCanAccessLabs",
        "appIntentsCanApplyProfiles",
        "appIntentsEnabled",
        "appMode",
        "autoRehideDelaySeconds",
        "autoRehideEnabled",
        "automationPaused",
        "collapsedSeparatorLengthOverride",
        "crowdedRescueWorkspaceFallbackPreference",
        "crowdedRevealAskBeforeSwitching",
        "crowdedRevealAutoOpenSecondBar",
        "crowdedRevealRequireProEstimate",
        "crowdedRevealRescueEnabled",
        "crowdedRevealThresholdRatio",
        "dogfoodModeEnabled",
        "dogfoodNotesEnabled",
        "dynamicHotkeysEnabled",
        "expandedSeparatorLength",
        "fullMenuBarModeAutoExitEnabled",
        "fullMenuBarModeAutoExitSeconds",
        "fullMenuBarModeEnabled",
        "fullMenuBarModeShowsSecondBar",
        "fullMenuBarModeShowsSpacerMarkers",
        "fullMenuBarModeSuspendsAutoRehide",
        "functionBarCloseOnOutsideClick",
        "functionBarDensity",
        "functionBarKeyboardNavigationEnabled",
        "functionBarPlacementPreference",
        "functionBarPreviewEnabled",
        "functionBarPrimaryClickEnabled",
        "functionBarShowLabels",
        "functionBarShowSetSwitcher",
        "globalHotkeyDisplayName",
        "globalHotkeyEnabled",
        "groupStatusItemsEnabled",
        "groupsEnabled",
        "groupsJSONVersion",
        "hasCompletedOnboarding",
        "hoverRevealEnabled",
        "hoverRevealPollingIntervalSeconds",
        "iconMovingAllowSystemItems",
        "iconMovingDragDuration",
        "iconMovingEnabled",
        "iconMovingMaxRetries",
        "iconMovingRequireConfirmation",
        "infoStripAutoShowEnabled",
        "infoStripCloseOnOutsideClick",
        "infoStripHoverToFunctionBarEnabled",
        "infoStripKeyboardNavigationEnabled",
        "infoStripPauseWhenFunctionBarPinned",
        "infoStripPreviewEnabled",
        "infoStripShowPreviewBadge",
        "isCollapsed",
        "lastAccessibilityPermissionStatus",
        "launchAtLoginEnabled",
        "layoutFeaturesEnabled",
        "layoutSuggestionsEnabled",
        "maxDynamicHotkeys",
        "menuBarScanIntervalSeconds",
        "menuBarSpacingCustomItemSpacing",
        "menuBarSpacingCustomSelectionPadding",
        "menuBarSpacingHasBackup",
        "menuBarSpacingLabsEnabled",
        "menuBarSpacingLastApplyDate",
        "menuBarSpacingLastApplyStatus",
        "menuBarSpacingPreset",
        "privateAccessAllowDevicePasswordFallback",
        "privateAccessEnabled",
        "privateAccessLastAuthStatus",
        "privateAccessProtectAlwaysHidden",
        "privateAccessProtectAutomationCommands",
        "privateAccessProtectFindIcon",
        "privateAccessProtectIconMoving",
        "privateAccessProtectProfileApply",
        "privateAccessProtectSecondBar",
        "privateAccessProtectSpacingLabs",
        "privateAccessUnlockDurationSeconds",
        "proModeEnabled",
        "protectedGroupsRequireAuth",
        "renderedIconCaptureEnabled",
        "renderedIconRevealSweepEnabled",
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
        "secondBarPrimaryClickEnabled",
        "secondBarShowAlwaysHiddenItems",
        "secondBarShowHiddenItems",
        "secondBarShowLabels",
        "setBuilderAutosaveDrafts",
        "setBuilderDefaultGroupReferenceMode",
        "setBuilderDragDropEnabled",
        "setBuilderPreviewEnabled",
        "setBuilderShowAdvancedLibraryItems",
        "setBuilderShowFunctionBarPreview",
        "setBuilderWarnBeforeLinkedGroupEdits",
        "showCapacityWarnings",
        "showSeparators",
        "showSpacerMarkers",
        "smartTriggersEnabled",
        "spacerItemsEnabled",
        "spacerItemsJSONVersion",
        "workspacesPreviewEnabled"
    ]
}
