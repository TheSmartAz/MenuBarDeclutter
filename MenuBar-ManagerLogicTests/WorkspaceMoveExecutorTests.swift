import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

private func makeSnap(bundle: String, zone: MenuBarZone = .hidden) -> MenuBarItemSnapshot {
    MenuBarItemSnapshot(
        title: "T",
        role: "AXMenuBarItem",
        subrole: nil,
        frame: CGRect(x: 0, y: 0, width: 20, height: 20),
        owningProcessIdentifier: 1,
        owningApplicationName: "App",
        bundleIdentifier: bundle,
        zone: zone,
        isLikelySystemItem: false,
        scanTimestamp: Date(timeIntervalSince1970: 1)
    )
}

private func makeResult(_ outcome: IconMoveOutcome) -> IconMoveResult {
    IconMoveResult(
        outcome: outcome,
        command: .moveToZone(.visible),
        itemName: "x",
        error: nil,
        dragPlanSummary: nil,
        verificationSummary: nil,
        retries: 0
    )
}

@MainActor
@Suite("Workspace Move Executor")
struct WorkspaceMoveExecutorTests {
    @Test func resolvesKeyToCorrectSnapshotAndReportsSuccess() async {
        let a = makeSnap(bundle: "com.a")
        let b = makeSnap(bundle: "com.b")
        let executor = WorkspaceMoveExecutor(
            scan: { [a, b] },
            // Succeeds only if the adapter resolved the intended snapshot (com.a).
            performMove: { snapshot, _ in
                makeResult(snapshot.bundleIdentifier == "com.a" ? .succeeded : .failed)
            }
        )

        let ok = await executor.move(itemKey: WorkspaceItemKey.key(for: a), command: .moveToZone(.hidden))
        #expect(ok)
    }

    @Test func returnsFalseWhenItemAbsent() async {
        let executor = WorkspaceMoveExecutor(
            scan: { [makeSnap(bundle: "com.a")] },
            // Would report success if it were ever reached.
            performMove: { _, _ in makeResult(.succeeded) }
        )

        let ok = await executor.move(itemKey: "bundle:com.missing", command: .moveToZone(.hidden))
        #expect(!ok)
    }

    @Test func mapsNonSuccessOutcomesToFalse() async {
        for outcome in [IconMoveOutcome.failed, .skipped, .cancelled] {
            let a = makeSnap(bundle: "com.a")
            let executor = WorkspaceMoveExecutor(
                scan: { [a] },
                performMove: { _, _ in makeResult(outcome) }
            )
            let ok = await executor.move(itemKey: WorkspaceItemKey.key(for: a), command: .moveToZone(.hidden))
            #expect(!ok)
        }
    }
}
