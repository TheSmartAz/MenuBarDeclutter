import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Move Outcome")
struct MoveOutcomeTests {
    private func makeOutcome(
        appBundleIdentifier: String? = "com.example.move",
        appDisplayName: String? = "Example",
        commandKind: MoveCommandKind = .toZone,
        sourceZone: MenuBarZone = .hidden,
        targetZone: MenuBarZone = .visible,
        moveAttempted: Bool = true,
        result: IconMoveOutcome = .succeeded,
        verification: MoveVerificationSummary = .succeeded,
        failureReason: String? = nil,
        retries: Int = 0,
        latencySeconds: Double? = 0.4
    ) -> MoveOutcome {
        MoveOutcome(
            timestamp: Date(timeIntervalSince1970: 1_000_000),
            appBundleIdentifier: appBundleIdentifier,
            appDisplayName: appDisplayName,
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

    @Test func attemptedSuccessIsAReliabilitySampleAndSuccess() {
        let outcome = makeOutcome(result: .succeeded, verification: .succeeded)
        #expect(outcome.isReliabilitySample)
        #expect(outcome.isSuccess)
        #expect(!outcome.isHardFailure)
    }

    @Test func attemptedFailureIsAHardFailure() {
        let outcome = makeOutcome(result: .failed, verification: .notFound, failureReason: "dragFailed")
        #expect(outcome.isReliabilitySample)
        #expect(!outcome.isSuccess)
        #expect(outcome.isHardFailure)
    }

    @Test func gatingSkipIsNotAReliabilitySample() {
        let outcome = makeOutcome(
            moveAttempted: false,
            result: .skipped,
            verification: .notApplicable,
            failureReason: "disabled",
            latencySeconds: nil
        )
        #expect(!outcome.isReliabilitySample)
        #expect(!outcome.isSuccess)
        #expect(!outcome.isHardFailure)
    }

    @Test func cancellationIsExcludedFromReliabilitySamples() {
        let outcome = makeOutcome(
            moveAttempted: true,
            result: .cancelled,
            verification: .notApplicable,
            failureReason: "moveCancelled"
        )
        #expect(!outcome.isReliabilitySample)
        #expect(!outcome.isHardFailure)
    }

    @Test func redactedStripsThirdPartyIdentityButKeepsMechanics() {
        let outcome = makeOutcome(appBundleIdentifier: "com.secret.app", appDisplayName: "Secret App")
        let redacted = outcome.redacted

        #expect(redacted.appBundleIdentifier == nil)
        #expect(redacted.appDisplayName == nil)
        #expect(redacted.sourceZone == outcome.sourceZone)
        #expect(redacted.targetZone == outcome.targetZone)
        #expect(redacted.result == outcome.result)
        #expect(redacted.verification == outcome.verification)
        #expect(redacted.retries == outcome.retries)
        #expect(redacted.latencySeconds == outcome.latencySeconds)
        #expect(redacted.timestamp == outcome.timestamp)
    }

    @Test func codableRoundTripPreservesAllFields() throws {
        let outcome = makeOutcome(
            result: .failed,
            verification: .wrongZone,
            failureReason: "verificationFailed",
            retries: 2,
            latencySeconds: 1.75
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(outcome)
        let decoded = try decoder.decode(MoveOutcome.self, from: data)
        #expect(decoded == outcome)
    }

    @Test func latencyBucketMapsFromSeconds() {
        #expect(makeOutcome(latencySeconds: 0.5).latencyBucket == .underOneSecond)
        #expect(makeOutcome(latencySeconds: 2).latencyBucket == .oneToThreeSeconds)
        #expect(makeOutcome(latencySeconds: 5).latencyBucket == .overThreeSeconds)
        #expect(makeOutcome(latencySeconds: nil).latencyBucket == .notMeasured)
    }

    @Test func verificationSummaryMapsFromDragOutcome() {
        #expect(MoveVerificationSummary(.succeeded) == .succeeded)
        #expect(MoveVerificationSummary(.notFound) == .notFound)
        #expect(MoveVerificationSummary(.wrongZone(.hidden)) == .wrongZone)
        #expect(MoveVerificationSummary(nil) == .notApplicable)
    }

    @Test func commandKindMapsFromIconMoveCommand() {
        #expect(IconMoveCommand.moveToZone(.visible).kind == .toZone)
        #expect(IconMoveCommand.moveLeft.kind == .left)
        #expect(IconMoveCommand.moveRight.kind == .right)
    }
}
