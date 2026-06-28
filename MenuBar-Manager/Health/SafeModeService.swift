import AppKit
import Foundation

enum SafeModeLaunchReason: String, CaseIterable, Codable, Sendable {
    case modifierHeld
    case launchFlag
    case previousCrash

    var displayName: String {
        switch self {
        case .modifierHeld:
            "Option key held at launch"
        case .launchFlag:
            "Safe Mode launch flag"
        case .previousCrash:
            "Previous crash marker"
        }
    }
}

struct SafeModeLaunchState: Equatable, Codable, Sendable {
    var reasons: [SafeModeLaunchReason]

    var isSafeModeActive: Bool {
        !reasons.isEmpty
    }

    var shouldStartExpanded: Bool {
        isSafeModeActive || reasons.contains(.previousCrash)
    }

    var displaySummary: String {
        guard !reasons.isEmpty else { return "Inactive" }
        return reasons.map(\.displayName).joined(separator: ", ")
    }

    static let inactive = SafeModeLaunchState(reasons: [])
}

final class SafeModeService {
    private let appSupportPaths: AppSupportPaths
    private let fileManager: FileManager

    init(
        appSupportPaths: AppSupportPaths,
        fileManager: FileManager = .default
    ) {
        self.appSupportPaths = appSupportPaths
        self.fileManager = fileManager
    }

    var safeModeFlagURL: URL {
        appSupportPaths.applicationSupportDirectory.appendingPathComponent("safe-mode-next-launch.flag")
    }

    var crashMarkerURL: URL {
        appSupportPaths.applicationSupportDirectory.appendingPathComponent("running.marker")
    }

    func detectLaunchState(modifierFlags: NSEvent.ModifierFlags = NSEvent.modifierFlags) -> SafeModeLaunchState {
        var reasons: [SafeModeLaunchReason] = []

        if modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option) {
            reasons.append(.modifierHeld)
        }

        if fileManager.fileExists(atPath: safeModeFlagURL.path) {
            reasons.append(.launchFlag)
            try? fileManager.removeItem(at: safeModeFlagURL)
        }

        if fileManager.fileExists(atPath: crashMarkerURL.path) {
            reasons.append(.previousCrash)
        }

        return SafeModeLaunchState(reasons: reasons)
    }

    func requestSafeModeOnNextLaunch() throws {
        try appSupportPaths.ensureDirectoriesExist()
        try Data("safe-mode\n".utf8).write(to: safeModeFlagURL, options: .atomic)
    }

    func writeRunningMarker() throws {
        try appSupportPaths.ensureDirectoriesExist()
        try Data("running\n".utf8).write(to: crashMarkerURL, options: .atomic)
    }

    func clearRunningMarker() throws {
        guard fileManager.fileExists(atPath: crashMarkerURL.path) else { return }
        try fileManager.removeItem(at: crashMarkerURL)
    }
}
