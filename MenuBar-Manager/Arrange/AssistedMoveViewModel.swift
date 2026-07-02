import Foundation
import Observation

nonisolated enum AssistedMoveDryRunStatus: String, Equatable, Sendable {
    case blocked
    case ready
}

nonisolated struct AssistedMoveFlowContext: Equatable, Sendable {
    let proModeEnabled: Bool
    let accessibilityDiscoveryEnabled: Bool
    let accessibilityPermissionGranted: Bool
    let iconMovingEnabled: Bool
    let safeModeActive: Bool
    let allowSystemItems: Bool
    let firstUseConfirmationAccepted: Bool
    let perMoveConfirmationAccepted: Bool
    let appBundleIdentifier: String

    var gateContext: AssistedMoveGateContext {
        AssistedMoveGateContext(
            proModeEnabled: proModeEnabled,
            accessibilityDiscoveryEnabled: accessibilityDiscoveryEnabled,
            accessibilityPermissionGranted: accessibilityPermissionGranted,
            iconMovingEnabled: iconMovingEnabled,
            safeModeActive: safeModeActive,
            allowSystemItems: allowSystemItems,
            firstUseConfirmationAccepted: firstUseConfirmationAccepted,
            perMoveConfirmationAccepted: perMoveConfirmationAccepted,
            appBundleIdentifier: appBundleIdentifier
        )
    }
}

nonisolated struct AssistedMoveDryRunPlan: Equatable, Sendable {
    let itemID: String
    let displayTitle: String
    let currentZone: MenuBarZone
    let targetZone: AssistedMoveTargetZone
    let command: IconMoveCommand
    let gateResult: AssistedMoveGateResult
    let status: AssistedMoveDryRunStatus
    let summary: String
    let plannedDragDirection: String
    let riskReason: String
    let steps: [String]
    let recoveryActions: [String]
    let diagnosticSummary: String
    let isDiagnosticsRedacted: Bool

    var canExecute: Bool {
        status == .ready && gateResult.isAvailable
    }
}

nonisolated struct AssistedMoveDryRunBuilder {
    func plan(
        snapshot: MenuBarItemSnapshot,
        targetZone: AssistedMoveTargetZone,
        context: AssistedMoveFlowContext
    ) -> AssistedMoveDryRunPlan {
        let gateResult = AssistedMoveGate().evaluate(
            snapshot: snapshot,
            targetZone: targetZone,
            context: context.gateContext
        )
        let command = IconMoveCommand.moveToZone(targetZone.menuBarZone)
        let status: AssistedMoveDryRunStatus = gateResult.isAvailable ? .ready : .blocked
        let displayTitle = Self.displayTitle(for: snapshot)

        return AssistedMoveDryRunPlan(
            itemID: snapshot.id,
            displayTitle: displayTitle,
            currentZone: snapshot.zone,
            targetZone: targetZone,
            command: command,
            gateResult: gateResult,
            status: status,
            summary: "Dry-run only for \(displayTitle): review a move to \(targetZone.menuBarZone.displayName).",
            plannedDragDirection: Self.plannedDragDirection(
                currentZone: snapshot.zone,
                targetZone: targetZone.menuBarZone
            ),
            riskReason: Self.riskReason(
                snapshot: snapshot,
                gateResult: gateResult
            ),
            steps: Self.steps(
                currentZone: snapshot.zone,
                targetZone: targetZone.menuBarZone
            ),
            recoveryActions: Self.recoveryActions,
            diagnosticSummary: "Assisted Move dry-run: target=\(targetZone.rawValue), failures=\(gateResult.failures.count), redacted=true.",
            isDiagnosticsRedacted: true
        )
    }

    private static func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier,
            snapshot.zone.displayName
        ]) ?? "Menu Bar Item"
    }

    private static func steps(
        currentZone: MenuBarZone,
        targetZone: MenuBarZone
    ) -> [String] {
        [
            "Identify one source item in \(currentZone.displayName).",
            "Confirm the target zone is \(targetZone.displayName).",
            "Check whether source and target zones need to be revealed first.",
            "Review the planned Command-drag path. No CGEvent is posted during dry-run.",
            "If you choose Try Assisted Move later, refresh local Accessibility metadata and verify the target zone.",
            "On failure, restore previous reveal behavior and use recovery actions."
        ]
    }

    private static func plannedDragDirection(
        currentZone: MenuBarZone,
        targetZone: MenuBarZone
    ) -> String {
        switch (currentZone, targetZone) {
        case (.hidden, .visible), (.alwaysHidden, .visible), (.alwaysHidden, .hidden):
            "right"
        case (.visible, .hidden), (.visible, .alwaysHidden), (.hidden, .alwaysHidden):
            "left"
        case (.unknown, _), (_, .unknown):
            "unknown until zones are revealed"
        default:
            "same zone"
        }
    }

    private static func riskReason(
        snapshot: MenuBarItemSnapshot,
        gateResult: AssistedMoveGateResult
    ) -> String {
        if let firstFailure = gateResult.failures.first {
            return firstFailure.title
        }

        if snapshot.isLikelySystemItem {
            return "Likely system item"
        }

        if snapshot.frame == nil {
            return "Missing item frame"
        }

        return "Experimental single-item Command-drag; verify after any attempt."
    }

    private static let recoveryActions = [
        "Reveal all items.",
        "Reset layout.",
        "Retry dry-run.",
        "Open Guided Manual Arrange.",
        "Export diagnostics from Recovery."
    ]
}

@MainActor
@Observable
final class AssistedMoveViewModel {
    var selectedItemID: MenuBarItemSnapshot.ID?
    var targetZone: AssistedMoveTargetZone = .hidden
    var firstUseConfirmationAccepted = false
    var perMoveConfirmationAccepted = false
    var lastDryRun: AssistedMoveDryRunPlan?
    var lastCommandResult: MenuBarCommandResult?
    var lastMoveResult: IconMoveResult?
    var isExecuting = false

    private let builder: AssistedMoveDryRunBuilder

    init(builder: AssistedMoveDryRunBuilder = AssistedMoveDryRunBuilder()) {
        self.builder = builder
    }

    func refreshSelection(from snapshots: [MenuBarItemSnapshot]) {
        guard !snapshots.isEmpty else {
            selectedItemID = nil
            lastDryRun = nil
            return
        }

        let ids = Set(snapshots.map(\.id))
        if selectedItemID.map({ ids.contains($0) }) != true {
            selectedItemID = snapshots.first?.id
            lastDryRun = nil
        }
    }

    func selectedSnapshot(in snapshots: [MenuBarItemSnapshot]) -> MenuBarItemSnapshot? {
        guard let selectedItemID else { return snapshots.first }
        return snapshots.first { $0.id == selectedItemID } ?? snapshots.first
    }

    @discardableResult
    func generateDryRun(
        snapshot: MenuBarItemSnapshot,
        context: AssistedMoveFlowContext
    ) -> AssistedMoveDryRunPlan {
        let plan = builder.plan(
            snapshot: snapshot,
            targetZone: targetZone,
            context: context
        )
        lastDryRun = plan
        lastMoveResult = nil
        return plan
    }

    func beginExecution() {
        isExecuting = true
        lastMoveResult = nil
    }

    func finishExecution(result: IconMoveResult) {
        lastMoveResult = result
        isExecuting = false
    }

    func cancel(commandResult: MenuBarCommandResult?) {
        lastCommandResult = commandResult
        lastDryRun = nil
        lastMoveResult = nil
        isExecuting = false
    }
}
