import AppKit
import Foundation

@MainActor
final class IconMoveService {
    private let settingsStore: SettingsStore
    private let permissionService: AccessibilityPermissionService
    private let liveStatus: LiveDiagnosticsStatus
    private let diagnosticsLogger: DiagnosticsLogger
    private let dragExecutor: any DragExecuting
    private let verifier: DragVerificationService
    private let planFactory: DragPlanFactory
    private let screenGeometry: ScreenGeometryService
    private let safetyRules: IconMoveSafetyRules
    private let separatorFramesProvider: () -> MenuBarSeparatorFrames
    private let currentVisibilityProvider: () -> HidingVisibilityState
    private let setVisibility: (HidingVisibilityState) -> Void
    private let refreshSnapshots: @MainActor () async -> [MenuBarItemSnapshot]
    private let suspendRuntimeBehaviors: () -> Void
    private let resumeRuntimeBehaviors: () -> Void
    private let confirmationHandler: (MenuBarItemSnapshot, IconMoveCommand) -> IconMoveConfirmationDecision
    private let now: () -> Date

    private var isMoving = false

#if DEBUG
    var isMoveInProgressForTesting: Bool { isMoving }
#endif

    init(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService,
        liveStatus: LiveDiagnosticsStatus,
        diagnosticsLogger: DiagnosticsLogger,
        dragExecutor: any DragExecuting = DragExecutor(),
        verifier: DragVerificationService = DragVerificationService(),
        planFactory: DragPlanFactory = DragPlanFactory(),
        screenGeometry: ScreenGeometryService = ScreenGeometryService(),
        safetyRules: IconMoveSafetyRules = IconMoveSafetyRules(),
        separatorFramesProvider: @escaping () -> MenuBarSeparatorFrames,
        currentVisibilityProvider: @escaping () -> HidingVisibilityState,
        setVisibility: @escaping (HidingVisibilityState) -> Void,
        refreshSnapshots: @escaping @MainActor () async -> [MenuBarItemSnapshot],
        suspendRuntimeBehaviors: @escaping () -> Void,
        resumeRuntimeBehaviors: @escaping () -> Void,
        confirmationHandler: ((MenuBarItemSnapshot, IconMoveCommand) -> IconMoveConfirmationDecision)? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.permissionService = permissionService
        self.liveStatus = liveStatus
        self.diagnosticsLogger = diagnosticsLogger
        self.dragExecutor = dragExecutor
        self.verifier = verifier
        self.planFactory = planFactory
        self.screenGeometry = screenGeometry
        self.safetyRules = safetyRules
        self.separatorFramesProvider = separatorFramesProvider
        self.currentVisibilityProvider = currentVisibilityProvider
        self.setVisibility = setVisibility
        self.refreshSnapshots = refreshSnapshots
        self.suspendRuntimeBehaviors = suspendRuntimeBehaviors
        self.resumeRuntimeBehaviors = resumeRuntimeBehaviors
        self.confirmationHandler = confirmationHandler ?? { snapshot, command in
            IconMoveService.defaultConfirmation(snapshot: snapshot, command: command)
        }
        self.now = now
    }

    func move(_ snapshot: MenuBarItemSnapshot, command: IconMoveCommand) async -> IconMoveResult {
        switch preflight(snapshot: snapshot, command: command) {
        case .ready(let context):
            return await move(snapshot, command: command, context: context, requiresInternalConfirmation: true)
        case .finished(let result):
            return result
        }
    }

    func moveAfterExternalConfirmation(
        _ snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand
    ) async -> IconMoveResult {
        switch preflight(snapshot: snapshot, command: command) {
        case .ready(let context):
            return await move(snapshot, command: command, context: context, requiresInternalConfirmation: false)
        case .finished(let result):
            return result
        }
    }

