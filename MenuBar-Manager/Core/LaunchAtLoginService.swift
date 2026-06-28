import AppKit
import Foundation
import Observation
import ServiceManagement

/// Manages the "Launch at Login" preference using the public `SMAppService`
/// API added in macOS 13. No Accessibility, Apple Events, or Input Monitoring
/// permission is required.
///
/// `SMAppService.mainApp.register()` is only ever called when the user
/// explicitly enables the toggle in Settings; the service never auto-enables
/// login items by itself.
@MainActor
@Observable
final class LaunchAtLoginService {
    /// Last registration outcome, surfaced in Settings and Diagnostics. `nil`
    /// means no operation has been attempted yet.
    private(set) var lastRegistrationResult: RegistrationResult?

    /// Cached "currently registered" flag. Refreshed from `SMAppService`
    /// whenever `refreshStatus()` is called. Kept as a stored observable so the
    /// Settings toggle can render without blocking on a live SMAppService call
    /// during view updates.
    private(set) var isCurrentlyRegistered: Bool = false
    private(set) var statusDisplayName: String = "Not Registered"

    @ObservationIgnored private let service: SMAppService
    @ObservationIgnored private let diagnosticsLogger: DiagnosticsLogger?
    @ObservationIgnored private let bundleIdentifier: String

    init(
        service: SMAppService = .mainApp,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        bundleIdentifier: String = AppConstants.bundleIdentifier
    ) {
        self.service = service
        self.diagnosticsLogger = diagnosticsLogger
        self.bundleIdentifier = bundleIdentifier
    }

    // MARK: Registration outcome

    enum RegistrationResult: Equatable, Sendable {
        case registered
        case unregistered
        case failed(message: String)

        var isFailure: Bool {
            if case .failed = self { return true }
            return false
        }

        var displayName: String {
            switch self {
            case .registered:
                "Registered"
            case .unregistered:
                "Unregistered"
            case .failed(let message):
                "Failed: \(message)"
            }
        }
    }

    // MARK: Actions

    /// Enables launch at login. Calls `register()` on `SMAppService.mainApp`.
    /// The result is recorded in `lastRegistrationResult` and logged to the
    /// diagnostics ring buffer.
    func register() {
        do {
            try service.register()
            lastRegistrationResult = .registered
            isCurrentlyRegistered = true
            refreshStatus()
            diagnosticsLogger?.log("Launch at Login enabled via SMAppService.", level: .info)
        } catch {
            let message = Self.describe(error)
            lastRegistrationResult = .failed(message: message)
            isCurrentlyRegistered = false
            refreshStatus()
            diagnosticsLogger?.log("Launch at Login registration failed: \(message)", level: .error)
        }
    }

    /// Disables launch at login. Calls `unregister()` on `SMAppService.mainApp`.
    func unregister() {
        do {
            try service.unregister()
            lastRegistrationResult = .unregistered
            isCurrentlyRegistered = false
            refreshStatus()
            diagnosticsLogger?.log("Launch at Login disabled via SMAppService.", level: .info)
        } catch {
            let message = Self.describe(error)
            lastRegistrationResult = .failed(message: message)
            refreshStatus()
            diagnosticsLogger?.log("Launch at Login unregistration failed: \(message)", level: .error)
        }
    }

    /// Reflects the user's `launchAtLoginEnabled` setting onto the system.
    /// Called by `AppEnvironment` after settings load and whenever the toggle
    /// changes. Compares against the live `SMAppService` status to avoid
    /// spurious registration calls when the desired state already matches.
    func apply(enabled: Bool) {
        refreshStatus()
        if enabled && !isCurrentlyRegistered {
            register()
        } else if !enabled && isCurrentlyRegistered {
            unregister()
        }
    }

    /// Refreshes `isCurrentlyRegistered` from the live `SMAppService` status.
    func refreshStatus() {
        let status = service.status
        isCurrentlyRegistered = status == .enabled
        statusDisplayName = Self.displayName(for: status)
    }

    @discardableResult
    func openLoginItemsSettings() -> Bool {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return false
        }
        let opened = NSWorkspace.shared.open(url)
        diagnosticsLogger?.log(
            opened ? "Opened Login Items settings." : "Could not open Login Items settings.",
            level: opened ? .info : .warning,
            category: .launchAtLogin
        )
        return opened
    }

    // MARK: Helpers

    /// Converts an `SMAppService` error into a short human-readable string for
    /// diagnostics, without exposing internals. Kept `static` so it can be
    /// unit-tested in isolation.
    static func describe(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let message = localized.errorDescription, !message.isEmpty {
            return message
        }
        let nsError = error as NSError
        return "\(nsError.domain)(\(nsError.code)): \(nsError.localizedDescription)"
    }

    static func displayName(for status: SMAppService.Status) -> String {
        switch status {
        case .notRegistered:
            "Not Registered"
        case .enabled:
            "Enabled"
        case .requiresApproval:
            "Requires Approval"
        case .notFound:
            "Not Found"
        @unknown default:
            "Unknown"
        }
    }
}
