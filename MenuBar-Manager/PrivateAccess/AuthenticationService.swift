import Foundation
import LocalAuthentication

/// Protocol for authentication services. Abstracted so tests can inject
/// a mock without triggering real Touch ID/password prompts.
@MainActor
protocol AuthenticationService: AnyObject {
    /// Authenticate the user. Returns true on success, false on failure/cancel.
    func authenticate(reason: String) async -> AuthenticationResult
}

/// Result of an authentication attempt.
nonisolated enum AuthenticationResult: Equatable, Sendable {
    case success
    case failure(String)
    case cancel
    case unavailable

    var isAuthorized: Bool {
        if case .success = self { return true }
        return false
    }

    var statusString: String {
        switch self {
        case .success: "success"
        case .failure: "failure"
        case .cancel: "cancel"
        case .unavailable: "unavailable"
        }
    }
}

/// Real LocalAuthentication service using LAContext.
@MainActor
final class LocalAuthenticationService: AuthenticationService {
    private let allowPasswordFallback: () -> Bool

    init(allowPasswordFallback: @escaping () -> Bool = { true }) {
        self.allowPasswordFallback = allowPasswordFallback
    }

    func authenticate(reason: String) async -> AuthenticationResult {
        let context = LAContext()
        context.localizedReason = reason

        var error: NSError?
        let policy: LAPolicy
        if allowPasswordFallback() {
            policy = .deviceOwnerAuthentication
        } else {
            policy = .deviceOwnerAuthenticationWithBiometrics
        }

        guard context.canEvaluatePolicy(policy, error: &error) else {
            return .unavailable
        }

        do {
            let result = try await context.evaluatePolicy(policy, localizedReason: reason)
            return result ? .success : .failure("Authentication returned false.")
        } catch {
            let laError = error as? LAError
            if laError?.code == .userCancel || laError?.code == .systemCancel {
                return .cancel
            }
            return .failure(error.localizedDescription)
        }
    }
}
