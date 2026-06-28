import Foundation
import Observation

@MainActor
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
        case automationPaused

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

    private static let registeredDefaults: [Key: Any] = [
        .hasCompletedOnboarding: false,
        .launchAtLoginEnabled: false,
        .lastKnownAppVersion: "",
        .appMode: AppConstants.defaultAppMode,
        .isCollapsed: false,
        .startCollapsed: false,
        .expandedSeparatorLength: AppConstants.defaultExpandedSeparatorLength,
        .hasSeenDragHint: false,
        .showPrimarySeparator: true,
        .proModeEnabled: false,
        .accessibilityDiscoveryEnabled: false,
        .menuBarScanIntervalSeconds: AppConstants.defaultMenuBarScanIntervalSeconds,
        .searchEnabled: true,
        .searchHotkeyEnabled: false,
        .searchRevealOnSelection: true,
        .searchHighlightOnSelection: true,
        .secondBarEnabled: false,
        .secondBarShowHiddenItems: true,
        .secondBarShowAlwaysHiddenItems: true,
        .secondBarAutoCloseAfterSelection: true,
        .secondBarPositionModeRaw: SecondBarPositionMode.belowMenuBar.rawValue,
        .secondBarIconSize: AppConstants.defaultSecondBarIconSize,
        .secondBarShowLabels: true,
        .secondBarCloseOnOutsideClick: true,
        .secondBarActivateOwningAppOnSelection: false,
        .iconMovingEnabled: false,
        .iconMovingRequireConfirmation: true,
        .iconMovingConfirmationSuppressed: false,
        .iconMovingMaxRetries: AppConstants.defaultIconMovingMaxRetries,
        .iconMovingDragDuration: AppConstants.defaultIconMovingDragDuration,
        .iconMovingAllowSystemItems: false,
        .smartTriggersEnabled: false,
        .automationPaused: false,
        .autoRehideEnabled: true,
        .autoRehideDelaySeconds: AppConstants.defaultAutoRehideDelaySeconds,
        .hoverRevealEnabled: false,
        .hoverRevealPollingIntervalSeconds: AppConstants.defaultHoverRevealPollingIntervalSeconds,
        .alwaysHiddenEnabled: false,
        .showSeparators: true,
        .globalHotkeyEnabled: false,
        .revealAllOnOptionClick: true
    ]

    private static let registrationDefaults: [String: Any] = Dictionary(
        uniqueKeysWithValues: registeredDefaults.map { ($0.rawValue, $1) }
    )

    private static func registeredDefault<Value>(_ key: Key, as type: Value.Type = Value.self) -> Value {
        guard let value = registeredDefaults[key] as? Value else {
            preconditionFailure("Missing registered default for \(key.rawValue)")
        }
        return value
    }

    var hasCompletedOnboarding: Bool {
        didSet { persist(hasCompletedOnboarding, for: .hasCompletedOnboarding) }
    }

    var launchAtLoginEnabled: Bool {
        didSet { persist(launchAtLoginEnabled, for: .launchAtLoginEnabled) }
    }

    var lastKnownAppVersion: String {
        didSet { persist(lastKnownAppVersion, for: .lastKnownAppVersion) }
    }

    var appMode: AppMode {
        didSet { persist(appMode.rawValue, for: .appMode) }
    }

    var isCollapsed: Bool {
        didSet { persist(isCollapsed, for: .isCollapsed) }
    }

    /// When `true`, the bar always launches collapsed regardless of the last
    /// persisted `isCollapsed` value. Default `false` (restore the last state).
    var startCollapsed: Bool {
        didSet { persist(startCollapsed, for: .startCollapsed) }
    }

    var expandedSeparatorLength: Double {
        didSet { persist(expandedSeparatorLength, for: .expandedSeparatorLength) }
    }

    var collapsedSeparatorLengthOverride: Double? {
        didSet { persistOptional(collapsedSeparatorLengthOverride, for: .collapsedSeparatorLengthOverride) }
    }

    var hasSeenDragHint: Bool {
        didSet { persist(hasSeenDragHint, for: .hasSeenDragHint) }
    }

    var showPrimarySeparator: Bool {
        didSet { persist(showPrimarySeparator, for: .showPrimarySeparator) }
    }

    // MARK: Phase 4 Pro discovery settings

    var proModeEnabled: Bool {
        didSet { persist(proModeEnabled, for: .proModeEnabled) }
    }

    var accessibilityDiscoveryEnabled: Bool {
        didSet { persist(accessibilityDiscoveryEnabled, for: .accessibilityDiscoveryEnabled) }
    }

    var lastAccessibilityPermissionStatus: String? {
        didSet { persistOptional(lastAccessibilityPermissionStatus, for: .lastAccessibilityPermissionStatus) }
    }

    private var menuBarScanIntervalSecondsStorage: Double

    var menuBarScanIntervalSeconds: Double {
        get { menuBarScanIntervalSecondsStorage }
        set {
            let clamped = Self.clampMenuBarScanInterval(newValue)
            menuBarScanIntervalSecondsStorage = clamped
            persist(clamped, for: .menuBarScanIntervalSeconds)
        }
    }

    // MARK: Phase 5 Find Icon search settings

    var searchEnabled: Bool {
        didSet { persist(searchEnabled, for: .searchEnabled) }
    }

    var searchHotkeyEnabled: Bool {
        didSet { persist(searchHotkeyEnabled, for: .searchHotkeyEnabled) }
    }

    var searchHotkeyKeyCode: Int? {
        didSet { persistOptional(searchHotkeyKeyCode, for: .searchHotkeyKeyCode) }
    }

    var searchHotkeyModifiersRaw: UInt? {
        didSet { persistOptional(searchHotkeyModifiersRaw, for: .searchHotkeyModifiersRaw) }
    }

    var searchRevealOnSelection: Bool {
        didSet { persist(searchRevealOnSelection, for: .searchRevealOnSelection) }
    }

    var searchHighlightOnSelection: Bool {
        didSet { persist(searchHighlightOnSelection, for: .searchHighlightOnSelection) }
    }

    // MARK: Phase 6 Second Bar settings

    var secondBarEnabled: Bool {
        didSet { persist(secondBarEnabled, for: .secondBarEnabled) }
    }

    var secondBarShowHiddenItems: Bool {
        didSet { persist(secondBarShowHiddenItems, for: .secondBarShowHiddenItems) }
    }

    var secondBarShowAlwaysHiddenItems: Bool {
        didSet { persist(secondBarShowAlwaysHiddenItems, for: .secondBarShowAlwaysHiddenItems) }
    }

    var secondBarAutoCloseAfterSelection: Bool {
        didSet { persist(secondBarAutoCloseAfterSelection, for: .secondBarAutoCloseAfterSelection) }
    }

    var secondBarPositionModeRaw: String {
        didSet { persist(secondBarPositionModeRaw, for: .secondBarPositionModeRaw) }
    }

    private var secondBarIconSizeStorage: Double

    var secondBarIconSize: Double {
        get { secondBarIconSizeStorage }
        set {
            let clamped = Self.clampSecondBarIconSize(newValue)
            secondBarIconSizeStorage = clamped
            persist(clamped, for: .secondBarIconSize)
        }
    }

    var secondBarShowLabels: Bool {
        didSet { persist(secondBarShowLabels, for: .secondBarShowLabels) }
    }

    var secondBarCloseOnOutsideClick: Bool {
        didSet { persist(secondBarCloseOnOutsideClick, for: .secondBarCloseOnOutsideClick) }
    }

    var secondBarActivateOwningAppOnSelection: Bool {
        didSet { persist(secondBarActivateOwningAppOnSelection, for: .secondBarActivateOwningAppOnSelection) }
    }

    // MARK: Phase 7 icon moving settings

    var iconMovingEnabled: Bool {
        didSet { persist(iconMovingEnabled, for: .iconMovingEnabled) }
    }

    var iconMovingRequireConfirmation: Bool {
        didSet { persist(iconMovingRequireConfirmation, for: .iconMovingRequireConfirmation) }
    }

    var iconMovingConfirmationSuppressed: Bool {
        didSet { persist(iconMovingConfirmationSuppressed, for: .iconMovingConfirmationSuppressed) }
    }

    private var iconMovingMaxRetriesStorage: Int

    var iconMovingMaxRetries: Int {
        get { iconMovingMaxRetriesStorage }
        set {
            let clamped = Self.clampIconMovingMaxRetries(newValue)
            iconMovingMaxRetriesStorage = clamped
            persist(clamped, for: .iconMovingMaxRetries)
        }
    }

    private var iconMovingDragDurationStorage: Double

    var iconMovingDragDuration: Double {
        get { iconMovingDragDurationStorage }
        set {
            let clamped = Self.clampIconMovingDragDuration(newValue)
            iconMovingDragDurationStorage = clamped
            persist(clamped, for: .iconMovingDragDuration)
        }
    }

    var iconMovingAllowSystemItems: Bool {
        didSet { persist(iconMovingAllowSystemItems, for: .iconMovingAllowSystemItems) }
    }

    // MARK: Phase 8 profiles and triggers

    var smartTriggersEnabled: Bool {
        didSet { persist(smartTriggersEnabled, for: .smartTriggersEnabled) }
    }

    var automationPaused: Bool {
        didSet { persist(automationPaused, for: .automationPaused) }
    }

    // MARK: Phase 2 behavior settings

    var autoRehideEnabled: Bool {
        didSet { persist(autoRehideEnabled, for: .autoRehideEnabled) }
    }

    private var autoRehideDelaySecondsStorage: Double

    /// Auto-rehide delay in seconds, clamped to
    /// `AppConstants.minAutoRehideDelaySeconds ... AppConstants.maxAutoRehideDelaySeconds`.
    var autoRehideDelaySeconds: Double {
        get { autoRehideDelaySecondsStorage }
        set {
            let clamped = Self.clampAutoRehideDelay(newValue)
            autoRehideDelaySecondsStorage = clamped
            persist(clamped, for: .autoRehideDelaySeconds)
        }
    }

    var hoverRevealEnabled: Bool {
        didSet { persist(hoverRevealEnabled, for: .hoverRevealEnabled) }
    }

    private var hoverRevealPollingIntervalSecondsStorage: Double

    /// Hover reveal polling interval. Clamp so users cannot pause the feature
    /// by entering 0 or a huge value.
    var hoverRevealPollingIntervalSeconds: Double {
        get { hoverRevealPollingIntervalSecondsStorage }
        set {
            let clamped = Self.clampHoverPollingInterval(newValue)
            hoverRevealPollingIntervalSecondsStorage = clamped
            persist(clamped, for: .hoverRevealPollingIntervalSeconds)
        }
    }

    var alwaysHiddenEnabled: Bool {
        didSet { persist(alwaysHiddenEnabled, for: .alwaysHiddenEnabled) }
    }

    var showSeparators: Bool {
        didSet { persist(showSeparators, for: .showSeparators) }
    }

    var globalHotkeyEnabled: Bool {
        didSet { persist(globalHotkeyEnabled, for: .globalHotkeyEnabled) }
    }

    var globalHotkeyKeyCode: Int? {
        didSet { persistOptional(globalHotkeyKeyCode, for: .globalHotkeyKeyCode) }
    }

    var globalHotkeyModifiersRaw: UInt? {
        didSet { persistOptional(globalHotkeyModifiersRaw, for: .globalHotkeyModifiersRaw) }
    }

    var revealAllOnOptionClick: Bool {
        didSet { persist(revealAllOnOptionClick, for: .revealAllOnOptionClick) }
    }

    private func persist<Value>(_ value: Value, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    private func persistOptional<Value>(_ value: Value?, for key: Key) {
        if let value {
            persist(value, for: key)
        } else {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    private static func bool(for key: Key, in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    private static func string(for key: Key, default defaultValue: String, in defaults: UserDefaults) -> String {
        defaults.string(forKey: key.rawValue) ?? defaultValue
    }

    private static func optionalString(for key: Key, in defaults: UserDefaults) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    private static func value<Value>(for key: Key, default defaultValue: Value, in defaults: UserDefaults) -> Value {
        defaults.object(forKey: key.rawValue) as? Value ?? defaultValue
    }

    private static func optionalValue<Value>(
        for key: Key,
        as type: Value.Type = Value.self,
        in defaults: UserDefaults
    ) -> Value? {
        defaults.object(forKey: key.rawValue) as? Value
    }

    private static func optionalDoubleWhenPresent(for key: Key, in defaults: UserDefaults) -> Double? {
        if defaults.object(forKey: key.rawValue) != nil {
            return defaults.double(forKey: key.rawValue)
        }
        return nil
    }

    private static func clampedDouble(
        for key: Key,
        default defaultValue: Double,
        clamp: (Double) -> Double,
        in defaults: UserDefaults
    ) -> Double {
        let storedValue = value(for: key, default: defaultValue, in: defaults)
        let clampedValue = clamp(storedValue)
        defaults.set(clampedValue, forKey: key.rawValue)
        return clampedValue
    }

    private static func clampedInt(
        for key: Key,
        default defaultValue: Int,
        clamp: (Int) -> Int,
        in defaults: UserDefaults
    ) -> Int {
        let storedValue = value(for: key, default: defaultValue, in: defaults)
        let clampedValue = clamp(storedValue)
        defaults.set(clampedValue, forKey: key.rawValue)
        return clampedValue
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: Self.registrationDefaults)

        self.hasCompletedOnboarding = Self.bool(for: .hasCompletedOnboarding, in: defaults)
        self.launchAtLoginEnabled = Self.bool(for: .launchAtLoginEnabled, in: defaults)
        self.lastKnownAppVersion = Self.string(
            for: .lastKnownAppVersion,
            default: Self.registeredDefault(.lastKnownAppVersion),
            in: defaults
        )

        let storedModeRaw = Self.string(
            for: .appMode,
            default: Self.registeredDefault(.appMode),
            in: defaults
        )
        self.appMode = AppMode(rawValue: storedModeRaw) ?? .basic

        self.isCollapsed = Self.bool(for: .isCollapsed, in: defaults)
        self.startCollapsed = Self.bool(for: .startCollapsed, in: defaults)
        self.expandedSeparatorLength = Self.value(
            for: .expandedSeparatorLength,
            default: Self.registeredDefault(.expandedSeparatorLength),
            in: defaults
        )
        self.collapsedSeparatorLengthOverride = Self.optionalDoubleWhenPresent(
            for: .collapsedSeparatorLengthOverride,
            in: defaults
        )
        self.hasSeenDragHint = Self.bool(for: .hasSeenDragHint, in: defaults)
        self.showPrimarySeparator = Self.value(
            for: .showPrimarySeparator,
            default: Self.registeredDefault(.showPrimarySeparator),
            in: defaults
        )
        self.proModeEnabled = Self.bool(for: .proModeEnabled, in: defaults)
        self.accessibilityDiscoveryEnabled = Self.bool(for: .accessibilityDiscoveryEnabled, in: defaults)
        self.lastAccessibilityPermissionStatus = Self.optionalString(
            for: .lastAccessibilityPermissionStatus,
            in: defaults
        )

        self.menuBarScanIntervalSecondsStorage = Self.clampedDouble(
            for: .menuBarScanIntervalSeconds,
            default: Self.registeredDefault(.menuBarScanIntervalSeconds),
            clamp: Self.clampMenuBarScanInterval,
            in: defaults
        )

        self.searchEnabled = Self.value(
            for: .searchEnabled,
            default: Self.registeredDefault(.searchEnabled),
            in: defaults
        )
        self.searchHotkeyEnabled = Self.bool(for: .searchHotkeyEnabled, in: defaults)
        self.searchHotkeyKeyCode = Self.optionalValue(for: .searchHotkeyKeyCode, in: defaults)
        self.searchHotkeyModifiersRaw = Self.optionalValue(for: .searchHotkeyModifiersRaw, in: defaults)
        self.searchRevealOnSelection = Self.value(
            for: .searchRevealOnSelection,
            default: Self.registeredDefault(.searchRevealOnSelection),
            in: defaults
        )
        self.searchHighlightOnSelection = Self.value(
            for: .searchHighlightOnSelection,
            default: Self.registeredDefault(.searchHighlightOnSelection),
            in: defaults
        )

        self.secondBarEnabled = Self.bool(for: .secondBarEnabled, in: defaults)
        self.secondBarShowHiddenItems = Self.value(
            for: .secondBarShowHiddenItems,
            default: Self.registeredDefault(.secondBarShowHiddenItems),
            in: defaults
        )
        self.secondBarShowAlwaysHiddenItems = Self.value(
            for: .secondBarShowAlwaysHiddenItems,
            default: Self.registeredDefault(.secondBarShowAlwaysHiddenItems),
            in: defaults
        )
        self.secondBarAutoCloseAfterSelection = Self.value(
            for: .secondBarAutoCloseAfterSelection,
            default: Self.registeredDefault(.secondBarAutoCloseAfterSelection),
            in: defaults
        )
        self.secondBarPositionModeRaw = Self.string(
            for: .secondBarPositionModeRaw,
            default: Self.registeredDefault(.secondBarPositionModeRaw),
            in: defaults
        )

        self.secondBarIconSizeStorage = Self.clampedDouble(
            for: .secondBarIconSize,
            default: Self.registeredDefault(.secondBarIconSize),
            clamp: Self.clampSecondBarIconSize,
            in: defaults
        )

        self.secondBarShowLabels = Self.value(
            for: .secondBarShowLabels,
            default: Self.registeredDefault(.secondBarShowLabels),
            in: defaults
        )
        self.secondBarCloseOnOutsideClick = Self.value(
            for: .secondBarCloseOnOutsideClick,
            default: Self.registeredDefault(.secondBarCloseOnOutsideClick),
            in: defaults
        )
        self.secondBarActivateOwningAppOnSelection = Self.bool(
            for: .secondBarActivateOwningAppOnSelection,
            in: defaults
        )

        self.iconMovingEnabled = Self.bool(for: .iconMovingEnabled, in: defaults)
        self.iconMovingRequireConfirmation = Self.value(
            for: .iconMovingRequireConfirmation,
            default: Self.registeredDefault(.iconMovingRequireConfirmation),
            in: defaults
        )
        self.iconMovingConfirmationSuppressed = Self.bool(for: .iconMovingConfirmationSuppressed, in: defaults)
        self.iconMovingMaxRetriesStorage = Self.clampedInt(
            for: .iconMovingMaxRetries,
            default: Self.registeredDefault(.iconMovingMaxRetries),
            clamp: Self.clampIconMovingMaxRetries,
            in: defaults
        )
        self.iconMovingDragDurationStorage = Self.clampedDouble(
            for: .iconMovingDragDuration,
            default: Self.registeredDefault(.iconMovingDragDuration),
            clamp: Self.clampIconMovingDragDuration,
            in: defaults
        )

        self.iconMovingAllowSystemItems = Self.bool(for: .iconMovingAllowSystemItems, in: defaults)
        self.smartTriggersEnabled = Self.bool(for: .smartTriggersEnabled, in: defaults)
        self.automationPaused = Self.bool(for: .automationPaused, in: defaults)

        self.autoRehideEnabled = Self.value(
            for: .autoRehideEnabled,
            default: Self.registeredDefault(.autoRehideEnabled),
            in: defaults
        )
        self.autoRehideDelaySecondsStorage = Self.clampedDouble(
            for: .autoRehideDelaySeconds,
            default: Self.registeredDefault(.autoRehideDelaySeconds),
            clamp: Self.clampAutoRehideDelay,
            in: defaults
        )

        self.hoverRevealEnabled = Self.bool(for: .hoverRevealEnabled, in: defaults)

        self.hoverRevealPollingIntervalSecondsStorage = Self.clampedDouble(
            for: .hoverRevealPollingIntervalSeconds,
            default: Self.registeredDefault(.hoverRevealPollingIntervalSeconds),
            clamp: Self.clampHoverPollingInterval,
            in: defaults
        )

        self.alwaysHiddenEnabled = Self.bool(for: .alwaysHiddenEnabled, in: defaults)
        self.showSeparators = Self.value(
            for: .showSeparators,
            default: Self.registeredDefault(.showSeparators),
            in: defaults
        )
        self.globalHotkeyEnabled = Self.bool(for: .globalHotkeyEnabled, in: defaults)

        self.globalHotkeyKeyCode = Self.optionalValue(for: .globalHotkeyKeyCode, in: defaults)
        self.globalHotkeyModifiersRaw = Self.optionalValue(for: .globalHotkeyModifiersRaw, in: defaults)

        self.revealAllOnOptionClick = Self.value(
            for: .revealAllOnOptionClick,
            default: Self.registeredDefault(.revealAllOnOptionClick),
            in: defaults
        )
    }

    func restoreDefaults() {
        hasCompletedOnboarding = Self.registeredDefault(.hasCompletedOnboarding)
        launchAtLoginEnabled = Self.registeredDefault(.launchAtLoginEnabled)
        lastKnownAppVersion = Self.registeredDefault(.lastKnownAppVersion)
        appMode = AppMode(rawValue: Self.registeredDefault(.appMode, as: String.self)) ?? .basic
        isCollapsed = Self.registeredDefault(.isCollapsed)
        startCollapsed = Self.registeredDefault(.startCollapsed)
        expandedSeparatorLength = Self.registeredDefault(.expandedSeparatorLength)
        collapsedSeparatorLengthOverride = nil
        hasSeenDragHint = Self.registeredDefault(.hasSeenDragHint)
        showPrimarySeparator = Self.registeredDefault(.showPrimarySeparator)
        proModeEnabled = Self.registeredDefault(.proModeEnabled)
        accessibilityDiscoveryEnabled = Self.registeredDefault(.accessibilityDiscoveryEnabled)
        lastAccessibilityPermissionStatus = nil
        menuBarScanIntervalSeconds = Self.registeredDefault(.menuBarScanIntervalSeconds)
        searchEnabled = Self.registeredDefault(.searchEnabled)
        searchHotkeyEnabled = Self.registeredDefault(.searchHotkeyEnabled)
        searchHotkeyKeyCode = nil
        searchHotkeyModifiersRaw = nil
        searchRevealOnSelection = Self.registeredDefault(.searchRevealOnSelection)
        searchHighlightOnSelection = Self.registeredDefault(.searchHighlightOnSelection)
        secondBarEnabled = Self.registeredDefault(.secondBarEnabled)
        secondBarShowHiddenItems = Self.registeredDefault(.secondBarShowHiddenItems)
        secondBarShowAlwaysHiddenItems = Self.registeredDefault(.secondBarShowAlwaysHiddenItems)
        secondBarAutoCloseAfterSelection = Self.registeredDefault(.secondBarAutoCloseAfterSelection)
        secondBarPositionModeRaw = Self.registeredDefault(.secondBarPositionModeRaw)
        secondBarIconSize = Self.registeredDefault(.secondBarIconSize)
        secondBarShowLabels = Self.registeredDefault(.secondBarShowLabels)
        secondBarCloseOnOutsideClick = Self.registeredDefault(.secondBarCloseOnOutsideClick)
        secondBarActivateOwningAppOnSelection = Self.registeredDefault(.secondBarActivateOwningAppOnSelection)
        iconMovingEnabled = Self.registeredDefault(.iconMovingEnabled)
        iconMovingRequireConfirmation = Self.registeredDefault(.iconMovingRequireConfirmation)
        iconMovingConfirmationSuppressed = Self.registeredDefault(.iconMovingConfirmationSuppressed)
        iconMovingMaxRetries = Self.registeredDefault(.iconMovingMaxRetries)
        iconMovingDragDuration = Self.registeredDefault(.iconMovingDragDuration)
        iconMovingAllowSystemItems = Self.registeredDefault(.iconMovingAllowSystemItems)
        smartTriggersEnabled = Self.registeredDefault(.smartTriggersEnabled)
        automationPaused = Self.registeredDefault(.automationPaused)

        autoRehideEnabled = Self.registeredDefault(.autoRehideEnabled)
        autoRehideDelaySeconds = Self.registeredDefault(.autoRehideDelaySeconds)
        hoverRevealEnabled = Self.registeredDefault(.hoverRevealEnabled)
        hoverRevealPollingIntervalSeconds = Self.registeredDefault(.hoverRevealPollingIntervalSeconds)
        alwaysHiddenEnabled = Self.registeredDefault(.alwaysHiddenEnabled)
        showSeparators = Self.registeredDefault(.showSeparators)
        globalHotkeyEnabled = Self.registeredDefault(.globalHotkeyEnabled)
        globalHotkeyKeyCode = nil
        globalHotkeyModifiersRaw = nil
        revealAllOnOptionClick = Self.registeredDefault(.revealAllOnOptionClick)
    }

    // MARK: Clamping helpers

    /// Central NaN/+inf/-inf + range clamp shared by all `Double` settings clampers.
    /// Single source for the NaN/Infinity repair policy so each clamp helper reduces
    /// to a one-line `range` + `nanFallback` configuration.
    private static func clamp(
        _ value: Double,
        to range: ClosedRange<Double>,
        nanFallback: Double
    ) -> Double {
        if value.isNaN {
            return nanFallback
        }
        if value == .infinity {
            return range.upperBound
        }
        if value == -.infinity {
            return range.lowerBound
        }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    /// Clamps the auto-rehide delay to the documented bounds. Used for both
    /// the setter and the load path so persisted invalid values are repaired.
    static func clampAutoRehideDelay(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minAutoRehideDelaySeconds ... AppConstants.maxAutoRehideDelaySeconds,
            nanFallback: AppConstants.defaultAutoRehideDelaySeconds
        )
    }

    /// Clamps the hover polling interval to a small positive range.
    static func clampHoverPollingInterval(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minHoverRevealPollingIntervalSeconds ... AppConstants.maxHoverRevealPollingIntervalSeconds,
            nanFallback: AppConstants.defaultHoverRevealPollingIntervalSeconds
        )
    }

    /// Clamps the Accessibility scan throttle interval to a conservative range.
    static func clampMenuBarScanInterval(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minMenuBarScanIntervalSeconds ... AppConstants.maxMenuBarScanIntervalSeconds,
            nanFallback: AppConstants.defaultMenuBarScanIntervalSeconds
        )
    }

    static func clampSecondBarIconSize(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minSecondBarIconSize ... AppConstants.maxSecondBarIconSize,
            nanFallback: AppConstants.defaultSecondBarIconSize
        )
    }

    static func clampIconMovingMaxRetries(_ value: Int) -> Int {
        min(max(value, AppConstants.minIconMovingMaxRetries), AppConstants.maxIconMovingMaxRetries)
    }

    static func clampIconMovingDragDuration(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minIconMovingDragDuration ... AppConstants.maxIconMovingDragDuration,
            nanFallback: AppConstants.defaultIconMovingDragDuration
        )
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
