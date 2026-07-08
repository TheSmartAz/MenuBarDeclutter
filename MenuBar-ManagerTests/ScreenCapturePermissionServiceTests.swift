import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Screen Capture Permission Service")
@MainActor
struct ScreenCapturePermissionServiceTests {
    @Test func notGrantedStatusProvidesManualAddRecoveryInstruction() {
        let instruction = ScreenCapturePermissionStatus.notGranted.recoveryInstruction

        #expect(instruction?.contains("Screen & System Audio Recording") == true)
        #expect(instruction?.contains("Add") == true)
        #expect(instruction?.contains("/Applications/MenuBarDeclutter.app") == true)
    }

    @Test func grantedStatusDoesNotShowRecoveryInstruction() {
        #expect(ScreenCapturePermissionStatus.granted.recoveryInstruction == nil)
    }

    @Test func failedRequestKeepsNotGrantedStatusAndRecoveryPath() {
        var requestCount = 0
        var openSettingsCount = 0
        let service = ScreenCapturePermissionService(
            preflightAccess: { false },
            requestAccess: {
                requestCount += 1
                return false
            },
            systemSettingsOpener: {
                openSettingsCount += 1
                return true
            }
        )

        let status = service.requestPermissionFromUserAction()
        service.openSystemSettingsPrivacyPane()

        #expect(status == .notGranted)
        #expect(service.status == .notGranted)
        #expect(service.status.recoveryInstruction != nil)
        #expect(requestCount == 1)
        #expect(openSettingsCount == 1)
    }

    @Test func storesLastObservedPermissionStatus() {
        let suiteName = "ScreenCapturePermissionServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        var hasAccess = false
        let service = ScreenCapturePermissionService(
            settingsStore: store,
            preflightAccess: { hasAccess },
            requestAccess: { true }
        )

        #expect(service.status == .notGranted)
        #expect(store.lastScreenCapturePermissionStatus == ScreenCapturePermissionStatus.notGranted.rawValue)

        hasAccess = true
        #expect(service.refreshStatus() == .granted)
        #expect(store.lastScreenCapturePermissionStatus == ScreenCapturePermissionStatus.granted.rawValue)

        hasAccess = false
        #expect(service.requestPermissionFromUserAction() == .granted)
        #expect(store.lastScreenCapturePermissionStatus == ScreenCapturePermissionStatus.granted.rawValue)
    }
}
