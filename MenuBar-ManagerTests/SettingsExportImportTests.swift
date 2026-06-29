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
        let service = SettingsExportService(settingsStore: store, diagnosticsLogger: logger)

        let package = service.createExportPackage()
        #expect(package.packageVersion == 1)
        #expect(!package.appVersion.isEmpty)
        #expect(!package.settings.isEmpty)

        let data = try service.encode(package)
        #expect(!data.isEmpty)
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