    private func move(
        _ snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand,
        context: IconMovePreflightContext,
        requiresInternalConfirmation: Bool
    ) async -> IconMoveResult {
        isMoving = true
        defer {
            isMoving = false
        }

        if requiresInternalConfirmation,
           let cancellation = confirmIfNeeded(
            snapshot: snapshot,
            command: command,
            itemName: context.itemName,
            dogfoodContext: IconMoveDogfoodContext(
                sourceZone: context.sourceZone,
                targetZone: context.targetZone,
                startedAt: context.startedAt,
                moveAttempted: false
            )
        ) {
            return cancellation
        }

        guard !Task.isCancelled else {
            return cancelled(
                command: command,
                itemName: context.itemName,
                error: .moveCancelled,
                dogfoodContext: IconMoveDogfoodContext(
                    sourceZone: context.sourceZone,
                    targetZone: context.targetZone,
                    startedAt: context.startedAt,
                    moveAttempted: false
                )
            )
        }

        let session = beginMoveSession(sourceZone: snapshot.zone, targetZone: context.targetZone)

        defer {
            endMoveSession()
        }

        return await executeWithRetries(
            originalSnapshot: snapshot,
            command: command,
            itemName: context.itemName,
            preMoveVisibility: session.preMoveVisibility,
            dogfoodContext: IconMoveDogfoodContext(
                sourceZone: context.sourceZone,
                targetZone: context.targetZone,
                startedAt: context.startedAt,
                moveAttempted: true
            )
        )
    }

    func resetWarnings() {
        settingsStore.iconMovingConfirmationSuppressed = false
        diagnosticsLogger.log("Icon moving warnings reset.", level: .debug)
    }

    private enum IconMovePreflightResult {
        case ready(IconMovePreflightContext)
        case finished(IconMoveResult)
    }

    private struct IconMovePreflightContext {
        let itemName: String
        let sourceZone: MenuBarZone
        let targetZone: MenuBarZone
        let startedAt: Date
    }

    private struct IconMoveSession {
        let preMoveVisibility: HidingVisibilityState
    }

    private struct IconMoveDogfoodContext {
        let sourceZone: MenuBarZone
        let targetZone: MenuBarZone
        let startedAt: Date
        let moveAttempted: Bool
    }

    private func preflight(
        snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand
    ) -> IconMovePreflightResult {
        let startedAt = now()
        let itemName = displayName(for: snapshot)
        let targetZone = command.targetZone(currentZone: snapshot.zone)
        let dogfoodContext = IconMoveDogfoodContext(
            sourceZone: snapshot.zone,
            targetZone: targetZone,
            startedAt: startedAt,
            moveAttempted: false
        )

        if isMoving {
            return .finished(record(
                .skipped(command: command, itemName: itemName, error: .moveAlreadyInProgress),
                dogfoodContext: dogfoodContext
            ))
        }
        guard settingsStore.iconMovingEnabled else {
            return .finished(record(
                .skipped(command: command, itemName: itemName, error: .disabled),
                dogfoodContext: dogfoodContext
            ))
        }
        guard settingsStore.proModeEnabled else {
            return .finished(record(
                .skipped(command: command, itemName: itemName, error: .proModeRequired),
                dogfoodContext: dogfoodContext
            ))
        }
        guard permissionService.refreshStatus() == .granted else {
            return .finished(record(.skipped(
                command: command,
                itemName: itemName,
                error: .accessibilityPermissionRequired
            ), dogfoodContext: dogfoodContext))
        }
        if let error = safetyRules.validate(
            snapshot: snapshot,
            allowSystemItems: settingsStore.iconMovingAllowSystemItems,
            appBundleIdentifier: AppConstants.bundleIdentifier
        ) {
            return .finished(record(
                .skipped(command: command, itemName: itemName, error: error),
                dogfoodContext: dogfoodContext
            ))
        }

        guard !Task.isCancelled else {
            return .finished(cancelled(
                command: command,
                itemName: itemName,
                error: .moveCancelled,
                dogfoodContext: dogfoodContext
            ))
        }

        return .ready(IconMovePreflightContext(
            itemName: itemName,
            sourceZone: snapshot.zone,
            targetZone: targetZone,
            startedAt: startedAt
        ))
    }

    private func confirmIfNeeded(
        snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand,
        itemName: String,
        dogfoodContext: IconMoveDogfoodContext
    ) -> IconMoveResult? {
        guard settingsStore.iconMovingRequireConfirmation && !settingsStore.iconMovingConfirmationSuppressed else {
            return nil
        }

        let decision = confirmationHandler(snapshot, command)
        if decision.suppressFutureWarnings {
            settingsStore.iconMovingConfirmationSuppressed = true
        }

        guard decision.confirmed else {
            return cancelled(
                command: command,
                itemName: itemName,
                error: .confirmationCancelled,
                dogfoodContext: dogfoodContext
            )
        }

        return nil
    }

