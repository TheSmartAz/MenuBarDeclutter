import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("MenuBarScanCoordinator")
@MainActor
struct MenuBarScanCoordinatorTests {
    @Test func manualRefreshAvailableWhenConfiguredEvenIfPermissionCacheIsStale() {
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

        #expect(harness.permissionService.status == .granted)
        #expect(harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.count == 1)
    }

    @Test func revokedPermissionClearsExistingDiagnosticsWithoutScanningAgain() {
        var isTrusted = true
        let harness = makeHarness(isTrusted: { isTrusted })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        harness.coordinator.requestManualRefresh()
        #expect(harness.permissionService.status == .granted)
        #expect(harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.count == 1)

        isTrusted = false
        harness.coordinator.requestManualRefresh()

        #expect(harness.permissionService.status == .denied)
        #expect(harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.isEmpty)
        #expect(harness.liveStatus.lastMenuBarScanTime == nil)
        #expect(harness.liveStatus.menuBarScanFailuresCount == 0)
    }

    @Test func automaticScansAreThrottledButManualRefreshBypassesThrottle() {
        var now = Date(timeIntervalSince1970: 100)
        let harness = makeHarness(isTrusted: { true }, now: { now })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true
        harness.store.menuBarScanIntervalSeconds = 10

        harness.coordinator.scanIfAllowed(reason: "launch")
        #expect(harness.scanner.scanCount == 1)

        now = Date(timeIntervalSince1970: 101)
        harness.coordinator.scanIfAllowed(reason: "visibility change")
        #expect(harness.scanner.scanCount == 1)

        harness.coordinator.requestManualRefresh()
        #expect(harness.scanner.scanCount == 2)
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
        #expect(harness.scanner.scanCount == 1)

        now = Date(timeIntervalSince1970: 101)
        notificationCenter.post(name: HidingService.visibilityDidChangeNotification, object: nil)
        notificationCenter.post(name: HidingService.visibilityDidChangeNotification, object: nil)
        notificationCenter.post(name: HidingService.visibilityDidChangeNotification, object: nil)

        await waitUntilScanCount(2, scanner: harness.scanner)

        #expect(harness.scanner.scanCount == 2)
    }

    @Test func disabledProModeClearsScanStateAndDoesNotScan() {
        let harness = makeHarness(isTrusted: { true })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true
        harness.coordinator.requestManualRefresh()
        #expect(harness.liveStatus.scannedMenuBarItems.count == 1)

        harness.store.proModeEnabled = false
        harness.coordinator.scanIfAllowed(reason: "settings changed")

        #expect(harness.scanner.scanCount == 1)
        #expect(harness.liveStatus.scannedMenuBarItems.isEmpty)
        #expect(harness.coordinator.isManualRefreshAvailable == false)
        #expect(harness.coordinator.canScan == false)
    }

    private func makeHarness(
        isTrusted: @escaping () -> Bool?,
        notificationCenter: NotificationCenter = NotificationCenter(),
        visibilityScanDebounceNanoseconds: UInt64 = 250_000_000,
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
        let scanner = FakeMenuBarScanner()
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

        while scanner.scanCount < expectedCount,
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

@MainActor
private final class FakeMenuBarScanner: MenuBarScanning {
    private(set) var scanCount = 0

    func scan(
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?
    ) -> MenuBarScanResult {
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
                        primarySeparatorFrame: primarySeparatorFrame,
                        alwaysHiddenSeparatorFrame: alwaysHiddenSeparatorFrame
                    ),
                    isLikelySystemItem: false,
                    scanTimestamp: Date(timeIntervalSince1970: Double(scanCount))
                )
            ],
            scanTimestamp: Date(timeIntervalSince1970: Double(scanCount)),
            axFailuresCount: scanCount
        )
    }
}
