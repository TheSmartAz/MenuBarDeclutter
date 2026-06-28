import Foundation

nonisolated struct HotkeyCallbackResolver<Identifier: Hashable & Sendable>: Sendable {
    enum MatchKind: Equatable, Sendable {
        case carbonID
        case singleRegistrationFallback
    }

    enum Resolution: Equatable, Sendable {
        case matched(Identifier, MatchKind)
        case unknown(UnknownReason)
    }

    enum UnknownReason: Equatable, Sendable {
        case missingCarbonIDWithoutSingleRegistration
        case unregisteredCarbonID(UInt32)
    }

    let identifierByCarbonID: [UInt32: Identifier]
    let registeredIdentifiers: Set<Identifier>

    func resolve(carbonID: UInt32?) -> Resolution {
        if let carbonID {
            guard let identifier = identifierByCarbonID[carbonID] else {
                return .unknown(.unregisteredCarbonID(carbonID))
            }
            return .matched(identifier, .carbonID)
        }

        guard registeredIdentifiers.count == 1,
              let identifier = registeredIdentifiers.first else {
            return .unknown(.missingCarbonIDWithoutSingleRegistration)
        }

        return .matched(identifier, .singleRegistrationFallback)
    }
}