    private func beginMoveSession(sourceZone: MenuBarZone, targetZone: MenuBarZone) -> IconMoveSession {
        liveStatus.iconMoveInProgress = true
        suspendRuntimeBehaviors()

        let preMoveVisibility = currentVisibilityProvider()
        revealForMove(sourceZone: sourceZone, targetZone: targetZone)

        return IconMoveSession(preMoveVisibility: preMoveVisibility)
    }

    private func endMoveSession() {
        resumeRuntimeBehaviors()
        liveStatus.iconMoveInProgress = false
    }

    private func executeWithRetries(
        originalSnapshot: MenuBarItemSnapshot,
        command: IconMoveCommand,
        itemName: String,
        preMoveVisibility: HidingVisibilityState,
        dogfoodContext: IconMoveDogfoodContext
    ) async -> IconMoveResult {
        var currentSnapshot = originalSnapshot
        var lastPlan: DragPlan?
        var lastVerification: DragVerificationResult?
        let maxRetries = settingsStore.iconMovingMaxRetries

        for attempt in 0...maxRetries {
            guard !Task.isCancelled else {
                return cancelled(
                    command: command,
                    itemName: itemName,
                    error: .moveCancelled,
                    plan: lastPlan,
                    verification: lastVerification,
                    retries: attempt,
                    restoreVisibility: preMoveVisibility,
                    dogfoodContext: dogfoodContext
                )
            }

            do {
                let plan = try makePlan(
                    snapshot: currentSnapshot,
                    command: command,
                    preMoveVisibility: preMoveVisibility,
                    retryCount: attempt
                )
                lastPlan = plan
                liveStatus.lastIconMoveDragPlanSummary = plan.summary
                diagnosticsLogger.log("Icon move plan: \(plan.summary)", level: .debug)

                guard await dragExecutor.execute(plan) else {
                    if Task.isCancelled {
                        return cancelled(
                            command: command,
                            itemName: itemName,
                            error: .moveCancelled,
                            plan: lastPlan,
                            verification: lastVerification,
                            retries: attempt,
                            restoreVisibility: preMoveVisibility,
                            dogfoodContext: dogfoodContext
                        )
                    }

                    return fail(
                        command: command,
                        itemName: itemName,
                        error: .dragFailed,
                        plan: lastPlan,
                        verification: lastVerification,
                        retries: attempt,
                        restoreVisibility: preMoveVisibility,
                        dogfoodContext: dogfoodContext
                    )
                }

                guard await AsyncPause.sleep(0.18) else {
                    return cancelled(
                        command: command,
                        itemName: itemName,
                        error: .moveCancelled,
                        plan: lastPlan,
                        verification: lastVerification,
                        retries: attempt,
                        restoreVisibility: preMoveVisibility,
                        dogfoodContext: dogfoodContext
                    )
                }

                let rescanned = await refreshSnapshots()
                let verification = verifier.verify(
                    original: originalSnapshot,
                    targetZone: plan.targetZone,
                    rescannedSnapshots: rescanned
                )
                lastVerification = verification
                liveStatus.lastIconMoveVerificationSummary = verification.summary

                if verification.isSuccess {
                    // Successful moves keep the bar revealed so the user can see the new icon position.
                    // Failure and cancellation paths restore the captured pre-move visibility.
                    let result = IconMoveResult(
                        outcome: .succeeded,
                        command: command,
                        itemName: itemName,
                        error: nil,
                        dragPlanSummary: plan.summary,
                        verificationSummary: verification.summary,
                        retries: attempt
                    )
                    return record(result, dogfoodContext: dogfoodContext)
                }

                if let updated = verification.matchedSnapshot {
                    currentSnapshot = updated
                }
            } catch let error as IconMoveError {
                return fail(
                    command: command,
                    itemName: itemName,
                    error: error,
                    plan: lastPlan,
                    verification: lastVerification,
                    retries: attempt,
                    restoreVisibility: preMoveVisibility,
                    dogfoodContext: dogfoodContext
                )
            } catch {
                return fail(
                    command: command,
                    itemName: itemName,
                    error: .planningFailed,
                    plan: lastPlan,
                    verification: lastVerification,
                    retries: attempt,
                    restoreVisibility: preMoveVisibility,
                    dogfoodContext: dogfoodContext
                )
            }
        }

        return fail(
            command: command,
            itemName: itemName,
            error: .verificationFailed,
            plan: lastPlan,
            verification: lastVerification,
            retries: maxRetries,
            restoreVisibility: preMoveVisibility,
            dogfoodContext: dogfoodContext
        )
    }

