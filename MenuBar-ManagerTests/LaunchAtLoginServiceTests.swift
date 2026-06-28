import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("LaunchAtLoginService")
@MainActor
struct LaunchAtLoginServiceTests {
    @Test func registrationResultFailureFlag() {
        #expect(LaunchAtLoginService.RegistrationResult.registered.isFailure == false)
        #expect(LaunchAtLoginService.RegistrationResult.unregistered.isFailure == false)
        #expect(LaunchAtLoginService.RegistrationResult.failed(message: "boom").isFailure == true)
    }

    @Test func describeFallsBackToLocalizedDescriptionForNonSMAppServiceErrors() {
        struct CustomError: LocalizedError {
            var errorDescription: String? { "custom-error" }
        }

        let message = LaunchAtLoginService.describe(CustomError())
        #expect(message == "custom-error")
    }

    @Test func freshServiceHasNoResultAndFlagsUnregistered() {
        let service = LaunchAtLoginService(diagnosticsLogger: nil)
        #expect(service.lastRegistrationResult == nil)
        #expect(service.isCurrentlyRegistered == false)
    }
}