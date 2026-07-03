import AppKit
import CoreGraphics
import Foundation
import Observation

nonisolated struct MenuBarSeparatorFrames: Sendable {
    let primary: CGRect?
    let alwaysHidden: CGRect?
}

nonisolated struct RunningApplicationSnapshot: Equatable, Sendable {
    let processIdentifier: pid_t
    let bundleIdentifier: String?
    let localizedName: String?
}

nonisolated struct MenuBarScanContext: Sendable {
    let primarySeparatorFrame: CGRect?
    let alwaysHiddenSeparatorFrame: CGRect?
    let screenFrames: [CGRect]
    let runningApplications: [RunningApplicationSnapshot]
}

nonisolated protocol MenuBarScanning: Sendable {
    func scan(context: MenuBarScanContext) async -> MenuBarScanResult

    func invalidateCandidateCache() async
}

extension MenuBarScanning {
    func invalidateCandidateCache() async {}
}

@MainActor
@Observable
final class MenuBarScanCoordinator {
    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private let permissionService: AccessibilityPermissionService
    @ObservationIgnored private let scanner: any MenuBarScanning
    @ObservationIgnored private let diagnosticsLogger: DiagnosticsLogger
    @ObservationIgnored private let liveStatus: LiveDiagnosticsStatus
    @ObservationIgnored private let newItemInboxStore: NewMenuBarItemInboxStore?
    @ObservationIgnored private let separatorFramesProvider: () -> MenuBarSeparatorFrames
    @ObservationIgnored private let runningApplicationsProvider: () -> [RunningApplicationSnapshot]
    @ObservationIgnored private let screenFramesProvider: () -> [CGRect]
    @ObservationIgnored private let currentProcessIdentifier: pid_t
    @ObservationIgnored private let notificationCenter: NotificationCenter
    @ObservationIgnored private let workspaceNotificationCenter: NotificationCenter
    @ObservationIgnored private let visibilityScanDebounceNanoseconds: UInt64
    @ObservationIgnored private let now: () -> Date

    @ObservationIgnored nonisolated(unsafe) private var visibilityObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var workspaceLifecycleObservers: [NSObjectProtocol] = []
    @ObservationIgnored private var pendingVisibilityScanTask: Task<Void, Never>?
    @ObservationIgnored private var pendingScanTask: Task<Void, Never>?
    @ObservationIgnored private var visibilityScanRequestID = 0
    @ObservationIgnored private var scanRequestID = 0
    @ObservationIgnored private var lastScanDate: Date?

    private(set) var lastResult: MenuBarScanResult?
    private(set) var lastSkipReason: String?

    init(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        scanner: any MenuBarScanning,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        newItemInboxStore: NewMenuBarItemInboxStore? = nil,
        separatorFramesProvider: @escaping () -> MenuBarSeparatorFrames,
        runningApplicationsProvider: @escaping () -> [RunningApplicationSnapshot] = {
            NSWorkspace.shared.runningApplications
                .filter { $0.isTerminated == false }
                .map {
                    RunningApplicationSnapshot(
                        processIdentifier: $0.processIdentifier,
                        bundleIdentifier: $0.bundleIdentifier,
                        localizedName: $0.localizedName
                    )
                }
        },
        screenFramesProvider: @escaping () -> [CGRect] = {
            NSScreen.screens.map(\.frame)
        },
        currentProcessIdentifier: pid_t = ProcessInfo.processInfo.processIdentifier,
        notificationCenter: NotificationCenter = .default,
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        visibilityScanDebounceNanoseconds: UInt64 = 250_000_000,
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.permissionService = permissionService
        self.scanner = scanner
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.newItemInboxStore = newItemInboxStore
        self.separatorFramesProvider = separatorFramesProvider
        self.runningApplicationsProvider = runningApplicationsProvider
        self.screenFramesProvider = screenFramesProvider
        self.currentProcessIdentifier = currentProcessIdentifier
        self.notificationCenter = notificationCenter
        self.workspaceNotificationCenter = workspaceNotificationCenter
        self.visibilityScanDebounceNanoseconds = visibilityScanDebounceNanoseconds
        self.now = now
    }

