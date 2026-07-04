import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SettingsExportImport")
@MainActor
struct SettingsExportImportTests {
    @Test func exportPackageSchema() throws {
        let suiteName = "export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let createdAt = Date(timeIntervalSince1970: 42)
        let service = SettingsExportService(
            settingsStore: store,
            diagnosticsLogger: logger,
            appVersionProvider: { "0.1.3 (4)" },
            now: { createdAt }
        )

        let package = service.createExportPackage()
        #expect(package.packageVersion == 1)
        #expect(package.schemaVersion == 1)
        #expect(package.appName == "MenuBarDeclutter")
        #expect(package.appVersion == "0.1.3 (4)")
        #expect(package.exportKind == .fullSettings)
        #expect(package.createdAt == createdAt)
        #expect(package.redactionMode == .privacySafe)
        #expect(Set(package.includedSections) == Set(SettingsExportSection.defaultIncludedSections))
        #expect(!package.settings.isEmpty)
        #expect(package.settings[SettingsStore.Key.launchAtLoginEnabled.rawValue] == nil)
        #expect(package.omittedSettings.contains(SettingsStore.Key.launchAtLoginEnabled.rawValue))
        #expect(package.omittedSettings.contains(SettingsStore.Key.showPrimarySeparator.rawValue))
        #expect(package.omittedSettings.contains(SettingsStore.Key.privateAccessLastAuthStatus.rawValue))

        let data = try service.encode(package)
        #expect(!data.isEmpty)
    }

    @Test func realExportDoesNotWritePlaceholderValues() throws {
        let suiteName = "real-export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.autoRehideEnabled = true
        store.autoRehideDelaySeconds = 42
        store.searchHotkeyKeyCode = 3
        store.searchHotkeyModifiersRaw = 0x0900
        store.lastAccessibilityPermissionStatus = AccessibilityPermissionStatus.granted.rawValue
        store.launchAtLoginEnabled = true
        store.privateAccessLastAuthStatus = "unlocked"
        store.dogfoodRunID = "private-run-id"

        let logger = DiagnosticsLogger()
        let service = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)

        let package = service.createExportPackage()

