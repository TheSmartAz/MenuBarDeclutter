import Foundation

/// Policy for private access protection. A value-type snapshot derived from
/// SettingsStore to avoid threading the observable store into auth logic.
nonisolated struct PrivateAccessPolicy: Equatable, Sendable {
    var isEnabled: Bool
    var protectAlwaysHidden: Bool
    var protectSecondBar: Bool
    var protectFindIcon: Bool
    var protectIconMoving: Bool
    var protectSpacingLabs: Bool
    var protectProfileApply: Bool
    var protectAutomationCommands: Bool
    var protectedGroupsRequireAuth: Bool
    var unlockDurationSeconds: Double
    var allowDevicePasswordFallback: Bool

    @MainActor
    init(store: SettingsStore) {
        self.isEnabled = store.privateAccessEnabled
        self.protectAlwaysHidden = store.privateAccessProtectAlwaysHidden
        self.protectSecondBar = store.privateAccessProtectSecondBar
        self.protectFindIcon = store.privateAccessProtectFindIcon
        self.protectIconMoving = store.privateAccessProtectIconMoving
        self.protectSpacingLabs = store.privateAccessProtectSpacingLabs
        self.protectProfileApply = store.privateAccessProtectProfileApply
        self.protectAutomationCommands = store.privateAccessProtectAutomationCommands
        self.protectedGroupsRequireAuth = store.protectedGroupsRequireAuth
        self.unlockDurationSeconds = store.privateAccessUnlockDurationSeconds
        self.allowDevicePasswordFallback = store.privateAccessAllowDevicePasswordFallback
    }

    /// Check if a resource is protected by this policy.
    func isProtected(_ resource: ProtectedResource) -> Bool {
        guard isEnabled else { return false }
        switch resource {
        case .revealAll:
            return false
        case .alwaysHiddenZone:
            return protectAlwaysHidden
        case .findIcon:
            return protectFindIcon
        case .secondBar:
            return protectSecondBar
        case .iconMoving:
            return protectIconMoving
        case .protectedGroup:
            return protectedGroupsRequireAuth
        case .profileApply:
            return protectProfileApply
        case .layoutSpacingLabs:
            return protectSpacingLabs
        case .appIntent:
            return protectAutomationCommands
        }
    }
}
