import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("TriggerService persistence")
@MainActor
struct TriggerServicePersistenceTests {
    @Test func addUpdateDeleteRoundTripsThroughAppSupportPaths() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let profile = harness.profileStore.createProfile(name: "Work")
        let trigger = TriggerModel(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Docked",
            profileID: profile.id,
            rule: .externalDisplayConnected(minimumDisplayCount: 2),
            debounceSeconds: 30
        )

        harness.triggerService.addTrigger(trigger)

        var updated = trigger
        updated.name = "Docked Workspace"
        updated.isEnabled = false
        updated.rule = .frontmostApp(bundleIdentifier: "com.example.editor")
        harness.triggerService.update(updated)

        let reloaded = harness.makeTriggerService()
        reloaded.load()

        #expect(reloaded.triggers == [updated])
        #expect(FileManager.default.fileExists(atPath: harness.triggerStorageURL.path))

        reloaded.delete(updated)

        let afterDelete = harness.makeTriggerService()
        afterDelete.load()

        #expect(afterDelete.triggers.isEmpty)
    }

    @Test func triggerStorageCoexistsWithProfileStoreFiles() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let profile = harness.profileStore.createProfile(name: "Travel")
        let trigger = TriggerModel(
            name: "Browser",
            profileID: profile.id,
            rule: .frontmostApp(bundleIdentifier: "com.example.browser")
        )
        harness.triggerService.addTrigger(trigger)
        let triggerDataBeforeProfileReload = try Data(contentsOf: harness.triggerStorageURL)

        let reloadedProfiles = ProfileStore(appSupportPaths: harness.paths)
        reloadedProfiles.load()

        #expect(reloadedProfiles.profiles.map(\.name) == ["Travel"])
        #expect(reloadedProfiles.lastError == nil)
        #expect(try Data(contentsOf: harness.triggerStorageURL) == triggerDataBeforeProfileReload)
    }

    @Test func loadMissingTriggerFileKeepsEmptyInMemoryState() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        harness.triggerService.load()

        #expect(harness.triggerService.triggers.isEmpty)
        #expect(harness.triggerService.lastError == nil)
        #expect(!FileManager.default.fileExists(atPath: harness.triggerStorageURL.path))
        #expect(FileManager.default.fileExists(atPath: harness.paths.profilesDirectory.path))
    }

    @Test func loadCorruptTriggerFileReportsErrorWithoutOverwritingFile() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        try harness.paths.ensureDirectoriesExist()
        let corruptData = Data("{".utf8)
        try corruptData.write(to: harness.triggerStorageURL)

        harness.triggerService.load()

        #expect(harness.triggerService.triggers.isEmpty)
        #expect(harness.triggerService.lastError != nil)
        #expect(try Data(contentsOf: harness.triggerStorageURL) == corruptData)
    }

    @Test func startIsIdempotentAndStopClearsObserversAndTimer() throws {
        let harness = try makeHarness()
        defer {
            harness.triggerService.stop()
            harness.cleanup()
        }
        harness.settingsStore.smartTriggersEnabled = true

        harness.triggerService.start()

        #expect(harness.triggerService.observerCountForTesting == 3)
        #expect(harness.triggerService.hasTimerForTesting)

        harness.triggerService.start()

        #expect(harness.triggerService.observerCountForTesting == 3)
        #expect(harness.triggerService.hasTimerForTesting)

        harness.triggerService.stop()

        #expect(harness.triggerService.observerCountForTesting == 0)
        #expect(!harness.triggerService.hasTimerForTesting)
    }

    private func makeHarness() throws -> Harness {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TriggerServicePersistenceTests-\(UUID().uuidString)", isDirectory: true)
        let suiteName = "TriggerServicePersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let paths = AppSupportPaths(baseURL: baseURL)
        let settingsStore = SettingsStore(defaults: defaults)
        let profileStore = ProfileStore(appSupportPaths: paths, now: { Date(timeIntervalSince1970: 100) })
        let diagnosticsLogger = DiagnosticsLogger()
        let liveStatus = LiveDiagnosticsStatus()
        let visibilityBox = VisibilityBox()
        let profileApplicationService = ProfileApplicationService(
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            setVisibility: { visibilityBox.value = $0 }
        )
        let triggerService = TriggerService(
            settingsStore: settingsStore,
            profileStore: profileStore,
            profileApplicationService: profileApplicationService,
            appSupportPaths: paths,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            now: { Date(timeIntervalSince1970: 200) }
        )

        return Harness(
            baseURL: baseURL,
            paths: paths,
            settingsStore: settingsStore,
            profileStore: profileStore,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            visibilityBox: visibilityBox,
            triggerService: triggerService,
            defaults: defaults,
            suiteName: suiteName
        )
    }

    private final class VisibilityBox {
        var value: HidingVisibilityState?
    }

    private struct Harness {
        let baseURL: URL
        let paths: AppSupportPaths
        let settingsStore: SettingsStore
        let profileStore: ProfileStore
        let diagnosticsLogger: DiagnosticsLogger
        let liveStatus: LiveDiagnosticsStatus
        let visibilityBox: VisibilityBox
        let triggerService: TriggerService
        let defaults: UserDefaults
        let suiteName: String

        var triggerStorageURL: URL {
            paths.profilesDirectory.appendingPathComponent(TriggerService.storageFilename)
        }

        func makeTriggerService() -> TriggerService {
            let profileApplicationService = ProfileApplicationService(
                settingsStore: settingsStore,
                diagnosticsLogger: diagnosticsLogger,
                liveStatus: liveStatus,
                setVisibility: { visibilityBox.value = $0 }
            )
            return TriggerService(
                settingsStore: settingsStore,
                profileStore: profileStore,
                profileApplicationService: profileApplicationService,
                appSupportPaths: paths,
                diagnosticsLogger: diagnosticsLogger,
                liveStatus: liveStatus,
                now: { Date(timeIntervalSince1970: 200) }
            )
        }

        func cleanup() {
            triggerService.stop()
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: baseURL)
        }
    }
}
