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
        case settingsMigrationVersion
        case v01SafeDefaultsNoticePending
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
        case lastScreenCapturePermissionStatus
        case menuBarScanIntervalSeconds
        case renderedIconCaptureEnabled
        case renderedIconRevealSweepEnabled

        // Phase 5 — Find Icon search
        case searchEnabled
        case searchHotkeyEnabled
        case searchHotkeyKeyCode
        case searchHotkeyModifiersRaw
        case searchRevealOnSelection
        case searchHighlightOnSelection

        // Phase 6 — Second Bar
        case secondBarEnabled
        case secondBarPrimaryClickEnabled
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

        // Phase 9.2 — private dogfood QA
        case dogfoodModeEnabled
        case dogfoodRunID
        case dogfoodNotesEnabled

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

        // Phase 10 — Layout & Capacity
        case layoutFeaturesEnabled
        case fullMenuBarModeEnabled
        case crowdedRevealRescueEnabled
        case layoutSuggestionsEnabled
        case showCapacityWarnings
        case fullMenuBarModeAutoExitEnabled
        case fullMenuBarModeAutoExitSeconds
        case fullMenuBarModeShowsSecondBar
        case fullMenuBarModeSuspendsAutoRehide
        case fullMenuBarModeShowsSpacerMarkers
        case crowdedRevealAutoOpenSecondBar
        case crowdedRevealAskBeforeSwitching
        case crowdedRescueWorkspaceFallbackPreference
        case crowdedRevealThresholdRatio
        case crowdedRevealRequireProEstimate
        case spacerItemsEnabled
        case showSpacerMarkers
        case spacerItemsJSONVersion
        case menuBarSpacingLabsEnabled
        case menuBarSpacingPreset
        case menuBarSpacingCustomItemSpacing
        case menuBarSpacingCustomSelectionPadding
        case menuBarSpacingHasBackup
        case menuBarSpacingLastApplyStatus
        case menuBarSpacingLastApplyDate

        // Phase 11 — Groups, Private Access, Hotkeys, Shortcuts, Migration
        case groupsEnabled
        case groupStatusItemsEnabled
        case protectedGroupsRequireAuth
        case groupsJSONVersion
        case privateAccessEnabled
        case privateAccessProtectAlwaysHidden
        case privateAccessProtectSecondBar
        case privateAccessProtectFindIcon
        case privateAccessProtectIconMoving
        case privateAccessProtectSpacingLabs
        case privateAccessProtectProfileApply
        case privateAccessProtectAutomationCommands
        case privateAccessUnlockDurationSeconds
        case privateAccessLastAuthStatus
        case privateAccessAllowDevicePasswordFallback
        case appIntentsEnabled
        case appIntentsCanApplyProfiles
        case appIntentsCanAccessLabs
        case dynamicHotkeysEnabled
        case maxDynamicHotkeys

        // Phase 16+ preview workspaces/function bar gates
        case workspacesPreviewEnabled
        case functionBarPreviewEnabled
        case functionBarPrimaryClickEnabled
        case functionBarPlacementPreference
        case functionBarShowSetSwitcher
        case functionBarShowLabels
        case functionBarDensity
        case functionBarCloseOnOutsideClick
        case functionBarKeyboardNavigationEnabled
        case setBuilderPreviewEnabled
        case setBuilderDragDropEnabled
        case setBuilderShowAdvancedLibraryItems
        case setBuilderDefaultGroupReferenceMode
        case setBuilderShowFunctionBarPreview
        case setBuilderAutosaveDrafts
        case setBuilderWarnBeforeLinkedGroupEdits
        case infoStripPreviewEnabled
        case infoStripAutoShowEnabled
        case infoStripHoverToFunctionBarEnabled
        case infoStripCloseOnOutsideClick
        case infoStripPauseWhenFunctionBarPinned
        case infoStripKeyboardNavigationEnabled
        case infoStripShowPreviewBadge
    }

    static let privacySafeExportOmittedKeys: Set<Key> = [
        .launchAtLoginEnabled,
        .lastKnownAppVersion,
        .settingsMigrationVersion,
        .v01SafeDefaultsNoticePending,
        .showPrimarySeparator,
        .lastAccessibilityPermissionStatus,
        .lastScreenCapturePermissionStatus,
        .iconMovingConfirmationSuppressed,
        .dogfoodModeEnabled,
        .dogfoodRunID,
        .dogfoodNotesEnabled,
        .menuBarSpacingHasBackup,
        .menuBarSpacingLastApplyStatus,
        .menuBarSpacingLastApplyDate,
        .privateAccessLastAuthStatus
    ]

    static let importSkippedKeys: Set<Key> = privacySafeExportOmittedKeys

    static var privacySafeExportKeys: [Key] {
        Key.allCases.filter { !privacySafeExportOmittedKeys.contains($0) }
    }

    static var migrationSnapshotKeys: [Key] {
        Key.allCases.filter { $0 != .showPrimarySeparator }
    }

    @ObservationIgnored private let defaults: UserDefaults

    private static let registeredDefaults: [Key: Any] = [
        .hasCompletedOnboarding: false,
        .launchAtLoginEnabled: false,
        .lastKnownAppVersion: "",
        .settingsMigrationVersion: "",
        .v01SafeDefaultsNoticePending: false,
        .appMode: AppConstants.defaultAppMode,
        .isCollapsed: false,
        .startCollapsed: false,
        .expandedSeparatorLength: AppConstants.defaultExpandedSeparatorLength,
        .hasSeenDragHint: false,
        .showPrimarySeparator: true,
        .proModeEnabled: false,
        .accessibilityDiscoveryEnabled: false,
        .menuBarScanIntervalSeconds: AppConstants.defaultMenuBarScanIntervalSeconds,
        .renderedIconCaptureEnabled: false,
        .renderedIconRevealSweepEnabled: false,
        .searchEnabled: true,
        .searchHotkeyEnabled: false,
        .searchRevealOnSelection: true,
        .searchHighlightOnSelection: true,
        .secondBarEnabled: true,
        .secondBarPrimaryClickEnabled: false,
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
        .automationPaused: true,
        .dogfoodModeEnabled: false,
        .dogfoodNotesEnabled: true,
        .autoRehideEnabled: false,
        .autoRehideDelaySeconds: AppConstants.defaultAutoRehideDelaySeconds,
        .hoverRevealEnabled: false,
        .hoverRevealPollingIntervalSeconds: AppConstants.defaultHoverRevealPollingIntervalSeconds,
        .alwaysHiddenEnabled: false,
        .showSeparators: true,
        .globalHotkeyEnabled: false,
        .revealAllOnOptionClick: true,

        // Phase 10 — Layout & Capacity defaults
        .layoutFeaturesEnabled: true,
        .fullMenuBarModeEnabled: true,
        .crowdedRevealRescueEnabled: true,
        .layoutSuggestionsEnabled: true,
        .showCapacityWarnings: true,
        .fullMenuBarModeAutoExitEnabled: true,
        .fullMenuBarModeAutoExitSeconds: AppConstants.defaultFullMenuBarModeAutoExitSeconds,
        .fullMenuBarModeShowsSecondBar: false,
        .fullMenuBarModeSuspendsAutoRehide: true,
        .fullMenuBarModeShowsSpacerMarkers: true,
        .crowdedRevealAutoOpenSecondBar: true,
        .crowdedRevealAskBeforeSwitching: false,
        .crowdedRescueWorkspaceFallbackPreference: CrowdedRescueWorkspaceFallbackPreference.preferSecondBar.rawValue,
        .crowdedRevealThresholdRatio: AppConstants.defaultCrowdedRevealThresholdRatio,
        .crowdedRevealRequireProEstimate: false,
        .spacerItemsEnabled: true,
        .showSpacerMarkers: true,
        .spacerItemsJSONVersion: 1,
        .menuBarSpacingLabsEnabled: false,
        .menuBarSpacingPreset: MenuBarSpacingPreset.system.rawValue,
        .menuBarSpacingCustomItemSpacing: AppConstants.defaultMenuBarSpacingCustomItemSpacing,
        .menuBarSpacingCustomSelectionPadding: AppConstants.defaultMenuBarSpacingCustomSelectionPadding,
        .menuBarSpacingHasBackup: false,

        // Phase 11 defaults
        .groupsEnabled: true,
        .groupStatusItemsEnabled: false,
        .protectedGroupsRequireAuth: false,
        .groupsJSONVersion: 1,
        .privateAccessEnabled: false,
        .privateAccessProtectAlwaysHidden: false,
        .privateAccessProtectSecondBar: false,
        .privateAccessProtectFindIcon: false,
        .privateAccessProtectIconMoving: true,
        .privateAccessProtectSpacingLabs: true,
        .privateAccessProtectProfileApply: false,
        .privateAccessProtectAutomationCommands: false,
        .privateAccessUnlockDurationSeconds: AppConstants.defaultPrivateAccessUnlockDurationSeconds,
        .privateAccessAllowDevicePasswordFallback: true,
        .appIntentsEnabled: true,
        .appIntentsCanApplyProfiles: false,
        .appIntentsCanAccessLabs: false,
        .dynamicHotkeysEnabled: false,
        .maxDynamicHotkeys: AppConstants.defaultMaxDynamicHotkeys,

        // Phase 16+ preview defaults
        .workspacesPreviewEnabled: false,
        .functionBarPreviewEnabled: false,
        .functionBarPrimaryClickEnabled: false,
        .functionBarPlacementPreference: FunctionBarPlacementPreference.belowMenuBarIcon.rawValue,
        .functionBarShowSetSwitcher: true,
        .functionBarShowLabels: true,
        .functionBarDensity: "regular",
        .functionBarCloseOnOutsideClick: true,
        .functionBarKeyboardNavigationEnabled: true,
        .setBuilderPreviewEnabled: false,
        .setBuilderDragDropEnabled: true,
        .setBuilderShowAdvancedLibraryItems: false,
        .setBuilderDefaultGroupReferenceMode: WorkspaceGroupReferenceMode.linked.rawValue,
        .setBuilderShowFunctionBarPreview: true,
        .setBuilderAutosaveDrafts: true,
        .setBuilderWarnBeforeLinkedGroupEdits: true,
        .infoStripPreviewEnabled: false,
        .infoStripAutoShowEnabled: false,
        .infoStripHoverToFunctionBarEnabled: true,
        .infoStripCloseOnOutsideClick: true,
        .infoStripPauseWhenFunctionBarPinned: true,
        .infoStripKeyboardNavigationEnabled: true,
        .infoStripShowPreviewBadge: true
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

    var settingsMigrationVersion: String {
        didSet { persist(settingsMigrationVersion, for: .settingsMigrationVersion) }
    }

    var v01SafeDefaultsNoticePending: Bool {
        didSet { persist(v01SafeDefaultsNoticePending, for: .v01SafeDefaultsNoticePending) }
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
        didSet {
            if !showPrimarySeparator {
                showPrimarySeparator = true
            }
            persist(true, for: .showPrimarySeparator)
        }
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

    var lastScreenCapturePermissionStatus: String? {
        didSet { persistOptional(lastScreenCapturePermissionStatus, for: .lastScreenCapturePermissionStatus) }
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

    var renderedIconCaptureEnabled: Bool {
        didSet { persist(renderedIconCaptureEnabled, for: .renderedIconCaptureEnabled) }
    }

    var renderedIconRevealSweepEnabled: Bool {
        didSet { persist(renderedIconRevealSweepEnabled, for: .renderedIconRevealSweepEnabled) }
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

    var secondBarPrimaryClickEnabled: Bool {
        didSet { persist(secondBarPrimaryClickEnabled, for: .secondBarPrimaryClickEnabled) }
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

    // MARK: Phase 9.2 dogfood settings

    var dogfoodModeEnabled: Bool {
        didSet { persist(dogfoodModeEnabled, for: .dogfoodModeEnabled) }
    }

    var dogfoodRunID: String? {
        didSet { persistOptional(dogfoodRunID, for: .dogfoodRunID) }
    }

    var dogfoodNotesEnabled: Bool {
        didSet { persist(dogfoodNotesEnabled, for: .dogfoodNotesEnabled) }
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

    // MARK: Phase 10 Layout & Capacity settings

    var layoutFeaturesEnabled: Bool {
        didSet { persist(layoutFeaturesEnabled, for: .layoutFeaturesEnabled) }
    }

    var fullMenuBarModeEnabled: Bool {
        didSet { persist(fullMenuBarModeEnabled, for: .fullMenuBarModeEnabled) }
    }

    var crowdedRevealRescueEnabled: Bool {
        didSet { persist(crowdedRevealRescueEnabled, for: .crowdedRevealRescueEnabled) }
    }

    var layoutSuggestionsEnabled: Bool {
        didSet { persist(layoutSuggestionsEnabled, for: .layoutSuggestionsEnabled) }
    }

    var showCapacityWarnings: Bool {
        didSet { persist(showCapacityWarnings, for: .showCapacityWarnings) }
    }

    var fullMenuBarModeAutoExitEnabled: Bool {
        didSet { persist(fullMenuBarModeAutoExitEnabled, for: .fullMenuBarModeAutoExitEnabled) }
    }

    private var fullMenuBarModeAutoExitSecondsStorage: Double

    var fullMenuBarModeAutoExitSeconds: Double {
        get { fullMenuBarModeAutoExitSecondsStorage }
        set {
            let clamped = Self.clampFullMenuBarModeAutoExitSeconds(newValue)
            fullMenuBarModeAutoExitSecondsStorage = clamped
            persist(clamped, for: .fullMenuBarModeAutoExitSeconds)
        }
    }

    var fullMenuBarModeShowsSecondBar: Bool {
        didSet { persist(fullMenuBarModeShowsSecondBar, for: .fullMenuBarModeShowsSecondBar) }
    }

    var fullMenuBarModeSuspendsAutoRehide: Bool {
        didSet { persist(fullMenuBarModeSuspendsAutoRehide, for: .fullMenuBarModeSuspendsAutoRehide) }
    }

    var fullMenuBarModeShowsSpacerMarkers: Bool {
        didSet { persist(fullMenuBarModeShowsSpacerMarkers, for: .fullMenuBarModeShowsSpacerMarkers) }
    }

    var crowdedRevealAutoOpenSecondBar: Bool {
        didSet { persist(crowdedRevealAutoOpenSecondBar, for: .crowdedRevealAutoOpenSecondBar) }
    }

    var crowdedRevealAskBeforeSwitching: Bool {
        didSet { persist(crowdedRevealAskBeforeSwitching, for: .crowdedRevealAskBeforeSwitching) }
    }

    var crowdedRescueWorkspaceFallbackPreference: String {
        didSet {
            if CrowdedRescueWorkspaceFallbackPreference(rawValue: crowdedRescueWorkspaceFallbackPreference) == nil {
                crowdedRescueWorkspaceFallbackPreference = CrowdedRescueWorkspaceFallbackPreference.preferSecondBar.rawValue
            }
            persist(crowdedRescueWorkspaceFallbackPreference, for: .crowdedRescueWorkspaceFallbackPreference)
        }
    }

    private var crowdedRevealThresholdRatioStorage: Double

    var crowdedRevealThresholdRatio: Double {
        get { crowdedRevealThresholdRatioStorage }
        set {
            let clamped = Self.clampCrowdedRevealThresholdRatio(newValue)
            crowdedRevealThresholdRatioStorage = clamped
            persist(clamped, for: .crowdedRevealThresholdRatio)
        }
    }

    var crowdedRevealRequireProEstimate: Bool {
        didSet { persist(crowdedRevealRequireProEstimate, for: .crowdedRevealRequireProEstimate) }
    }

    var spacerItemsEnabled: Bool {
        didSet { persist(spacerItemsEnabled, for: .spacerItemsEnabled) }
    }

    var showSpacerMarkers: Bool {
        didSet { persist(showSpacerMarkers, for: .showSpacerMarkers) }
    }

    var spacerItemsJSONVersion: Int {
        didSet { persist(spacerItemsJSONVersion, for: .spacerItemsJSONVersion) }
    }

    var menuBarSpacingLabsEnabled: Bool {
        didSet { persist(menuBarSpacingLabsEnabled, for: .menuBarSpacingLabsEnabled) }
    }

    var menuBarSpacingPreset: String {
        didSet { persist(menuBarSpacingPreset, for: .menuBarSpacingPreset) }
    }

    private var menuBarSpacingCustomItemSpacingStorage: Int

    var menuBarSpacingCustomItemSpacing: Int {
        get { menuBarSpacingCustomItemSpacingStorage }
        set {
            let clamped = Self.clampMenuBarSpacingCustomItemSpacing(newValue)
            menuBarSpacingCustomItemSpacingStorage = clamped
            persist(clamped, for: .menuBarSpacingCustomItemSpacing)
        }
    }

    private var menuBarSpacingCustomSelectionPaddingStorage: Int

    var menuBarSpacingCustomSelectionPadding: Int {
        get { menuBarSpacingCustomSelectionPaddingStorage }
        set {
            let clamped = Self.clampMenuBarSpacingCustomSelectionPadding(newValue)
            menuBarSpacingCustomSelectionPaddingStorage = clamped
            persist(clamped, for: .menuBarSpacingCustomSelectionPadding)
        }
    }

    var menuBarSpacingHasBackup: Bool {
        didSet { persist(menuBarSpacingHasBackup, for: .menuBarSpacingHasBackup) }
    }

    var menuBarSpacingLastApplyStatus: String? {
        didSet { persistOptional(menuBarSpacingLastApplyStatus, for: .menuBarSpacingLastApplyStatus) }
    }

    var menuBarSpacingLastApplyDate: Date? {
        didSet { persistOptional(menuBarSpacingLastApplyDate, for: .menuBarSpacingLastApplyDate) }
    }

    // MARK: Phase 11 — Groups, Private Access, Hotkeys, Shortcuts

    var groupsEnabled: Bool {
        didSet { persist(groupsEnabled, for: .groupsEnabled) }
    }

    var groupStatusItemsEnabled: Bool {
        didSet { persist(groupStatusItemsEnabled, for: .groupStatusItemsEnabled) }
    }

    var protectedGroupsRequireAuth: Bool {
        didSet { persist(protectedGroupsRequireAuth, for: .protectedGroupsRequireAuth) }
    }

    var groupsJSONVersion: Int {
        didSet { persist(groupsJSONVersion, for: .groupsJSONVersion) }
    }

    var privateAccessEnabled: Bool {
        didSet { persist(privateAccessEnabled, for: .privateAccessEnabled) }
    }

    var privateAccessProtectAlwaysHidden: Bool {
        didSet { persist(privateAccessProtectAlwaysHidden, for: .privateAccessProtectAlwaysHidden) }
    }

    var privateAccessProtectSecondBar: Bool {
        didSet { persist(privateAccessProtectSecondBar, for: .privateAccessProtectSecondBar) }
    }

    var privateAccessProtectFindIcon: Bool {
        didSet { persist(privateAccessProtectFindIcon, for: .privateAccessProtectFindIcon) }
    }

    var privateAccessProtectIconMoving: Bool {
        didSet { persist(privateAccessProtectIconMoving, for: .privateAccessProtectIconMoving) }
    }

    var privateAccessProtectSpacingLabs: Bool {
        didSet { persist(privateAccessProtectSpacingLabs, for: .privateAccessProtectSpacingLabs) }
    }

    var privateAccessProtectProfileApply: Bool {
        didSet { persist(privateAccessProtectProfileApply, for: .privateAccessProtectProfileApply) }
    }

    var privateAccessProtectAutomationCommands: Bool {
        didSet { persist(privateAccessProtectAutomationCommands, for: .privateAccessProtectAutomationCommands) }
    }

    private var privateAccessUnlockDurationSecondsStorage: Double

    var privateAccessUnlockDurationSeconds: Double {
        get { privateAccessUnlockDurationSecondsStorage }
        set {
            let clamped = Self.clampPrivateAccessUnlockDuration(newValue)
            privateAccessUnlockDurationSecondsStorage = clamped
            persist(clamped, for: .privateAccessUnlockDurationSeconds)
        }
    }

    var privateAccessLastAuthStatus: String? {
        didSet { persistOptional(privateAccessLastAuthStatus, for: .privateAccessLastAuthStatus) }
    }

    var privateAccessAllowDevicePasswordFallback: Bool {
        didSet { persist(privateAccessAllowDevicePasswordFallback, for: .privateAccessAllowDevicePasswordFallback) }
    }

    var appIntentsEnabled: Bool {
        didSet { persist(appIntentsEnabled, for: .appIntentsEnabled) }
    }

    var appIntentsCanApplyProfiles: Bool {
        didSet { persist(appIntentsCanApplyProfiles, for: .appIntentsCanApplyProfiles) }
    }

    var appIntentsCanAccessLabs: Bool {
        didSet { persist(appIntentsCanAccessLabs, for: .appIntentsCanAccessLabs) }
    }

    var dynamicHotkeysEnabled: Bool {
        didSet { persist(dynamicHotkeysEnabled, for: .dynamicHotkeysEnabled) }
    }

    var maxDynamicHotkeys: Int {
        didSet { persist(maxDynamicHotkeys, for: .maxDynamicHotkeys) }
    }

    var workspacesPreviewEnabled: Bool {
        didSet { persist(workspacesPreviewEnabled, for: .workspacesPreviewEnabled) }
    }

    var functionBarPreviewEnabled: Bool {
        didSet { persist(functionBarPreviewEnabled, for: .functionBarPreviewEnabled) }
    }

    var functionBarPrimaryClickEnabled: Bool {
        didSet { persist(functionBarPrimaryClickEnabled, for: .functionBarPrimaryClickEnabled) }
    }

    var functionBarPlacementPreference: String {
        didSet { persist(functionBarPlacementPreference, for: .functionBarPlacementPreference) }
    }

    var functionBarShowSetSwitcher: Bool {
        didSet { persist(functionBarShowSetSwitcher, for: .functionBarShowSetSwitcher) }
    }

    var functionBarShowLabels: Bool {
        didSet { persist(functionBarShowLabels, for: .functionBarShowLabels) }
    }

    var functionBarDensity: String {
        didSet { persist(functionBarDensity, for: .functionBarDensity) }
    }

    var functionBarCloseOnOutsideClick: Bool {
        didSet { persist(functionBarCloseOnOutsideClick, for: .functionBarCloseOnOutsideClick) }
    }

    var functionBarKeyboardNavigationEnabled: Bool {
        didSet { persist(functionBarKeyboardNavigationEnabled, for: .functionBarKeyboardNavigationEnabled) }
    }

    var setBuilderPreviewEnabled: Bool {
        didSet { persist(setBuilderPreviewEnabled, for: .setBuilderPreviewEnabled) }
    }

    var setBuilderDragDropEnabled: Bool {
        didSet { persist(setBuilderDragDropEnabled, for: .setBuilderDragDropEnabled) }
    }

    var setBuilderShowAdvancedLibraryItems: Bool {
        didSet { persist(setBuilderShowAdvancedLibraryItems, for: .setBuilderShowAdvancedLibraryItems) }
    }

    var setBuilderDefaultGroupReferenceMode: String {
        didSet { persist(setBuilderDefaultGroupReferenceMode, for: .setBuilderDefaultGroupReferenceMode) }
    }

    var setBuilderShowFunctionBarPreview: Bool {
        didSet { persist(setBuilderShowFunctionBarPreview, for: .setBuilderShowFunctionBarPreview) }
    }

    var setBuilderAutosaveDrafts: Bool {
        didSet { persist(setBuilderAutosaveDrafts, for: .setBuilderAutosaveDrafts) }
    }

    var setBuilderWarnBeforeLinkedGroupEdits: Bool {
        didSet { persist(setBuilderWarnBeforeLinkedGroupEdits, for: .setBuilderWarnBeforeLinkedGroupEdits) }
    }

    var infoStripPreviewEnabled: Bool {
        didSet { persist(infoStripPreviewEnabled, for: .infoStripPreviewEnabled) }
    }

    var infoStripAutoShowEnabled: Bool {
        didSet { persist(infoStripAutoShowEnabled, for: .infoStripAutoShowEnabled) }
    }

    var infoStripHoverToFunctionBarEnabled: Bool {
        didSet { persist(infoStripHoverToFunctionBarEnabled, for: .infoStripHoverToFunctionBarEnabled) }
    }

    var infoStripCloseOnOutsideClick: Bool {
        didSet { persist(infoStripCloseOnOutsideClick, for: .infoStripCloseOnOutsideClick) }
    }

    var infoStripPauseWhenFunctionBarPinned: Bool {
        didSet { persist(infoStripPauseWhenFunctionBarPinned, for: .infoStripPauseWhenFunctionBarPinned) }
    }

    var infoStripKeyboardNavigationEnabled: Bool {
        didSet { persist(infoStripKeyboardNavigationEnabled, for: .infoStripKeyboardNavigationEnabled) }
    }

    var infoStripShowPreviewBadge: Bool {
        didSet { persist(infoStripShowPreviewBadge, for: .infoStripShowPreviewBadge) }
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
        self.settingsMigrationVersion = Self.string(
            for: .settingsMigrationVersion,
            default: Self.registeredDefault(.settingsMigrationVersion),
            in: defaults
        )
        self.v01SafeDefaultsNoticePending = Self.value(
            for: .v01SafeDefaultsNoticePending,
            default: Self.registeredDefault(.v01SafeDefaultsNoticePending),
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
        let storedShowPrimarySeparator: Bool = Self.value(
            for: .showPrimarySeparator,
            default: Self.registeredDefault(.showPrimarySeparator),
            in: defaults
        )
        self.showPrimarySeparator = true
        if storedShowPrimarySeparator != true {
            defaults.set(true, forKey: Key.showPrimarySeparator.rawValue)
        }
        self.proModeEnabled = Self.bool(for: .proModeEnabled, in: defaults)
        self.accessibilityDiscoveryEnabled = Self.bool(for: .accessibilityDiscoveryEnabled, in: defaults)
        self.lastAccessibilityPermissionStatus = Self.optionalString(
            for: .lastAccessibilityPermissionStatus,
            in: defaults
        )
        self.lastScreenCapturePermissionStatus = Self.optionalString(
            for: .lastScreenCapturePermissionStatus,
            in: defaults
        )

        self.menuBarScanIntervalSecondsStorage = Self.clampedDouble(
            for: .menuBarScanIntervalSeconds,
            default: Self.registeredDefault(.menuBarScanIntervalSeconds),
            clamp: Self.clampMenuBarScanInterval,
            in: defaults
        )
        self.renderedIconCaptureEnabled = Self.value(
            for: .renderedIconCaptureEnabled,
            default: Self.registeredDefault(.renderedIconCaptureEnabled),
            in: defaults
        )
        self.renderedIconRevealSweepEnabled = Self.value(
            for: .renderedIconRevealSweepEnabled,
            default: Self.registeredDefault(.renderedIconRevealSweepEnabled),
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
        self.secondBarPrimaryClickEnabled = Self.value(
            for: .secondBarPrimaryClickEnabled,
            default: Self.registeredDefault(.secondBarPrimaryClickEnabled),
            in: defaults
        )
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
        self.dogfoodModeEnabled = Self.bool(for: .dogfoodModeEnabled, in: defaults)
        self.dogfoodRunID = Self.optionalString(for: .dogfoodRunID, in: defaults)
        self.dogfoodNotesEnabled = Self.value(
            for: .dogfoodNotesEnabled,
            default: Self.registeredDefault(.dogfoodNotesEnabled),
            in: defaults
        )

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

        // Phase 10 — Layout & Capacity
        self.layoutFeaturesEnabled = Self.value(for: .layoutFeaturesEnabled, default: Self.registeredDefault(.layoutFeaturesEnabled), in: defaults)
        self.fullMenuBarModeEnabled = Self.value(for: .fullMenuBarModeEnabled, default: Self.registeredDefault(.fullMenuBarModeEnabled), in: defaults)
        self.crowdedRevealRescueEnabled = Self.value(for: .crowdedRevealRescueEnabled, default: Self.registeredDefault(.crowdedRevealRescueEnabled), in: defaults)
        self.layoutSuggestionsEnabled = Self.value(for: .layoutSuggestionsEnabled, default: Self.registeredDefault(.layoutSuggestionsEnabled), in: defaults)
        self.showCapacityWarnings = Self.value(for: .showCapacityWarnings, default: Self.registeredDefault(.showCapacityWarnings), in: defaults)
        self.fullMenuBarModeAutoExitEnabled = Self.value(for: .fullMenuBarModeAutoExitEnabled, default: Self.registeredDefault(.fullMenuBarModeAutoExitEnabled), in: defaults)
        self.fullMenuBarModeAutoExitSecondsStorage = Self.clampedDouble(
            for: .fullMenuBarModeAutoExitSeconds,
            default: Self.registeredDefault(.fullMenuBarModeAutoExitSeconds),
            clamp: Self.clampFullMenuBarModeAutoExitSeconds,
            in: defaults
        )
        self.fullMenuBarModeShowsSecondBar = Self.value(for: .fullMenuBarModeShowsSecondBar, default: Self.registeredDefault(.fullMenuBarModeShowsSecondBar), in: defaults)
        self.fullMenuBarModeSuspendsAutoRehide = Self.value(for: .fullMenuBarModeSuspendsAutoRehide, default: Self.registeredDefault(.fullMenuBarModeSuspendsAutoRehide), in: defaults)
        self.fullMenuBarModeShowsSpacerMarkers = Self.value(for: .fullMenuBarModeShowsSpacerMarkers, default: Self.registeredDefault(.fullMenuBarModeShowsSpacerMarkers), in: defaults)
        self.crowdedRevealAutoOpenSecondBar = Self.value(for: .crowdedRevealAutoOpenSecondBar, default: Self.registeredDefault(.crowdedRevealAutoOpenSecondBar), in: defaults)
        self.crowdedRevealAskBeforeSwitching = Self.value(for: .crowdedRevealAskBeforeSwitching, default: Self.registeredDefault(.crowdedRevealAskBeforeSwitching), in: defaults)
        let storedCrowdedWorkspaceFallback = Self.string(
            for: .crowdedRescueWorkspaceFallbackPreference,
            default: Self.registeredDefault(.crowdedRescueWorkspaceFallbackPreference),
            in: defaults
        )
        self.crowdedRescueWorkspaceFallbackPreference = CrowdedRescueWorkspaceFallbackPreference(rawValue: storedCrowdedWorkspaceFallback) == nil
            ? CrowdedRescueWorkspaceFallbackPreference.preferSecondBar.rawValue
            : storedCrowdedWorkspaceFallback
        self.crowdedRevealThresholdRatioStorage = Self.clampedDouble(
            for: .crowdedRevealThresholdRatio,
            default: Self.registeredDefault(.crowdedRevealThresholdRatio),
            clamp: Self.clampCrowdedRevealThresholdRatio,
            in: defaults
        )
        self.crowdedRevealRequireProEstimate = Self.value(for: .crowdedRevealRequireProEstimate, default: Self.registeredDefault(.crowdedRevealRequireProEstimate), in: defaults)
        self.spacerItemsEnabled = Self.value(for: .spacerItemsEnabled, default: Self.registeredDefault(.spacerItemsEnabled), in: defaults)
        self.showSpacerMarkers = Self.value(for: .showSpacerMarkers, default: Self.registeredDefault(.showSpacerMarkers), in: defaults)
        self.spacerItemsJSONVersion = Self.value(for: .spacerItemsJSONVersion, default: Self.registeredDefault(.spacerItemsJSONVersion), in: defaults)
        self.menuBarSpacingLabsEnabled = Self.value(for: .menuBarSpacingLabsEnabled, default: Self.registeredDefault(.menuBarSpacingLabsEnabled), in: defaults)
        self.menuBarSpacingPreset = Self.string(for: .menuBarSpacingPreset, default: Self.registeredDefault(.menuBarSpacingPreset), in: defaults)
        self.menuBarSpacingCustomItemSpacingStorage = Self.clampedInt(
            for: .menuBarSpacingCustomItemSpacing,
            default: Self.registeredDefault(.menuBarSpacingCustomItemSpacing),
            clamp: Self.clampMenuBarSpacingCustomItemSpacing,
            in: defaults
        )
        self.menuBarSpacingCustomSelectionPaddingStorage = Self.clampedInt(
            for: .menuBarSpacingCustomSelectionPadding,
            default: Self.registeredDefault(.menuBarSpacingCustomSelectionPadding),
            clamp: Self.clampMenuBarSpacingCustomSelectionPadding,
            in: defaults
        )
        self.menuBarSpacingHasBackup = Self.value(for: .menuBarSpacingHasBackup, default: Self.registeredDefault(.menuBarSpacingHasBackup), in: defaults)
        self.menuBarSpacingLastApplyStatus = Self.optionalString(for: .menuBarSpacingLastApplyStatus, in: defaults)
        self.menuBarSpacingLastApplyDate = Self.optionalValue(for: .menuBarSpacingLastApplyDate, in: defaults)

        // Phase 11 — Groups, Private Access, Hotkeys, Shortcuts
        self.groupsEnabled = Self.value(for: .groupsEnabled, default: Self.registeredDefault(.groupsEnabled), in: defaults)
        self.groupStatusItemsEnabled = Self.value(for: .groupStatusItemsEnabled, default: Self.registeredDefault(.groupStatusItemsEnabled), in: defaults)
        self.protectedGroupsRequireAuth = Self.value(for: .protectedGroupsRequireAuth, default: Self.registeredDefault(.protectedGroupsRequireAuth), in: defaults)
        self.groupsJSONVersion = Self.value(for: .groupsJSONVersion, default: Self.registeredDefault(.groupsJSONVersion), in: defaults)
        self.privateAccessEnabled = Self.value(for: .privateAccessEnabled, default: Self.registeredDefault(.privateAccessEnabled), in: defaults)
        self.privateAccessProtectAlwaysHidden = Self.value(for: .privateAccessProtectAlwaysHidden, default: Self.registeredDefault(.privateAccessProtectAlwaysHidden), in: defaults)
        self.privateAccessProtectSecondBar = Self.value(for: .privateAccessProtectSecondBar, default: Self.registeredDefault(.privateAccessProtectSecondBar), in: defaults)
        self.privateAccessProtectFindIcon = Self.value(for: .privateAccessProtectFindIcon, default: Self.registeredDefault(.privateAccessProtectFindIcon), in: defaults)
        self.privateAccessProtectIconMoving = Self.value(for: .privateAccessProtectIconMoving, default: Self.registeredDefault(.privateAccessProtectIconMoving), in: defaults)
        self.privateAccessProtectSpacingLabs = Self.value(for: .privateAccessProtectSpacingLabs, default: Self.registeredDefault(.privateAccessProtectSpacingLabs), in: defaults)
        self.privateAccessProtectProfileApply = Self.value(for: .privateAccessProtectProfileApply, default: Self.registeredDefault(.privateAccessProtectProfileApply), in: defaults)
        self.privateAccessProtectAutomationCommands = Self.value(for: .privateAccessProtectAutomationCommands, default: Self.registeredDefault(.privateAccessProtectAutomationCommands), in: defaults)
        self.privateAccessUnlockDurationSecondsStorage = Self.clampedDouble(
            for: .privateAccessUnlockDurationSeconds,
            default: Self.registeredDefault(.privateAccessUnlockDurationSeconds),
            clamp: Self.clampPrivateAccessUnlockDuration,
            in: defaults
        )
        self.privateAccessLastAuthStatus = Self.optionalString(for: .privateAccessLastAuthStatus, in: defaults)
        self.privateAccessAllowDevicePasswordFallback = Self.value(for: .privateAccessAllowDevicePasswordFallback, default: Self.registeredDefault(.privateAccessAllowDevicePasswordFallback), in: defaults)
        self.appIntentsEnabled = Self.value(for: .appIntentsEnabled, default: Self.registeredDefault(.appIntentsEnabled), in: defaults)
        self.appIntentsCanApplyProfiles = Self.value(for: .appIntentsCanApplyProfiles, default: Self.registeredDefault(.appIntentsCanApplyProfiles), in: defaults)
        self.appIntentsCanAccessLabs = Self.value(for: .appIntentsCanAccessLabs, default: Self.registeredDefault(.appIntentsCanAccessLabs), in: defaults)
        self.dynamicHotkeysEnabled = Self.value(for: .dynamicHotkeysEnabled, default: Self.registeredDefault(.dynamicHotkeysEnabled), in: defaults)
        self.maxDynamicHotkeys = Self.value(for: .maxDynamicHotkeys, default: Self.registeredDefault(.maxDynamicHotkeys), in: defaults)
        self.workspacesPreviewEnabled = Self.value(
            for: .workspacesPreviewEnabled,
            default: Self.registeredDefault(.workspacesPreviewEnabled),
            in: defaults
        )
        self.functionBarPreviewEnabled = Self.value(
            for: .functionBarPreviewEnabled,
            default: Self.registeredDefault(.functionBarPreviewEnabled),
            in: defaults
        )
        self.functionBarPrimaryClickEnabled = Self.value(
            for: .functionBarPrimaryClickEnabled,
            default: Self.registeredDefault(.functionBarPrimaryClickEnabled),
            in: defaults
        )
        self.functionBarPlacementPreference = Self.string(
            for: .functionBarPlacementPreference,
            default: Self.registeredDefault(.functionBarPlacementPreference),
            in: defaults
        )
        self.functionBarShowSetSwitcher = Self.value(
            for: .functionBarShowSetSwitcher,
            default: Self.registeredDefault(.functionBarShowSetSwitcher),
            in: defaults
        )
        self.functionBarShowLabels = Self.value(
            for: .functionBarShowLabels,
            default: Self.registeredDefault(.functionBarShowLabels),
            in: defaults
        )
        self.functionBarDensity = Self.string(
            for: .functionBarDensity,
            default: Self.registeredDefault(.functionBarDensity),
            in: defaults
        )
        self.functionBarCloseOnOutsideClick = Self.value(
            for: .functionBarCloseOnOutsideClick,
            default: Self.registeredDefault(.functionBarCloseOnOutsideClick),
            in: defaults
        )
        self.functionBarKeyboardNavigationEnabled = Self.value(
            for: .functionBarKeyboardNavigationEnabled,
            default: Self.registeredDefault(.functionBarKeyboardNavigationEnabled),
            in: defaults
        )
        self.setBuilderPreviewEnabled = Self.value(
            for: .setBuilderPreviewEnabled,
            default: Self.registeredDefault(.setBuilderPreviewEnabled),
            in: defaults
        )
        self.setBuilderDragDropEnabled = Self.value(
            for: .setBuilderDragDropEnabled,
            default: Self.registeredDefault(.setBuilderDragDropEnabled),
            in: defaults
        )
        self.setBuilderShowAdvancedLibraryItems = Self.value(
            for: .setBuilderShowAdvancedLibraryItems,
            default: Self.registeredDefault(.setBuilderShowAdvancedLibraryItems),
            in: defaults
        )
        self.setBuilderDefaultGroupReferenceMode = Self.string(
            for: .setBuilderDefaultGroupReferenceMode,
            default: Self.registeredDefault(.setBuilderDefaultGroupReferenceMode),
            in: defaults
        )
        self.setBuilderShowFunctionBarPreview = Self.value(
            for: .setBuilderShowFunctionBarPreview,
            default: Self.registeredDefault(.setBuilderShowFunctionBarPreview),
            in: defaults
        )
        self.setBuilderAutosaveDrafts = Self.value(
            for: .setBuilderAutosaveDrafts,
            default: Self.registeredDefault(.setBuilderAutosaveDrafts),
            in: defaults
        )
        self.setBuilderWarnBeforeLinkedGroupEdits = Self.value(
            for: .setBuilderWarnBeforeLinkedGroupEdits,
            default: Self.registeredDefault(.setBuilderWarnBeforeLinkedGroupEdits),
            in: defaults
        )
        self.infoStripPreviewEnabled = Self.value(
            for: .infoStripPreviewEnabled,
            default: Self.registeredDefault(.infoStripPreviewEnabled),
            in: defaults
        )
        self.infoStripAutoShowEnabled = Self.value(
            for: .infoStripAutoShowEnabled,
            default: Self.registeredDefault(.infoStripAutoShowEnabled),
            in: defaults
        )
        self.infoStripHoverToFunctionBarEnabled = Self.value(
            for: .infoStripHoverToFunctionBarEnabled,
            default: Self.registeredDefault(.infoStripHoverToFunctionBarEnabled),
            in: defaults
        )
        self.infoStripCloseOnOutsideClick = Self.value(
            for: .infoStripCloseOnOutsideClick,
            default: Self.registeredDefault(.infoStripCloseOnOutsideClick),
            in: defaults
        )
        self.infoStripPauseWhenFunctionBarPinned = Self.value(
            for: .infoStripPauseWhenFunctionBarPinned,
            default: Self.registeredDefault(.infoStripPauseWhenFunctionBarPinned),
            in: defaults
        )
        self.infoStripKeyboardNavigationEnabled = Self.value(
            for: .infoStripKeyboardNavigationEnabled,
            default: Self.registeredDefault(.infoStripKeyboardNavigationEnabled),
            in: defaults
        )
        self.infoStripShowPreviewBadge = Self.value(
            for: .infoStripShowPreviewBadge,
            default: Self.registeredDefault(.infoStripShowPreviewBadge),
            in: defaults
        )
    }

    func restoreDefaults() {
        hasCompletedOnboarding = Self.registeredDefault(.hasCompletedOnboarding)
        launchAtLoginEnabled = Self.registeredDefault(.launchAtLoginEnabled)
        lastKnownAppVersion = Self.registeredDefault(.lastKnownAppVersion)
        settingsMigrationVersion = AppConstants.currentSettingsMigrationVersion
        v01SafeDefaultsNoticePending = Self.registeredDefault(.v01SafeDefaultsNoticePending)
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
        lastScreenCapturePermissionStatus = nil
        menuBarScanIntervalSeconds = Self.registeredDefault(.menuBarScanIntervalSeconds)
        renderedIconCaptureEnabled = Self.registeredDefault(.renderedIconCaptureEnabled)
        renderedIconRevealSweepEnabled = Self.registeredDefault(.renderedIconRevealSweepEnabled)
        searchEnabled = Self.registeredDefault(.searchEnabled)
        searchHotkeyEnabled = Self.registeredDefault(.searchHotkeyEnabled)
        searchHotkeyKeyCode = nil
        searchHotkeyModifiersRaw = nil
        searchRevealOnSelection = Self.registeredDefault(.searchRevealOnSelection)
        searchHighlightOnSelection = Self.registeredDefault(.searchHighlightOnSelection)
        secondBarEnabled = Self.registeredDefault(.secondBarEnabled)
        secondBarPrimaryClickEnabled = Self.registeredDefault(.secondBarPrimaryClickEnabled)
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
        dogfoodModeEnabled = Self.registeredDefault(.dogfoodModeEnabled)
        dogfoodRunID = nil
        dogfoodNotesEnabled = Self.registeredDefault(.dogfoodNotesEnabled)

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

        // Phase 10 — Layout & Capacity
        layoutFeaturesEnabled = Self.registeredDefault(.layoutFeaturesEnabled)
        fullMenuBarModeEnabled = Self.registeredDefault(.fullMenuBarModeEnabled)
        crowdedRevealRescueEnabled = Self.registeredDefault(.crowdedRevealRescueEnabled)
        layoutSuggestionsEnabled = Self.registeredDefault(.layoutSuggestionsEnabled)
        showCapacityWarnings = Self.registeredDefault(.showCapacityWarnings)
        fullMenuBarModeAutoExitEnabled = Self.registeredDefault(.fullMenuBarModeAutoExitEnabled)
        fullMenuBarModeAutoExitSeconds = Self.registeredDefault(.fullMenuBarModeAutoExitSeconds)
        fullMenuBarModeShowsSecondBar = Self.registeredDefault(.fullMenuBarModeShowsSecondBar)
        fullMenuBarModeSuspendsAutoRehide = Self.registeredDefault(.fullMenuBarModeSuspendsAutoRehide)
        fullMenuBarModeShowsSpacerMarkers = Self.registeredDefault(.fullMenuBarModeShowsSpacerMarkers)
        crowdedRevealAutoOpenSecondBar = Self.registeredDefault(.crowdedRevealAutoOpenSecondBar)
        crowdedRevealAskBeforeSwitching = Self.registeredDefault(.crowdedRevealAskBeforeSwitching)
        crowdedRescueWorkspaceFallbackPreference = Self.registeredDefault(.crowdedRescueWorkspaceFallbackPreference)
        crowdedRevealThresholdRatio = Self.registeredDefault(.crowdedRevealThresholdRatio)
        crowdedRevealRequireProEstimate = Self.registeredDefault(.crowdedRevealRequireProEstimate)
        spacerItemsEnabled = Self.registeredDefault(.spacerItemsEnabled)
        showSpacerMarkers = Self.registeredDefault(.showSpacerMarkers)
        spacerItemsJSONVersion = Self.registeredDefault(.spacerItemsJSONVersion)
        menuBarSpacingLabsEnabled = Self.registeredDefault(.menuBarSpacingLabsEnabled)
        menuBarSpacingPreset = Self.registeredDefault(.menuBarSpacingPreset)
        menuBarSpacingCustomItemSpacing = Self.registeredDefault(.menuBarSpacingCustomItemSpacing)
        menuBarSpacingCustomSelectionPadding = Self.registeredDefault(.menuBarSpacingCustomSelectionPadding)
        menuBarSpacingHasBackup = Self.registeredDefault(.menuBarSpacingHasBackup)
        menuBarSpacingLastApplyStatus = nil
        menuBarSpacingLastApplyDate = nil

        // Phase 11
        groupsEnabled = Self.registeredDefault(.groupsEnabled)
        groupStatusItemsEnabled = Self.registeredDefault(.groupStatusItemsEnabled)
        protectedGroupsRequireAuth = Self.registeredDefault(.protectedGroupsRequireAuth)
        groupsJSONVersion = Self.registeredDefault(.groupsJSONVersion)
        privateAccessEnabled = Self.registeredDefault(.privateAccessEnabled)
        privateAccessProtectAlwaysHidden = Self.registeredDefault(.privateAccessProtectAlwaysHidden)
        privateAccessProtectSecondBar = Self.registeredDefault(.privateAccessProtectSecondBar)
        privateAccessProtectFindIcon = Self.registeredDefault(.privateAccessProtectFindIcon)
        privateAccessProtectIconMoving = Self.registeredDefault(.privateAccessProtectIconMoving)
        privateAccessProtectSpacingLabs = Self.registeredDefault(.privateAccessProtectSpacingLabs)
        privateAccessProtectProfileApply = Self.registeredDefault(.privateAccessProtectProfileApply)
        privateAccessProtectAutomationCommands = Self.registeredDefault(.privateAccessProtectAutomationCommands)
        privateAccessUnlockDurationSeconds = Self.registeredDefault(.privateAccessUnlockDurationSeconds)
        privateAccessLastAuthStatus = nil
        privateAccessAllowDevicePasswordFallback = Self.registeredDefault(.privateAccessAllowDevicePasswordFallback)
        appIntentsEnabled = Self.registeredDefault(.appIntentsEnabled)
        appIntentsCanApplyProfiles = Self.registeredDefault(.appIntentsCanApplyProfiles)
        appIntentsCanAccessLabs = Self.registeredDefault(.appIntentsCanAccessLabs)
        dynamicHotkeysEnabled = Self.registeredDefault(.dynamicHotkeysEnabled)
        maxDynamicHotkeys = Self.registeredDefault(.maxDynamicHotkeys)
        workspacesPreviewEnabled = Self.registeredDefault(.workspacesPreviewEnabled)
        functionBarPreviewEnabled = Self.registeredDefault(.functionBarPreviewEnabled)
        functionBarPrimaryClickEnabled = Self.registeredDefault(.functionBarPrimaryClickEnabled)
        functionBarPlacementPreference = Self.registeredDefault(.functionBarPlacementPreference)
        functionBarShowSetSwitcher = Self.registeredDefault(.functionBarShowSetSwitcher)
        functionBarShowLabels = Self.registeredDefault(.functionBarShowLabels)
        functionBarDensity = Self.registeredDefault(.functionBarDensity)
        functionBarCloseOnOutsideClick = Self.registeredDefault(.functionBarCloseOnOutsideClick)
        functionBarKeyboardNavigationEnabled = Self.registeredDefault(.functionBarKeyboardNavigationEnabled)
        setBuilderPreviewEnabled = Self.registeredDefault(.setBuilderPreviewEnabled)
        setBuilderDragDropEnabled = Self.registeredDefault(.setBuilderDragDropEnabled)
        setBuilderShowAdvancedLibraryItems = Self.registeredDefault(.setBuilderShowAdvancedLibraryItems)
        setBuilderDefaultGroupReferenceMode = Self.registeredDefault(.setBuilderDefaultGroupReferenceMode)
        setBuilderShowFunctionBarPreview = Self.registeredDefault(.setBuilderShowFunctionBarPreview)
        setBuilderAutosaveDrafts = Self.registeredDefault(.setBuilderAutosaveDrafts)
        setBuilderWarnBeforeLinkedGroupEdits = Self.registeredDefault(.setBuilderWarnBeforeLinkedGroupEdits)
        infoStripPreviewEnabled = Self.registeredDefault(.infoStripPreviewEnabled)
        infoStripAutoShowEnabled = Self.registeredDefault(.infoStripAutoShowEnabled)
        infoStripHoverToFunctionBarEnabled = Self.registeredDefault(.infoStripHoverToFunctionBarEnabled)
        infoStripCloseOnOutsideClick = Self.registeredDefault(.infoStripCloseOnOutsideClick)
        infoStripPauseWhenFunctionBarPinned = Self.registeredDefault(.infoStripPauseWhenFunctionBarPinned)
        infoStripKeyboardNavigationEnabled = Self.registeredDefault(.infoStripKeyboardNavigationEnabled)
        infoStripShowPreviewBadge = Self.registeredDefault(.infoStripShowPreviewBadge)
    }

    func effectiveFunctionBarPlacementPreference() -> FunctionBarPlacementPreference {
        FunctionBarPlacementPreference(rawValue: functionBarPlacementPreference) ?? .belowMenuBarIcon
    }

    func effectiveSetBuilderDefaultGroupReferenceMode() -> WorkspaceGroupReferenceMode {
        WorkspaceGroupReferenceMode(rawValue: setBuilderDefaultGroupReferenceMode) ?? .linked
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

    // MARK: Phase 10 clamping helpers

    static func clampFullMenuBarModeAutoExitSeconds(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minFullMenuBarModeAutoExitSeconds ... AppConstants.maxFullMenuBarModeAutoExitSeconds,
            nanFallback: AppConstants.defaultFullMenuBarModeAutoExitSeconds
        )
    }

    static func clampCrowdedRevealThresholdRatio(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minCrowdedRevealThresholdRatio ... AppConstants.maxCrowdedRevealThresholdRatio,
            nanFallback: AppConstants.defaultCrowdedRevealThresholdRatio
        )
    }

    static func clampMenuBarSpacingCustomItemSpacing(_ value: Int) -> Int {
        min(max(value, AppConstants.minMenuBarSpacingCustomItemSpacing), AppConstants.maxMenuBarSpacingCustomItemSpacing)
    }

    static func clampMenuBarSpacingCustomSelectionPadding(_ value: Int) -> Int {
        min(max(value, AppConstants.minMenuBarSpacingCustomSelectionPadding), AppConstants.maxMenuBarSpacingCustomSelectionPadding)
    }

    // MARK: Phase 11 clamping helpers

    static func clampPrivateAccessUnlockDuration(_ value: Double) -> Double {
        clamp(
            value,
            to: AppConstants.minPrivateAccessUnlockDurationSeconds ... AppConstants.maxPrivateAccessUnlockDurationSeconds,
            nanFallback: AppConstants.defaultPrivateAccessUnlockDurationSeconds
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
