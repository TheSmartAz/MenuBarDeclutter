import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Icon Moving Planning")
@MainActor
struct IconMovePlanningTests {
    @Test func dragPlanTargetsVisibleSideOfPrimarySeparator() throws {
        let snapshot = makeSnapshot(zone: .hidden, frame: CGRect(x: 260, y: 850, width: 24, height: 22))
        let plan = try DragPlanFactory().plan(
            for: snapshot,
            command: .moveToZone(.visible),
            context: DragPlanningContext(
                primarySeparatorFrame: CGRect(x: 500, y: 848, width: 20, height: 24),
                alwaysHiddenSeparatorFrame: CGRect(x: 200, y: 848, width: 20, height: 24),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
            ),
            preMoveVisibilityState: .expanded,
            duration: 0.35,
            retryCount: 0
        )

        #expect(plan.modifierFlags.contains(.maskCommand))
        #expect(plan.targetZone == .visible)
        #expect(plan.targetPoint.x > 520)
    }

    @Test func movingLeftKeepsCurrentZoneAndMovesTargetLeft() throws {
        let snapshot = makeSnapshot(zone: .hidden, frame: CGRect(x: 300, y: 850, width: 24, height: 22))
        let plan = try DragPlanFactory().plan(
            for: snapshot,
            command: .moveLeft,
            context: DragPlanningContext(primarySeparatorFrame: nil, alwaysHiddenSeparatorFrame: nil),
            preMoveVisibilityState: .expanded,
            duration: 0.35,
            retryCount: 0
        )

        #expect(plan.targetZone == .hidden)
        #expect(plan.targetPoint.x < plan.sourcePoint.x)
    }

    @Test func safetyRejectsOwnSeparatorItems() {
        let snapshot = makeSnapshot(
            bundleID: AppConstants.bundleIdentifier,
            zone: .visible,
            frame: CGRect(x: 600, y: 850, width: 24, height: 22)
        )

        let error = IconMoveSafetyRules().validate(
            snapshot: snapshot,
            allowSystemItems: true,
            appBundleIdentifier: AppConstants.bundleIdentifier
        )

        #expect(error == .unsafeOwnItem)
    }

    @Test func safetyRejectsSystemItemsByDefault() {
        let snapshot = makeSnapshot(
            zone: .visible,
            frame: CGRect(x: 600, y: 850, width: 24, height: 22),
            isSystem: true
        )

        let error = IconMoveSafetyRules().validate(
            snapshot: snapshot,
            allowSystemItems: false,
            appBundleIdentifier: AppConstants.bundleIdentifier
        )

        #expect(error == .unsafeSystemItem)
    }

    @Test func verificationReportsWrongZoneWhenItemIsFoundElsewhere() {
        let original = makeSnapshot(bundleID: "com.example.move", zone: .hidden)
        let after = makeSnapshot(bundleID: "com.example.move", zone: .hidden)

        let result = DragVerificationService().verify(
            original: original,
            targetZone: .visible,
            rescannedSnapshots: [after]
        )

        #expect(result.outcome == .wrongZone(.hidden))
        #expect(result.isSuccess == false)
    }

    @Test func verificationMatchesWithLocaleStableFoldedText() {
        let original = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            title: "CAF\u{00C9} Status",
            owningApplicationName: "Example"
        )
        let after = makeSnapshot(
            bundleID: "com.example.move",
            zone: .visible,
            title: " cafe status ",
            owningApplicationName: "Different"
        )

        let result = DragVerificationService().verify(
            original: original,
            targetZone: .visible,
            rescannedSnapshots: [after]
        )

