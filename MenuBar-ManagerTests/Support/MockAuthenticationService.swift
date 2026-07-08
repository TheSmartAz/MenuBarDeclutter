import Foundation
@testable import MenuBarDeclutter

/// Mock authentication service for tests.
@MainActor
final class MockAuthenticationService: AuthenticationService {
    var result: AuthenticationResult = .success

    func authenticate(reason: String) async -> AuthenticationResult {
        result
    }
}
