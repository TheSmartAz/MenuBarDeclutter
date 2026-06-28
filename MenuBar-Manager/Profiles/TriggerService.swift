import AppKit
import Foundation
import IOKit.ps
import Observation

@MainActor
@Observable
final class TriggerService {
    static let storageFilename = "triggers.json"

    private let settingsStore: SettingsStore
    private let profileStore: ProfileStore
    private let profileApplicationService: ProfileApplicationService
    private let appSupportPaths: AppSupportPaths
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let evaluator: TriggerRuleEvaluator
    private let fileManager: FileManager
    private let now: () -> Date

    private var observers: [NSObjectProtocol] = []
    private var timer: Timer?

    var triggers: [TriggerModel] = []
    private(set) var lastError: String?

    init(
        settingsStore: SettingsStore,
        profileStore: ProfileStore,
        profileApplicationService: ProfileApplicationService,
        appSupportPaths: AppSupportPaths,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        evaluator: TriggerRuleEvaluator = TriggerRuleEvaluator(),
        fileManager: FileManager = .default,
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.profileStore = profileStore
        self.profileApplicationService = profileApplicationService
        self.appSupportPaths = appSupportPaths
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.evaluator = evaluator
        self.fileManager = fileManager
        self.now = now
    }

    func load() {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let url = storageURL
            guard fileManager.fileExists(atPath: url.path) else {
                triggers = []
                return
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            triggers = try decoder.decode([TriggerModel].self, from: data)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func save() {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(triggers)
            try data.write(to: storageURL, options: .atomic)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func start() {
        guard settingsStore.smartTriggersEnabled else {
            stop()
            return
        }
        guard !settingsStore.automationPaused else {
            stop()
            liveStatus.automationPaused = true
            diagnosticsLogger.log("Automation paused; smart triggers not started.", level: .info, category: .trigger)
            return
        }
        guard observers.isEmpty else { return }

        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateCurrentContext(reason: "screen change")
            }
        })

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateCurrentContext(reason: "app launch")
            }
        })

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateCurrentContext(reason: "frontmost app")
            }
        })

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateCurrentContext(reason: "timer")
            }
        }

        liveStatus.automationPaused = false
        diagnosticsLogger.log("Smart triggers started.", level: .debug, category: .trigger)
        evaluateCurrentContext(reason: "start")
    }

    func stop() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
        timer?.invalidate()
        timer = nil
        diagnosticsLogger.log("Smart triggers stopped.", level: .debug, category: .trigger)
    }

    @discardableResult
    func addTrigger(_ trigger: TriggerModel) -> TriggerModel {
        triggers.append(trigger)
        save()
        return trigger
    }

    func delete(_ trigger: TriggerModel) {
        triggers.removeAll { $0.id == trigger.id }
        save()
    }

    func update(_ trigger: TriggerModel) {
        if let index = triggers.firstIndex(where: { $0.id == trigger.id }) {
            triggers[index] = trigger
        } else {
            triggers.append(trigger)
        }
        save()
    }

    func evaluate(context: TriggerEvaluationContext, reason: String) {
        guard settingsStore.smartTriggersEnabled else { return }
        guard !settingsStore.automationPaused else {
            liveStatus.automationPaused = true
            liveStatus.triggerEvaluationLog = "Automation paused; skipped trigger evaluation (\(reason))."
            diagnosticsLogger.log("Automation paused; skipped trigger evaluation.", level: .debug, category: .trigger)
            return
        }

        let currentDate = now()
        var logs: [String] = []
        for trigger in triggers where evaluator.shouldFire(trigger: trigger, context: context, now: currentDate) {
            logs.append("Matched \(trigger.name) (\(reason))")
            fire(trigger, now: currentDate)
        }

        if logs.isEmpty {
            logs.append("No triggers matched (\(reason)).")
        }
        liveStatus.triggerEvaluationLog = logs.joined(separator: "\n")
    }

    func evaluateCurrentContext(reason: String) {
        evaluate(context: currentContext(), reason: reason)
    }

    private func fire(_ trigger: TriggerModel, now: Date) {
        guard let profile = profileStore.profiles.first(where: { $0.id == trigger.profileID }) else {
            diagnosticsLogger.log("Trigger \(trigger.name) skipped; profile missing.", level: .warning)
            return
        }

        if liveStatus.activeProfileID == profile.id.uuidString {
            diagnosticsLogger.log("Trigger \(trigger.name) skipped to avoid a profile loop.", level: .debug)
            return
        }

        profileApplicationService.applyBasicSettings(
            profile: profile,
            snapshots: liveStatus.scannedMenuBarItems,
            accessibilityStatus: liveStatus.accessibilityPermissionStatus,
            allowProMoves: false
        )

        if let index = triggers.firstIndex(where: { $0.id == trigger.id }) {
            triggers[index].lastFiredAt = now
        }
        save()

        liveStatus.lastTriggerFired = trigger.name
        diagnosticsLogger.log("Smart trigger fired: \(trigger.name) -> \(profile.name).")
    }

    private func currentContext() -> TriggerEvaluationContext {
        let runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let components = Calendar.current.dateComponents([.hour, .minute], from: now())

        return TriggerEvaluationContext(
            displayCount: NSScreen.screens.count,
            runningBundleIdentifiers: runningBundleIDs,
            frontmostBundleIdentifier: frontmost,
            batteryPercent: Self.currentBatteryPercent(),
            dateComponents: components,
            focusModeActive: nil,
            wifiSSID: nil
        )
    }

    private static func currentBatteryPercent() -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
                maxCapacity > 0 else {
                continue
            }

            return Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())
        }

        return nil
    }

    private var storageURL: URL {
        appSupportPaths.profilesDirectory.appendingPathComponent(Self.storageFilename)
    }
}
