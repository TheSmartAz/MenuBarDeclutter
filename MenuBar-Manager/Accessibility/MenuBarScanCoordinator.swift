import CoreGraphics
import Foundation
import Observation

struct MenuBarSeparatorFrames {
    let primary: CGRect?
    let alwaysHidden: CGRect?
}

protocol MenuBarScanning: AnyObject {
    func scan(
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?
    ) -> MenuBarScanResult
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
    @ObservationIgnored private let now: () -> Date

    @ObservationIgnored private var visibilityObserver: NSObjectProtocol?
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
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.permissionService = permissionService
        self.scanner = scanner
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.separatorFramesProvider = separatorFramesProvider
        self.now = now
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
        refreshAfterSettingsChanged(reason: "launch")
    }

    func stop() {
        if let visibilityObserver {
            NotificationCenter.default.removeObserver(visibilityObserver)
            self.visibilityObserver = nil
        }
    }

    func refreshAfterSettingsChanged(reason: String = "settings changed") {
        let status = permissionService.refreshStatus()
        liveStatus.accessibilityPermissionStatus = status
        scanIfAllowed(reason: reason)
    }

    func requestManualRefresh() {
        scanIfAllowed(reason: "manual refresh", force: true)
    }

    @discardableResult
    func scanIfAllowed(reason: String, force: Bool = false) -> MenuBarScanResult? {
        let status = permissionService.refreshStatus()
        liveStatus.accessibilityPermissionStatus = status

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

        let frames = separatorFramesProvider()
        let result = scanner.scan(
            primarySeparatorFrame: frames.primary,
            alwaysHiddenSeparatorFrame: frames.alwaysHidden
        )
        lastResult = result
        lastScanDate = currentDate
        lastSkipReason = nil
        apply(result: result)

        diagnosticsLogger.log(
            "AX scan completed for \(reason): \(result.snapshots.count) items, \(result.axFailuresCount) AX failures."
        )
        return result
    }

    private func clearScanState(skipReason: String) {
        lastSkipReason = skipReason
        lastResult = nil
        lastScanDate = nil
        liveStatus.scannedMenuBarItems = []
        liveStatus.lastMenuBarScanTime = nil
        liveStatus.menuBarScanFailuresCount = 0
        liveStatus.menuBarScanVisibleCount = 0
        liveStatus.menuBarScanHiddenCount = 0
        liveStatus.menuBarScanAlwaysHiddenCount = 0
        liveStatus.menuBarScanUnknownCount = 0
        liveStatus.searchIndexItemCount = 0
        diagnosticsLogger.log("AX scan unavailable: \(skipReason).", level: .debug)
    }

    private func apply(result: MenuBarScanResult) {
        liveStatus.scannedMenuBarItems = result.snapshots
        liveStatus.lastMenuBarScanTime = result.scanTimestamp
        liveStatus.menuBarScanFailuresCount = result.axFailuresCount
        liveStatus.menuBarScanVisibleCount = result.visibleCount
        liveStatus.menuBarScanHiddenCount = result.hiddenCount
        liveStatus.menuBarScanAlwaysHiddenCount = result.alwaysHiddenCount
        liveStatus.menuBarScanUnknownCount = result.unknownCount
        liveStatus.searchIndexItemCount = result.snapshots.count
    }

    private func observeVisibilityChanges() {
        guard visibilityObserver == nil else { return }
        visibilityObserver = NotificationCenter.default.addObserver(
            forName: HidingService.visibilityDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                _ = self?.scanIfAllowed(reason: "visibility change")
            }
        }
    }
}
