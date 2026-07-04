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
    typealias DateProvider = () -> Date

    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private let diagnosticsLogger: DiagnosticsLogger
    @ObservationIgnored private let trustProvider: TrustProvider
    @ObservationIgnored private let promptTrustProvider: TrustProvider
    @ObservationIgnored private let systemSettingsOpener: SystemSettingsOpener
    @ObservationIgnored private let statusCacheDuration: TimeInterval
    @ObservationIgnored private let now: DateProvider
    @ObservationIgnored private var lastStatusRefreshDate: Date?

    private(set) var status: AccessibilityPermissionStatus
    var currentStatus: AccessibilityPermissionStatus {
        refreshStatusIfNeeded(force: false)
    }

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
        },
        statusCacheDuration: TimeInterval = 1,
        now: @escaping DateProvider = Date.init
    ) {
        let trusted = trustProvider()
        let checkedAt = now()
        let initialStatus = Self.mapPermissionStatus(
            isTrusted: trusted,
            lastRecordedStatus: settingsStore.lastAccessibilityPermissionStatus
        )

        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.trustProvider = trustProvider
        self.promptTrustProvider = promptTrustProvider
        self.systemSettingsOpener = systemSettingsOpener
        self.statusCacheDuration = statusCacheDuration.isFinite ? max(0, statusCacheDuration) : 0
        self.now = now
        self.lastStatusRefreshDate = checkedAt
        self.status = initialStatus
        self.settingsStore.lastAccessibilityPermissionStatus = initialStatus.rawValue
    }

    @discardableResult
    func refreshStatus() -> AccessibilityPermissionStatus {
        refreshStatusIfNeeded(force: true)
    }

    func markStale() {
        lastStatusRefreshDate = nil
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

        lastStatusRefreshDate = now()
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

    private func refreshStatusIfNeeded(force: Bool) -> AccessibilityPermissionStatus {
        guard force || isStatusCacheStale else {
            return status
        }

        let mapped = Self.mapPermissionStatus(
            isTrusted: trustProvider(),
            lastRecordedStatus: settingsStore.lastAccessibilityPermissionStatus
        )
        lastStatusRefreshDate = now()
        applyStatus(mapped, reason: "permission check")
        return status
    }

    private var isStatusCacheStale: Bool {
        guard let lastStatusRefreshDate else { return true }
        return now().timeIntervalSince(lastStatusRefreshDate) >= statusCacheDuration
    }

}
