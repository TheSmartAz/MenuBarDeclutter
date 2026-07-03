import AppKit
import ApplicationServices
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

    @Test func moveServiceAwaitsFreshSnapshotsBeforeVerifying() async {
        let suiteName = "IconMovePlanningTests.freshScan.\(UUID().uuidString)"
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

        var refreshStarted = false
        var refreshCompleted = false
        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: ProbeDragExecutor(probe: dragProbe),
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 848, width: 20, height: 24),
                    alwaysHidden: nil
                )
            },
            currentVisibilityProvider: { .collapsed },
            setVisibility: { _ in },
            refreshSnapshots: {
                refreshStarted = true
                try? await Task.sleep(nanoseconds: 50_000_000)
                refreshCompleted = true
                return [moved]
            },
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: {}
        )

        let result = await service.move(original, command: .moveToZone(.visible))

        #expect(result.outcome == .succeeded)
        #expect(refreshStarted)
        #expect(refreshCompleted)
        #expect(result.verificationSummary == "Expected Visible: Succeeded")
    }

    @Test func moveServiceRecordsPrivacySafeDogfoodEventWhenBlocked() async throws {
        let suiteName = "IconMovePlanningTests.dogfood.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.iconMovingEnabled = false

        let logger = DiagnosticsLogger()
        let permission = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { true },
            promptTrustProvider: { true },
            systemSettingsOpener: { true }
        )
        let liveStatus = LiveDiagnosticsStatus()
        let snapshot = makeSnapshot(
            bundleID: "com.example.private",
            zone: .hidden,
            title: "Private Title",
            owningApplicationName: "Private App",
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )

        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            separatorFramesProvider: {
                MenuBarSeparatorFrames(primary: nil, alwaysHidden: nil)
            },
            currentVisibilityProvider: { .collapsed },
            setVisibility: { _ in },
            refreshSnapshots: { [] },
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: {},
            now: { Date(timeIntervalSince1970: 10) }
        )

        let result = await service.move(snapshot, command: .moveToZone(.visible))
        let event = try #require(logger.events.last { $0.category == .dogfood })

        #expect(result.outcome == .skipped)
        #expect(event.message == "Assisted Move dogfood event recorded.")
        #expect(event.metadata["moveAttempted"] == "false")
        #expect(event.metadata["sourceZone"] == "hidden")
        #expect(event.metadata["targetZone"] == "visible")
        #expect(event.metadata["result"] == "skipped")
        #expect(event.metadata["failureReason"] == "disabled")
        #expect(event.metadata["durationBucket"] == "underOneSecond")
        #expect(event.metadata["redacted"] == "true")
        #expect(!event.metadata.values.contains("Private Title"))
        #expect(!event.metadata.values.contains("Private App"))
        #expect(!event.metadata.values.contains("com.example.private"))
    }

    @Test func moveServiceRevealsAllForUnknownZoneMoves() async {
        let suiteName = "IconMovePlanningTests.unknownZoneReveal.\(UUID().uuidString)"
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
            zone: .unknown,
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )
        let moved = makeSnapshot(
            bundleID: "com.example.move",
            zone: .visible,
            frame: CGRect(x: 560, y: 850, width: 24, height: 22)
        )

        var visibility: HidingVisibilityState = .collapsed
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
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: {}
        )

        let result = await service.move(original, command: .moveToZone(.visible))

        #expect(result.outcome == .succeeded)
        #expect(await dragProbe.executeCount() == 1)
        #expect(visibility == .revealAll)
    }

    @Test func moveServiceRestoresVisibilityWhenDragFails() async {
        let suiteName = "IconMovePlanningTests.dragFailed.\(UUID().uuidString)"
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
        let original = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )

        var visibility: HidingVisibilityState = .collapsed
        var visibilityChanges: [HidingVisibilityState] = []
        var resumed = false
        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: FailingDragExecutor(),
            separatorFramesProvider: {
                MenuBarSeparatorFrames(
                    primary: CGRect(x: 500, y: 848, width: 20, height: 24),
                    alwaysHidden: CGRect(x: 200, y: 848, width: 20, height: 24)
                )
            },
            currentVisibilityProvider: { visibility },
            setVisibility: { newVisibility in
                visibility = newVisibility
                visibilityChanges.append(newVisibility)
            },
            refreshSnapshots: { [] },
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: { resumed = true }
        )

        let result = await service.move(original, command: .moveToZone(.visible))

        #expect(result.outcome == .failed)
        #expect(result.error == .dragFailed)
        #expect(liveStatus.iconMoveInProgress == false)
        #expect(liveStatus.lastIconMoveResult == IconMoveOutcome.failed.rawValue)
        #expect(resumed)
        #expect(visibility == .collapsed)
        #expect(visibilityChanges == [.expanded, .collapsed])
    }

    @Test func moveServicePlansWithInjectedScreenGeometry() async {
        let suiteName = "IconMovePlanningTests.geometry.\(UUID().uuidString)"
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
        let screenFrame = CGRect(x: 0, y: 0, width: 300, height: 900)
        let screenGeometry = ScreenGeometryService(
            widthsProvider: { [300] },
            screenFramesProvider: { [screenFrame] },
            primaryScreenFrameProvider: { screenFrame }
        )
        let original = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            frame: CGRect(x: 260, y: 850, width: 24, height: 22)
        )
        let moved = makeSnapshot(
            bundleID: "com.example.move",
            zone: .hidden,
            frame: CGRect(x: 276, y: 850, width: 24, height: 22)
        )

        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: ProbeDragExecutor(probe: dragProbe),
            screenGeometry: screenGeometry,
            separatorFramesProvider: {
                MenuBarSeparatorFrames(primary: nil, alwaysHidden: nil)
            },
            currentVisibilityProvider: { .expanded },
            setVisibility: { _ in },
            refreshSnapshots: { [moved] },
            suspendRuntimeBehaviors: {},
            resumeRuntimeBehaviors: {}
        )

        let result = await service.move(original, command: .moveRight)
        let plan = await dragProbe.lastPlan()

        #expect(result.outcome == .succeeded)
        #expect(plan?.targetFrame.maxX == screenFrame.maxX)
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

    @Test func liveDogfoodMovesOneFixtureItemWhenExplicitlyEnabled() async throws {
        guard Self.liveDogfoodRunIsExplicitlyEnabled() else {
            return
        }

        #expect(AXIsProcessTrusted())

        let fixtureApp = try #require(
            NSWorkspace.shared.runningApplications.first { application in
                application.localizedName == "MenuBarFixtureApp"
            }
        )
        let snapshots = Self.fixtureSnapshots(for: fixtureApp)
        let target = try #require(snapshots.first {
            $0.title == "Long" && $0.frame != nil && !$0.isLikelySystemItem
        })
        let beforeFrame = try #require(target.frame)

        let suiteName = "IconMovePlanningTests.liveDogfood.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        store.iconMovingEnabled = true
        store.iconMovingRequireConfirmation = false
        store.iconMovingMaxRetries = 0
        store.iconMovingDragDuration = 0.25

        let logger = DiagnosticsLogger()
        let permission = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { true },
            promptTrustProvider: { true },
            systemSettingsOpener: { true }
        )
        let liveStatus = LiveDiagnosticsStatus()
        var visibility: HidingVisibilityState = .expanded
        var didSuspendRuntime = false
        var didResumeRuntime = false

        let service = IconMoveService(
            settingsStore: store,
            permissionService: permission,
            liveStatus: liveStatus,
            diagnosticsLogger: logger,
            dragExecutor: DragExecutor(restoreMousePosition: true),
            separatorFramesProvider: {
                MenuBarSeparatorFrames(primary: nil, alwaysHidden: nil)
            },
            currentVisibilityProvider: { visibility },
            setVisibility: { visibility = $0 },
            refreshSnapshots: {
                Self.fixtureSnapshots(for: fixtureApp)
            },
            suspendRuntimeBehaviors: { didSuspendRuntime = true },
            resumeRuntimeBehaviors: { didResumeRuntime = true }
        )

        let result = await service.move(target, command: .moveRight)
        let after = try #require(
            Self.fixtureSnapshots(for: fixtureApp).first {
                DragVerificationService.matches(original: target, candidate: $0)
            }
        )
        let afterFrame = try #require(after.frame)
        let movedDistance = abs(afterFrame.midX - beforeFrame.midX)
        let dogfoodEvent = try #require(logger.events.last { $0.category == .dogfood })

        #expect(result.outcome == .succeeded)
        #expect(movedDistance >= 4)
        #expect(liveStatus.iconMoveInProgress == false)
        #expect(didSuspendRuntime)
        #expect(didResumeRuntime)
        #expect(dogfoodEvent.message == "Assisted Move dogfood event recorded.")
        #expect(dogfoodEvent.metadata["moveAttempted"] == "true")
        #expect(dogfoodEvent.metadata["sourceZone"] == "visible")
        #expect(dogfoodEvent.metadata["targetZone"] == "visible")
        #expect(dogfoodEvent.metadata["result"] == "succeeded")
        #expect(dogfoodEvent.metadata["redacted"] == "true")
        #expect(!dogfoodEvent.metadata.values.contains("Long"))
        #expect(!dogfoodEvent.metadata.values.contains(fixtureApp.bundleIdentifier ?? ""))
    }

    private static func liveDogfoodRunIsExplicitlyEnabled() -> Bool {
        ProcessInfo.processInfo.environment["MBD_LIVE_ICON_MOVE_DOGFOOD_TEST"] == "1"
            || FileManager.default.fileExists(atPath: "/tmp/MenuBarDeclutter-live-icon-move-dogfood.enabled")
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

    private static func fixtureSnapshots(for application: NSRunningApplication) -> [MenuBarItemSnapshot] {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let root = readElement(appElement, attribute: "AXExtrasMenuBar") else {
            return []
        }

        return readChildren(root).compactMap { element in
            let role = readString(element, attribute: kAXRoleAttribute as String)
            let title = DisplayString.firstNonEmpty([
                readString(element, attribute: kAXTitleAttribute as String),
                readString(element, attribute: kAXDescriptionAttribute as String),
                readString(element, attribute: "AXIdentifier")
            ])
            let frame = readFrame(element)
            guard role == "AXMenuBarItem", frame != nil else {
                return nil
            }

            return MenuBarItemSnapshot(
                title: title,
                role: role,
                subrole: readString(element, attribute: kAXSubroleAttribute as String),
                frame: frame,
                owningProcessIdentifier: application.processIdentifier,
                owningApplicationName: application.localizedName,
                bundleIdentifier: application.bundleIdentifier,
                zone: .visible,
                isLikelySystemItem: false,
                scanTimestamp: Date()
            )
        }
    }

    private static func readString(_ element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value else {
            return nil
        }
        return value as? String
    }

    private static func readElement(_ element: AXUIElement, attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    private static func readChildren(_ element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
              let value else {
            return []
        }
        return value as? [AXUIElement] ?? []
    }

    private static func readFrame(_ element: AXUIElement) -> CGRect? {
        guard let position = readCGPoint(element, attribute: kAXPositionAttribute as String),
              let size = readCGSize(element, attribute: kAXSizeAttribute as String) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private static func readCGPoint(_ element: AXUIElement, attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = unsafeDowncast(value, to: AXValue.self)
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    private static func readCGSize(_ element: AXUIElement, attribute: String) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = unsafeDowncast(value, to: AXValue.self)
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }
}

private actor AsyncDragProbe {
    private var count = 0
    private var plan: DragPlan?

    func execute(_ plan: DragPlan) async -> Bool {
        count += 1
        self.plan = plan
        await Task.yield()
        return true
    }

    func executeCount() -> Int {
        count
    }

    func lastPlan() -> DragPlan? {
        plan
    }
}

nonisolated private struct ProbeDragExecutor: DragExecuting {
    let probe: AsyncDragProbe

    func execute(_ plan: DragPlan) async -> Bool {
        await probe.execute(plan)
    }
}

nonisolated private struct FailingDragExecutor: DragExecuting {
    func execute(_ plan: DragPlan) async -> Bool {
        false
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
