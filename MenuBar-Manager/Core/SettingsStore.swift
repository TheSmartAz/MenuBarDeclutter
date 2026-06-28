import Foundation
import Observation

@Observable
final class SettingsStore {
    enum AppMode: String, CaseIterable, Identifiable {
        case basic

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .basic:
                "Basic Mode"
            }
        }
    }

    enum Key: String, CaseIterable {
        case hasCompletedOnboarding
        case launchAtLoginEnabled
        case lastKnownAppVersion
        case appMode
        case isCollapsed
        case startCollapsed
        case expandedSeparatorLength
        case collapsedSeparatorLengthOverride
        case hasSeenDragHint
        case showPrimarySeparator

        // Phase 4 — opt-in Accessibility discovery
        case proModeEnabled
        case accessibilityDiscoveryEnabled
        case lastAccessibilityPermissionStatus
        case menuBarScanIntervalSeconds

        // Phase 5 — Find Icon search
        case searchEnabled
        case searchHotkeyEnabled
        case searchHotkeyKeyCode
        case searchHotkeyModifiersRaw
        case searchRevealOnSelection
        case searchHighlightOnSelection

        // Phase 6 — Second Bar
        case secondBarEnabled
        case secondBarShowHiddenItems
        case secondBarShowAlwaysHiddenItems
        case secondBarAutoCloseAfterSelection
        case secondBarPositionModeRaw
        case secondBarIconSize
        case secondBarShowLabels
        case secondBarCloseOnOutsideClick
        case secondBarActivateOwningAppOnSelection

        // Phase 7 — explicit icon moving
        case iconMovingEnabled
        case iconMovingRequireConfirmation
        case iconMovingConfirmationSuppressed
        case iconMovingMaxRetries
        case iconMovingDragDuration
        case iconMovingAllowSystemItems

        // Phase 8 — profiles and smart triggers
        case smartTriggersEnabled

        // Phase 2 — Basic UX polish
        case autoRehideEnabled
        case autoRehideDelaySeconds
        case hoverRevealEnabled
        case hoverRevealPollingIntervalSeconds
        case alwaysHiddenEnabled
        case showSeparators
        case globalHotkeyEnabled
        case globalHotkeyKeyCode
        case globalHotkeyModifiersRaw
        case revealAllOnOptionClick
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding.rawValue) }
    }

    var launchAtLoginEnabled: Bool {
        didSet { defaults.set(launchAtLoginEnabled, forKey: Key.launchAtLoginEnabled.rawValue) }
    }

    var lastKnownAppVersion: String {
        didSet { defaults.set(lastKnownAppVersion, forKey: Key.lastKnownAppVersion.rawValue) }
    }

    var appMode: AppMode {
        didSet { defaults.set(appMode.rawValue, forKey: Key.appMode.rawValue) }
    }

    var isCollapsed: Bool {
        didSet { defaults.set(isCollapsed, forKey: Key.isCollapsed.rawValue) }
    }

    /// When `true`, the bar always launches collapsed regardless of the last
    /// persisted `isCollapsed` value. Default `false` (restore the last state).
    var startCollapsed: Bool {
        didSet { defaults.set(startCollapsed, forKey: Key.startCollapsed.rawValue) }
    }

    var expandedSeparatorLength: Double {
        didSet { defaults.set(expandedSeparatorLength, forKey: Key.expandedSeparatorLength.rawValue) }
    }

    var collapsedSeparatorLengthOverride: Double? {
        didSet {
            if let collapsedSeparatorLengthOverride {
                defaults.set(
                    collapsedSeparatorLengthOverride,
                    forKey: Key.collapsedSeparatorLengthOverride.rawValue
                )
            } else {
                defaults.removeObject(forKey: Key.collapsedSeparatorLengthOverride.rawValue)
            }
        }
    }

    var hasSeenDragHint: Bool {
        didSet { defaults.set(hasSeenDragHint, forKey: Key.hasSeenDragHint.rawValue) }
    }

    var showPrimarySeparator: Bool {
        didSet { defaults.set(showPrimarySeparator, forKey: Key.showPrimarySeparator.rawValue) }
    }

    // MARK: Phase 4 Pro discovery settings

    var proModeEnabled: Bool {
        didSet { defaults.set(proModeEnabled, forKey: Key.proModeEnabled.rawValue) }
    }

    var accessibilityDiscoveryEnabled: Bool {
        didSet { defaults.set(accessibilityDiscoveryEnabled, forKey: Key.accessibilityDiscoveryEnabled.rawValue) }
    }

    var lastAccessibilityPermissionStatus: String? {
        didSet {
            if let lastAccessibilityPermissionStatus {
                defaults.set(
                    lastAccessibilityPermissionStatus,
                    forKey: Key.lastAccessibilityPermissionStatus.rawValue
                )
            } else {
                defaults.removeObject(forKey: Key.lastAccessibilityPermissionStatus.rawValue)
            }
        }
    }

    private var menuBarScanIntervalSecondsStorage: Double

    var menuBarScanIntervalSeconds: Double {
        get { menuBarScanIntervalSecondsStorage }
        set {
            let clamped = Self.clampMenuBarScanInterval(newValue)
            menuBarScanIntervalSecondsStorage = clamped
            defaults.set(clamped, forKey: Key.menuBarScanIntervalSeconds.rawValue)
        }
    }

    // MARK: Phase 5 Find Icon search settings

    var searchEnabled: Bool {
        didSet { defaults.set(searchEnabled, forKey: Key.searchEnabled.rawValue) }
    }

    var searchHotkeyEnabled: Bool {
        didSet { defaults.set(searchHotkeyEnabled, forKey: Key.searchHotkeyEnabled.rawValue) }
    }

    var searchHotkeyKeyCode: Int? {
        didSet {
            if let searchHotkeyKeyCode {
                defaults.set(searchHotkeyKeyCode, forKey: Key.searchHotkeyKeyCode.rawValue)
            } else {
                defaults.removeObject(forKey: Key.searchHotkeyKeyCode.rawValue)
            }
        }
    }

    var searchHotkeyModifiersRaw: UInt? {
        didSet {
            if let searchHotkeyModifiersRaw {
                defaults.set(searchHotkeyModifiersRaw, forKey: Key.searchHotkeyModifiersRaw.rawValue)
            } else {
                defaults.removeObject(forKey: Key.searchHotkeyModifiersRaw.rawValue)
            }
        }
    }

    var searchRevealOnSelection: Bool {
        didSet { defaults.set(searchRevealOnSelection, forKey: Key.searchRevealOnSelection.rawValue) }
    }

    var searchHighlightOnSelection: Bool {
        didSet { defaults.set(searchHighlightOnSelection, forKey: Key.searchHighlightOnSelection.rawValue) }
    }

    // MARK: Phase 6 Second Bar settings

    var secondBarEnabled: Bool {
        didSet { defaults.set(secondBarEnabled, forKey: Key.secondBarEnabled.rawValue) }
    }

    var secondBarShowHiddenItems: Bool {
        didSet { defaults.set(secondBarShowHiddenItems, forKey: Key.secondBarShowHiddenItems.rawValue) }
    }

    var secondBarShowAlwaysHiddenItems: Bool {
        didSet { defaults.set(secondBarShowAlwaysHiddenItems, forKey: Key.secondBarShowAlwaysHiddenItems.rawValue) }
    }

    var secondBarAutoCloseAfterSelection: Bool {
        didSet { defaults.set(secondBarAutoCloseAfterSelection, forKey: Key.secondBarAutoCloseAfterSelection.rawValue) }
    }

    var secondBarPositionModeRaw: String {
        didSet { defaults.set(secondBarPositionModeRaw, forKey: Key.secondBarPositionModeRaw.rawValue) }
    }

    private var secondBarIconSizeStorage: Double

    var secondBarIconSize: Double {
        get { secondBarIconSizeStorage }
        set {
            let clamped = Self.clampSecondBarIconSize(newValue)
            secondBarIconSizeStorage = clamped
            defaults.set(clamped, forKey: Key.secondBarIconSize.rawValue)
        }
    }

    var secondBarShowLabels: Bool {
        didSet { defaults.set(secondBarShowLabels, forKey: Key.secondBarShowLabels.rawValue) }
    }

    var secondBarCloseOnOutsideClick: Bool {
        didSet { defaults.set(secondBarCloseOnOutsideClick, forKey: Key.secondBarCloseOnOutsideClick.rawValue) }
    }

    var secondBarActivateOwningAppOnSelection: Bool {
        didSet {
            defaults.set(secondBarActivateOwningAppOnSelection, forKey: Key.secondBarActivateOwningAppOnSelection.rawValue)
        }
    }

    // MARK: Phase 7 icon moving settings

    var iconMovingEnabled: Bool {
        didSet { defaults.set(iconMovingEnabled, forKey: Key.iconMovingEnabled.rawValue) }
    }

    var iconMovingRequireConfirmation: Bool {
        didSet { defaults.set(iconMovingRequireConfirmation, forKey: Key.iconMovingRequireConfirmation.rawValue) }
    }

    var iconMovingConfirmationSuppressed: Bool {
        didSet {
            defaults.set(iconMovingConfirmationSuppressed, forKey: Key.iconMovingConfirmationSuppressed.rawValue)
        }
    }

    private var iconMovingMaxRetriesStorage: Int

    var iconMovingMaxRetries: Int {
        get { iconMovingMaxRetriesStorage }
        set {
            let clamped = Self.clampIconMovingMaxRetries(newValue)
            iconMovingMaxRetriesStorage = clamped
            defaults.set(clamped, forKey: Key.iconMovingMaxRetries.rawValue)
        }
    }

    private var iconMovingDragDurationStorage: Double

    var iconMovingDragDuration: Double {
        get { iconMovingDragDurationStorage }
        set {
            let clamped = Self.clampIconMovingDragDuration(newValue)
            iconMovingDragDurationStorage = clamped
            defaults.set(clamped, forKey: Key.iconMovingDragDuration.rawValue)
        }
    }

    var iconMovingAllowSystemItems: Bool {
        didSet { defaults.set(iconMovingAllowSystemItems, forKey: Key.iconMovingAllowSystemItems.rawValue) }
    }

    // MARK: Phase 8 profiles and triggers

    var smartTriggersEnabled: Bool {
        didSet { defaults.set(smartTriggersEnabled, forKey: Key.smartTriggersEnabled.rawValue) }
    }

    // MARK: Phase 2 behavior settings

    var autoRehideEnabled: Bool {
        didSet { defaults.set(autoRehideEnabled, forKey: Key.autoRehideEnabled.rawValue) }
    }

    private var autoRehideDelaySecondsStorage: Double

    /// Auto-rehide delay in seconds, clamped to
    /// `AppConstants.minAutoRehideDelaySeconds ... AppConstants.maxAutoRehideDelaySeconds`.
    var autoRehideDelaySeconds: Double {
        get { autoRehideDelaySecondsStorage }
        set {
            let clamped = Self.clampAutoRehideDelay(newValue)
            autoRehideDelaySecondsStorage = clamped
            defaults.set(clamped, forKey: Key.autoRehideDelaySeconds.rawValue)
        }
    }

    var hoverRevealEnabled: Bool {
        didSet {
            defaults.set(hoverRevealEnabled, forKey: Key.hoverRevealEnabled.rawValue)
        }
    }

    private var hoverRevealPollingIntervalSecondsStorage: Double

    /// Hover reveal polling interval. Clamp so users cannot pause the feature
    /// by entering 0 or a huge value.
    var hoverRevealPollingIntervalSeconds: Double {
        get { hoverRevealPollingIntervalSecondsStorage }
        set {
            let clamped = Self.clampHoverPollingInterval(newValue)
            hoverRevealPollingIntervalSecondsStorage = clamped
            defaults.set(clamped, forKey: Key.hoverRevealPollingIntervalSeconds.rawValue)
        }
    }

    var alwaysHiddenEnabled: Bool {
        didSet { defaults.set(alwaysHiddenEnabled, forKey: Key.alwaysHiddenEnabled.rawValue) }
    }

    var showSeparators: Bool {
        didSet { defaults.set(showSeparators, forKey: Key.showSeparators.rawValue) }
    }

    var globalHotkeyEnabled: Bool {
        didSet { defaults.set(globalHotkeyEnabled, forKey: Key.globalHotkeyEnabled.rawValue) }
    }

    var globalHotkeyKeyCode: Int? {
        didSet {
            if let globalHotkeyKeyCode {
                defaults.set(globalHotkeyKeyCode, forKey: Key.globalHotkeyKeyCode.rawValue)
            } else {
                defaults.removeObject(forKey: Key.globalHotkeyKeyCode.rawValue)
            }
        }
    }

    var globalHotkeyModifiersRaw: UInt? {
        didSet {
            if let globalHotkeyModifiersRaw {
                defaults.set(globalHotkeyModifiersRaw, forKey: Key.globalHotkeyModifiersRaw.rawValue)
            } else {
                defaults.removeObject(forKey: Key.globalHotkeyModifiersRaw.rawValue)
            }
        }
    }

    var revealAllOnOptionClick: Bool {
        didSet { defaults.set(revealAllOnOptionClick, forKey: Key.revealAllOnOptionClick.rawValue) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Key.hasCompletedOnboarding.rawValue: false,
            Key.launchAtLoginEnabled.rawValue: false,
            Key.lastKnownAppVersion.rawValue: "",
            Key.appMode.rawValue: AppConstants.defaultAppMode,
            Key.isCollapsed.rawValue: false,
            Key.startCollapsed.rawValue: false,
            Key.expandedSeparatorLength.rawValue: AppConstants.defaultExpandedSeparatorLength,
            Key.hasSeenDragHint.rawValue: false,
            Key.showPrimarySeparator.rawValue: true,
            Key.proModeEnabled.rawValue: false,
            Key.accessibilityDiscoveryEnabled.rawValue: false,
            Key.menuBarScanIntervalSeconds.rawValue: AppConstants.defaultMenuBarScanIntervalSeconds,
            Key.searchEnabled.rawValue: true,
            Key.searchHotkeyEnabled.rawValue: false,
            Key.searchRevealOnSelection.rawValue: true,
            Key.searchHighlightOnSelection.rawValue: true,
            Key.secondBarEnabled.rawValue: false,
            Key.secondBarShowHiddenItems.rawValue: true,
            Key.secondBarShowAlwaysHiddenItems.rawValue: true,
            Key.secondBarAutoCloseAfterSelection.rawValue: true,
            Key.secondBarPositionModeRaw.rawValue: SecondBarPositionMode.belowMenuBar.rawValue,
            Key.secondBarIconSize.rawValue: AppConstants.defaultSecondBarIconSize,
            Key.secondBarShowLabels.rawValue: true,
            Key.secondBarCloseOnOutsideClick.rawValue: true,
            Key.secondBarActivateOwningAppOnSelection.rawValue: false,
            Key.iconMovingEnabled.rawValue: false,
            Key.iconMovingRequireConfirmation.rawValue: true,
            Key.iconMovingConfirmationSuppressed.rawValue: false,
            Key.iconMovingMaxRetries.rawValue: AppConstants.defaultIconMovingMaxRetries,
            Key.iconMovingDragDuration.rawValue: AppConstants.defaultIconMovingDragDuration,
            Key.iconMovingAllowSystemItems.rawValue: false,
            Key.smartTriggersEnabled.rawValue: false,
            Key.autoRehideEnabled.rawValue: true,
            Key.autoRehideDelaySeconds.rawValue: AppConstants.defaultAutoRehideDelaySeconds,
            Key.hoverRevealEnabled.rawValue: false,
            Key.hoverRevealPollingIntervalSeconds.rawValue: AppConstants.defaultHoverRevealPollingIntervalSeconds,
            Key.alwaysHiddenEnabled.rawValue: false,
            Key.showSeparators.rawValue: true,
            Key.globalHotkeyEnabled.rawValue: false,
            Key.revealAllOnOptionClick.rawValue: true
        ])

        self.hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding.rawValue)
        self.launchAtLoginEnabled = defaults.bool(forKey: Key.launchAtLoginEnabled.rawValue)
        self.lastKnownAppVersion = defaults.string(forKey: Key.lastKnownAppVersion.rawValue) ?? ""

        let storedMode = defaults.string(forKey: Key.appMode.rawValue)
            .flatMap(AppMode.init(rawValue:)) ?? .basic
        self.appMode = storedMode

        self.isCollapsed = defaults.bool(forKey: Key.isCollapsed.rawValue)
        self.startCollapsed = defaults.bool(forKey: Key.startCollapsed.rawValue)

        let expandedLength = defaults.object(forKey: Key.expandedSeparatorLength.rawValue) as? Double
        self.expandedSeparatorLength = expandedLength ?? AppConstants.defaultExpandedSeparatorLength

        if defaults.object(forKey: Key.collapsedSeparatorLengthOverride.rawValue) != nil {
            self.collapsedSeparatorLengthOverride = defaults.double(
                forKey: Key.collapsedSeparatorLengthOverride.rawValue
            )
        } else {
            self.collapsedSeparatorLengthOverride = nil
        }

        self.hasSeenDragHint = defaults.bool(forKey: Key.hasSeenDragHint.rawValue)
        self.showPrimarySeparator = defaults.object(forKey: Key.showPrimarySeparator.rawValue) as? Bool ?? true
        self.proModeEnabled = defaults.bool(forKey: Key.proModeEnabled.rawValue)
        self.accessibilityDiscoveryEnabled = defaults.bool(forKey: Key.accessibilityDiscoveryEnabled.rawValue)
        self.lastAccessibilityPermissionStatus = defaults.string(
            forKey: Key.lastAccessibilityPermissionStatus.rawValue
        )

        let storedScanInterval = defaults.object(forKey: Key.menuBarScanIntervalSeconds.rawValue) as? Double
        let clampedScanInterval = Self.clampMenuBarScanInterval(
            storedScanInterval ?? AppConstants.defaultMenuBarScanIntervalSeconds
        )
        self.menuBarScanIntervalSecondsStorage = clampedScanInterval
        defaults.set(clampedScanInterval, forKey: Key.menuBarScanIntervalSeconds.rawValue)

        self.searchEnabled = defaults.object(forKey: Key.searchEnabled.rawValue) as? Bool ?? true
        self.searchHotkeyEnabled = defaults.bool(forKey: Key.searchHotkeyEnabled.rawValue)
        self.searchHotkeyKeyCode = defaults.object(forKey: Key.searchHotkeyKeyCode.rawValue) as? Int
        self.searchHotkeyModifiersRaw = defaults.object(forKey: Key.searchHotkeyModifiersRaw.rawValue) as? UInt
        self.searchRevealOnSelection = defaults.object(forKey: Key.searchRevealOnSelection.rawValue) as? Bool ?? true
        self.searchHighlightOnSelection = defaults.object(forKey: Key.searchHighlightOnSelection.rawValue) as? Bool ?? true

        self.secondBarEnabled = defaults.bool(forKey: Key.secondBarEnabled.rawValue)
        self.secondBarShowHiddenItems = defaults.object(forKey: Key.secondBarShowHiddenItems.rawValue) as? Bool ?? true
        self.secondBarShowAlwaysHiddenItems = defaults.object(forKey: Key.secondBarShowAlwaysHiddenItems.rawValue) as? Bool ?? true
        self.secondBarAutoCloseAfterSelection = defaults.object(forKey: Key.secondBarAutoCloseAfterSelection.rawValue) as? Bool ?? true
        self.secondBarPositionModeRaw = defaults.string(forKey: Key.secondBarPositionModeRaw.rawValue)
            ?? SecondBarPositionMode.belowMenuBar.rawValue

        let storedSecondBarIconSize = defaults.object(forKey: Key.secondBarIconSize.rawValue) as? Double
        let clampedSecondBarIconSize = Self.clampSecondBarIconSize(
            storedSecondBarIconSize ?? AppConstants.defaultSecondBarIconSize
        )
        self.secondBarIconSizeStorage = clampedSecondBarIconSize
        defaults.set(clampedSecondBarIconSize, forKey: Key.secondBarIconSize.rawValue)

        self.secondBarShowLabels = defaults.object(forKey: Key.secondBarShowLabels.rawValue) as? Bool ?? true
        self.secondBarCloseOnOutsideClick = defaults.object(forKey: Key.secondBarCloseOnOutsideClick.rawValue) as? Bool ?? true
        self.secondBarActivateOwningAppOnSelection = defaults.bool(
            forKey: Key.secondBarActivateOwningAppOnSelection.rawValue
        )

        self.iconMovingEnabled = defaults.bool(forKey: Key.iconMovingEnabled.rawValue)
        self.iconMovingRequireConfirmation = defaults.object(forKey: Key.iconMovingRequireConfirmation.rawValue) as? Bool ?? true
        self.iconMovingConfirmationSuppressed = defaults.bool(forKey: Key.iconMovingConfirmationSuppressed.rawValue)

        let storedIconMoveRetries = defaults.object(forKey: Key.iconMovingMaxRetries.rawValue) as? Int
        let clampedIconMoveRetries = Self.clampIconMovingMaxRetries(
            storedIconMoveRetries ?? AppConstants.defaultIconMovingMaxRetries
        )
        self.iconMovingMaxRetriesStorage = clampedIconMoveRetries
        defaults.set(clampedIconMoveRetries, forKey: Key.iconMovingMaxRetries.rawValue)

        let storedIconMoveDuration = defaults.object(forKey: Key.iconMovingDragDuration.rawValue) as? Double
        let clampedIconMoveDuration = Self.clampIconMovingDragDuration(
            storedIconMoveDuration ?? AppConstants.defaultIconMovingDragDuration
        )
        self.iconMovingDragDurationStorage = clampedIconMoveDuration
        defaults.set(clampedIconMoveDuration, forKey: Key.iconMovingDragDuration.rawValue)

        self.iconMovingAllowSystemItems = defaults.bool(forKey: Key.iconMovingAllowSystemItems.rawValue)
        self.smartTriggersEnabled = defaults.bool(forKey: Key.smartTriggersEnabled.rawValue)

        self.autoRehideEnabled = defaults.object(forKey: Key.autoRehideEnabled.rawValue) as? Bool ?? true

        let storedDelay = defaults.object(forKey: Key.autoRehideDelaySeconds.rawValue) as? Double
        let clampedDelay = Self.clampAutoRehideDelay(
            storedDelay ?? AppConstants.defaultAutoRehideDelaySeconds
        )
        self.autoRehideDelaySecondsStorage = clampedDelay
        defaults.set(clampedDelay, forKey: Key.autoRehideDelaySeconds.rawValue)

        self.hoverRevealEnabled = defaults.bool(forKey: Key.hoverRevealEnabled.rawValue)

        let storedInterval = defaults.object(forKey: Key.hoverRevealPollingIntervalSeconds.rawValue) as? Double
        let clampedInterval = Self.clampHoverPollingInterval(
            storedInterval ?? AppConstants.defaultHoverRevealPollingIntervalSeconds
        )
        self.hoverRevealPollingIntervalSecondsStorage = clampedInterval
        defaults.set(clampedInterval, forKey: Key.hoverRevealPollingIntervalSeconds.rawValue)

        self.alwaysHiddenEnabled = defaults.bool(forKey: Key.alwaysHiddenEnabled.rawValue)
        self.showSeparators = defaults.object(forKey: Key.showSeparators.rawValue) as? Bool ?? true
        self.globalHotkeyEnabled = defaults.bool(forKey: Key.globalHotkeyEnabled.rawValue)

        self.globalHotkeyKeyCode = defaults.object(forKey: Key.globalHotkeyKeyCode.rawValue) as? Int
        self.globalHotkeyModifiersRaw = defaults.object(forKey: Key.globalHotkeyModifiersRaw.rawValue) as? UInt

        self.revealAllOnOptionClick = defaults.object(forKey: Key.revealAllOnOptionClick.rawValue) as? Bool ?? true
    }

    func restoreDefaults() {
        hasCompletedOnboarding = false
        launchAtLoginEnabled = false
        lastKnownAppVersion = ""
        appMode = .basic
        isCollapsed = false
        startCollapsed = false
        expandedSeparatorLength = AppConstants.defaultExpandedSeparatorLength
        collapsedSeparatorLengthOverride = nil
        hasSeenDragHint = false
        showPrimarySeparator = true
        proModeEnabled = false
        accessibilityDiscoveryEnabled = false
        lastAccessibilityPermissionStatus = nil
        menuBarScanIntervalSeconds = AppConstants.defaultMenuBarScanIntervalSeconds
        searchEnabled = true
        searchHotkeyEnabled = false
        searchHotkeyKeyCode = nil
        searchHotkeyModifiersRaw = nil
        searchRevealOnSelection = true
        searchHighlightOnSelection = true
        secondBarEnabled = false
        secondBarShowHiddenItems = true
        secondBarShowAlwaysHiddenItems = true
        secondBarAutoCloseAfterSelection = true
        secondBarPositionModeRaw = SecondBarPositionMode.belowMenuBar.rawValue
        secondBarIconSize = AppConstants.defaultSecondBarIconSize
        secondBarShowLabels = true
        secondBarCloseOnOutsideClick = true
        secondBarActivateOwningAppOnSelection = false
        iconMovingEnabled = false
        iconMovingRequireConfirmation = true
        iconMovingConfirmationSuppressed = false
        iconMovingMaxRetries = AppConstants.defaultIconMovingMaxRetries
        iconMovingDragDuration = AppConstants.defaultIconMovingDragDuration
        iconMovingAllowSystemItems = false
        smartTriggersEnabled = false

        autoRehideEnabled = true
        autoRehideDelaySeconds = AppConstants.defaultAutoRehideDelaySeconds
        hoverRevealEnabled = false
        hoverRevealPollingIntervalSeconds = AppConstants.defaultHoverRevealPollingIntervalSeconds
        alwaysHiddenEnabled = false
        showSeparators = true
        globalHotkeyEnabled = false
        globalHotkeyKeyCode = nil
        globalHotkeyModifiersRaw = nil
        revealAllOnOptionClick = true
    }

    // MARK: Clamping helpers

    /// Clamps the auto-rehide delay to the documented bounds. Used for both
    /// the setter and the load path so persisted invalid values are repaired.
    static func clampAutoRehideDelay(_ value: Double) -> Double {
        if value.isNaN {
            return AppConstants.defaultAutoRehideDelaySeconds
        }
        if value == .infinity {
            return AppConstants.maxAutoRehideDelaySeconds
        }
        if value == -.infinity {
            return AppConstants.minAutoRehideDelaySeconds
        }
        return min(max(value, AppConstants.minAutoRehideDelaySeconds), AppConstants.maxAutoRehideDelaySeconds)
    }

    /// Clamps the hover polling interval to a small positive range.
    static func clampHoverPollingInterval(_ value: Double) -> Double {
        if value.isNaN {
            return AppConstants.defaultHoverRevealPollingIntervalSeconds
        }
        if value == .infinity {
            return AppConstants.maxHoverRevealPollingIntervalSeconds
        }
        if value == -.infinity {
            return AppConstants.minHoverRevealPollingIntervalSeconds
        }
        return min(
            max(value, AppConstants.minHoverRevealPollingIntervalSeconds),
            AppConstants.maxHoverRevealPollingIntervalSeconds
        )
    }

    /// Clamps the Accessibility scan throttle interval to a conservative range.
    static func clampMenuBarScanInterval(_ value: Double) -> Double {
        if value.isNaN {
            return AppConstants.defaultMenuBarScanIntervalSeconds
        }
        if value == .infinity {
            return AppConstants.maxMenuBarScanIntervalSeconds
        }
        if value == -.infinity {
            return AppConstants.minMenuBarScanIntervalSeconds
        }
        return min(
            max(value, AppConstants.minMenuBarScanIntervalSeconds),
            AppConstants.maxMenuBarScanIntervalSeconds
        )
    }

    static func clampSecondBarIconSize(_ value: Double) -> Double {
        if value.isNaN {
            return AppConstants.defaultSecondBarIconSize
        }
        if value == .infinity {
            return AppConstants.maxSecondBarIconSize
        }
        if value == -.infinity {
            return AppConstants.minSecondBarIconSize
        }
        return min(max(value, AppConstants.minSecondBarIconSize), AppConstants.maxSecondBarIconSize)
    }

    static func clampIconMovingMaxRetries(_ value: Int) -> Int {
        min(max(value, AppConstants.minIconMovingMaxRetries), AppConstants.maxIconMovingMaxRetries)
    }

    static func clampIconMovingDragDuration(_ value: Double) -> Double {
        if value.isNaN {
            return AppConstants.defaultIconMovingDragDuration
        }
        if value == .infinity {
            return AppConstants.maxIconMovingDragDuration
        }
        if value == -.infinity {
            return AppConstants.minIconMovingDragDuration
        }
        return min(max(value, AppConstants.minIconMovingDragDuration), AppConstants.maxIconMovingDragDuration)
    }

    func effectiveSecondBarPositionMode() -> SecondBarPositionMode {
        SecondBarPositionMode(rawValue: secondBarPositionModeRaw) ?? .belowMenuBar
    }

    // MARK: Global hotkey

    /// Returns the active hotkey model, or the app default when nothing has
    /// been recorded yet.
    func effectiveGlobalHotkey() -> HotkeyModel {
        if let keyCode = globalHotkeyKeyCode,
           let modifiers = globalHotkeyModifiersRaw {
            return HotkeyModel(keyCode: UInt32(keyCode), modifiersRaw: UInt32(modifiers))
        }
        return HotkeyModel(
            keyCode: AppConstants.defaultHotkeyCode,
            modifiersRaw: AppConstants.defaultHotkeyModifierFlags
        )
    }

    /// Stores the given hotkey (or clears it when `nil`).
    func setGlobalHotkey(_ model: HotkeyModel?) {
        if let model {
            globalHotkeyKeyCode = Int(model.keyCode)
            globalHotkeyModifiersRaw = UInt(model.modifiersRaw)
        } else {
            globalHotkeyKeyCode = nil
            globalHotkeyModifiersRaw = nil
        }
    }

    /// Resets the stored hotkey to the app default (Option + Command + B).
    func resetGlobalHotkeyToDefault() {
        globalHotkeyKeyCode = Int(AppConstants.defaultHotkeyCode)
        globalHotkeyModifiersRaw = UInt(AppConstants.defaultHotkeyModifierFlags)
    }

    // MARK: Search hotkey

    /// Returns the active Find Icon hotkey model, or the app default when
    /// nothing has been recorded yet.
    func effectiveSearchHotkey() -> HotkeyModel {
        if let keyCode = searchHotkeyKeyCode,
           let modifiers = searchHotkeyModifiersRaw {
            return HotkeyModel(keyCode: UInt32(keyCode), modifiersRaw: UInt32(modifiers))
        }
        return HotkeyModel(
            keyCode: AppConstants.defaultSearchHotkeyCode,
            modifiersRaw: AppConstants.defaultSearchHotkeyModifierFlags
        )
    }

    /// Stores the given Find Icon hotkey (or clears it when `nil`).
    func setSearchHotkey(_ model: HotkeyModel?) {
        if let model {
            searchHotkeyKeyCode = Int(model.keyCode)
            searchHotkeyModifiersRaw = UInt(model.modifiersRaw)
        } else {
            searchHotkeyKeyCode = nil
            searchHotkeyModifiersRaw = nil
        }
    }

    /// Resets the Find Icon hotkey to Option + Command + F.
    func resetSearchHotkeyToDefault() {
        searchHotkeyKeyCode = Int(AppConstants.defaultSearchHotkeyCode)
        searchHotkeyModifiersRaw = UInt(AppConstants.defaultSearchHotkeyModifierFlags)
    }
}
