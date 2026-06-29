import Foundation

/// Gate that protects actions behind Private Access authentication.
/// All protected actions must call this gate before execution.
@MainActor
final class ProtectedActionGate {
    private let coordinator: PrivateAccessCoordinator

    init(coordinator: PrivateAccessCoordinator) {
        self.coordinator = coordinator
    }

    /// Execute a protected action. If auth is required, prompts the user.
    /// Returns true if the action was executed, false if blocked.
    func execute(
        resource: ProtectedResource,
        reason: String,
        action: () -> Void
    ) async -> Bool {
        guard coordinator.isProtected(resource) else {
            action()
            return true
        }

        let granted = await coordinator.requestAccess(to: resource, reason: reason)
        guard granted else { return false }

        action()
        return true
    }

    /// Check if a resource is currently accessible without prompting.
    func canAccessWithoutPrompt(_ resource: ProtectedResource) -> Bool {
        !coordinator.isProtected(resource) || coordinator.isUnlocked
    }
}