    deinit {
        removeNotificationObservers()
    }

    var canScan: Bool {
        isManualRefreshAvailable
            && permissionService.status == .granted
    }

    var isManualRefreshAvailable: Bool {
        settingsStore.proModeEnabled
            && settingsStore.accessibilityDiscoveryEnabled
    }

    func start() {
        observeVisibilityChanges()
        observeWorkspaceLifecycleChanges()
        refreshAfterSettingsChanged(reason: "launch")
    }

    func stop() {
        removeNotificationObservers()
        visibilityScanRequestID += 1
        pendingVisibilityScanTask?.cancel()
        pendingVisibilityScanTask = nil
        cancelPendingScan()
    }

    func refreshAfterSettingsChanged(reason: String = "settings changed") {
        let status = permissionService.refreshStatus()
        setLiveStatus(\.accessibilityPermissionStatus, to: status)
        scanIfAllowed(reason: reason)
    }

    func requestManualRefresh() {
        scanIfAllowed(reason: "manual refresh", force: true)
    }

    @discardableResult
    func scanIfAllowed(reason: String, force: Bool = false) -> MenuBarScanResult? {
        switch prepareScan(reason: reason, force: force) {
        case .start(let context):
            startScan(context: context, reason: reason)
            return lastResult
        case .finished(let result):
            return result
        }
    }

    @discardableResult
    func scanIfAllowedAndWait(reason: String, force: Bool = false) async -> MenuBarScanResult? {
        switch prepareScan(reason: reason, force: force) {
        case .start(let context):
            return await runScanAndWait(context: context, reason: reason)
        case .finished(let result):
            return result
        }
    }

    @discardableResult
    func requestManualRefreshAndWait(reason: String = "manual refresh") async -> MenuBarScanResult? {
        await scanIfAllowedAndWait(reason: reason, force: true)
    }

    private enum ScanStartDecision {
        case start(MenuBarScanContext)
        case finished(MenuBarScanResult?)
    }

    private func prepareScan(reason: String, force: Bool) -> ScanStartDecision {
        let status = permissionService.refreshStatus()
        setLiveStatus(\.accessibilityPermissionStatus, to: status)
        setLiveStatus(\.menuBarScanLifecycleState, to: .requested)
        setLiveStatus(\.menuBarScanLastReason, to: reason)
        setLiveStatus(\.menuBarScanLastSkipReason, to: nil)

        diagnosticsLogger.log(
            "AX scan requested for \(reason): pro=\(settingsStore.proModeEnabled), discovery=\(settingsStore.accessibilityDiscoveryEnabled), permission=\(status.rawValue), force=\(force).",
            level: .debug,
            category: .scan
        )

        guard settingsStore.proModeEnabled else {
            clearScanState(skipReason: "Pro Mode disabled")
            return .finished(nil)
        }

        guard settingsStore.accessibilityDiscoveryEnabled else {
            clearScanState(skipReason: "Accessibility discovery disabled")
            return .finished(nil)
        }

        guard status == .granted else {
            clearScanState(skipReason: "Accessibility permission \(status.displayName.lowercased())")
            return .finished(nil)
        }

        let currentDate = now()
        if !force,
           let lastScanDate,
           currentDate.timeIntervalSince(lastScanDate) < settingsStore.menuBarScanIntervalSeconds {
            lastSkipReason = "Throttled"
            setLiveStatus(\.menuBarScanLifecycleState, to: .skipped)
            setLiveStatus(\.menuBarScanLastSkipReason, to: "Throttled")
            diagnosticsLogger.log("AX scan skipped for \(reason): throttled.", level: .debug)
            return .finished(lastResult)
        }

        let context = makeScanContext()
        lastScanDate = currentDate
        lastSkipReason = nil
        return .start(context)
    }

