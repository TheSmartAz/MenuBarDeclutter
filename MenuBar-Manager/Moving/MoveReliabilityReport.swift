import Foundation

/// Aggregates `MoveOutcome` records into the measured reliability of the
/// single-item move primitive: the overall success rate, its breakdowns, and a
/// go/no-go gate. Pure and deterministic so it is fully unit-testable; the
/// hardware QA run feeds it real outcomes collected by `MoveOutcomeStore`.
///
/// The success rate is computed over reliability samples only — attempts that
/// actually ran the drag mechanism to a succeeded/failed conclusion. Gating
/// skips and user/Task cancellations are reported separately so they never
/// dilute the number that gates the Level-2 Workspaces work.
nonisolated struct MoveReliabilityReport: Equatable, Sendable {
    enum GateStatus: String, Equatable, Sendable {
        case pass
        case fail
        case insufficientData

        var label: String {
            switch self {
            case .pass:
                "PASS"
            case .fail:
                "FAIL"
            case .insufficientData:
                "INSUFFICIENT DATA"
            }
        }
    }

    struct RateSlice: Equatable, Sendable {
        let key: String
        let samples: Int
        let successes: Int

        var rate: Double { samples == 0 ? 0 : Double(successes) / Double(samples) }
    }

    let gateThreshold: Double
    let minimumSamples: Int

    let totalRecords: Int
    let reliabilitySamples: Int
    let successes: Int
    let hardFailures: Int
    let cancellations: Int
    let gatingSkips: Int
    let firstAttemptSuccesses: Int

    let meanLatencySeconds: Double?
    let latencyUnderOneSecond: Int
    let latencyOneToThreeSeconds: Int
    let latencyOverThreeSeconds: Int

    let failureHistogram: [String: Int]
    let perApp: [RateSlice]
    let perTransition: [RateSlice]

    var successRate: Double {
        reliabilitySamples == 0 ? 0 : Double(successes) / Double(reliabilitySamples)
    }

    var gateStatus: GateStatus {
        guard reliabilitySamples >= minimumSamples else { return .insufficientData }
        return successRate >= gateThreshold ? .pass : .fail
    }

    var meetsGate: Bool { gateStatus == .pass }

    init(outcomes: [MoveOutcome], gateThreshold: Double = 0.95, minimumSamples: Int = 20) {
        self.gateThreshold = gateThreshold
        self.minimumSamples = minimumSamples
        self.totalRecords = outcomes.count

        let samples = outcomes.filter(\.isReliabilitySample)
        self.reliabilitySamples = samples.count
        self.successes = samples.filter(\.isSuccess).count
        self.hardFailures = samples.filter(\.isHardFailure).count
        self.cancellations = outcomes.filter { $0.moveAttempted && $0.result == .cancelled }.count
        self.gatingSkips = outcomes.filter { !$0.moveAttempted }.count
        self.firstAttemptSuccesses = samples.filter { $0.isSuccess && $0.retries == 0 }.count

        let latencies = samples.compactMap(\.latencySeconds)
        self.meanLatencySeconds = latencies.isEmpty ? nil : latencies.reduce(0, +) / Double(latencies.count)
        self.latencyUnderOneSecond = samples.filter { $0.latencyBucket == .underOneSecond }.count
        self.latencyOneToThreeSeconds = samples.filter { $0.latencyBucket == .oneToThreeSeconds }.count
        self.latencyOverThreeSeconds = samples.filter { $0.latencyBucket == .overThreeSeconds }.count

        var histogram: [String: Int] = [:]
        for outcome in samples where outcome.isHardFailure {
            histogram[outcome.failureReason ?? "unknown", default: 0] += 1
        }
        self.failureHistogram = histogram

        self.perApp = Self.slices(from: samples) { $0.appBundleIdentifier ?? "(unknown)" }
        self.perTransition = Self.slices(from: samples) { "\($0.sourceZone.rawValue)→\($0.targetZone.rawValue)" }
    }

    private static func slices(
        from samples: [MoveOutcome],
        key: (MoveOutcome) -> String
    ) -> [RateSlice] {
        var bucketed: [String: (samples: Int, successes: Int)] = [:]
        for outcome in samples {
            let k = key(outcome)
            var entry = bucketed[k] ?? (samples: 0, successes: 0)
            entry.samples += 1
            if outcome.isSuccess { entry.successes += 1 }
            bucketed[k] = entry
        }
        return bucketed
            .map { RateSlice(key: $0.key, samples: $0.value.samples, successes: $0.value.successes) }
            .sorted { lhs, rhs in
                lhs.samples != rhs.samples ? lhs.samples > rhs.samples : lhs.key < rhs.key
            }
    }

    /// Human-readable summary written to the local reliability file for the QA
    /// run. Includes per-app identity, so it is LOCAL ONLY and must never be
    /// added to the diagnostics export.
    func plainText() -> String {
        var lines: [String] = []
        lines.append("Assisted Move Reliability")
        lines.append("Gate: success rate ≥ \(Self.percent(gateThreshold)) over ≥ \(minimumSamples) samples → \(gateStatus.label)")
        lines.append("Success rate: \(Self.percent(successRate)) (\(successes)/\(reliabilitySamples) samples)")
        lines.append("Records: \(totalRecords) total • hard failures: \(hardFailures) • cancelled: \(cancellations) • gating skips: \(gatingSkips)")
        lines.append("First-attempt successes: \(firstAttemptSuccesses)/\(successes)")
        let mean = meanLatencySeconds.map { String(format: "%.2fs", $0) } ?? "—"
        lines.append("Latency: mean \(mean) (<1s: \(latencyUnderOneSecond), 1–3s: \(latencyOneToThreeSeconds), >3s: \(latencyOverThreeSeconds))")
        if failureHistogram.isEmpty {
            lines.append("Failures: none")
        } else {
            let parts = failureHistogram
                .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
                .map { "\($0.key) ×\($0.value)" }
            lines.append("Failures: \(parts.joined(separator: ", "))")
        }
        lines.append("")
        lines.append("By zone transition:")
        for slice in perTransition {
            lines.append("  \(slice.key): \(Self.percent(slice.rate)) (\(slice.successes)/\(slice.samples))")
        }
        if perTransition.isEmpty { lines.append("  (none)") }
        lines.append("")
        lines.append("By app (local only — never exported):")
        for slice in perApp {
            lines.append("  \(slice.key): \(Self.percent(slice.rate)) (\(slice.successes)/\(slice.samples))")
        }
        if perApp.isEmpty { lines.append("  (none)") }
        return lines.joined(separator: "\n")
    }

    private static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }
}