        #expect(package.settings.values.allSatisfy { $0 != "exported" })
        #expect(package.settings[SettingsStore.Key.autoRehideEnabled.rawValue] == "true")
        #expect(package.settings[SettingsStore.Key.autoRehideDelaySeconds.rawValue] == "42.0")
        #expect(package.settings[SettingsStore.Key.searchHotkeyKeyCode.rawValue] == "3")
        #expect(package.settings[SettingsStore.Key.searchHotkeyModifiersRaw.rawValue] == "2304")
        #expect(package.settings[SettingsStore.Key.launchAtLoginEnabled.rawValue] == nil)
        #expect(package.settings[SettingsStore.Key.showPrimarySeparator.rawValue] == nil)
        #expect(package.settings[SettingsStore.Key.lastAccessibilityPermissionStatus.rawValue] == nil)
        #expect(package.settings[SettingsStore.Key.privateAccessLastAuthStatus.rawValue] == nil)
        #expect(package.settings[SettingsStore.Key.dogfoodRunID.rawValue] == nil)
    }

    @Test func exportPackageRedactsProtectedGroups() throws {
        let suiteName = "protected-group-export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let service = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)
        let protectedGroup = IconGroup(
            name: "Secret Finance",
            notes: "private notes",
            isProtected: true,
            itemRefs: [
                IconGroupItemRef(
                    bundleIdentifier: "com.example.finance",
                    appName: "Secret Finance"
                )
            ]
        )

        let package = service.createExportPackage(groups: [protectedGroup])
        let data = try service.encode(package)
        let json = String(decoding: data, as: UTF8.self)

        #expect(package.groups.first?.name == "Protected Group")
        #expect(package.groups.first?.itemRefs.isEmpty == true)
        #expect(!json.contains("Secret Finance"))
        #expect(!json.contains("private notes"))
        #expect(!json.contains("com.example.finance"))
    }

    @Test func importDryRun() throws {
        let suiteName = "import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let exportService = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)
        let importService = SettingsImportService(diagnosticsLogger: logger)

        let package = exportService.createExportPackage(
            groups: [IconGroup(name: "Test")],
            hotkeyBindings: [HotkeyBinding(action: .pauseAutomation, keyCode: 1, modifiersRaw: 0)]
        )

        let dryRun = importService.dryRun(package: package, existingHotkeyBindings: [])

        #expect(dryRun.addedGroups == 1)
        #expect(dryRun.addedHotkeys == 1)
    }

    @Test func exportPackageIncludesProfilePayloads() throws {
        let suiteName = "profile-export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let exportService = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let profile = ProfileModel.makeDefault(
            name: "Presentation",
            now: Date(timeIntervalSince1970: 100)
        )

        let package = exportService.createExportPackage(profiles: [profile])
        let decoded = try importService.decode(data: exportService.encode(package))

        #expect(package.profiles == [profile])
        #expect(decoded.profiles == [profile])
    }

    @Test func legacyMetadataOnlyProfilesDecodeAsEmptyPayload() throws {
        let json = """
        {
          "packageVersion": 1,
          "appVersion": "0.1.0",
          "createdAt": "2026-06-29T00:00:00Z",
          "settings": {},
          "profiles": [
            {
              "id": "00000000-0000-0000-0000-000000000301",
              "name": "Legacy Summary",
              "isReadOnly": false,
              "createdAt": "2026-06-29T00:00:00Z",
              "updatedAt": "2026-06-29T00:00:00Z"
            }
          ]
        }
        """
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())

        let package = try importService.decode(data: Data(json.utf8))

        #expect(package.profiles.isEmpty)
    }

    @Test func malformedCurrentProfilePayloadThrows() throws {
        let json = """
        {
          "packageVersion": 1,
          "appVersion": "0.1.0",
          "createdAt": "2026-06-29T00:00:00Z",
          "settings": {},
          "profiles": [
            {
              "schemaVersion": 2,
              "id": "00000000-0000-0000-0000-000000000302",
              "name": "Broken Current Profile",
              "createdAt": "2026-06-29T00:00:00Z",
              "updatedAt": "2026-06-29T00:00:00Z",
              "preferredVisibilityState": "expanded",
              "autoRehideEnabled": true,
              "hoverRevealEnabled": false,
              "targetZonesByBundleID": {},
              "notes": ""
            }
          ]
        }
        """
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())

        do {
            _ = try importService.decode(data: Data(json.utf8))
            Issue.record("Expected malformed current profile payload to fail decoding.")
        } catch {
            #expect(error is DecodingError)
        }
    }

    @Test func exportAndImportPreservesWorkspaceSnapshot() throws {
        let suiteName = "workspace-export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let paths = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: paths.applicationSupportDirectory.deletingLastPathComponent()) }

        let settingsStore = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let exportService = SettingsExportService(settingsStore: settingsStore, diagnosticsLogger: logger)
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let now = Date(timeIntervalSince1970: 200)
        var snapshot = WorkspaceStoreSnapshot.defaults(now: now)
        snapshot.workspaces[0].name = "Imported Workspace"
        snapshot.workspaces[0].functionItems.append(.command(.showFunctionBar, now: now))

        let package = exportService.createExportPackage(workspaceSnapshot: snapshot)
        let decoded = try importService.decode(data: exportService.encode(package))
        let dryRun = importService.dryRun(package: decoded)

        let workspaceStore = WorkspaceStore(
            fileURL: paths.workspaceStoreFileURL,
            backupsDirectory: paths.workspaceBackupsDirectory
        )
        let initialSnapshot = try workspaceStore.load()
        let switchingService = WorkspaceSwitchingService(
            store: workspaceStore,
            initialSnapshot: initialSnapshot
        )
        let result = try importService.apply(
            package: decoded,
            settingsStore: settingsStore,
            workspaceImportHandler: { imported in
                try switchingService.importSnapshot(imported)
            },
            selectedSections: [.workspaces]
        )

        #expect(decoded.workspaceSnapshot == snapshot)
        #expect(dryRun.addedWorkspaces == snapshot.workspaces.count)
        #expect(result.importedWorkspaces == snapshot.workspaces.count)
        #expect(switchingService.currentSnapshot().workspaces[0].name == "Imported Workspace")
        #expect(switchingService.currentSnapshot().workspaces[0].functionItems.contains {
            $0.kind == .command(.showFunctionBar)
        })
    }

    @Test func privacySafeWorkspaceExportRedactsProxyIdentityMetadata() throws {
        let suiteName = "workspace-redaction-export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = SettingsStore(defaults: defaults)
        let exportService = SettingsExportService(
            settingsStore: settingsStore,
            diagnosticsLogger: DiagnosticsLogger()
        )
        let workspace = MenuBarWorkspace(
            name: "Secret Workspace",
            functionItems: [
                WorkspaceItem(
                    kind: .menuBarItem(MenuBarItemReference(
                        stableHash: "stable-hash",
                        lastKnownDisplayName: "Secret Menu Extra",
                        lastKnownBundleIdentifier: "com.example.secret"
                    )),
                    displayNameOverride: "Secret Override"
                )
            ],
            isProtected: true
        )
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])

        let package = exportService.createExportPackage(workspaceSnapshot: snapshot)
        let data = try exportService.encode(package)
        let json = String(decoding: data, as: UTF8.self)
        let exportedWorkspace = try #require(package.workspaceSnapshot?.workspaces.first)
        let exportedItem = try #require(exportedWorkspace.functionItems.first)

        #expect(exportedWorkspace.name == "Protected Workspace")
        if case .menuBarItem(let reference) = exportedItem.kind {
            #expect(reference.stableHash == "stable-hash")
            #expect(reference.lastKnownDisplayName == nil)
            #expect(reference.lastKnownBundleIdentifier == nil)
            #expect(exportedItem.displayNameOverride == nil)
        } else {
            Issue.record("Expected exported menu bar item reference.")
        }
        #expect(!json.contains("Secret Workspace"))
        #expect(!json.contains("Secret Menu Extra"))
        #expect(!json.contains("Secret Override"))
        #expect(!json.contains("com.example.secret"))
    }

    @Test func privacySafeWorkspaceExportRedactsAllItemDisplayOverrides() throws {
        let suiteName = "workspace-command-redaction-export-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let exportService = SettingsExportService(
            settingsStore: SettingsStore(defaults: defaults),
            diagnosticsLogger: DiagnosticsLogger()
        )
        let workspace = MenuBarWorkspace(
            name: "Personal",
            functionItems: [
                WorkspaceItem(
                    kind: .command(.openSettings),
                    displayNameOverride: "Private Client Settings"
                )
            ]
        )
        let snapshot = WorkspaceStoreSnapshot(activeWorkspaceID: workspace.id, workspaces: [workspace])

        let package = exportService.createExportPackage(workspaceSnapshot: snapshot)
        let data = try exportService.encode(package)
        let json = String(decoding: data, as: UTF8.self)
        let exportedItem = try #require(package.workspaceSnapshot?.workspaces.first?.functionItems.first)

        #expect(exportedItem.displayNameOverride == nil)
        #expect(!json.contains("Private Client Settings"))
    }

    @Test func workspaceImportDryRunValidatesAndApplyUsesRepairedSnapshot() throws {
        let suiteName = "workspace-import-validation-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let workspaces = (0..<(WorkspaceValidationConstants.maxWorkspaces + 2)).map { index in
            MenuBarWorkspace(name: "Workspace \(index)")
        }
        let omittedActiveID = try #require(workspaces.last?.id)
        let snapshot = WorkspaceStoreSnapshot(
            schemaVersion: 999,
            activeWorkspaceID: omittedActiveID,
            workspaces: workspaces
        )
        let package = SettingsExportPackage(
            appVersion: "1.0",
            includedSections: [.workspaces],
            settings: [:],
            workspaceSnapshot: snapshot
        )
        let service = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())

        let dryRun = service.dryRun(package: package, selectedSections: [.workspaces])
        var importedSnapshot: WorkspaceStoreSnapshot?
        let result = try service.apply(
            package: package,
            settingsStore: SettingsStore(defaults: defaults),
            workspaceImportHandler: { importedSnapshot = $0 },
            selectedSections: [.workspaces]
        )
        let imported = try #require(importedSnapshot)

        #expect(dryRun.addedWorkspaces == WorkspaceValidationConstants.maxWorkspaces)
        #expect(dryRun.conflicts.contains { $0.kind == .workspaceValidation })
        #expect(result.importedWorkspaces == WorkspaceValidationConstants.maxWorkspaces)
        #expect(imported.schemaVersion == WorkspaceStoreSnapshot.currentSchemaVersion)
        #expect(imported.workspaces.count == WorkspaceValidationConstants.maxWorkspaces)
        #expect(imported.activeWorkspaceID == imported.workspaces.first?.id)
        #expect(!imported.workspaces.contains { $0.id == omittedActiveID })
    }

    @Test func safeImportAppliesSettingsButSkipsExperimentalEnablers() throws {
        let suiteName = "safe-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [
                "autoRehideEnabled": "true",
                "iconMovingEnabled": "true",
                "launchAtLoginEnabled": "true",
                "maxDynamicHotkeys": "-3",
                "menuBarSpacingLabsEnabled": "true",
                "renderedIconCaptureEnabled": "true",
                "renderedIconRevealSweepEnabled": "true",
                "smartTriggersEnabled": "true"
            ]
        )

        let dryRun = importService.dryRun(package: package, importExperimentalSettings: false)
        let result = try importService.apply(
            package: package,
            settingsStore: store,
            importExperimentalSettings: false
        )

        #expect(dryRun.hasRisks)
        #expect(dryRun.conflicts.contains { $0.description == "Accurate Icons would be enabled." })
        #expect(dryRun.conflicts.contains { $0.description == "Accurate Icons Reveal Sweep would be enabled." })
        #expect(store.autoRehideEnabled)
        #expect(!store.iconMovingEnabled)
        #expect(!store.launchAtLoginEnabled)
        #expect(!store.menuBarSpacingLabsEnabled)
        #expect(!store.renderedIconCaptureEnabled)
        #expect(!store.renderedIconRevealSweepEnabled)
        #expect(!store.smartTriggersEnabled)
        #expect(store.maxDynamicHotkeys == 0)
        #expect(result.skippedSettings == 6)
        #expect(result.skippedExperimentalFlags == [
            "Icon Moving",
            "Menu Bar Spacing Labs",
            "Accurate Icons",
            "Accurate Icons Reveal Sweep",
            "Smart Triggers"
        ])
    }

    @Test func importTurnsOffRevealSweepWhenRenderedCaptureIsDisabled() throws {
        let suiteName = "accurate-icons-disable-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.renderedIconCaptureEnabled = true
        store.renderedIconRevealSweepEnabled = true
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [
                "renderedIconCaptureEnabled": "false",
                "renderedIconRevealSweepEnabled": "true"
            ]
        )

        let result = try importService.apply(
            package: package,
            settingsStore: store,
            importExperimentalSettings: false
        )

        #expect(!store.renderedIconCaptureEnabled)
        #expect(!store.renderedIconRevealSweepEnabled)
        #expect(result.skippedExperimentalFlags == [
            "Accurate Icons Reveal Sweep"
        ])
    }

    @Test func explicitRestoreCanImportAccurateIconSettings() throws {
        let suiteName = "accurate-icons-restore-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [
                "renderedIconCaptureEnabled": "true",
                "renderedIconRevealSweepEnabled": "true"
            ]
        )

        let result = try importService.apply(
            package: package,
            settingsStore: store,
            importExperimentalSettings: true
        )

        #expect(store.renderedIconCaptureEnabled)
        #expect(store.renderedIconRevealSweepEnabled)
        #expect(result.skippedExperimentalFlags.isEmpty)
    }

    @Test func safeImportSkipsPreviewRuntimeEnablers() throws {
        let suiteName = "safe-preview-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [
                "workspacesPreviewEnabled": "true",
                "functionBarPreviewEnabled": "true",
                "functionBarPrimaryClickEnabled": "true",
                "setBuilderPreviewEnabled": "true",
                "infoStripPreviewEnabled": "true",
                "infoStripAutoShowEnabled": "true",
                "functionBarPlacementPreference": FunctionBarPlacementPreference.nearMouse.rawValue
            ]
        )

        let dryRun = importService.dryRun(package: package, importExperimentalSettings: false)
        let result = try importService.apply(
            package: package,
            settingsStore: store,
            importExperimentalSettings: false
        )

        #expect(dryRun.hasRisks)
        #expect(!store.workspacesPreviewEnabled)
        #expect(!store.functionBarPreviewEnabled)
        #expect(!store.functionBarPrimaryClickEnabled)
        #expect(!store.setBuilderPreviewEnabled)
        #expect(!store.infoStripPreviewEnabled)
        #expect(!store.infoStripAutoShowEnabled)
        #expect(store.functionBarPlacementPreference == FunctionBarPlacementPreference.nearMouse.rawValue)
        #expect(result.skippedExperimentalFlags == [
            "Function Bar Preview",
            "Function Bar Primary Click",
            "Info Strip Auto-show",
            "Info Strip Preview",
            "Set Builder Preview",
            "Workspaces Preview"
        ])
    }

    @Test func importRepairsInvalidFunctionBarPresentationOptions() throws {
        let suiteName = "function-bar-import-repair-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.functionBarPlacementPreference = FunctionBarPlacementPreference.nearMouse.rawValue
        store.functionBarDensity = FunctionBarDensity.compact.rawValue
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [
                "functionBarPlacementPreference": "outside-display",
                "functionBarDensity": "ultra"
            ]
        )

        let result = try importService.apply(package: package, settingsStore: store)

        #expect(store.functionBarPlacementPreference == FunctionBarPlacementPreference.belowMenuBarIcon.rawValue)
        #expect(store.functionBarDensity == FunctionBarDensity.regular.rawValue)
        #expect(result.appliedSettings == 2)
        #expect(result.skippedSettings == 0)
    }

    @Test func applyImportMergesObjectsByIdentity() throws {
        let suiteName = "object-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let paths = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: paths.applicationSupportDirectory.deletingLastPathComponent()) }

        let settingsStore = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let profileStore = ProfileStore(appSupportPaths: paths)
        let groupStore = IconGroupStore(
            directory: paths.applicationSupportDirectory,
            backupsDirectory: paths.backupsDirectory
        )
        let hotkeyStore = HotkeyBindingStore(
            directory: paths.applicationSupportDirectory,
            backupsDirectory: paths.backupsDirectory
        )
        let spacerStore = SpacerItemStore(
            directory: paths.applicationSupportDirectory,
            backupsDirectory: paths.backupsDirectory
        )
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let profile = ProfileModel.makeDefault(
            name: "Work",
            now: Date(timeIntervalSince1970: 200)
        )
        let group = IconGroup(name: "Work Apps")
        let hotkey = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let spacer = SpacerItemModel(type: .thinSpacer, sortOrder: 2)
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [:],
            profiles: [profile],
            groups: [group],
            hotkeyBindings: [hotkey],
            spacerItems: [spacer]
        )

        let result = try importService.apply(
            package: package,
            settingsStore: settingsStore,
            profileStore: profileStore,
            groupStore: groupStore,
            hotkeyBindingStore: hotkeyStore,
            spacerItemStore: spacerStore
        )

        #expect(result.importedProfiles == 1)
        #expect(result.importedGroups == 1)
        #expect(result.importedHotkeys == 1)
        #expect(result.importedSpacers == 1)
        #expect(profileStore.profiles.map(\.id) == [profile.id])
        #expect(groupStore.groups.map(\.id) == [group.id])
        #expect(hotkeyStore.bindings.map(\.id) == [hotkey.id])
        #expect(spacerStore.items.map(\.id) == [spacer.id])
    }

    @Test func applyImportSkipsConflictingHotkeys() throws {
        let suiteName = "hotkey-import-conflict-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let paths = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: paths.applicationSupportDirectory.deletingLastPathComponent()) }

        let settingsStore = SettingsStore(defaults: defaults)
        let hotkeyStore = HotkeyBindingStore(
            directory: paths.applicationSupportDirectory,
            backupsDirectory: paths.backupsDirectory
        )
        let existing = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        hotkeyStore.add(binding: existing)

        let imported = HotkeyBinding(action: .resumeAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [:],
            hotkeyBindings: [imported]
        )
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())

        let result = try importService.apply(
            package: package,
            settingsStore: settingsStore,
            hotkeyBindingStore: hotkeyStore
        )

        #expect(result.importedHotkeys == 0)
        #expect(result.skippedHotkeys == 1)
        #expect(hotkeyStore.bindings.map(\.id) == [existing.id])
    }

    @Test func hotkeyConflictDetection() {
        let logger = DiagnosticsLogger()
        let importService = SettingsImportService(diagnosticsLogger: logger)

        let existingBinding = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [:],
            hotkeyBindings: [HotkeyBinding(action: .resumeAutomation, keyCode: 11, modifiersRaw: 0x0100)]
        )

        let dryRun = importService.dryRun(package: package, existingHotkeyBindings: [existingBinding])

        #expect(dryRun.hasConflicts)
        #expect(dryRun.conflicts.contains { $0.kind == .hotkeyConflict })
    }

    @Test func experimentalFlagSafety() {
        let logger = DiagnosticsLogger()
        let importService = SettingsImportService(diagnosticsLogger: logger)

        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: [
                "iconMovingEnabled": "true",
                "menuBarSpacingLabsEnabled": "true",
                "renderedIconCaptureEnabled": "true",
                "renderedIconRevealSweepEnabled": "true",
                "smartTriggersEnabled": "true"
            ]
        )

        let dryRun = importService.dryRun(package: package, importExperimentalSettings: false)

        #expect(dryRun.wouldEnableIconMoving)
        #expect(dryRun.wouldEnableSpacingLabs)
        #expect(dryRun.wouldEnableSmartTriggers)
        #expect(dryRun.hasRisks)
        #expect(dryRun.conflicts.contains { $0.description == "Accurate Icons would be enabled." })
        #expect(dryRun.conflicts.contains { $0.description == "Accurate Icons Reveal Sweep would be enabled." })
    }

    @Test func legacyPreviewPackageDecodesWithMetadataDefaults() throws {
        let json = """
        {
          "packageVersion": 1,
          "appVersion": "0.1.0",
          "createdAt": "2026-06-29T00:00:00Z",
          "settings": {
            "autoRehideEnabled": "true"
          }
        }
        """
        let logger = DiagnosticsLogger()
        let importService = SettingsImportService(diagnosticsLogger: logger)

        let package = try importService.decode(data: Data(json.utf8))

        #expect(package.exportKind == .fullSettings)
        #expect(package.redactionMode == .privacySafe)
        #expect(package.schemaVersion == 1)
        #expect(package.appName == "MenuBarDeclutter")
        #expect(Set(package.includedSections) == Set(SettingsExportSection.defaultIncludedSections))
        #expect(package.omittedSettings.isEmpty)
        #expect(package.settings["autoRehideEnabled"] == "true")
        #expect(package.groups.isEmpty)
        #expect(package.hotkeyBindings.isEmpty)
    }

    @Test func selectedSectionImportOnlyAppliesRequestedSections() throws {
        let suiteName = "selected-section-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let paths = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: paths.applicationSupportDirectory.deletingLastPathComponent()) }

        let settingsStore = SettingsStore(defaults: defaults)
        let groupStore = IconGroupStore(
            directory: paths.applicationSupportDirectory,
            backupsDirectory: paths.backupsDirectory
        )
        let importService = SettingsImportService(diagnosticsLogger: DiagnosticsLogger())
        let group = IconGroup(name: "Selective")
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: ["autoRehideEnabled": "true"],
            groups: [group]
        )

        let dryRun = importService.dryRun(package: package, selectedSections: [.groups])
        let result = try importService.apply(
            package: package,
            settingsStore: settingsStore,
            groupStore: groupStore,
            selectedSections: [.groups]
        )

        #expect(dryRun.modifiedSettings == 0)
        #expect(dryRun.addedGroups == 1)
        #expect(!settingsStore.autoRehideEnabled)
        #expect(groupStore.groups.map(\.id) == [group.id])
        #expect(result.appliedSettings == 0)
        #expect(result.importedGroups == 1)
    }

    @Test func importBackupCreationWritesReadableJSON() throws {
        let backupsDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ImportBackupTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: backupsDirectory) }

        let logger = DiagnosticsLogger()
        let backupService = ImportBackupService(
            backupsDirectory: backupsDirectory,
            diagnosticsLogger: logger,
            now: { Date(timeIntervalSince1970: 0) }
        )
        let data = Data(#"{"settings":{}}"#.utf8)

        let backupURL = try backupService.createBackup(data: data)

        #expect(FileManager.default.fileExists(atPath: backupURL.path))
        #expect(backupURL.lastPathComponent == "settings-pre-import-1970-01-01_000000.json")
        let listedBackup = try #require(backupService.listBackups().first)
        #expect(listedBackup.lastPathComponent == backupURL.lastPathComponent)
        #expect(backupService.listBackups().count == 1)
        #expect(try backupService.readBackup(at: backupURL) == data)
        #expect(try backupService.readBackup(at: listedBackup) == data)
    }

    @Test func importBackupServiceReturnsLatestBackupFirst() throws {
        let backupsDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ImportBackupLatestTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: backupsDirectory) }

        var now = Date(timeIntervalSince1970: 0)
        let backupService = ImportBackupService(
            backupsDirectory: backupsDirectory,
            now: { now }
        )

        let older = try backupService.createBackup(data: Data(#"{"older":true}"#.utf8))
        now = Date(timeIntervalSince1970: 3_600)
        let newer = try backupService.createBackup(data: Data(#"{"newer":true}"#.utf8))

        #expect(backupService.listBackups().map(\.lastPathComponent) == [newer.lastPathComponent, older.lastPathComponent])
        #expect(backupService.latestBackup()?.lastPathComponent == newer.lastPathComponent)
    }

    @Test func safeApplyCreatesBackupBeforeMutation() throws {
        let suiteName = "safe-apply-backup-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let backupsDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("SafeApplyBackupTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: backupsDirectory) }

        let store = SettingsStore(defaults: defaults)
        store.autoRehideEnabled = false
        let logger = DiagnosticsLogger()
        let exportService = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let backupService = ImportBackupService(
            backupsDirectory: backupsDirectory,
            now: { Date(timeIntervalSince1970: 0) }
        )
        let currentPackage = exportService.createExportPackage()
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: ["autoRehideEnabled": "true"]
        )

        _ = try importService.applyWithBackup(
            package: package,
            currentPackage: currentPackage,
            backupService: backupService,
            settingsStore: store
        )

        let backupURL = try #require(backupService.latestBackup())
        let backupPackage = try importService.decode(data: backupService.readBackup(at: backupURL))
        #expect(store.autoRehideEnabled)
        #expect(backupURL.lastPathComponent == "settings-pre-import-1970-01-01_000000.json")
        #expect(backupPackage.settings[SettingsStore.Key.autoRehideEnabled.rawValue] == "false")
    }

    @Test func applyWithBackupRollsBackAfterFailure() throws {
        let suiteName = "rollback-import-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let paths = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: paths.applicationSupportDirectory.deletingLastPathComponent()) }

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.autoRehideEnabled = false
        let logger = DiagnosticsLogger()
        let groupStore = IconGroupStore(
            directory: paths.applicationSupportDirectory,
            backupsDirectory: paths.backupsDirectory
        )
        let exportService = SettingsExportService(settingsStore: settingsStore, diagnosticsLogger: logger)
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let backupService = ImportBackupService(
            backupsDirectory: paths.backupsDirectory,
            now: { Date(timeIntervalSince1970: 0) }
        )
        let currentPackage = exportService.createExportPackage(groups: groupStore.groups)
        let package = SettingsExportPackage(
            appVersion: "1.0",
            settings: ["autoRehideEnabled": "true"],
            groups: [IconGroup(name: "Should Roll Back")]
        )

        do {
            _ = try importService.applyWithBackup(
                package: package,
                currentPackage: currentPackage,
                backupService: backupService,
                settingsStore: settingsStore,
                groupStore: groupStore,
                failureInjection: .afterSettings
            )
            Issue.record("Expected simulated apply failure.")
        } catch let error as SettingsImportApplyError {
            #expect(error == .simulatedFailureAfterSettings)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(!settingsStore.autoRehideEnabled)
        #expect(groupStore.groups.isEmpty)
        #expect(backupService.listBackups().count == 1)
    }

    @Test func backupPackageRestoreCanReapplyPreviousExperimentalState() throws {
        let suiteName = "backup-restore-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.iconMovingEnabled = true
        store.menuBarSpacingLabsEnabled = true
        store.smartTriggersEnabled = true
        let logger = DiagnosticsLogger()
        let exportService = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)
        let importService = SettingsImportService(diagnosticsLogger: logger)
        let backupPackage = exportService.createExportPackage()

        store.iconMovingEnabled = false
        store.menuBarSpacingLabsEnabled = false
        store.smartTriggersEnabled = false

        let result = try importService.apply(
            package: backupPackage,
            settingsStore: store,
            importExperimentalSettings: true
        )

        #expect(store.iconMovingEnabled)
        #expect(store.menuBarSpacingLabsEnabled)
        #expect(store.smartTriggersEnabled)
        #expect(result.skippedExperimentalFlags.isEmpty)
    }
}

