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
        #expect(harness.liveStatus.menuBarScanLifecycleState == .completed)
        #expect(harness.liveStatus.menuBarScanLastReason == "manual refresh")
        #expect(harness.liveStatus.menuBarScanLastSkipReason == nil)
    }

    @Test func manualRefreshAndWaitReturnsFreshCompletedResult() async throws {
        let harness = makeHarness(isTrusted: { true }, scanDelayNanoseconds: 80_000_000)
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        let awaitedResult = await harness.coordinator.requestManualRefreshAndWait(reason: "assisted move verification")
        let result = try #require(awaitedResult)

        #expect(await harness.scanner.scanCount == 1)
        #expect(result.snapshots.count == 1)
        #expect(harness.coordinator.lastResult == result)
        #expect(harness.liveStatus.scannedMenuBarItems == result.snapshots)
        #expect(harness.liveStatus.menuBarScanLifecycleState == .completed)
        #expect(harness.liveStatus.menuBarScanLastReason == "assisted move verification")
        #expect(harness.liveStatus.menuBarScanLastSkipReason == nil)
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

    @Test func successfulScanUpdatesNewItemInboxCount() async {
        let harness = makeHarness(isTrusted: { true })
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(1, scanner: harness.scanner)
        await waitUntil { harness.liveStatus.newMenuBarItemReviewCount == 1 }

        #expect(harness.newItemInboxStore.inbox.reviewCount == 1)
        #expect(harness.liveStatus.newMenuBarItemReviewCount == 1)

        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(2, scanner: harness.scanner)

        #expect(harness.newItemInboxStore.inbox.reviewCount == 1)
        #expect(harness.liveStatus.newMenuBarItemReviewCount == 1)
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
        #expect(harness.liveStatus.menuBarScanLifecycleState == .skipped)
        #expect(harness.liveStatus.menuBarScanLastReason == "visibility change")
        #expect(harness.liveStatus.menuBarScanLastSkipReason == "Throttled")

        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(2, scanner: harness.scanner)
        #expect(await harness.scanner.scanCount == 2)
        await waitUntil { harness.liveStatus.menuBarScanLifecycleState == .completed }
    }

    @Test func rapidVisibilityChangesCoalesceIntoOneScan() async {
        var now = Date(timeIntervalSince1970: 100)
        let harness = makeHarness(
            isTrusted: { true },
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
        harness.coordinator.scheduleVisibilityChangeScanForTesting()
        harness.coordinator.scheduleVisibilityChangeScanForTesting()
        harness.coordinator.scheduleVisibilityChangeScanForTesting()

        await harness.coordinator.waitForPendingVisibilityScanForTesting()

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

    @Test func scanContextExcludesCurrentProcessFromRunningApplicationCandidates() async {
        let currentProcessIdentifier: pid_t = 41_001
        let otherProcessIdentifier: pid_t = 41_002
        let harness = makeHarness(
            isTrusted: { true },
            runningApplicationsProvider: {
                [
                    RunningApplicationSnapshot(
                        processIdentifier: currentProcessIdentifier,
                        bundleIdentifier: "local.MenuBarDeclutter",
                        localizedName: "MenuBarDeclutter"
                    ),
                    RunningApplicationSnapshot(
                        processIdentifier: otherProcessIdentifier,
                        bundleIdentifier: "local.OtherMenuExtra",
                        localizedName: "Other Menu Extra"
                    )
                ]
            },
            currentProcessIdentifier: currentProcessIdentifier
        )
        defer { harness.tearDown() }
        harness.store.proModeEnabled = true
        harness.store.accessibilityDiscoveryEnabled = true

        harness.coordinator.requestManualRefresh()
        await waitUntilScanCount(1, scanner: harness.scanner)

        let scannedProcessIdentifiers = await harness.scanner.lastRunningApplicationProcessIdentifiers
        #expect(scannedProcessIdentifiers == [otherProcessIdentifier])
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
        #expect(harness.liveStatus.menuBarScanLifecycleState == .skipped)
        #expect(harness.liveStatus.menuBarScanLastSkipReason == "Optional Pro disabled")
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
        #expect(harness.coordinator.lastSkipReason == "Optional Pro disabled")
    }

    private func makeHarness(
        isTrusted: @escaping () -> Bool?,
        notificationCenter: NotificationCenter = NotificationCenter(),
        workspaceNotificationCenter: NotificationCenter = NotificationCenter(),
        visibilityScanDebounceNanoseconds: UInt64 = 250_000_000,
        scanDelayNanoseconds: UInt64 = 0,
        runningApplicationsProvider: @escaping () -> [RunningApplicationSnapshot] = { [] },
        currentProcessIdentifier: pid_t = ProcessInfo.processInfo.processIdentifier,
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
        let newItemInboxStore = NewMenuBarItemInboxStore(fileURL: nil)
        let coordinator = MenuBarScanCoordinator(
            settingsStore: store,
            permissionService: permissionService,
            scanner: scanner,
            diagnosticsLogger: logger,
            liveStatus: liveStatus,
            newItemInboxStore: newItemInboxStore,
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 0, width: 20, height: 24),
                    alwaysHidden: CGRect(x: 200, y: 0, width: 20, height: 24)
                )
            },
            runningApplicationsProvider: runningApplicationsProvider,
            screenFramesProvider: {
                [CGRect(x: 0, y: 0, width: 1440, height: 900)]
            },
            currentProcessIdentifier: currentProcessIdentifier,
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
            newItemInboxStore: newItemInboxStore,
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
    let newItemInboxStore: NewMenuBarItemInboxStore
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
    private(set) var lastRunningApplicationProcessIdentifiers: [pid_t] = []

    init(scanDelayNanoseconds: UInt64 = 0) {
        self.scanDelayNanoseconds = scanDelayNanoseconds
    }

    func scan(context: MenuBarScanContext) async -> MenuBarScanResult {
        if scanDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: scanDelayNanoseconds)
        }

        scanCount += 1
        lastRunningApplicationProcessIdentifiers = context.runningApplications.map(\.processIdentifier)

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