        #expect(result.outcome == .succeeded)
        #expect(result.matchedSnapshot == after)
    }

    @Test func moveServiceAwaitsDragAndClearsProgress() async {
        let suiteName = "IconMovePlanningTests.service.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.iconMovingEnabled = true
        store.iconMovingRequireConfirmation = false
        store.iconMovingMaxRetries = 0

        let logger = DiagnosticsLogger()
        let permission = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { true },
            promptTrustProvider: { true },
            systemSettingsOpener: { true }
        )
        let liveStatus = LiveDiagnosticsStatus()
        let dragProbe = AsyncDragProbe()
        let original = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )
        let moved = makeSnapshot(
            bundleID: "com.example.move",
            zone: .visible,
            frame: CGRect(x: 560, y: 850, width: 24, height: 22)
        )

        var visibility: HidingVisibilityState = .collapsed
        var suspended = false
        var resumed = false
        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: ProbeDragExecutor(probe: dragProbe),
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 848, width: 20, height: 24),
                    alwaysHidden: CGRect(x: 200, y: 848, width: 20, height: 24)
                )
            },
            currentVisibilityProvider: { visibility },
            setVisibility: { visibility = $0 },
            refreshSnapshots: { [moved] },
            suspendRuntimeBehaviors: { suspended = true },
            resumeRuntimeBehaviors: { resumed = true }
        )

        let result = await service.move(original, command: .moveToZone(.visible))

        #expect(result.outcome == .succeeded)
        #expect(await dragProbe.executeCount() == 1)
        #expect(liveStatus.iconMoveInProgress == false)
        #expect(liveStatus.lastIconMoveResult == IconMoveOutcome.succeeded.rawValue)
        #expect(suspended)
        #expect(resumed)
        #expect(visibility == .expanded)
    }

    @Test func confirmationSetsMoveGuardBeforeDecisionReturns() async {
        let suiteName = "IconMovePlanningTests.reentrant.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.iconMovingEnabled = true
        store.iconMovingRequireConfirmation = true
        store.iconMovingConfirmationSuppressed = false
        store.iconMovingMaxRetries = 0

        let logger = DiagnosticsLogger()
        let permission = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { true },
            promptTrustProvider: { true },
            systemSettingsOpener: { true }
        )
        let liveStatus = LiveDiagnosticsStatus()
        let dragProbe = AsyncDragProbe()
        let original = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )
        var confirmationCallCount = 0
        var guardWasActiveDuringConfirmation = false
        var visibility: HidingVisibilityState = .collapsed
        var service: IconMoveService!

        service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: ProbeDragExecutor(probe: dragProbe),
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 848, width: 20, height: 24),
                    alwaysHidden: CGRect(x: 200, y: 848, width: 20, height: 24)
                )
            },
            currentVisibilityProvider: { visibility },
            setVisibility: { visibility = $0 },
            refreshSnapshots: { [] },
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: {},
            confirmationHandler: { _, _ in
                confirmationCallCount += 1
                guardWasActiveDuringConfirmation = service.isMoveInProgressForTesting
                return IconMoveConfirmationDecision(confirmed: false, suppressFutureWarnings: false)
            }
        )

        let result = await service.move(original, command: .moveToZone(.visible))

        #expect(result.outcome == .cancelled)
        #expect(result.error == .confirmationCancelled)
        #expect(guardWasActiveDuringConfirmation)
        #expect(confirmationCallCount == 1)
        #expect(await dragProbe.executeCount() == 0)
        #expect(liveStatus.iconMoveInProgress == false)
    }

    @Test func moveServiceReturnsCancelledWhenDragTaskIsCancelled() async {
        let suiteName = "IconMovePlanningTests.cancelled.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.iconMovingEnabled = true
        store.iconMovingRequireConfirmation = false
        store.iconMovingMaxRetries = 0

        let logger = DiagnosticsLogger()
        let permission = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { true },
            promptTrustProvider: { true },
            systemSettingsOpener: { true }
        )
        let liveStatus = LiveDiagnosticsStatus()
        let dragProbe = ControlledDragProbe()
        let original = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )

        var visibility: HidingVisibilityState = .collapsed
        var resumed = false
        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: ControlledDragExecutor(probe: dragProbe),
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 848, width: 20, height: 24),
                    alwaysHidden: CGRect(x: 200, y: 848, width: 20, height: 24)
                )
            },
            currentVisibilityProvider: { visibility },
            setVisibility: { visibility = $0 },
            refreshSnapshots: { [] },
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: { resumed = true }
        )

        let task = Task { @MainActor in
            await service.move(original, command: .moveToZone(.visible))
        }

        await dragProbe.waitForExecute()
        task.cancel()
        await dragProbe.finish(returning: false)

        let result = await task.value

        #expect(result.outcome == .cancelled)
        #expect(result.error == .moveCancelled)
        #expect(liveStatus.lastIconMoveResult == IconMoveOutcome.cancelled.rawValue)
        #expect(liveStatus.lastIconMoveError == IconMoveError.moveCancelled.displayName)
        #expect(liveStatus.iconMoveInProgress == false)
        #expect(resumed)
        #expect(visibility == .collapsed)
    }

    @Test func dragExecutorReleasesMouseWhenCancellationStopsDragMovement() async {
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            Issue.record("Failed to create CGEventSource")
            return
        }

        let recorder = DragEventRecorder()
        let pauser = CountingCancellationPauser(cancelOnCall: 3)
        let executor = DragExecutor(
            eventSourceFactory: { eventSource },
            currentMouseLocationProvider: { _ in CGPoint(x: 44, y: 44) },
            mouseMovePoster: { point, _ in
                recorder.record(.move(point))
            },
            mouseEventPoster: { type, point, _, _ in
                recorder.record(.mouse(type, point))
            },
            pauseHandler: { _ in
                await pauser.pause()
            },
            restoreMousePosition: false
        )
        let plan = DragPlan(
            sourceFrame: CGRect(x: 100, y: 800, width: 24, height: 22),
            targetFrame: CGRect(x: 220, y: 800, width: 24, height: 22),
            sourcePoint: CGPoint(x: 112, y: 811),
            targetPoint: CGPoint(x: 232, y: 811),
            modifierFlags: .maskCommand,
            duration: 0.1,
            retryCount: 0,
            preMoveVisibilityState: .expanded,
            targetZone: .visible
        )

        let succeeded = await executor.execute(plan)
        let events = recorder.snapshot()

        #expect(succeeded == false)
        #expect(events.compactMap(\.mouseType) == [.leftMouseDown, .leftMouseDragged, .leftMouseUp])
        #expect(events.first?.isMove == true)
        #expect(events.last?.mouseType == .leftMouseUp)
        #expect(await pauser.pauseCount() == 3)
    }

    private func makeSnapshot(
        bundleID: String = "com.example.app",
        zone: MenuBarZone,
        title: String = "Status",
        owningApplicationName: String = "Example",
        frame: CGRect? = CGRect(x: 100, y: 850, width: 24, height: 22),
        isSystem: Bool = false
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: UUID().uuidString,
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 42,
            owningApplicationName: owningApplicationName,
            bundleIdentifier: bundleID,
            zone: zone,
            isLikelySystemItem: isSystem,
            scanTimestamp: Date(timeIntervalSince1970: 1)
        )
    }
}