    private func makePlan(
        snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand,
        preMoveVisibility: HidingVisibilityState,
        retryCount: Int
    ) throws -> DragPlan {
        let frames = separatorFramesProvider()
        let screenFrame = screenGeometry.screenFrame(intersecting: snapshot.frame ?? .zero)

        return try planFactory.plan(
            for: snapshot,
            command: command,
            context: DragPlanningContext(
                primarySeparatorFrame: frames.primary,
                alwaysHiddenSeparatorFrame: frames.alwaysHidden,
                screenFrame: screenFrame
            ),
            preMoveVisibilityState: preMoveVisibility,
            duration: settingsStore.iconMovingDragDuration,
            retryCount: retryCount
        )
    }

    private func revealForMove(sourceZone: MenuBarZone, targetZone: MenuBarZone) {
        if sourceZone == .unknown || targetZone == .unknown {
            setVisibility(.revealAll)
        } else if sourceZone == .alwaysHidden || targetZone == .alwaysHidden {
            setVisibility(.revealAll)
        } else if sourceZone == .hidden || targetZone == .hidden {
            setVisibility(.expanded)
        }
    }

    private func fail(
        command: IconMoveCommand,
        itemName: String,
        error: IconMoveError,
        plan: DragPlan?,
        verification: DragVerificationResult?,
        retries: Int,
        restoreVisibility: HidingVisibilityState,
        dogfoodContext: IconMoveDogfoodContext
    ) -> IconMoveResult {
        setVisibility(restoreVisibility)
        return record(IconMoveResult(
            outcome: .failed,
            command: command,
            itemName: itemName,
            error: error,
            dragPlanSummary: plan?.summary,
            verificationSummary: verification?.summary,
            retries: retries
        ), dogfoodContext: dogfoodContext)
    }

    private func cancelled(
        command: IconMoveCommand,
        itemName: String,
        error: IconMoveError,
        plan: DragPlan? = nil,
        verification: DragVerificationResult? = nil,
        retries: Int = 0,
        restoreVisibility: HidingVisibilityState? = nil,
        dogfoodContext: IconMoveDogfoodContext
    ) -> IconMoveResult {
        if let restoreVisibility {
            setVisibility(restoreVisibility)
        }

        return record(IconMoveResult(
            outcome: .cancelled,
            command: command,
            itemName: itemName,
            error: error,
            dragPlanSummary: plan?.summary,
            verificationSummary: verification?.summary,
            retries: retries
        ), dogfoodContext: dogfoodContext)
    }

    private func record(
        _ result: IconMoveResult,
        dogfoodContext: IconMoveDogfoodContext? = nil
    ) -> IconMoveResult {
        liveStatus.lastIconMoveResult = result.outcome.rawValue
        liveStatus.lastIconMoveError = result.error?.displayName
        liveStatus.lastIconMoveDragPlanSummary = result.dragPlanSummary
        liveStatus.lastIconMoveVerificationSummary = result.verificationSummary
        liveStatus.lastIconMoveRetriesCount = result.retries
        diagnosticsLogger.log(result.summary, level: result.outcome == .succeeded ? .info : .warning)

        if let dogfoodContext {
            let event = AssistedMoveDogfoodLogEvent(
                moveAttempted: dogfoodContext.moveAttempted,
                sourceZone: dogfoodContext.sourceZone,
                targetZone: dogfoodContext.targetZone,
                result: result.outcome,
                failureReason: result.error,
                durationBucket: .bucket(for: now().timeIntervalSince(dogfoodContext.startedAt))
            )
            diagnosticsLogger.log(
                "Assisted Move dogfood event recorded.",
                level: result.outcome == .succeeded ? .info : .warning,
                category: .dogfood,
                metadata: event.metadata
            )
        }

        return result
    }

    private func displayName(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }

    private static func defaultConfirmation(
        snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand
    ) -> IconMoveConfirmationDecision {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Move menu bar icon?"
        alert.informativeText = """
        MenuBarDeclutter will simulate a Command-drag for "\(snapshot.owningApplicationName ?? snapshot.title ?? "this item")". This may fail depending on the app or system item. The move starts only because you requested it.
        """
        alert.addButton(withTitle: command.displayName)
        alert.addButton(withTitle: "Cancel")
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Do not show this warning again"

        let response = alert.runModal()
        return IconMoveConfirmationDecision(
            confirmed: response == .alertFirstButtonReturn,
            suppressFutureWarnings: alert.suppressionButton?.state == .on
        )
    }
}
