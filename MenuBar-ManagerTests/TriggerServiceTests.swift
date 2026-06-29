import AppKit
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("TriggerService")
@MainActor
struct TriggerServiceTests {
    @Test func evaluateUsesFirstMatchingTriggerAndSavesOnce() throws {
        let saveCounter = SaveCounter()
        let firedAt = Date(timeIntervalSince1970: 2_000)
        let harness = makeHarness(now: { firedAt }, saveCounter: saveCounter)
        defer { harness.tearDown() }

        let firstProfile = harness.createProfile(
            name: "Focus",
            preferredVisibilityState: .collapsed,
            showSecondBar: true,
            autoRehideEnabled: false,
            hoverRevealEnabled: true
        )
        let secondProfile = harness.createProfile(
            name: "Presentation",
            preferredVisibilityState: .revealAll,
            showSecondBar: false,
            autoRehideEnabled: true,
            hoverRevealEnabled: false
        )
        let firstTrigger = TriggerModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            name: "First match",
            profileID: firstProfile.id,
            rule: .externalDisplayConnected(minimumDisplayCount: 2),
            debounceSeconds: 0
        )
        let secondTrigger = TriggerModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            name: "Second match",
            profileID: secondProfile.id,
            rule: .externalDisplayConnected(minimumDisplayCount: 2),
            debounceSeconds: 0
        )
        harness.service.triggers = [firstTrigger, secondTrigger]

        harness.service.evaluate(
            context: TriggerEvaluationContext(displayCount: 2),
            reason: "unit test"
        )

        #expect(saveCounter.count == 1)
        #expect(harness.service.triggers[0].lastFiredAt == firedAt)
        #expect(harness.service.triggers[1].lastFiredAt == nil)
        #expect(harness.liveStatus.lastTriggerFired == "First match")
        #expect(harness.liveStatus.activeProfileID == firstProfile.id.uuidString)
        #expect(harness.liveStatus.activeProfileName == firstProfile.name)
        #expect(harness.settingsStore.secondBarEnabled == true)
        #expect(harness.settingsStore.autoRehideEnabled == false)
        #expect(harness.settingsStore.hoverRevealEnabled == true)
        #expect(harness.applyProbe.visibilityStates == [.collapsed])
        #expect(harness.applyProbe.activeProfileIDsAtVisibilityApply == [firstProfile.id.uuidString])
        #expect(harness.liveStatus.triggerEvaluationLog == "Matched First match (unit test).")

        let persistedTriggers = try harness.persistedTriggers()
        #expect(persistedTriggers.map(\.id) == [firstTrigger.id, secondTrigger.id])
        #expect(persistedTriggers[0].lastFiredAt == firedAt)
        #expect(persistedTriggers[1].lastFiredAt == nil)
    }

    @Test func evaluateSkipsWhenAutomationPaused() {
        let saveCounter = SaveCounter()
        let firedAt = Date(timeIntervalSince1970: 2_100)
        let harness = makeHarness(now: { firedAt }, saveCounter: saveCounter)
        defer { harness.tearDown() }
        harness.settingsStore.automationPaused = true
        let profile = harness.createProfile(
            name: "Paused",
            preferredVisibilityState: .collapsed
        )
        harness.service.triggers = [
            TriggerModel(
                name: "Paused trigger",
                profileID: profile.id,
                rule: .externalDisplayConnected(minimumDisplayCount: 2),
                debounceSeconds: 0
            )
        ]

        harness.service.evaluate(
            context: TriggerEvaluationContext(displayCount: 2),
            reason: "paused unit test"
        )

        #expect(saveCounter.count == 0)
        #expect(harness.service.triggers[0].lastFiredAt == nil)
        #expect(harness.liveStatus.automationPaused)
        #expect(harness.liveStatus.lastTriggerFired == nil)
        #expect(harness.applyProbe.visibilityStates.isEmpty)
        #expect(harness.liveStatus.triggerEvaluationLog == "Automation paused; skipped trigger evaluation (paused unit test).")
    }

    @Test func evaluateSkipsAlreadyActiveProfileWithoutMutatingLastFiredAt() {
        let saveCounter = SaveCounter()
        let firedAt = Date(timeIntervalSince1970: 2_200)
        let harness = makeHarness(now: { firedAt }, saveCounter: saveCounter)
        defer { harness.tearDown() }
        let profile = harness.createProfile(
            name: "Already Active",
            preferredVisibilityState: .collapsed
        )
        harness.liveStatus.activeProfileID = profile.id.uuidString
        harness.service.triggers = [
            TriggerModel(
                name: "Loop guard",
                profileID: profile.id,
                rule: .externalDisplayConnected(minimumDisplayCount: 2),
                debounceSeconds: 0
            )
        ]

        harness.service.evaluate(
            context: TriggerEvaluationContext(displayCount: 2),
            reason: "loop unit test"
        )

        #expect(saveCounter.count == 0)
        #expect(harness.service.triggers[0].lastFiredAt == nil)
        #expect(harness.liveStatus.lastTriggerFired == nil)
        #expect(harness.applyProbe.visibilityStates.isEmpty)
        #expect(harness.liveStatus.triggerEvaluationLog == "Matched Loop guard but skipped (loop unit test).")
    }

    @Test func startCoalescesBurstScreenEventsIntoSingleEvaluation() async throws {
        let saveCounter = SaveCounter()
        let clock = EvaluationClock(date: Date(timeIntervalSince1970: 3_000))
        let notificationCenter = NotificationCenter()
        let harness = makeHarness(
            now: { clock.now() },
            saveCounter: saveCounter,
            notificationCenter: notificationCenter,
            workspaceNotificationCenter: NotificationCenter(),
            evaluationDebounceInterval: .milliseconds(25),
            currentContextProvider: {
                TriggerEvaluationContext(displayCount: 1)
            }
        )
        defer { harness.tearDown() }

        let profile = harness.createProfile(
            name: "Any Display",
            preferredVisibilityState: .collapsed
        )
        harness.service.triggers = [
            TriggerModel(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
                name: "Display burst",
                profileID: profile.id,
                rule: .externalDisplayConnected(minimumDisplayCount: 1),
                debounceSeconds: 0
            )
        ]

        harness.service.start()
        for _ in 0..<5 {
            notificationCenter.post(
                name: NSApplication.didChangeScreenParametersNotification,
                object: NSApp
            )
        }

        await waitUntil {
            saveCounter.count == 1
        }

        #expect(clock.callCount == 1)
        #expect(saveCounter.count == 1)
        #expect(harness.service.triggers[0].lastFiredAt == clock.date)
        #expect(harness.liveStatus.lastTriggerFired == "Display burst")
        #expect(harness.liveStatus.triggerEvaluationLog == "Matched Display burst (screen change).")
    }

    private func makeHarness(
        now: @escaping () -> Date,
        saveCounter: SaveCounter,
        notificationCenter: NotificationCenter = NotificationCenter(),
        workspaceNotificationCenter: NotificationCenter = NotificationCenter(),
        evaluationDebounceInterval: Duration = .milliseconds(250),
        currentContextProvider: (() -> TriggerEvaluationContext)? = nil
    ) -> Harness {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent("TriggerServiceTests-\(UUID().uuidString)", isDirectory: true)
        let appSupportPaths = AppSupportPaths(fileManager: fileManager, baseURL: temporaryRoot)
        let suiteName = "TriggerServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.smartTriggersEnabled = true
        settingsStore.automationPaused = false

        let diagnosticsLogger = DiagnosticsLogger()
        let liveStatus = LiveDiagnosticsStatus()
        let profileStore = ProfileStore(appSupportPaths: appSupportPaths, fileManager: fileManager)
        let applyProbe = ApplyProbe()
        let profileApplicationService = ProfileApplicationService(
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            setVisibility: { state in
                applyProbe.visibilityStates.append(state)
                applyProbe.activeProfileIDsAtVisibilityApply.append(liveStatus.activeProfileID)
            }
        )
        let service = TriggerService(
            settingsStore: settingsStore,
            profileStore: profileStore,
            profileApplicationService: profileApplicationService,
            appSupportPaths: appSupportPaths,
            diagnosticsLogger: diagnosticsLogger,
            liveStatus: liveStatus,
            fileManager: fileManager,
            now: now,
            notificationCenter: notificationCenter,
            workspaceNotificationCenter: workspaceNotificationCenter,
            evaluationDebounceInterval: evaluationDebounceInterval,
            batteryPercentProvider: { nil },
            currentContextProvider: currentContextProvider,
            didSave: { saveCounter.increment() }
        )

        return Harness(
            temporaryRoot: temporaryRoot,
            defaults: defaults,
            suiteName: suiteName,
            settingsStore: settingsStore,
            profileStore: profileStore,
            service: service,
            liveStatus: liveStatus,
            applyProbe: applyProbe,
            appSupportPaths: appSupportPaths,
            fileManager: fileManager
        )
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        condition: @escaping () -> Bool
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int64(timeoutNanoseconds))

        while !condition(),
              ContinuousClock.now < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private final class SaveCounter {
        private(set) var count = 0

        func increment() {
            count += 1
        }
    }

    private final class EvaluationClock {
        let date: Date
        private(set) var callCount = 0

        init(date: Date) {
            self.date = date
        }

        func now() -> Date {
            callCount += 1
            return date
        }
    }

    private final class ApplyProbe {
        var visibilityStates: [HidingVisibilityState] = []
        var activeProfileIDsAtVisibilityApply: [String?] = []
    }

    private struct Harness {
        let temporaryRoot: URL
        let defaults: UserDefaults
        let suiteName: String
        let settingsStore: SettingsStore
        let profileStore: ProfileStore
        let service: TriggerService
        let liveStatus: LiveDiagnosticsStatus
        let applyProbe: ApplyProbe
        let appSupportPaths: AppSupportPaths
        let fileManager: FileManager

        func createProfile(
            name: String,
            preferredVisibilityState: HidingVisibilityState,
            showSecondBar: Bool = false,
            autoRehideEnabled: Bool = true,
            hoverRevealEnabled: Bool = false
        ) -> ProfileModel {
            var profile = profileStore.createProfile(name: name)
            profile.preferredVisibilityState = preferredVisibilityState
            profile.showSecondBar = showSecondBar
            profile.autoRehideEnabled = autoRehideEnabled
            profile.hoverRevealEnabled = hoverRevealEnabled
            profileStore.update(profile)
            return profile
        }

        func persistedTriggers() throws -> [TriggerModel] {
            let url = appSupportPaths.profilesDirectory
                .appendingPathComponent(TriggerService.storageFilename)
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TriggerModel].self, from: data)
        }

        func tearDown() {
            service.stop()
            defaults.removePersistentDomain(forName: suiteName)
            try? fileManager.removeItem(at: temporaryRoot)
        }
    }
}