    private func startScan(context: MenuBarScanContext, reason: String) {
        let (requestID, scanner) = beginScan(context: context, reason: reason)
        pendingScanTask = Task { @MainActor [weak self] in
            let result = await scanner.scan(context: context)
            self?.completeScan(result: result, requestID: requestID, reason: reason)
        }
    }

    private func runScanAndWait(context: MenuBarScanContext, reason: String) async -> MenuBarScanResult? {
        let (requestID, scanner) = beginScan(context: context, reason: reason)
        let result = await scanner.scan(context: context)
        return completeScan(result: result, requestID: requestID, reason: reason) ? result : nil
    }

    private func beginScan(
        context: MenuBarScanContext,
        reason: String
    ) -> (requestID: Int, scanner: any MenuBarScanning) {
        scanRequestID += 1
        let requestID = scanRequestID
        let scanner = scanner

        pendingScanTask?.cancel()
        pendingScanTask = nil
        setLiveStatus(\.menuBarScanLifecycleState, to: .running)
        diagnosticsLogger.log(
            "AX scan started for \(reason): apps=\(context.runningApplications.count), screens=\(context.screenFrames.count).",
            level: .debug,
            category: .scan
        )
        return (requestID, scanner)
    }

    @discardableResult
    private func completeScan(result: MenuBarScanResult, requestID: Int, reason: String) -> Bool {
        guard scanRequestID == requestID else {
            diagnosticsLogger.log("AX scan result ignored for \(reason): stale request.", level: .debug)
            return false
        }

        lastResult = result
        lastSkipReason = nil
        setLiveStatus(\.menuBarScanLifecycleState, to: .completed)
        setLiveStatus(\.menuBarScanLastSkipReason, to: nil)
        apply(result: result)

        diagnosticsLogger.log(
            "AX scan completed for \(reason): \(result.snapshots.count) items, \(result.axFailuresCount) AX failures."
        )
        pendingScanTask = nil
        return true
    }

    private func makeScanContext() -> MenuBarScanContext {
        let frames = separatorFramesProvider()
        // System-wide roots still cover menu extras. Skip our own app process so
        // AX scanning never asks AppKit to service its main menu off-main.
        let runningApplications = runningApplicationsProvider()
            .filter { $0.processIdentifier != currentProcessIdentifier }

        return MenuBarScanContext(
            primarySeparatorFrame: frames.primary,
            alwaysHiddenSeparatorFrame: frames.alwaysHidden,
            screenFrames: screenFramesProvider(),
            runningApplications: runningApplications
        )
    }

    private func cancelPendingScan() {
        scanRequestID += 1
        pendingScanTask?.cancel()
        pendingScanTask = nil
    }

    private func clearScanState(skipReason: String) {
        cancelPendingScan()
        lastSkipReason = skipReason
        lastResult = nil
        lastScanDate = nil
        setLiveStatus(\.menuBarScanLifecycleState, to: .skipped)
        setLiveStatus(\.menuBarScanLastSkipReason, to: skipReason)
        setLiveStatus(\.scannedMenuBarItems, to: [])
        setLiveStatus(\.lastMenuBarScanTime, to: nil)
        setLiveStatus(\.menuBarScanFailuresCount, to: 0)
        setLiveStatus(\.menuBarScanVisibleCount, to: 0)
        setLiveStatus(\.menuBarScanHiddenCount, to: 0)
        setLiveStatus(\.menuBarScanAlwaysHiddenCount, to: 0)
        setLiveStatus(\.menuBarScanUnknownCount, to: 0)
        setLiveStatus(\.menuBarScanFailureSummary, to: nil)
        setLiveStatus(\.searchIndexItemCount, to: 0)
        setLiveStatus(\.newMenuBarItemReviewCount, to: newItemInboxStore?.inbox.reviewCount ?? 0)
        diagnosticsLogger.log("AX scan unavailable: \(skipReason).", level: .debug)
    }

