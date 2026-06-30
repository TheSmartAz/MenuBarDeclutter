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
            appVersionProvider: { "0.1.1 (2)" },
            now: { createdAt }
        )

        let package = service.createExportPackage()
        #expect(package.packageVersion == 1)
        #expect(package.appVersion == "0.1.1 (2)")
        #expect(package.exportKind == .fullSettings)
        #expect(package.createdAt == createdAt)
        #expect(package.redactionMode == .privacySafe)
        #expect(!package.settings.isEmpty)
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
                "smartTriggersEnabled": "true"
            ]
        )

        let result = try importService.apply(
            package: package,
            settingsStore: store,
            importExperimentalSettings: false
        )

        #expect(store.autoRehideEnabled)
        #expect(!store.iconMovingEnabled)
        #expect(!store.launchAtLoginEnabled)
        #expect(!store.menuBarSpacingLabsEnabled)
        #expect(!store.smartTriggersEnabled)
        #expect(store.maxDynamicHotkeys == 0)
        #expect(result.skippedSettings == 4)
        #expect(result.skippedExperimentalFlags == [
            "Icon Moving",
            "Menu Bar Spacing Labs",
            "Smart Triggers"
        ])
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
                "smartTriggersEnabled": "true"
            ]
        )

        let dryRun = importService.dryRun(package: package, importExperimentalSettings: false)

        #expect(dryRun.wouldEnableIconMoving)
        #expect(dryRun.wouldEnableSpacingLabs)
        #expect(dryRun.wouldEnableSmartTriggers)
        #expect(dryRun.hasRisks)
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
        #expect(package.omittedSettings.isEmpty)
        #expect(package.settings["autoRehideEnabled"] == "true")
        #expect(package.groups.isEmpty)
        #expect(package.hotkeyBindings.isEmpty)
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
        #expect(backupService.listBackups() == [backupURL])
        #expect(try backupService.readBackup(at: backupURL) == data)
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
        #expect(loaded.name == "Work Setup")
        #expect(loaded.description == "My work configuration")
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
