import Foundation

/// The kind of move requested, in a Codable-stable form independent of
/// `IconMoveCommand` (which carries associated values and is not
/// `RawRepresentable`).
nonisolated enum MoveCommandKind: String, Codable, Equatable, Sendable {
    case toZone
    case left
    case right
}

/// Whether the post-move rescan confirmed the item landed in the target zone.
/// Preserves the `notFound` vs `wrongZone` distinction that `IconMoveResult`
/// otherwise flattens into a single `.verificationFailed` error.
nonisolated enum MoveVerificationSummary: String, Codable, Equatable, Sendable {
    case succeeded
    case notFound
    case wrongZone
    case notApplicable

    init(_ outcome: DragVerificationOutcome?) {
        switch outcome {
        case .some(.succeeded):
            self = .succeeded
        case .some(.notFound):
            self = .notFound
        case .some(.wrongZone):
            self = .wrongZone
        case .none:
            self = .notApplicable
        }
    }
}

/// A single durable record of one assisted-move attempt. This is the raw
/// measurement the foundation-reliability work aggregates into a success rate
/// for the single-item move primitive that Level-2 Workspaces will depend on.
///
/// PRIVACY: `appBundleIdentifier` and `appDisplayName` identify a third-party
/// menu bar item and are stored LOCAL-ONLY. Never include a non-redacted
/// `MoveOutcome` in the diagnostics export; use `redacted` for anything that
/// may leave the device.
nonisolated struct MoveOutcome: Codable, Equatable, Sendable {
    let timestamp: Date
    let appBundleIdentifier: String?
    let appDisplayName: String?
    let commandKind: MoveCommandKind
    let sourceZone: MenuBarZone
    let targetZone: MenuBarZone
    let moveAttempted: Bool
    let result: IconMoveOutcome
    let verification: MoveVerificationSummary
    let failureReason: String?
    let retries: Int
    let latencySeconds: Double?

    /// A move that actually ran the drag mechanism to a verifiable conclusion
    /// (succeeded or failed). Gating skips (`moveAttempted == false`) and
    /// user/Task cancellations are excluded — they do not measure whether the
    /// mechanism itself works, so they must not dilute the success rate.
    var isReliabilitySample: Bool {
        moveAttempted && (result == .succeeded || result == .failed)
    }

    var isSuccess: Bool { result == .succeeded }

    var isHardFailure: Bool { isReliabilitySample && result == .failed }

    /// Coarse latency bucket, reusing the existing dogfood bucketing.
    var latencyBucket: AssistedMoveDurationBucket {
        .bucket(for: latencySeconds)
    }

    /// A copy with third-party identity removed, safe to surface off-device.
    var redacted: MoveOutcome {
        MoveOutcome(
            timestamp: timestamp,
            appBundleIdentifier: nil,
            appDisplayName: nil,
            commandKind: commandKind,
            sourceZone: sourceZone,
            targetZone: targetZone,
            moveAttempted: moveAttempted,
            result: result,
            verification: verification,
            failureReason: failureReason,
            retries: retries,
            latencySeconds: latencySeconds
        )
    }
}

extension IconMoveCommand {
    nonisolated var kind: MoveCommandKind {
        switch self {
        case .moveToZone:
            .toZone
        case .moveLeft:
            .left
        case .moveRight:
            .right
        }
    }
}

/// Sink for per-attempt move outcomes. Implemented by `MoveOutcomeStore` in
/// production and by test doubles in unit tests. Kept intentionally minimal so
/// `IconMoveService` depends only on "record one outcome".
@MainActor
protocol MoveOutcomeRecording: AnyObject {
    func record(_ outcome: MoveOutcome)
}
