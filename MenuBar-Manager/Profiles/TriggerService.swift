import AppKit
import Foundation
import IOKit.ps
import Observation

@MainActor
@Observable
final class TriggerService {
    static let storageFilename = "triggers.json"

    /// Coalescing window for event-driven trigger evaluations. `didActivateApplication`
    /// can fire repeatedly during alt-tabbing; without debounce, every frontmost-app
    /// switch synchronously rebuilt `TriggerEvaluationContext` (enumerating
    /// `NSWorkspace.runningApplications`, calling `IOPSCopy...`, etc.) and scanned
    /// every trigger. The 250ms window coalesces a burst of events into a single
    /// evaluation while preserving the perception of responsive automation.
    static let evaluationDebounceInterval: Duration = .milliseconds(250)

    /// Timer cadence for periodic re-evaluation. The timer also refreshes the cached
    /// battery percentage (the `IOPSCopy...` IPC is too expensive to invoke on every
    /// `didActivateApplication` event), so trigger rules that depend on battery state
    /// see a fresh value approximately every `timerInterval` seconds.
    static let timerInterval: TimeInterval = 60

    private let settingsStore: SettingsStore
    private let profileStore: ProfileStore
    private let profileApplicationService: ProfileApplicationService
    private let appSupportPaths: AppSupportPaths
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let evaluator: TriggerRuleEvaluator
    private let fileManager: FileManager
    private let now: () -> Date

    /// Pairs of `(notification center, observer)` so `stop()` removes each observer
    /// from the center it was actually registered with (the previous implementation
    /// blindly called `removeObserver` on both centers, which masked intent).
    private var observers: [(center: NotificationCenter, observer: NSObjectProtocol)] = []
    private var timer: Timer?

    /// Pending coalesced evaluation. Cancelled and rescheduled on every event so a
    /// burst of `didActivateApplication` notifications collapses into one evaluation
    /// after `evaluationDebounceInterval` of quiescence.
    @ObservationIgnored private var pendingEvaluationTask: Task<Void, Never>?

    /// Latest reason supplied for the pending evaluation; surfaced in diagnostics
    /// logs so the trigger evaluation log still reports the most recent event type
    /// (e.g. "frontmost app" wins over "screen change" if both fired within the
    /// debounce window).
    @ObservationIgnored private var pendingEvaluationReason: String = ""

    /// Cached battery percentage refreshed by the 60s timer. Event-driven evaluations
    /// reuse this value instead of paying `IOPSCopyPowerSourcesInfo` IPC on every
    /// didActivateApplication burst.
    private var cachedBatteryPercent: Int?

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

        observers.append((
            center: NotificationCenter.default,
            observer: NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: NSApp,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.scheduleEvaluation(reason: "screen change")
                }
            }
        ))

        observers.append((
            center: NSWorkspace.shared.notificationCenter,
            observer: NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.scheduleEvaluation(reason: "app launch")
                }
            }
        ))

        observers.append((
            center: NSWorkspace.shared.notificationCenter,
            observer: NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.scheduleEvaluation(reason: "frontmost app")
                }
            }
        ))

        timer = Timer.scheduledTimer(withTimeInterval: Self.timerInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                // Refresh the cached battery value on the timer tick; event-driven
                // evaluations reuse this cache instead of paying the IOPSCopy IPC on
                // every didActivateApplication burst.
                self?.cachedBatteryPercent = Self.currentBatteryPercent()
                self?.scheduleEvaluation(reason: "timer")
            }
        }

        // Prime the battery cache so the first event-driven evaluation has a
        // meaningful value before the first 60s tick elapses.
        cachedBatteryPercent = Self.currentBatteryPercent()

        liveStatus.automationPaused = false
        diagnosticsLogger.log("Smart triggers started.", level: .debug, category: .trigger)
        scheduleEvaluation(reason: "start")
    }

    func stop() {
        pendingEvaluationTask?.cancel()
        pendingEvaluationTask = nil
        pendingEvaluationReason = ""

        for entry in observers {
            entry.center.removeObserver(entry.observer)
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

        // Precedence policy: the first matching trigger in array order wins and fires.
        // Previously every matching trigger fired in array order with no documented
        // winner, which produced "last array entry wins" semantics and could chain
        // overlapping applies (one trigger observing a context that another trigger
        // had just changed). Picking the first match keeps the semantics explicit and
        // is sufficient for the current Basic-Mode-only trigger surface.
        let currentDate = now()
        guard let matchingTrigger = triggers.first(where: {
            evaluator.shouldFire(trigger: $0, context: context, now: currentDate)
        }) else {
            liveStatus.triggerEvaluationLog = "No triggers matched (\(reason))."
            return
        }

        fire(matchingTrigger, now: currentDate)
        // `fire` returns without saving if the profile is missing or the loop guard
        // blocks the apply; only persist when we actually mutated `lastFiredAt`.
        if let index = triggers.firstIndex(where: { $0.id == matchingTrigger.id }),
           triggers[index].lastFiredAt == currentDate {
            // Single atomic write per evaluation (previously `save()` ran once per
            // matching trigger, so a burst of N matches produced N atomic writes).
            save()
        }
        liveStatus.triggerEvaluationLog = "Matched \(matchingTrigger.name) (\(reason))."
    }

    func evaluateCurrentContext(reason: String) {
        evaluate(context: currentContext(), reason: reason)
    }

    /// Schedules a debounced re-evaluation. Cancels any pending evaluation first so a
    /// rapid burst of `didActivateApplication` notifications coalesces into a single
    /// evaluation after `evaluationDebounceInterval` of quiescence.
    private func scheduleEvaluation(reason: String) {
        pendingEvaluationTask?.cancel()
        pendingEvaluationReason = reason
        let capturedReason = reason
        pendingEvaluationTask = Task { @MainActor in
            try? await Task.sleep(for: Self.evaluationDebounceInterval)
            if Task.isCancelled { return }
            self.evaluateCurrentContext(reason: capturedReason)
        }
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

        // Set the active profile id first so a concurrent or coalesced trigger
        // evaluation observably sees the in-flight transition (the previous
        // implementation set it only after `applyBasicSettings` returned, leaving a
        // window where overlapping triggers could not detect the in-progress apply).
        liveStatus.activeProfileID = profile.id.uuidString

        profileApplicationService.applyBasicSettings(
            profile: profile,
            snapshots: liveStatus.scannedMenuBarItems,
            accessibilityStatus: liveStatus.accessibilityPermissionStatus,
            allowProMoves: false
        )

        if let index = triggers.firstIndex(where: { $0.id == trigger.id }) {
            triggers[index].lastFiredAt = now
        }
        // Persistence is performed by the caller (`evaluate`) once per evaluation pass
        // to avoid the previous "save-once-per-matching-trigger" write churn.

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
            batteryPercent: cachedBatteryPercent,
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
