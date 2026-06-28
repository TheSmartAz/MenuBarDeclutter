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
    private let refreshSnapshots: () -> [MenuBarItemSnapshot]
    private let suspendRuntimeBehaviors: () -> Void
    private let resumeRuntimeBehaviors: () -> Void
    private let confirmationHandler: (MenuBarItemSnapshot, IconMoveCommand) -> IconMoveConfirmationDecision

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
        refreshSnapshots: @escaping () -> [MenuBarItemSnapshot],
        suspendRuntimeBehaviors: @escaping () -> Void,
        resumeRuntimeBehaviors: @escaping () -> Void,
        confirmationHandler: ((MenuBarItemSnapshot, IconMoveCommand) -> IconMoveConfirmationDecision)? = nil
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
    }

    func move(_ snapshot: MenuBarItemSnapshot, command: IconMoveCommand) async -> IconMoveResult {
        let itemName = displayName(for: snapshot)
        let targetZone = command.targetZone(currentZone: snapshot.zone)

        if isMoving {
            return record(.skipped(command: command, itemName: itemName, error: .moveAlreadyInProgress))
        }
        guard settingsStore.iconMovingEnabled else {
            return record(.skipped(command: command, itemName: itemName, error: .disabled))
        }
        guard settingsStore.proModeEnabled else {
            return record(.skipped(command: command, itemName: itemName, error: .proModeRequired))
        }
        guard permissionService.refreshStatus() == .granted else {
            return record(.skipped(command: command, itemName: itemName, error: .accessibilityPermissionRequired))
        }
        if let error = safetyRules.validate(
            snapshot: snapshot,
            allowSystemItems: settingsStore.iconMovingAllowSystemItems,
            appBundleIdentifier: AppConstants.bundleIdentifier
        ) {
            return record(.skipped(command: command, itemName: itemName, error: error))
        }

        guard !Task.isCancelled else {
            return cancelled(command: command, itemName: itemName, error: .moveCancelled)
        }

        isMoving = true
        defer {
            isMoving = false
        }

        if settingsStore.iconMovingRequireConfirmation && !settingsStore.iconMovingConfirmationSuppressed {
            let decision = confirmationHandler(snapshot, command)
            if decision.suppressFutureWarnings {
                settingsStore.iconMovingConfirmationSuppressed = true
            }
            guard decision.confirmed else {
                return cancelled(command: command, itemName: itemName, error: .confirmationCancelled)
            }
        }

        guard !Task.isCancelled else {
            return cancelled(command: command, itemName: itemName, error: .moveCancelled)
        }

        liveStatus.iconMoveInProgress = true
        suspendRuntimeBehaviors()
        let preMoveVisibility = currentVisibilityProvider()
        revealForMove(sourceZone: snapshot.zone, targetZone: targetZone)

        defer {
            resumeRuntimeBehaviors()
            liveStatus.iconMoveInProgress = false
        }

        var currentSnapshot = snapshot
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
                    restoreVisibility: preMoveVisibility
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
                            restoreVisibility: preMoveVisibility
                        )
                    }

                    return fail(
                        command: command,
                        itemName: itemName,
                        error: .dragFailed,
                        plan: lastPlan,
                        verification: lastVerification,
                        retries: attempt,
                        restoreVisibility: preMoveVisibility
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
                        restoreVisibility: preMoveVisibility
                    )
                }

                let rescanned = refreshSnapshots()
                let verification = verifier.verify(
                    original: snapshot,
                    targetZone: plan.targetZone,
                    rescannedSnapshots: rescanned
                )
                lastVerification = verification
                liveStatus.lastIconMoveVerificationSummary = verification.summary

                if verification.isSuccess {
                    let result = IconMoveResult(
                        outcome: .succeeded,
                        command: command,
                        itemName: itemName,
                        error: nil,
                        dragPlanSummary: plan.summary,
                        verificationSummary: verification.summary,
                        retries: attempt
                    )
                    return record(result)
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
                    restoreVisibility: preMoveVisibility
                )
            } catch {
                return fail(
                    command: command,
                    itemName: itemName,
                    error: .planningFailed,
                    plan: lastPlan,
                    verification: lastVerification,
                    retries: attempt,
                    restoreVisibility: preMoveVisibility
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
            restoreVisibility: preMoveVisibility
        )
    }

    func resetWarnings() {
        settingsStore.iconMovingConfirmationSuppressed = false
        diagnosticsLogger.log("Icon moving warnings reset.", level: .debug)
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
        if sourceZone == .alwaysHidden || targetZone == .alwaysHidden {
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
        restoreVisibility: HidingVisibilityState
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
        ))
    }

    private func cancelled(
        command: IconMoveCommand,
        itemName: String,
        error: IconMoveError,
        plan: DragPlan? = nil,
        verification: DragVerificationResult? = nil,
        retries: Int = 0,
        restoreVisibility: HidingVisibilityState? = nil
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
        ))
    }

    private func record(_ result: IconMoveResult) -> IconMoveResult {
        liveStatus.lastIconMoveResult = result.outcome.rawValue
        liveStatus.lastIconMoveError = result.error?.displayName
        liveStatus.lastIconMoveDragPlanSummary = result.dragPlanSummary
        liveStatus.lastIconMoveVerificationSummary = result.verificationSummary
        liveStatus.lastIconMoveRetriesCount = result.retries
        diagnosticsLogger.log(result.summary, level: result.outcome == .succeeded ? .info : .warning)
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
