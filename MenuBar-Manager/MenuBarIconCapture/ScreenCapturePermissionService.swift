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
}

@MainActor
@Observable
final class ScreenCapturePermissionService {
    typealias AccessProvider = @MainActor () -> Bool
    typealias SystemSettingsOpener = @MainActor () -> Bool

    @ObservationIgnored private let preflightAccess: AccessProvider
    @ObservationIgnored private let requestAccess: AccessProvider
    @ObservationIgnored private let systemSettingsOpener: SystemSettingsOpener

    private(set) var status: ScreenCapturePermissionStatus

    init(
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
        self.status = preflightAccess() ? .granted : .notGranted
    }

    @discardableResult
    func refreshStatus() -> ScreenCapturePermissionStatus {
        let newStatus: ScreenCapturePermissionStatus = preflightAccess() ? .granted : .notGranted
        if status != newStatus {
            status = newStatus
        }
        return status
    }

    @discardableResult
    func requestPermissionFromUserAction() -> ScreenCapturePermissionStatus {
        let granted = requestAccess()
        status = granted ? .granted : .notGranted
        return status
    }

    @discardableResult
    func openSystemSettingsPrivacyPane() -> Bool {
        systemSettingsOpener()
    }
}
