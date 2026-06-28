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

    private func makeSnapshot(
        bundleID: String = "com.example.app",
        zone: MenuBarZone,
        frame: CGRect? = CGRect(x: 100, y: 850, width: 24, height: 22),
        isSystem: Bool = false
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: UUID().uuidString,
            title: "Status",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: 42,
            owningApplicationName: "Example",
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
