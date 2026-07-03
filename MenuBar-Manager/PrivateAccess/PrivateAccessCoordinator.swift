import Foundation

/// Coordinator for Private Access that owns the authentication service,
/// unlock session, and policy.
@MainActor
final class PrivateAccessCoordinator {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let authService: any AuthenticationService
    private let unlockSession: UnlockSession
    private let now: () -> Date

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        authService: any AuthenticationService,
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.authService = authService
        self.now = now
        self.unlockSession = UnlockSession(
            durationProvider: { [weak settingsStore] in
                settingsStore?.privateAccessUnlockDurationSeconds ?? AppConstants.defaultPrivateAccessUnlockDurationSeconds
            },
            now: now
        )
    }

    /// Current policy snapshot.
    var policy: PrivateAccessPolicy {
        PrivateAccessPolicy(store: settingsStore)
    }

    /// Whether the unlock session is currently active.
    var isUnlocked: Bool {
        unlockSession.isActive
    }

    /// Check if a resource is protected.
    func isProtected(_ resource: ProtectedResource) -> Bool {
        policy.isProtected(resource)
    }

    /// Request access to a protected resource. If the unlock session is
    /// active, returns true immediately. Otherwise, prompts authentication.
    func requestAccess(to resource: ProtectedResource, reason: String) async -> Bool {
        guard settingsStore.privateAccessEnabled else { return true }
        guard policy.isProtected(resource) else { return true }

        if unlockSession.isActive {
            return true
        }

        let result = await authService.authenticate(reason: reason)
        settingsStore.privateAccessLastAuthStatus = result.statusString

        switch result {
        case .success:
            unlockSession.unlock()
            diagnosticsLogger.log(
                "Private Access: authentication succeeded.",
                category: .privacy,
                metadata: ["resource": resource.diagnosticKind]
            )
            return true
        case .failure:
            diagnosticsLogger.log(
                "Private Access: authentication failed.",
                level: .warning,
                category: .privacy,
                metadata: ["resource": resource.diagnosticKind]
            )
            return false
        case .cancel:
            diagnosticsLogger.log(
                "Private Access: authentication cancelled.",
                level: .info,
                category: .privacy,
                metadata: ["resource": resource.diagnosticKind]
            )
            return false
        case .unavailable:
            diagnosticsLogger.log(
                "Private Access: authentication unavailable.",
                level: .warning,
                category: .privacy,
                metadata: ["resource": resource.diagnosticKind]
            )
            return false
        }
    }

    /// Authenticate before enabling Private Access so the lock cannot be
    /// armed without a successful device-owner check.
    func enablePrivateAccessAfterAuthentication(reason: String) async -> AuthenticationResult {
        guard !settingsStore.privateAccessEnabled else { return .success }

        let result = await authService.authenticate(reason: reason)
        settingsStore.privateAccessLastAuthStatus = result.statusString

        switch result {
        case .success:
            settingsStore.privateAccessEnabled = true
            unlockSession.unlock()
            diagnosticsLogger.log("Private Access: enabled after authentication.", category: .privacy)
        case .failure:
            diagnosticsLogger.log(
                "Private Access: enable authentication failed.",
                level: .warning,
                category: .privacy
            )
        case .cancel:
            diagnosticsLogger.log(
                "Private Access: enable authentication cancelled.",
                level: .info,
                category: .privacy
            )
        case .unavailable:
            diagnosticsLogger.log(
                "Private Access: enable authentication unavailable.",
                level: .warning,
                category: .privacy
            )
        }

        return result
    }

    /// Clear the unlock session.
    func clearUnlock() {
        unlockSession.clear()
        diagnosticsLogger.log("Private Access: unlock session cleared.", category: .privacy)
    }

    /// Test authentication without granting access.
    func testAuthentication() async -> AuthenticationResult {
        let result = await authService.authenticate(reason: "Test Private Access authentication.")
        settingsStore.privateAccessLastAuthStatus = result.statusString
        return result
    }
}
