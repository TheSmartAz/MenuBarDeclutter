import Foundation

/// Resources that can be protected by Private Access.
nonisolated enum ProtectedResource: Hashable, Sendable {
    case revealAll
    case alwaysHiddenZone
    case findIcon
    case secondBar
    case iconMoving
    case protectedGroup(UUID)
    case profileApply
    case layoutSpacingLabs
    case appIntent(String)

    /// Whether this resource is protected based on the given settings.
    @MainActor
    func isProtected(in settings: SettingsStore) -> Bool {
        guard settings.privateAccessEnabled else { return false }
        switch self {
        case .revealAll:
            return false // Not protected by default
        case .alwaysHiddenZone:
            return settings.privateAccessProtectAlwaysHidden
        case .findIcon:
            return settings.privateAccessProtectFindIcon
        case .secondBar:
            return settings.privateAccessProtectSecondBar
        case .iconMoving:
            return settings.privateAccessProtectIconMoving
        case .protectedGroup:
            return settings.protectedGroupsRequireAuth
        case .profileApply:
            return false // Not protected by default
        case .layoutSpacingLabs:
            return settings.privateAccessProtectSpacingLabs
        case .appIntent:
            return false
        }
    }

    var diagnosticKind: String {
        switch self {
        case .revealAll:
            "revealAll"
        case .alwaysHiddenZone:
            "alwaysHiddenZone"
        case .findIcon:
            "findIcon"
        case .secondBar:
            "secondBar"
        case .iconMoving:
            "iconMoving"
        case .protectedGroup:
            "protectedGroup"
        case .profileApply:
            "profileApply"
        case .layoutSpacingLabs:
            "layoutSpacingLabs"
        case .appIntent:
            "appIntent"
        }
    }
}
