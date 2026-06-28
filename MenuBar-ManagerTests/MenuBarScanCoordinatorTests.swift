import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("MenuBarScanCoordinator")
@MainActor
struct MenuBarScanCoordinatorTests {
    @Test func manualRefreshAvailableWhenConfiguredEvenIfPermissionCacheIsStale() async {
        var isTrusted = false
        let harness = makeHarness(isTrusted: { isTrusted })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        #expect(harness.permissionService.status == .notRequested)
        #expect(harness.coordinator.isManualRefreshAvailable == true)
        #expect(harness.coordinator.canScan == false)

        isTrusted = true
        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(1, scanner: harness.scanner)
        await waitUntil { harness.liveStatus.scannedMenuBarItems.count == 1 }

        #expect(harness.permissionService.status == .granted)
        #expect(await harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.count == 1)
    }

    @Test func revokedPermissionClearsExistingDiagnosticsWithoutScanningAgain() async {
        var isTrusted = true
        let harness = makeHarness(isTrusted: { isTrusted })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(1, scanner: harness.scanner)
        await waitUntil { harness.liveStatus.scannedMenuBarItems.count == 1 }
        #expect(harness.permissionService.status == .granted)
        #expect(await harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.count == 1)

        isTrusted = false
        harness.coordinator.requestManualRefresh()

        #expect(harness.permissionService.status == .denied)
        #expect(await harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.isEmpty)
        #expect(harness.liveStatus.lastMenuBarScanTime == nil)
        #expect(harness.liveStatus.menuBarScanFailuresCount == 0)
    }

    @Test func automaticScansAreThrottledButManualRefreshBypassesThrottle() async {
        var now = Date(timeIntervalSince1970: 100)
        let harness = makeHarness(isTrusted: { true }, now: { now })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true
        harness.store.menuBarScanIntervalSeconds = 10

        harness.coordinator.scanIfAllowed(reason: "launch")
        await waitUntilScanCount(1, scanner: harness.scanner)
        #expect(await harness.scanner.scanCount == 1)

        now = Date(timeIntervalSince1970: 101)
        harness.coordinator.scanIfAllowed(reason: "visibility change")
        #expect(await harness.scanner.scanCount == 1)

        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(2, scanner: harness.scanner)
        #expect(await harness.scanner.scanCount == 2)
    }

    @Test func rapidVisibilityNotificationsCoalesceIntoOneScan() async {
        var now = Date(timeIntervalSince1970: 100)
        let notificationCenter = NotificationCenter()
        let harness = makeHarness(
            isTrusted: { true },
            notificationCenter: notificationCenter,
            visibilityScanDebounceNanoseconds: 20_000_000,
            now: { now }
        )
        defer {
            harness.coordinator.stop()
            harness.tearDown()
        }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true
        harness.store.menuBarScanIntervalSeconds = 0.5

        harness.coordinator.start()
        await waitUntilScanCount(1, scanner: harness.scanner)
        #expect(await harness.scanner.scanCount == 1)

        now = Date(timeIntervalSince1970: 101)
        notificationCenter.post(name: HidingService.visibilityDidChangeNotification, object: nil)
        notificationCenter.post(name: HidingService.visibilityDidChangeNotification, object: nil)
        notificationCenter.post(name: HidingService.visibilityDidChangeNotification, object: nil)

        await waitUntilScanCount(2, scanner: harness.scanner)

        #expect(await harness.scanner.scanCount == 2)
    }

