import AppKit
import CoreGraphics
import Foundation
import Observation

enum ScreenCapturePermissionStatus: String, CaseIterable, Identifiable, Sendable {
    case granted
    case notGranted
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .granted:
            "Granted"
        case .notGranted:
            "Not Granted"
        case .unknown:
            "Unknown"
        }
    }

    var recoveryInstruction: String? {
        switch self {
        case .granted:
            nil
        case .notGranted, .unknown:
            "If MenuBarDeclutter is not listed, use Add in Screen & System Audio Recording and select /Applications/MenuBarDeclutter.app."
        }
    }
}

@MainActor
@Observable
final class ScreenCapturePermissionService {
    typealias AccessProvider = @MainActor () -> Bool
    typealias SystemSettingsOpener = @MainActor () -> Bool

    @ObservationIgnored private let preflightAccess: AccessProvider
    @ObservationIgnored private let requestAccess: AccessProvider
    @ObservationIgnored private let systemSettingsOpener: SystemSettingsOpener
    @ObservationIgnored private let settingsStore: SettingsStore?

    private(set) var status: ScreenCapturePermissionStatus

    init(
        settingsStore: SettingsStore? = nil,
        preflightAccess: @escaping AccessProvider = { CGPreflightScreenCaptureAccess() },
        requestAccess: @escaping AccessProvider = { CGRequestScreenCaptureAccess() },
        systemSettingsOpener: @escaping SystemSettingsOpener = {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
                return false
            }
            return NSWorkspace.shared.open(url)
        }
    ) {
        self.preflightAccess = preflightAccess
        self.requestAccess = requestAccess
        self.systemSettingsOpener = systemSettingsOpener
        self.settingsStore = settingsStore
        self.status = preflightAccess() ? .granted : .notGranted
        self.settingsStore?.lastScreenCapturePermissionStatus = self.status.rawValue
    }

    @discardableResult
    func refreshStatus() -> ScreenCapturePermissionStatus {
        let newStatus: ScreenCapturePermissionStatus = preflightAccess() ? .granted : .notGranted
        applyStatus(newStatus)
        return status
    }

    @discardableResult
    func requestPermissionFromUserAction() -> ScreenCapturePermissionStatus {
        let granted = requestAccess()
        applyStatus(granted ? .granted : .notGranted)
        return status
    }

    @discardableResult
    func openSystemSettingsPrivacyPane() -> Bool {
        systemSettingsOpener()
    }

    private func applyStatus(_ newStatus: ScreenCapturePermissionStatus) {
        if status != newStatus {
            status = newStatus
        }
        settingsStore?.lastScreenCapturePermissionStatus = newStatus.rawValue
    }
}
