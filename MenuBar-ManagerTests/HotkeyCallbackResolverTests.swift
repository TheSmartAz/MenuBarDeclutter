import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HotkeyCallbackResolver")
struct HotkeyCallbackResolverTests {
    @Test func resolvesKnownCarbonID() {
        let resolver = HotkeyCallbackResolver(
            identifierByCarbonID: [
                1: GlobalHotkeyManager.RegistrationIdentifier.visibilityToggle,
                2: GlobalHotkeyManager.RegistrationIdentifier.findIcon
            ],
            registeredIdentifiers: [.visibilityToggle, .findIcon]
        )

        #expect(resolver.resolve(carbonID: 2) == .matched(.findIcon, .carbonID))
    }

    @Test func rejectsUnknownCarbonID() {
        let resolver = HotkeyCallbackResolver(
            identifierByCarbonID: [
                1: GlobalHotkeyManager.RegistrationIdentifier.visibilityToggle
            ],
            registeredIdentifiers: [.visibilityToggle]
        )

        #expect(resolver.resolve(carbonID: 99) == .unknown(.unregisteredCarbonID(99)))
    }

    @Test func usesExplicitSingleRegistrationFallbackForMissingCarbonID() {
        let resolver = HotkeyCallbackResolver(
            identifierByCarbonID: [
                1: GlobalHotkeyManager.RegistrationIdentifier.visibilityToggle
            ],
            registeredIdentifiers: [.visibilityToggle]
        )

        #expect(
            resolver.resolve(carbonID: nil) == .matched(.visibilityToggle, .singleRegistrationFallback)
        )
    }

    @Test func rejectsMissingCarbonIDWhenMultipleRegistrationsExist() {
        let resolver = HotkeyCallbackResolver(
            identifierByCarbonID: [
                1: GlobalHotkeyManager.RegistrationIdentifier.visibilityToggle,
                2: GlobalHotkeyManager.RegistrationIdentifier.findIcon
            ],
            registeredIdentifiers: [.visibilityToggle, .findIcon]
        )

        #expect(
            resolver.resolve(carbonID: nil) == .unknown(.missingCarbonIDWithoutSingleRegistration)
        )
    }
}