private actor AsyncDragProbe {
    private var count = 0

    func execute(_ plan: DragPlan) async -> Bool {
        count += 1
        await Task.yield()
        return true
    }

    func executeCount() -> Int {
        count
    }
}

nonisolated private struct ProbeDragExecutor: DragExecuting {
    let probe: AsyncDragProbe

    func execute(_ plan: DragPlan) async -> Bool {
        await probe.execute(plan)
    }
}

private actor ControlledDragProbe {
    private var executeCount = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var completion: CheckedContinuation<Bool, Never>?

    func execute(_ plan: DragPlan) async -> Bool {
        await withCheckedContinuation { continuation in
            completion = continuation
            executeCount += 1
            resumeReadyWaiters()
        }
    }

    func waitForExecute() async {
        guard executeCount == 0 else { return }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func finish(returning result: Bool) {
        completion?.resume(returning: result)
        completion = nil
    }

    private func resumeReadyWaiters() {
        guard executeCount > 0 else { return }

        let ready = waiters
        waiters.removeAll()
        for waiter in ready {
            waiter.resume()
        }
    }
}

nonisolated private struct ControlledDragExecutor: DragExecuting {
    let probe: ControlledDragProbe

    func execute(_ plan: DragPlan) async -> Bool {
        await probe.execute(plan)
    }
}

private enum DragExecutorEvent: Equatable {
    case move(CGPoint)
    case mouse(CGEventType, CGPoint)

    var isMove: Bool {
        switch self {
        case .move:
            true
        case .mouse:
            false
        }
    }

    var mouseType: CGEventType? {
        switch self {
        case .move:
            nil
        case .mouse(let type, _):
            type
        }
    }
}

nonisolated private final class DragEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [DragExecutorEvent] = []

    func record(_ event: DragExecutorEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    func snapshot() -> [DragExecutorEvent] {
        lock.lock()
        let snapshot = events
        lock.unlock()
        return snapshot
    }
}

private actor CountingCancellationPauser {
    private let cancelOnCall: Int
    private var count = 0

    init(cancelOnCall: Int) {
        self.cancelOnCall = cancelOnCall
    }

    func pause() async -> Bool {
        count += 1
        await Task.yield()
        return count < cancelOnCall
    }

    func pauseCount() -> Int {
        count
    }
}
