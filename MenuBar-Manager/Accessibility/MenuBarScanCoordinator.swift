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
    @ObservationIgnored private let separatorFramesProvider: () -> MenuBarSeparatorFrames
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
        separatorFramesProvider: @escaping () -> MenuBarSeparatorFrames,
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
        self.separatorFramesProvider = separatorFramesProvider
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
        let status = permissionService.refreshStatus()
        setLiveStatus(\.accessibilityPermissionStatus, to: status)

        guard settingsStore.proModeEnabled else {
            clearScanState(skipReason: "Pro Mode disabled")
            return nil
        }

        guard settingsStore.accessibilityDiscoveryEnabled else {
            clearScanState(skipReason: "Accessibility discovery disabled")
            return nil
        }

        guard status == .granted else {
            clearScanState(skipReason: "Accessibility permission \(status.displayName.lowercased())")
            return nil
        }

        let currentDate = now()
        if !force,
           let lastScanDate,
           currentDate.timeIntervalSince(lastScanDate) < settingsStore.menuBarScanIntervalSeconds {
            lastSkipReason = "Throttled"
            diagnosticsLogger.log("AX scan skipped for \(reason): throttled.", level: .debug)
            return lastResult
        }

        let context = makeScanContext()
        lastScanDate = currentDate
        lastSkipReason = nil
        startScan(context: context, reason: reason)
        return lastResult
    }

    private func startScan(context: MenuBarScanContext, reason: String) {
        scanRequestID += 1
        let requestID = scanRequestID
        let scanner = scanner

        pendingScanTask?.cancel()
        pendingScanTask = Task { @MainActor [weak self] in
            let result = await scanner.scan(context: context)
            self?.completeScan(result: result, requestID: requestID, reason: reason)
        }
    }

    private func completeScan(result: MenuBarScanResult, requestID: Int, reason: String) {
        guard scanRequestID == requestID,
              pendingScanTask?.isCancelled == false else {
            diagnosticsLogger.log("AX scan result ignored for \(reason): stale request.", level: .debug)
            return
        }

        lastResult = result
        lastSkipReason = nil
        apply(result: result)

        diagnosticsLogger.log(
            "AX scan completed for \(reason): \(result.snapshots.count) items, \(result.axFailuresCount) AX failures."
        )
        pendingScanTask = nil
    }

    private func makeScanContext() -> MenuBarScanContext {
        let frames = separatorFramesProvider()
        let runningApplications = NSWorkspace.shared.runningApplications
            .filter { $0.isTerminated == false }
            .map {
                RunningApplicationSnapshot(
                    processIdentifier: $0.processIdentifier,
                    bundleIdentifier: $0.bundleIdentifier,
                    localizedName: $0.localizedName
                )
            }

        return MenuBarScanContext(
            primarySeparatorFrame: frames.primary,
            alwaysHiddenSeparatorFrame: frames.alwaysHidden,
            screenFrames: NSScreen.screens.map(\.frame),
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
        setLiveStatus(\.scannedMenuBarItems, to: [])
        setLiveStatus(\.lastMenuBarScanTime, to: nil)
        setLiveStatus(\.menuBarScanFailuresCount, to: 0)
        setLiveStatus(\.menuBarScanVisibleCount, to: 0)
        setLiveStatus(\.menuBarScanHiddenCount, to: 0)
        setLiveStatus(\.menuBarScanAlwaysHiddenCount, to: 0)
        setLiveStatus(\.menuBarScanUnknownCount, to: 0)
        setLiveStatus(\.searchIndexItemCount, to: 0)
        diagnosticsLogger.log("AX scan unavailable: \(skipReason).", level: .debug)
    }

    private func apply(result: MenuBarScanResult) {
        setLiveStatus(\.scannedMenuBarItems, to: result.snapshots)
        setLiveStatus(\.lastMenuBarScanTime, to: result.scanTimestamp)
        setLiveStatus(\.menuBarScanFailuresCount, to: result.axFailuresCount)
        setLiveStatus(\.menuBarScanVisibleCount, to: result.visibleCount)
        setLiveStatus(\.menuBarScanHiddenCount, to: result.hiddenCount)
        setLiveStatus(\.menuBarScanAlwaysHiddenCount, to: result.alwaysHiddenCount)
        setLiveStatus(\.menuBarScanUnknownCount, to: result.unknownCount)
        setLiveStatus(\.searchIndexItemCount, to: result.snapshots.count)
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
