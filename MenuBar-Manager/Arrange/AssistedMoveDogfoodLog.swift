import Foundation

nonisolated enum AssistedMoveDurationBucket: String, Equatable, Sendable {
    case underOneSecond
    case oneToThreeSeconds
    case overThreeSeconds
    case notMeasured

    static func bucket(for elapsed: TimeInterval?) -> AssistedMoveDurationBucket {
        guard let elapsed, elapsed.isFinite, elapsed >= 0 else {
            return .notMeasured
        }

        if elapsed < 1 {
            return .underOneSecond
        }

        if elapsed <= 3 {
            return .oneToThreeSeconds
        }

        return .overThreeSeconds
    }
}

nonisolated struct AssistedMoveDogfoodLogEvent: Equatable, Sendable {
    let moveAttempted: Bool
    let sourceZone: MenuBarZone
    let targetZone: MenuBarZone
    let result: IconMoveOutcome
    let failureReason: IconMoveError?
    let durationBucket: AssistedMoveDurationBucket

    var metadata: [String: String] {
        [
            "moveAttempted": "\(moveAttempted)",
            "sourceZone": sourceZone.rawValue,
            "targetZone": targetZone.rawValue,
            "result": result.rawValue,
            "failureReason": failureReason?.diagnosticName ?? "none",
            "durationBucket": durationBucket.rawValue,
            "redacted": "true"
        ]
    }
}

private extension IconMoveError {
    nonisolated var diagnosticName: String {
        switch self {
        case .disabled:
            "disabled"
        case .proModeRequired:
            "proModeRequired"
        case .accessibilityPermissionRequired:
            "accessibilityPermissionRequired"
        case .confirmationCancelled:
            "confirmationCancelled"
        case .moveAlreadyInProgress:
            "moveAlreadyInProgress"
        case .missingSourceFrame:
            "missingSourceFrame"
        case .unsafeOwnItem:
            "unsafeOwnItem"
        case .unsafeSystemItem:
            "unsafeSystemItem"
        case .planningFailed:
            "planningFailed"
        case .dragFailed:
            "dragFailed"
        case .moveCancelled:
            "moveCancelled"
        case .verificationFailed:
            "verificationFailed"
        }
    }
}
