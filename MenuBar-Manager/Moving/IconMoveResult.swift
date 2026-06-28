import Foundation

enum IconMoveCommand: Equatable, Sendable {
    case moveToZone(MenuBarZone)
    case moveLeft
    case moveRight

    var displayName: String {
        switch self {
        case .moveToZone(let zone):
            "Move to \(zone.displayName)"
        case .moveLeft:
            "Move Left"
        case .moveRight:
            "Move Right"
        }
    }

    func targetZone(currentZone: MenuBarZone) -> MenuBarZone {
        switch self {
        case .moveToZone(let zone):
            zone
        case .moveLeft, .moveRight:
            currentZone
        }
    }
}

enum IconMoveOutcome: String, Sendable {
    case succeeded
    case failed
    case skipped
    case cancelled
}

struct IconMoveResult: Equatable, Sendable {
    let outcome: IconMoveOutcome
    let command: IconMoveCommand
    let itemName: String
    let error: IconMoveError?
    let dragPlanSummary: String?
    let verificationSummary: String?
    let retries: Int

    var summary: String {
        switch outcome {
        case .succeeded:
            "\(command.displayName) succeeded for \(itemName)."
        case .failed:
            "\(command.displayName) failed for \(itemName): \(error?.displayName ?? "Unknown Error")."
        case .skipped:
            "\(command.displayName) skipped for \(itemName): \(error?.displayName ?? "Not Available")."
        case .cancelled:
            "\(command.displayName) cancelled for \(itemName)."
        }
    }

    static func skipped(
        command: IconMoveCommand,
        itemName: String,
        error: IconMoveError
    ) -> IconMoveResult {
        IconMoveResult(
            outcome: .skipped,
            command: command,
            itemName: itemName,
            error: error,
            dragPlanSummary: nil,
            verificationSummary: nil,
            retries: 0
        )
    }
}
