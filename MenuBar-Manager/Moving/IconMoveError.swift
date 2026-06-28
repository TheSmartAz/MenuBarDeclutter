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
    case verificationFailed

    var displayName: String {
        switch self {
        case .disabled:
            "Icon Moving Disabled"
        case .proModeRequired:
            "Pro Mode Required"
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
        case .verificationFailed:
            "Verification Failed"
        }
    }
}
