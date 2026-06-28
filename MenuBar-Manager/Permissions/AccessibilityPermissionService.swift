import AppKit
import ApplicationServices
import Foundation
import Observation

private let accessibilityPromptOptionKey = "AXTrustedCheckOptionPrompt"

enum AccessibilityPermissionStatus: String, CaseIterable, Identifiable, Sendable {
    case notRequested
    case denied
    case granted
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notRequested:
            "Not Requested"
        case .denied:
            "Denied"
        case .granted:
            "Granted"
        case .unknown:
            "Unknown"
        }
    }
}

@MainActor
@Observable
final class AccessibilityPermissionService {
    typealias TrustProvider = () -> Bool?
    typealias SystemSettingsOpener = () -> Bool

    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private let diagnosticsLogger: DiagnosticsLogger
    @ObservationIgnored private let trustProvider: TrustProvider
    @ObservationIgnored private let promptTrustProvider: TrustProvider
    @ObservationIgnored private let systemSettingsOpener: SystemSettingsOpener

    private(set) var status: AccessibilityPermissionStatus

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        trustProvider: @escaping TrustProvider = {
            AXIsProcessTrustedWithOptions([
                accessibilityPromptOptionKey: false
            ] as CFDictionary)
        },
        promptTrustProvider: @escaping TrustProvider = {
            AXIsProcessTrustedWithOptions([
                accessibilityPromptOptionKey: true
            ] as CFDictionary)
        },
        systemSettingsOpener: @escaping SystemSettingsOpener = {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
                return false
            }
            return NSWorkspace.shared.open(url)
        }
    ) {
        let initialStatus = Self.mapPermissionStatus(
            isTrusted: trustProvider(),
            lastRecordedStatus: settingsStore.lastAccessibilityPermissionStatus
        )

        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.trustProvider = trustProvider
        self.promptTrustProvider = promptTrustProvider
        self.systemSettingsOpener = systemSettingsOpener
        self.status = initialStatus
        self.settingsStore.lastAccessibilityPermissionStatus = initialStatus.rawValue
    }

    @discardableResult
    func refreshStatus() -> AccessibilityPermissionStatus {
        let mapped = Self.mapPermissionStatus(
            isTrusted: trustProvider(),
            lastRecordedStatus: settingsStore.lastAccessibilityPermissionStatus
        )
        applyStatus(mapped, reason: "permission check")
        return status
    }

    @discardableResult
    func requestPromptFromUserAction() -> AccessibilityPermissionStatus {
        let trusted = promptTrustProvider()
        let mapped: AccessibilityPermissionStatus
        if trusted == true {
            mapped = .granted
        } else if trusted == false {
            mapped = .denied
        } else {
            mapped = .unknown
        }

        applyStatus(mapped, reason: "user-requested Accessibility prompt")
        return status
    }

    func openSystemSettingsPrivacyPane() {
        if systemSettingsOpener() {
            diagnosticsLogger.log("Opened System Settings Accessibility privacy pane.")
        } else {
            diagnosticsLogger.log("Could not open System Settings Accessibility privacy pane.", level: .warning)
        }
    }

    static func mapPermissionStatus(
        isTrusted: Bool?,
        lastRecordedStatus: String?
    ) -> AccessibilityPermissionStatus {
        guard let isTrusted else {
            return .unknown
        }

        if isTrusted {
            return .granted
        }

        guard let lastRecordedStatus,
              let previous = AccessibilityPermissionStatus(rawValue: lastRecordedStatus) else {
            return .notRequested
        }

        switch previous {
        case .granted, .denied:
            return .denied
        case .notRequested:
            return .notRequested
        case .unknown:
            return .unknown
        }
    }

    private func applyStatus(_ newStatus: AccessibilityPermissionStatus, reason: String) {
        let previousStatus = status
        status = newStatus
        settingsStore.lastAccessibilityPermissionStatus = newStatus.rawValue

        guard previousStatus != newStatus else { return }
        diagnosticsLogger.log(
            "Accessibility permission status \(previousStatus.displayName) -> \(newStatus.displayName) (\(reason))."
        )
    }
}
