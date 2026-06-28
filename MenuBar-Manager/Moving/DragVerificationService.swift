import Foundation

enum DragVerificationOutcome: Equatable, Sendable {
    case succeeded
    case notFound
    case wrongZone(MenuBarZone)

    var displayName: String {
        switch self {
        case .succeeded:
            "Succeeded"
        case .notFound:
            "Item Not Found"
        case .wrongZone(let zone):
            "Wrong Zone: \(zone.displayName)"
        }
    }
}

struct DragVerificationResult: Equatable, Sendable {
    let outcome: DragVerificationOutcome
    let matchedSnapshot: MenuBarItemSnapshot?
    let expectedZone: MenuBarZone

    var isSuccess: Bool {
        outcome == .succeeded
    }

    var summary: String {
        "Expected \(expectedZone.displayName): \(outcome.displayName)"
    }
}

struct DragVerificationService {
    func verify(
        original: MenuBarItemSnapshot,
        targetZone: MenuBarZone,
        rescannedSnapshots: [MenuBarItemSnapshot]
    ) -> DragVerificationResult {
        guard let matched = rescannedSnapshots.first(where: { Self.matches(original: original, candidate: $0) }) else {
            return DragVerificationResult(
                outcome: .notFound,
                matchedSnapshot: nil,
                expectedZone: targetZone
            )
        }

        guard matched.zone == targetZone || targetZone == .unknown else {
            return DragVerificationResult(
                outcome: .wrongZone(matched.zone),
                matchedSnapshot: matched,
                expectedZone: targetZone
            )
        }

        return DragVerificationResult(
            outcome: .succeeded,
            matchedSnapshot: matched,
            expectedZone: targetZone
        )
    }

    static func matches(original: MenuBarItemSnapshot, candidate: MenuBarItemSnapshot) -> Bool {
        if let originalBundle = original.bundleIdentifier,
           let candidateBundle = candidate.bundleIdentifier,
           originalBundle == candidateBundle {
            return normalized(original.title) == normalized(candidate.title)
                || normalized(original.owningApplicationName) == normalized(candidate.owningApplicationName)
        }

        if let originalPID = original.owningProcessIdentifier,
           let candidatePID = candidate.owningProcessIdentifier,
           originalPID == candidatePID {
            return normalized(original.title) == normalized(candidate.title)
        }

        return original.id == candidate.id
    }

    private static func normalized(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            ?? ""
    }
}
