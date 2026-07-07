import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Move Reliability Report")
struct MoveReliabilityReportTests {
    private func outcome(
        attempted: Bool = true,
        result: IconMoveOutcome = .succeeded,
        retries: Int = 0,
        failureReason: String? = nil,
        app: String? = "com.example.app",
        source: MenuBarZone = .hidden,
        target: MenuBarZone = .visible,
        latency: Double? = 0.4
    ) -> MoveOutcome {
        MoveOutcome(
            timestamp: Date(timeIntervalSince1970: 1_000_000),
            appBundleIdentifier: app,
            appDisplayName: app,
            commandKind: .toZone,
            sourceZone: source,
            targetZone: target,
            moveAttempted: attempted,
            result: result,
            verification: result == .succeeded ? .succeeded : .notApplicable,
            failureReason: failureReason,
            retries: retries,
            latencySeconds: attempted ? latency : nil
        )
    }

    @Test func rateIsComputedOverReliabilitySamplesOnly() {
        let outcomes =
            Array(repeating: outcome(result: .succeeded), count: 3)
            + [outcome(result: .failed, failureReason: "dragFailed")]
            + Array(repeating: outcome(attempted: false, result: .skipped, failureReason: "disabled", latency: nil), count: 2)
            + [outcome(result: .cancelled, failureReason: "moveCancelled")]

        let report = MoveReliabilityReport(outcomes: outcomes)

        #expect(report.totalRecords == 7)
        #expect(report.reliabilitySamples == 4)   // 3 success + 1 fail
        #expect(report.successes == 3)
        #expect(report.hardFailures == 1)
        #expect(report.gatingSkips == 2)
        #expect(report.cancellations == 1)
        #expect(abs(report.successRate - 0.75) < 0.0001)
    }

    @Test func gatePassesAtThresholdWithEnoughSamples() {
        let outcomes = Array(repeating: outcome(result: .succeeded), count: 19)
            + [outcome(result: .failed, failureReason: "verificationFailed")]
        let report = MoveReliabilityReport(outcomes: outcomes, gateThreshold: 0.95, minimumSamples: 20)

        #expect(report.reliabilitySamples == 20)
        #expect(abs(report.successRate - 0.95) < 0.0001)
        #expect(report.gateStatus == .pass)
        #expect(report.meetsGate)
    }

    @Test func gateFailsBelowThreshold() {
        let outcomes = Array(repeating: outcome(result: .succeeded), count: 17)
            + Array(repeating: outcome(result: .failed, failureReason: "dragFailed"), count: 3)
        let report = MoveReliabilityReport(outcomes: outcomes, gateThreshold: 0.95, minimumSamples: 20)

        #expect(report.gateStatus == .fail)
        #expect(!report.meetsGate)
    }

    @Test func gateReportsInsufficientDataBelowMinimumSamples() {
        let outcomes = Array(repeating: outcome(result: .succeeded), count: 5)
        let report = MoveReliabilityReport(outcomes: outcomes, gateThreshold: 0.95, minimumSamples: 20)

        #expect(report.successRate == 1.0)
        #expect(report.gateStatus == .insufficientData)
        #expect(!report.meetsGate)
    }

    @Test func firstAttemptSuccessesCountZeroRetryOnly() {
        let outcomes = [
            outcome(result: .succeeded, retries: 0),
            outcome(result: .succeeded, retries: 0),
            outcome(result: .succeeded, retries: 2)
        ]
        let report = MoveReliabilityReport(outcomes: outcomes)
        #expect(report.successes == 3)
        #expect(report.firstAttemptSuccesses == 2)
    }

    @Test func failureHistogramCountsByReason() {
        let outcomes = [
            outcome(result: .failed, failureReason: "dragFailed"),
            outcome(result: .failed, failureReason: "dragFailed"),
            outcome(result: .failed, failureReason: "verificationFailed")
        ]
        let report = MoveReliabilityReport(outcomes: outcomes)
        #expect(report.failureHistogram["dragFailed"] == 2)
        #expect(report.failureHistogram["verificationFailed"] == 1)
    }

    @Test func perAppAndPerTransitionSlicesSortByVolume() {
        let outcomes =
            Array(repeating: outcome(result: .succeeded, app: "com.a", source: .hidden, target: .visible), count: 3)
            + [outcome(result: .failed, failureReason: "dragFailed", app: "com.a", source: .hidden, target: .visible)]
            + [outcome(result: .succeeded, app: "com.b", source: .visible, target: .alwaysHidden)]

        let report = MoveReliabilityReport(outcomes: outcomes)

        #expect(report.perApp.first?.key == "com.a")
        #expect(report.perApp.first?.samples == 4)
        #expect(report.perApp.first?.successes == 3)
        #expect(abs((report.perApp.first?.rate ?? 0) - 0.75) < 0.0001)

        let transition = report.perTransition.first { $0.key == "hidden→visible" }
        #expect(transition?.samples == 4)
        #expect(transition?.successes == 3)
    }

    @Test func latencyStatsAggregate() {
        let outcomes = [
            outcome(result: .succeeded, latency: 0.5),
            outcome(result: .succeeded, latency: 2.0),
            outcome(result: .succeeded, latency: 5.0)
        ]
        let report = MoveReliabilityReport(outcomes: outcomes)
        #expect(report.latencyUnderOneSecond == 1)
        #expect(report.latencyOneToThreeSeconds == 1)
        #expect(report.latencyOverThreeSeconds == 1)
        #expect(abs((report.meanLatencySeconds ?? 0) - 2.5) < 0.0001)
    }

    @Test func plainTextContainsRateAndGate() {
        let outcomes = Array(repeating: outcome(result: .succeeded), count: 19)
            + [outcome(result: .failed, failureReason: "dragFailed")]
        let text = MoveReliabilityReport(outcomes: outcomes).plainText()
        #expect(text.contains("Assisted Move Reliability"))
        #expect(text.contains("Success rate: 95.0%"))
        #expect(text.contains("PASS"))
        #expect(text.contains("hidden→visible"))
    }

    @Test func emptyReportIsInsufficientAndSafe() {
        let report = MoveReliabilityReport(outcomes: [])
        #expect(report.reliabilitySamples == 0)
        #expect(report.successRate == 0)
        #expect(report.gateStatus == .insufficientData)
        #expect(report.plainText().contains("INSUFFICIENT DATA"))
    }
}
