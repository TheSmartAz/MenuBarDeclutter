import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("MenuBarSpacingService")
@MainActor
struct MenuBarSpacingServiceTests {
    @Test func backupCreation() {
        let suiteName = "spacing-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let runner = MockMenuBarSpacingCommandRunner()

        // Simulate existing values
        _ = runner.writeItemSpacing(10)
        _ = runner.writeSelectionPadding(8)

        let service = MenuBarSpacingService(
            settingsStore: store,
            diagnosticsLogger: logger,
            commandRunner: runner,
            enableUndocumentedSpacingDefaults: false
        )

        let backup = service.backupCurrentValues()
        #expect(backup != nil)
        #expect(backup?.itemSpacing == 10)
        #expect(backup?.selectionPadding == 8)
        #expect(store.menuBarSpacingHasBackup)
    }

    @Test func restorePrevious() {
        let suiteName = "spacing-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.menuBarSpacingLabsEnabled = true
        store.menuBarSpacingHasBackup = true

        let logger = DiagnosticsLogger()
        let runner = MockMenuBarSpacingCommandRunner()

        let service = MenuBarSpacingService(
            settingsStore: store,
            diagnosticsLogger: logger,
            commandRunner: runner,
            enableUndocumentedSpacingDefaults: true
        )

        let result = service.restorePrevious()
        #expect(result.success)
        #expect(store.menuBarSpacingPreset == MenuBarSpacingPreset.system.rawValue)
        #expect(!store.menuBarSpacingHasBackup)
    }

    @Test func resetToSystemDefault() {
        let suiteName = "spacing-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.menuBarSpacingLabsEnabled = true

        let logger = DiagnosticsLogger()
        let runner = MockMenuBarSpacingCommandRunner()
        _ = runner.writeItemSpacing(4)

        let service = MenuBarSpacingService(
            settingsStore: store,
            diagnosticsLogger: logger,
            commandRunner: runner,
            enableUndocumentedSpacingDefaults: true
        )

        let result = service.resetToSystemDefault()
        #expect(result.success)
        #expect(runner.deleteCallCount > 0)
        #expect(store.menuBarSpacingPreset == MenuBarSpacingPreset.system.rawValue)
    }

    @Test func customValueClamping() {
        #expect(MenuBarSpacingService.clampItemSpacing(1) == MenuBarSpacingService.minCustomItemSpacing)
        #expect(MenuBarSpacingService.clampItemSpacing(100) == MenuBarSpacingService.maxCustomItemSpacing)
        #expect(MenuBarSpacingService.clampItemSpacing(12) == 12)

        #expect(MenuBarSpacingService.clampSelectionPadding(1) == MenuBarSpacingService.minCustomSelectionPadding)
        #expect(MenuBarSpacingService.clampSelectionPadding(100) == MenuBarSpacingService.maxCustomSelectionPadding)
        #expect(MenuBarSpacingService.clampSelectionPadding(8) == 8)
    }

    @Test func dryRunModeDoesNotWrite() {
        let suiteName = "spacing-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.menuBarSpacingLabsEnabled = true

        let logger = DiagnosticsLogger()
        let runner = MockMenuBarSpacingCommandRunner()

        let service = MenuBarSpacingService(
            settingsStore: store,
            diagnosticsLogger: logger,
            commandRunner: runner,
            enableUndocumentedSpacingDefaults: false
        )

        let result = service.apply(preset: .compact)
        #expect(result.success)
        #expect(result.isDryRun)
        #expect(runner.writeCallCount == 0)
        #expect(store.menuBarSpacingLastApplyStatus == "dry-run")
    }

    @Test func disabledLabsRejectsApply() {
        let suiteName = "spacing-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.menuBarSpacingLabsEnabled = false

        let logger = DiagnosticsLogger()
        let runner = MockMenuBarSpacingCommandRunner()

        let service = MenuBarSpacingService(
            settingsStore: store,
            diagnosticsLogger: logger,
            commandRunner: runner,
            enableUndocumentedSpacingDefaults: true
        )

        let result = service.apply(preset: .compact)
        #expect(!result.success)
    }
}
