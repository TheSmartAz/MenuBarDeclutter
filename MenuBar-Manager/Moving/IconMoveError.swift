import Foundation

enum IconMoveError: Error, Equatable, Sendable {
    case disabled
    case proModeRequired
    case accessibilityPermissionRequired
    case confirmationCancelled
    case moveAlreadyInProgress
    case missingSourceFrame
    case unsafeOwnItem
    case unsafeSystemItem
    case planningFailed
    case dragFailed
    case moveCancelled
    case verificationFailed

    var displayName: String {
        switch self {
        case .disabled:
            "Icon Moving Disabled"
        case .proModeRequired:
            "Optional Pro Required"
        case .accessibilityPermissionRequired:
            "Accessibility Permission Required"
        case .confirmationCancelled:
            "Move Cancelled"
        case .moveAlreadyInProgress:
            "Move Already In Progress"
        case .missingSourceFrame:
            "Missing Source Frame"
        case .unsafeOwnItem:
            "MenuBarDeclutter Item Blocked"
        case .unsafeSystemItem:
            "System Item Blocked"
        case .planningFailed:
            "Could Not Plan Drag"
        case .dragFailed:
            "Drag Failed"
        case .moveCancelled:
            "Move Cancelled"
        case .verificationFailed:
            "Verification Failed"
        }
    }
}