    private func apply(result: MenuBarScanResult) {
        updateNewItemInbox(result: result)
        setLiveStatus(\.scannedMenuBarItems, to: result.snapshots)
        setLiveStatus(\.lastMenuBarScanTime, to: result.scanTimestamp)
        setLiveStatus(\.menuBarScanFailuresCount, to: result.axFailuresCount)
        setLiveStatus(\.menuBarScanVisibleCount, to: result.visibleCount)
        setLiveStatus(\.menuBarScanHiddenCount, to: result.hiddenCount)
        setLiveStatus(\.menuBarScanAlwaysHiddenCount, to: result.alwaysHiddenCount)
        setLiveStatus(\.menuBarScanUnknownCount, to: result.unknownCount)
        setLiveStatus(\.menuBarScanFailureSummary, to: result.axFailureSummary)
        setLiveStatus(\.searchIndexItemCount, to: result.snapshots.count)
    }

    private func updateNewItemInbox(result: MenuBarScanResult) {
        guard let newItemInboxStore else {
            setLiveStatus(\.newMenuBarItemReviewCount, to: 0)
            return
        }

        let update = NewMenuBarItemInboxDetector().update(
            inbox: newItemInboxStore.inbox,
            snapshots: result.snapshots,
            now: result.scanTimestamp,
            isScanningAllowed: true
        )
        let inbox = newItemInboxStore.apply(update: update)
        setLiveStatus(\.newMenuBarItemReviewCount, to: inbox.reviewCount)

        if !update.addedItemIDs.isEmpty {
            diagnosticsLogger.log(
                "New menu bar item inbox added \(update.addedItemIDs.count) item(s).",
                level: .debug,
                metadata: NewMenuBarItemInboxDiagnostics.metadata(update: update, inbox: inbox)
            )
        }
    }

    private func setLiveStatus<Value: Equatable>(
        _ keyPath: ReferenceWritableKeyPath<LiveDiagnosticsStatus, Value>,
        to value: Value
    ) {
        guard liveStatus[keyPath: keyPath] != value else { return }
        liveStatus[keyPath: keyPath] = value
    }

    private func observeVisibilityChanges() {
        guard visibilityObserver == nil else { return }
        visibilityObserver = notificationCenter.addObserver(
            forName: HidingService.visibilityDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleVisibilityChangeScan()
            }
        }
    }

    private nonisolated func removeNotificationObservers() {
        if let visibilityObserver {
            notificationCenter.removeObserver(visibilityObserver)
            self.visibilityObserver = nil
        }
        for observer in workspaceLifecycleObservers {
            workspaceNotificationCenter.removeObserver(observer)
        }
        workspaceLifecycleObservers.removeAll()
    }

    private func observeWorkspaceLifecycleChanges() {
        guard workspaceLifecycleObservers.isEmpty else { return }

        workspaceLifecycleObservers.append(
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.invalidateScannerCandidateCache(reason: "app launch")
                }
            }
        )

        workspaceLifecycleObservers.append(
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.invalidateScannerCandidateCache(reason: "app terminate")
                }
            }
        )
    }

    private func invalidateScannerCandidateCache(reason: String) {
        Task { [scanner] in
            await scanner.invalidateCandidateCache()
        }
        diagnosticsLogger.log("AX scanner candidate cache invalidated after \(reason).", level: .debug)
    }

    private func scheduleVisibilityChangeScan() {
        visibilityScanRequestID += 1
        let requestID = visibilityScanRequestID
        let debounceNanoseconds = visibilityScanDebounceNanoseconds

        pendingVisibilityScanTask?.cancel()
        pendingVisibilityScanTask = Task { @MainActor [weak self] in
            if debounceNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceNanoseconds)
            }

            guard let self,
                  Task.isCancelled == false,
                  self.visibilityScanRequestID == requestID else {
                return
            }

            _ = self.scanIfAllowed(reason: "visibility change", force: true)

            if self.visibilityScanRequestID == requestID {
                self.pendingVisibilityScanTask = nil
            }
        }
    }
}
