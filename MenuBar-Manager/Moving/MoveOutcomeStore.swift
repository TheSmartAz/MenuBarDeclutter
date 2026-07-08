import Foundation
import Observation

/// Local-only, capped, append store of `MoveOutcome` records used to compute
/// the real-world success rate of the single-item move primitive.
///
/// PRIVACY: Persists third-party identity (bundle id / display name) LOCALLY
/// ONLY, under Application Support. This file is deliberately NOT part of the
/// diagnostics export. Any code that surfaces this data off-device must use
/// `MoveOutcome.redacted`.
@MainActor
@Observable
final class MoveOutcomeStore: MoveOutcomeRecording {
    @ObservationIgnored private let appSupportPaths: AppSupportPaths
    @ObservationIgnored private let maxOutcomes: Int
    @ObservationIgnored private let store: CodableFileStore<[MoveOutcome]>

    private(set) var outcomes: [MoveOutcome]
    var lastError: String?

    init(
        appSupportPaths: AppSupportPaths,
        fileManager: FileManager = .default,
        maxOutcomes: Int = 500
    ) {
        self.appSupportPaths = appSupportPaths
        self.maxOutcomes = max(1, maxOutcomes)
        self.store = CodableFileStore(
            fileURL: appSupportPaths.moveOutcomesFileURL,
            fileManager: fileManager,
            encoder: Self.encoder(),
            decoder: Self.decoder()
        )
        self.outcomes = []
        load()
    }

    /// Appends one outcome, enforcing the retention cap (keeping the most
    /// recent), then persists atomically.
    func record(_ outcome: MoveOutcome) {
        outcomes.append(outcome)
        if outcomes.count > maxOutcomes {
            outcomes.removeFirst(outcomes.count - maxOutcomes)
        }
        persist()
    }

    func reset() {
        outcomes = []
        persist()
    }

    /// Computes the reliability report (success rate + gate + breakdowns) from
    /// the currently held outcomes.
    func reliabilityReport(
        gateThreshold: Double = 0.95,
        minimumSamples: Int = 20
    ) -> MoveReliabilityReport {
        MoveReliabilityReport(
            outcomes: outcomes,
            gateThreshold: gateThreshold,
            minimumSamples: minimumSamples
        )
    }

    private func load() {
        do {
            outcomes = try store.read() ?? []
            lastError = nil
        } catch {
            outcomes = []
            lastError = error.localizedDescription
        }
    }

    private func persist() {
        do {
            try store.write(outcomes)

            // Also refresh the human-readable reliability summary so the QA run
            // has a readable success-rate readout without any UI. Local only.
            // `store.write` already created the parent directory this sibling
            // file shares.
            let summary = MoveReliabilityReport(outcomes: outcomes).plainText()
            try Data(summary.utf8).write(
                to: appSupportPaths.moveReliabilitySummaryFileURL,
                options: .atomic
            )
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
