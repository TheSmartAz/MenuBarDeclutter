import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SettingsMigrationService")
@MainActor
struct SettingsMigrationServiceTests {
    @Test func preV01AlphaSettingsMigrateToSafeDefaultsAndBackUpSnapshot() throws {
        let suiteName = "SettingsMigrationServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsMigrationServiceTests.\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let store = SettingsStore(defaults: defaults)
        store.settingsMigrationVersion = ""
        store.launchAtLoginEnabled = true
        store.isCollapsed = true
        store.startCollapsed = true
        store.expandedSeparatorLength = .infinity
        store.collapsedSeparatorLengthOverride = 12
        store.autoRehideEnabled = true
        store.hoverRevealEnabled = true
        store.globalHotkeyEnabled = true
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        store.lastAccessibilityPermissionStatus = AccessibilityPermissionStatus.granted.rawValue
        store.searchEnabled = true
        store.searchHotkeyEnabled = true
        store.secondBarEnabled = true
        store.iconMovingEnabled = true
        store.iconMovingConfirmationSuppressed = true
        store.iconMovingAllowSystemItems = true
        store.smartTriggersEnabled = true
        store.automationPaused = false

        let logger = DiagnosticsLogger()
        let result = SettingsMigrationService(
            settingsStore: store,
            appSupportPaths: AppSupportPaths(baseURL: baseURL),
            diagnosticsLogger: logger,
            dateProvider: { Date(timeIntervalSince1970: 1_782_691_200) }
        ).migrateIfNeeded()

        #expect(result.didMigrate)
        #expect(store.settingsMigrationVersion == "0.1.0")
        #expect(store.v01SafeDefaultsNoticePending)
        #expect(store.launchAtLoginEnabled == false)
        #expect(store.isCollapsed == false)
        #expect(store.startCollapsed == false)
        #expect(store.expandedSeparatorLength == AppConstants.defaultExpandedSeparatorLength)
        #expect(store.collapsedSeparatorLengthOverride == nil)
        #expect(store.autoRehideEnabled == false)
        #expect(store.hoverRevealEnabled == false)
        #expect(store.globalHotkeyEnabled == false)
        #expect(store.proModeEnabled == false)
        #expect(store.accessibilityDiscoveryEnabled == false)
        #expect(store.lastAccessibilityPermissionStatus == nil)
        #expect(store.searchEnabled == false)
        #expect(store.searchHotkeyEnabled == false)
        #expect(store.secondBarEnabled == false)
        #expect(store.iconMovingEnabled == false)
        #expect(store.iconMovingConfirmationSuppressed == false)
        #expect(store.iconMovingAllowSystemItems == false)
        #expect(store.smartTriggersEnabled == false)
        #expect(store.automationPaused == true)

        let backupURL = try #require(result.backupURL)
        #expect(FileManager.default.fileExists(atPath: backupURL.path))
        let backupText = try String(contentsOf: backupURL, encoding: .utf8)
        #expect(backupText.contains("\"iconMovingEnabled\" : \"true\""))
        #expect(backupText.contains("\"migrationTargetVersion\" : \"0.1.0\""))
    }

    @Test func currentMigrationVersionDoesNotRewriteSettings() throws {
        let suiteName = "SettingsMigrationServiceTests.current.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsMigrationServiceTests.current.\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let store = SettingsStore(defaults: defaults)
        store.settingsMigrationVersion = "0.1.0"
        store.iconMovingEnabled = true

        let result = SettingsMigrationService(
            settingsStore: store,
            appSupportPaths: AppSupportPaths(baseURL: baseURL),
            diagnosticsLogger: DiagnosticsLogger()
        ).migrateIfNeeded()

        #expect(result.didMigrate == false)
        #expect(store.iconMovingEnabled == true)
        #expect(store.v01SafeDefaultsNoticePending == false)
    }

    @Test func freshInstallIsStampedWithoutShowingUpdateNotice() throws {
        let suiteName = "SettingsMigrationServiceTests.fresh.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsMigrationServiceTests.fresh.\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let store = SettingsStore(defaults: defaults)

        let result = SettingsMigrationService(
            settingsStore: store,
            appSupportPaths: AppSupportPaths(baseURL: baseURL),
            diagnosticsLogger: DiagnosticsLogger()
        ).migrateIfNeeded()

        #expect(result.didMigrate == false)
        #expect(store.settingsMigrationVersion == "0.1.0")
        #expect(store.v01SafeDefaultsNoticePending == false)
    }
}