private func makeTempPaths() -> AppSupportPaths {
    let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("SettingsExportImportTests-\(UUID().uuidString)", isDirectory: true)
    return AppSupportPaths(baseURL: baseURL)
}

@Suite("ProfilePack")
@MainActor
struct ProfilePackTests {
    private func makeTempDir() -> URL {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("PackTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }

    @Test func saveAndLoad() throws {
        let dir = makeTempDir()
        let store = ProfilePackStore(directory: dir)

        let pack = ProfilePack(name: "Work Setup", description: "My work configuration")
        let savedURL = try store.save(pack)

        let loaded = try store.load(from: savedURL)
        #expect(loaded.packVersion == 1)
        #expect(loaded.name == "Work Setup")
        #expect(loaded.description == "My work configuration")
    }

    @Test func legacySparsePackDecodesWithEmptyObjectCollections() throws {
        let dir = makeTempDir()
        let store = ProfilePackStore(directory: dir)
        let createdAt = "2026-07-03T12:00:00Z"
        let url = dir.appendingPathComponent("legacy.json")
        try Data("""
        {
          "name": "Legacy Pack",
          "description": "Old export",
          "createdAt": "\(createdAt)"
        }
        """.utf8).write(to: url)

        let loaded = try store.load(from: url)

        #expect(loaded.packVersion == 1)
        #expect(loaded.name == "Legacy Pack")
        #expect(loaded.profiles.isEmpty)
        #expect(loaded.groups.isEmpty)
        #expect(loaded.hotkeyBindings.isEmpty)
        #expect(loaded.spacerItems.isEmpty)
    }

    @Test func listPacks() throws {
        let dir = makeTempDir()
        let store = ProfilePackStore(directory: dir)

        _ = try store.save(ProfilePack(name: "Pack 1"))
        _ = try store.save(ProfilePack(name: "Pack 2"))

        let packs = store.listPacks()
        #expect(packs.count == 2)
    }
}
