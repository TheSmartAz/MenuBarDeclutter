import Foundation
import Testing
@testable import MenuBarDeclutter

@MainActor
@Suite("Move Outcome Store")
struct MoveOutcomeStoreTests {
    private func makeTempPaths() -> (AppSupportPaths, URL) {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("MoveOutcomeStoreTests-\(UUID().uuidString)", isDirectory: true)
        return (AppSupportPaths(baseURL: base), base)
    }

    private func makeOutcome(retries: Int) -> MoveOutcome {
        MoveOutcome(
            timestamp: Date(timeIntervalSince1970: 1_000_000 + Double(retries)),
            appBundleIdentifier: "com.example.move",
            appDisplayName: "Example",
            commandKind: .toZone,
            sourceZone: .hidden,
            targetZone: .visible,
            moveAttempted: true,
            result: .succeeded,
            verification: .succeeded,
            failureReason: nil,
            retries: retries,
            latencySeconds: 0.5
        )
    }

    @Test func recordsPersistAcrossStoreInstances() {
        let (paths, base) = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: base) }

        let writer = MoveOutcomeStore(appSupportPaths: paths)
        writer.record(makeOutcome(retries: 0))
        writer.record(makeOutcome(retries: 1))
        #expect(writer.lastError == nil)

        let reader = MoveOutcomeStore(appSupportPaths: paths)
        #expect(reader.outcomes.count == 2)
        #expect(reader.outcomes.map(\.retries) == [0, 1])
    }

    @Test func enforcesRetentionCapKeepingMostRecent() {
        let (paths, base) = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: base) }

        let store = MoveOutcomeStore(appSupportPaths: paths, maxOutcomes: 3)
        for retries in 0..<5 {
            store.record(makeOutcome(retries: retries))
        }

        #expect(store.outcomes.count == 3)
        #expect(store.outcomes.map(\.retries) == [2, 3, 4])

        let reader = MoveOutcomeStore(appSupportPaths: paths, maxOutcomes: 3)
        #expect(reader.outcomes.map(\.retries) == [2, 3, 4])
    }

    @Test func resetClearsPersistedOutcomes() {
        let (paths, base) = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: base) }

        let store = MoveOutcomeStore(appSupportPaths: paths)
        store.record(makeOutcome(retries: 0))
        store.reset()
        #expect(store.outcomes.isEmpty)

        let reader = MoveOutcomeStore(appSupportPaths: paths)
        #expect(reader.outcomes.isEmpty)
    }

    @Test func writesHumanReadableReliabilitySummaryAlongsideJSON() throws {
        let (paths, base) = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: base) }

        let store = MoveOutcomeStore(appSupportPaths: paths)
        store.record(makeOutcome(retries: 0))

        let summaryURL = paths.moveReliabilitySummaryFileURL
        #expect(FileManager.default.fileExists(atPath: summaryURL.path))
        let text = try String(contentsOf: summaryURL, encoding: .utf8)
        #expect(text.contains("Assisted Move Reliability"))
        #expect(text.contains("Success rate"))
    }

    @Test func reportReflectsRecordedOutcomes() {
        let (paths, base) = makeTempPaths()
        defer { try? FileManager.default.removeItem(at: base) }

        let store = MoveOutcomeStore(appSupportPaths: paths)
        store.record(makeOutcome(retries: 0))
        store.record(makeOutcome(retries: 1))

        let report = store.reliabilityReport(minimumSamples: 1)
        #expect(report.reliabilitySamples == 2)
        #expect(report.successes == 2)
        #expect(report.gateStatus == .pass)
    }
}
