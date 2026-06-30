import AppKit
import Foundation

enum OnboardingSystemSettingsOpener {
    static let menuBarSettingsURL = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!
    static let systemSettingsApplicationURL = URL(fileURLWithPath: "/System/Applications/System Settings.app", isDirectory: true)

    @discardableResult
    static func openMenuBarSettings(open: (URL) -> Bool = { NSWorkspace.shared.open($0) }) -> Bool {
        if open(menuBarSettingsURL) {
            return true
        }

        return open(systemSettingsApplicationURL)
    }
}
