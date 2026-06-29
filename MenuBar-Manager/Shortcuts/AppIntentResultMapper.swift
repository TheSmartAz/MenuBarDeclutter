import AppIntents
import Foundation

/// Maps AppIntentExecutionService results to AppIntent result strings.
nonisolated struct AppIntentResultMapper {
    static func message(for result: AppIntentExecutionService.Result) -> String {
        switch result {
        case .success:
            "Done."
        case .blocked(let reason):
            "Blocked: \(reason)"
        case .dryRunOnly(let reason):
            "Dry run only: \(reason)"
        case .requiresPrivateAccess:
            "This action requires Private Access. Please unlock in the MenuBarDeclutter app."
        case .requiresProMode:
            "This action requires Pro Mode."
        case .requiresAccessibility:
            "This action requires Accessibility permission."
        case .requiresLabs:
            "This action requires Menu Bar Spacing Labs to be enabled."
        case .automationPaused:
            "Automation is paused. Use Resume Automation to continue."
        case .safeModeBlocked:
            "This action is not available in Safe Mode."
        }
    }
}
