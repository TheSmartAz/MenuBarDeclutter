import CoreGraphics
import Foundation

enum AppConstants {
    static let displayName = "MenuBarDeclutter"
    static let defaultAppMode = "basic"
    static let currentSettingsMigrationVersion = "0.1.1"
    static let diagnosticsRingBufferLimit = 200

    // MARK: Separator geometry

    /// Default visible separator length when the menu bar is expanded.
    static let defaultExpandedSeparatorLength: Double = 20

    /// Multiplier applied to the widest screen width when computing the
    /// recommended collapsed separator length.
    static let collapsedSeparatorWidthMultiplier: Double = 2

    /// Absolute minimum collapsed separator length, regardless of screen size.
    static let collapsedSeparatorMinimumLength: Double = 1200

    /// Absolute maximum collapsed separator length. NSStatusItem cannot grow
    /// arbitrarily large, so cap the value well below its known limits.
    static let collapsedSeparatorMaximumLength: Double = 10000

    /// Accessibility label for the control item that toggles hidden items.
    static let controlItemAccessibilityLabel = "MenuBarDeclutter control"

    /// Accessibility label for the separator item.
    static let separatorAccessibilityLabel = "Hidden items separator"

    /// Accessibility label for the always-hidden separator.
    static let alwaysHiddenSeparatorAccessibilityLabel = "Always-hidden items separator"

    /// First-run and menu-triggered hint for positioning the separator.
    static let dragHintMessage = "Hold Command and drag the separator to choose which icons are hidden."

    /// Headless-safe screen frame used when macOS cannot report active screens.
    static let defaultScreenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

    // MARK: Phase 2 behavior defaults

    /// Default delay before the hidden items automatically collapse again.
    static let defaultAutoRehideDelaySeconds: Double = 5

    /// Default mouse-position polling interval used by hover reveal.
    static let defaultHoverRevealPollingIntervalSeconds: Double = 0.25

    /// Lower bound for the hover reveal polling interval to keep it responsive.
    static let minHoverRevealPollingIntervalSeconds: Double = 0.05

    /// Upper bound for the hover reveal polling interval to avoid stale polling.
    static let maxHoverRevealPollingIntervalSeconds: Double = 5

    /// Lower bound for the auto-rehide delay, regardless of user input.
    static let minAutoRehideDelaySeconds: Double = 0

    /// Upper bound for the auto-rehide delay (clamped to avoid pathological waits).
    static let maxAutoRehideDelaySeconds: Double = 600

    // MARK: Phase 4 Pro discovery defaults

    /// Default minimum interval between automatic Accessibility menu bar scans.
    static let defaultMenuBarScanIntervalSeconds: Double = 2

    /// Lower bound for Accessibility scan throttling. Manual refresh can still
    /// force a scan.
    static let minMenuBarScanIntervalSeconds: Double = 0.5

    /// Upper bound for Accessibility scan throttling.
    static let maxMenuBarScanIntervalSeconds: Double = 30

    // MARK: Phase 6 Second Bar defaults

    static let defaultSecondBarIconSize: Double = 32
    static let minSecondBarIconSize: Double = 20
    static let maxSecondBarIconSize: Double = 64

    // MARK: Phase 7 icon moving defaults

    static let defaultIconMovingMaxRetries: Int = 1
    static let minIconMovingMaxRetries: Int = 0
    static let maxIconMovingMaxRetries: Int = 3
    static let defaultIconMovingDragDuration: Double = 0.35
    static let minIconMovingDragDuration: Double = 0.15
    static let maxIconMovingDragDuration: Double = 1.5
    static let iconMovingTargetSpacingSourceWidthMultiplier: CGFloat = 1.5
    static let iconMovingMinimumTargetSpacing: CGFloat = 36

    // MARK: Default global hotkeys

    /// Virtual key code for "B" used by the default global hotkey.
    static let defaultHotkeyCode: UInt32 = 11

    /// Carbon modifier flags for the default hotkey (`cmdKey | optionKey`).
    static let defaultHotkeyModifierFlags: UInt32 = 0x0100 | 0x0800 // cmdKey | optionKey

    /// Virtual key code for "F" used by the default Find Icon hotkey.
    static let defaultSearchHotkeyCode: UInt32 = 3

    /// Carbon modifier flags for the default Find Icon hotkey (`cmdKey | optionKey`).
    static let defaultSearchHotkeyModifierFlags: UInt32 = 0x0100 | 0x0800 // cmdKey | optionKey

    /// Four-char-code signature used in the registered `EventHotKeyID`.
    static let hotkeyIDSignature: UInt32 = 0x4D424448 // 'MBDH' = MenuBarDeclutter Hotkey

    static let bundleIdentifier: String = {
        Bundle.main.bundleIdentifier ?? "local.MenuBarDeclutter"
    }()

    /// Marketing version (`CFBundleShortVersionString`), e.g. "1.0".
    static let marketingVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }()

    /// Build number (`CFBundleVersion`), e.g. "42".
    static let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }()

    static let appVersion: String = {
        switch (marketingVersion, buildNumber) {
        case let (marketing, build) where !marketing.isEmpty && !build.isEmpty:
            return "\(marketing) (\(build))"
        case let (marketing, _) where !marketing.isEmpty:
            return marketing
        case let (_, build) where !build.isEmpty:
            return build
        default:
            return "development"
        }
    }()

    // MARK: Phase 10 Layout & Capacity defaults

    static let defaultFullMenuBarModeAutoExitSeconds: Double = 30
    static let minFullMenuBarModeAutoExitSeconds: Double = 5
    static let maxFullMenuBarModeAutoExitSeconds: Double = 300

    static let defaultCrowdedRevealThresholdRatio: Double = 0.85
    static let minCrowdedRevealThresholdRatio: Double = 0.5
    static let maxCrowdedRevealThresholdRatio: Double = 1.0

    static let defaultMenuBarSpacingCustomItemSpacing: Int = 12
    static let minMenuBarSpacingCustomItemSpacing: Int = 2
    static let maxMenuBarSpacingCustomItemSpacing: Int = 32

    static let defaultMenuBarSpacingCustomSelectionPadding: Int = 8
    static let minMenuBarSpacingCustomSelectionPadding: Int = 2
    static let maxMenuBarSpacingCustomSelectionPadding: Int = 32

    // MARK: Phase 11 defaults

    static let defaultPrivateAccessUnlockDurationSeconds: Double = 300
    static let minPrivateAccessUnlockDurationSeconds: Double = 30
    static let maxPrivateAccessUnlockDurationSeconds: Double = 3600

    static let defaultMaxDynamicHotkeys: Int = 20
}