    @Test func applicationLifecycleNotificationsInvalidateScannerCandidateCache() async {
        let workspaceNotificationCenter = NotificationCenter()
        let harness = makeHarness(
            isTrusted: { false },
            workspaceNotificationCenter: workspaceNotificationCenter
        )
        defer {
            harness.coordinator.stop()
            harness.tearDown()
        }

        harness.coordinator.start()
        #expect(await harness.scanner.scanCount == 0)
        #expect(await harness.scanner.invalidateCandidateCacheCount == 0)

        workspaceNotificationCenter.post(name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        workspaceNotificationCenter.post(name: NSWorkspace.didTerminateApplicationNotification, object: nil)

        await waitUntilInvalidationCount(2, scanner: harness.scanner)

        #expect(await harness.scanner.invalidateCandidateCacheCount == 2)
        #expect(await harness.scanner.scanCount == 0)
    }

    @Test func stopRemovesApplicationLifecycleObservers() async {
        let workspaceNotificationCenter = NotificationCenter()
        let harness = makeHarness(
            isTrusted: { false },
            workspaceNotificationCenter: workspaceNotificationCenter
        )
        defer { harness.tearDown() }

        harness.coordinator.start()
        harness.coordinator.stop()

        workspaceNotificationCenter.post(name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        workspaceNotificationCenter.post(name: NSWorkspace.didTerminateApplicationNotification, object: nil)

        try? await Task.sleep(nanoseconds: 30_000_000)

        #expect(await harness.scanner.invalidateCandidateCacheCount == 0)
        #expect(await harness.scanner.scanCount == 0)
    }

    @Test func disabledProModeClearsScanStateAndDoesNotScan() async {
        let harness = makeHarness(isTrusted: { true })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true
        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(1, scanner: harness.scanner)
        await waitUntil { harness.liveStatus.scannedMenuBarItems.count == 1 }
        #expect(harness.liveStatus.scannedMenuBarItems.count == 1)

        harness.store.proModeEnabled = false
        harness.coordinator.scanIfAllowed(reason: "settings changed")

        #expect(await harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.isEmpty)
        #expect(harness.coordinator.isManualRefreshAvailable == false)
        #expect(harness.coordinator.canScan == false)
    }

    @Test func staleAsyncScanResultIsIgnoredAfterScanningIsDisabled() async {
        let harness = makeHarness(
            isTrusted: { true },
            scanDelayNanoseconds: 80_000_000
        )
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        harness.coordinator.requestManualRefresh()
        harness.store.proModeEnabled = false
        harness.coordinator.scanIfAllowed(reason: "settings changed")

        try? await Task.sleep(nanoseconds: 150_000_000)

        #expect(harness.liveStatus.scannedMenuBarItems.isEmpty)
        #expect(harness.coordinator.lastResult == nil)
        #expect(harness.coordinator.lastSkipReason == "Pro Mode disabled")
    }

    private func makeHarness(
        isTrusted: @escaping () -> Bool?,
        notificationCenter: NotificationCenter = NotificationCenter(),
        workspaceNotificationCenter: NotificationCenter = NotificationCenter(),
        visibilityScanDebounceNanoseconds: UInt64 = 250_000_000,
        scanDelayNanoseconds: UInt64 = 0,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 100) }
    ) -> CoordinatorHarness {
        let suiteName = "MenuBarScanCoordinatorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        let permissionService = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: isTrusted,
            promptTrustProvider: isTrusted,
            systemSettingsOpener: { true }
        )
        let liveStatus = LiveDiagnosticsStatus()
        let scanner = FakeMenuBarScanner(scanDelayNanoseconds: scanDelayNanoseconds)
        let coordinator = MenuBarScanCoordinator(
            settingsStore: store,
            permissionService: permissionService,
            scanner: scanner,
            diagnosticsLogger: logger,
            liveStatus: liveStatus,
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 0, width: 20, height: 24),
                    alwaysHidden: CGRect(x: 200, y: 0, width: 20, height: 24)
                )
            },
            notificationCenter: notificationCenter,
            workspaceNotificationCenter: workspaceNotificationCenter,
            visibilityScanDebounceNanoseconds: visibilityScanDebounceNanoseconds,
            now: now
        )

        return CoordinatorHarness(
            store: store,
            permissionService: permissionService,
            liveStatus: liveStatus,
            scanner: scanner,
            coordinator: coordinator,
            defaults: defaults,
            suiteName: suiteName
        )
    }

    private func waitUntilScanCount(
        _ expectedCount: Int,
        scanner: FakeMenuBarScanner,
        timeoutNanoseconds: UInt64 = 1_000_000_000
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int64(timeoutNanoseconds))

        while await scanner.scanCount < expectedCount,
              ContinuousClock.now < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func waitUntilInvalidationCount(
        _ expectedCount: Int,
        scanner: FakeMenuBarScanner,
        timeoutNanoseconds: UInt64 = 1_000_000_000
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int64(timeoutNanoseconds))

        while await scanner.invalidateCandidateCacheCount < expectedCount,
              ContinuousClock.now < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () -> Bool
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int64(timeoutNanoseconds))

        while !condition(),
              ContinuousClock.now < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

@MainActor
private struct CoordinatorHarness {
    let store: SettingsStore
    let permissionService: AccessibilityPermissionService
    let liveStatus: LiveDiagnosticsStatus
    let scanner: FakeMenuBarScanner
    let coordinator: MenuBarScanCoordinator
    let defaults: UserDefaults
    let suiteName: String

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private actor FakeMenuBarScanner: MenuBarScanning {
    private let scanDelayNanoseconds: UInt64
    private(set) var scanCount = 0
    private(set) var invalidateCandidateCacheCount = 0

    init(scanDelayNanoseconds: UInt64 = 0) {
        self.scanDelayNanoseconds = scanDelayNanoseconds
    }

    func scan(context: MenuBarScanContext) async -> MenuBarScanResult {
        if scanDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: scanDelayNanoseconds)
        }

        scanCount += 1

        return MenuBarScanResult(
            snapshots: [
                MenuBarItemSnapshot(
                    id: "fake-item",
                    title: "Fake Item",
                    role: "AXMenuBarItem",
                    subrole: nil,
                    frame: CGRect(x: 600, y: 0, width: 20, height: 24),
                    owningProcessIdentifier: 42,
                    owningApplicationName: "Fake",
                    bundleIdentifier: "local.fake",
                    zone: MenuBarZone.classify(
                        itemFrame: CGRect(x: 600, y: 0, width: 20, height: 24),
                        primarySeparatorFrame: context.primarySeparatorFrame,
                        alwaysHiddenSeparatorFrame: context.alwaysHiddenSeparatorFrame
                    ),
                    isLikelySystemItem: false,
                    scanTimestamp: Date(timeIntervalSince1970: Double(scanCount))
                )
            ],
            scanTimestamp: Date(timeIntervalSince1970: Double(scanCount)),
            axFailuresCount: scanCount
        )
    }

    func invalidateCandidateCache() async {
        invalidateCandidateCacheCount += 1
    }
}
