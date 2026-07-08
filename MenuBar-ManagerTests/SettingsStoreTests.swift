import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SettingsStore")
@MainActor
struct SettingsStoreTests {
    @Test func keyPoliciesKeepSensitiveAndLocalStateOutOfPortableSettings() {
        #expect(SettingsStore.privacySafeExportOmittedKeys.contains(.dogfoodRunID))
        #expect(SettingsStore.privacySafeExportOmittedKeys.contains(.launchAtLoginEnabled))
        #expect(SettingsStore.privacySafeExportOmittedKeys.contains(.privateAccessLastAuthStatus))
        #expect(SettingsStore.privacySafeExportOmittedKeys.contains(.menuBarSpacingLastApplyStatus))
        #expect(SettingsStore.privacySafeExportOmittedKeys.contains(.lastScreenCapturePermissionStatus))
        #expect(!SettingsStore.privacySafeExportKeys.contains(.dogfoodRunID))
        #expect(!SettingsStore.privacySafeExportKeys.contains(.launchAtLoginEnabled))
        #expect(!SettingsStore.privacySafeExportKeys.contains(.showPrimarySeparator))
        #expect(!SettingsStore.privacySafeExportKeys.contains(.lastScreenCapturePermissionStatus))
        #expect(SettingsStore.privacySafeExportKeys.contains(.proModeEnabled))

        #expect(SettingsStore.importSkippedKeys.isSuperset(of: SettingsStore.privacySafeExportOmittedKeys))
        #expect(SettingsStore.importSkippedKeys.contains(.launchAtLoginEnabled))

        #expect(!SettingsStore.migrationSnapshotKeys.contains(.showPrimarySeparator))
        #expect(SettingsStore.migrationSnapshotKeys.contains(.launchAtLoginEnabled))
    }

    @Test func defaultValuesAreRegistered() {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(store.hasCompletedOnboarding == false)
        #expect(store.launchAtLoginEnabled == false)
        #expect(store.lastKnownAppVersion == "")
        #expect(store.settingsMigrationVersion == "")
        #expect(store.v01SafeDefaultsNoticePending == false)
        #expect(store.appMode == .basic)
        #expect(store.isCollapsed == false)
        #expect(store.expandedSeparatorLength == AppConstants.defaultExpandedSeparatorLength)
        #expect(store.collapsedSeparatorLengthOverride == nil)
        #expect(store.hasSeenDragHint == false)
        #expect(store.showPrimarySeparator == true)
        #expect(store.searchEnabled == true)
        #expect(store.dogfoodModeEnabled == false)
        #expect(store.dogfoodRunID == nil)
        #expect(store.dogfoodNotesEnabled == true)
    }

    @Test func valuesPersistToUserDefaults() {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.hasCompletedOnboarding = true
        store.launchAtLoginEnabled = true
        store.lastKnownAppVersion = "1.0 (42)"
        store.appMode = .basic
        store.dogfoodModeEnabled = true
        store.dogfoodRunID = "dogfood-2026-06-28-120000"
        store.dogfoodNotesEnabled = false

        let reloadedStore = SettingsStore(defaults: defaults)

        #expect(reloadedStore.hasCompletedOnboarding == true)
        #expect(reloadedStore.launchAtLoginEnabled == true)
        #expect(reloadedStore.lastKnownAppVersion == "1.0 (42)")
        #expect(reloadedStore.appMode == .basic)
        #expect(reloadedStore.dogfoodModeEnabled == true)
        #expect(reloadedStore.dogfoodRunID == "dogfood-2026-06-28-120000")
        #expect(reloadedStore.dogfoodNotesEnabled == false)
    }

    @Test func phase1HidingFieldsPersist() {
        let suiteName = "SettingsStoreTests.phase1.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.isCollapsed = true
        store.expandedSeparatorLength = 30
        store.collapsedSeparatorLengthOverride = 5000
        store.hasSeenDragHint = true
        store.showPrimarySeparator = false

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.isCollapsed == true)
        #expect(reloaded.expandedSeparatorLength == 30)
        #expect(reloaded.collapsedSeparatorLengthOverride == 5000)
        #expect(reloaded.hasSeenDragHint == true)
        #expect(reloaded.showPrimarySeparator == true)
        #expect(defaults.bool(forKey: SettingsStore.Key.showPrimarySeparator.rawValue) == true)
    }

    @Test func legacyHiddenPrimarySeparatorPreferenceIsRepaired() {
        let suiteName = "SettingsStoreTests.primarySeparatorRepair.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(false, forKey: SettingsStore.Key.showPrimarySeparator.rawValue)

        let store = SettingsStore(defaults: defaults)

        #expect(store.showPrimarySeparator == true)
        #expect(defaults.bool(forKey: SettingsStore.Key.showPrimarySeparator.rawValue) == true)
    }

    @Test func collapsedSeparatorOverrideCanBeCleared() {
        let suiteName = "SettingsStoreTests.override.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.collapsedSeparatorLengthOverride = 3000
        #expect(store.collapsedSeparatorLengthOverride == 3000)

        store.collapsedSeparatorLengthOverride = nil
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.collapsedSeparatorLengthOverride == nil)
    }

    // MARK: Phase 2 defaults

    @Test func phase2DefaultsAreRegistered() {
        let suiteName = "SettingsStoreTests.phase2.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(store.autoRehideEnabled == false)
        #expect(store.autoRehideDelaySeconds == AppConstants.defaultAutoRehideDelaySeconds)
        #expect(store.hoverRevealEnabled == false)
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.defaultHoverRevealPollingIntervalSeconds)
        #expect(store.alwaysHiddenEnabled == false)
        #expect(store.showSeparators == true)
        #expect(store.globalHotkeyEnabled == false)
        #expect(store.globalHotkeyKeyCode == nil)
        #expect(store.globalHotkeyModifiersRaw == nil)
        #expect(store.revealAllOnOptionClick == true)
    }

    @Test func phase2FieldsPersist() {
        let suiteName = "SettingsStoreTests.phase2persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.autoRehideEnabled = false
        store.autoRehideDelaySeconds = 12
        store.hoverRevealEnabled = true
        store.hoverRevealPollingIntervalSeconds = 0.5
        store.alwaysHiddenEnabled = true
        store.showSeparators = false
        store.globalHotkeyEnabled = true
        store.globalHotkeyKeyCode = 11
        store.globalHotkeyModifiersRaw = 0x0900
        store.revealAllOnOptionClick = false

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.autoRehideEnabled == false)
        #expect(reloaded.autoRehideDelaySeconds == 12)
        #expect(reloaded.hoverRevealEnabled == true)
        #expect(reloaded.hoverRevealPollingIntervalSeconds == 0.5)
        #expect(reloaded.alwaysHiddenEnabled == true)
        #expect(reloaded.showSeparators == false)
        #expect(reloaded.globalHotkeyEnabled == true)
        #expect(reloaded.globalHotkeyKeyCode == 11)
        #expect(reloaded.globalHotkeyModifiersRaw == 0x0900)
        #expect(reloaded.revealAllOnOptionClick == false)
    }

    @Test func invalidAutoRehideDelayClamped() {
        let suiteName = "SettingsStoreTests.delayClamp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.autoRehideDelaySeconds = -100
        #expect(store.autoRehideDelaySeconds == AppConstants.minAutoRehideDelaySeconds)

        store.autoRehideDelaySeconds = 12345
        #expect(store.autoRehideDelaySeconds == AppConstants.maxAutoRehideDelaySeconds)

        store.autoRehideDelaySeconds = .nan
        #expect(store.autoRehideDelaySeconds == AppConstants.defaultAutoRehideDelaySeconds)

        store.autoRehideDelaySeconds = .infinity
        #expect(store.autoRehideDelaySeconds == AppConstants.maxAutoRehideDelaySeconds)

        store.autoRehideDelaySeconds = -.infinity
        #expect(store.autoRehideDelaySeconds == AppConstants.minAutoRehideDelaySeconds)
    }

    @Test func invalidHoverPollingIntervalClamped() {
        let suiteName = "SettingsStoreTests.pollClamp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.hoverRevealPollingIntervalSeconds = 0
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.minHoverRevealPollingIntervalSeconds)

        store.hoverRevealPollingIntervalSeconds = 999
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.maxHoverRevealPollingIntervalSeconds)

        store.hoverRevealPollingIntervalSeconds = .nan
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.defaultHoverRevealPollingIntervalSeconds)

        store.hoverRevealPollingIntervalSeconds = .infinity
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.maxHoverRevealPollingIntervalSeconds)

        store.hoverRevealPollingIntervalSeconds = -.infinity
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.minHoverRevealPollingIntervalSeconds)
    }

    @Test func restoreDefaultsResetsPhase2() {
        let suiteName = "SettingsStoreTests.restore2.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.autoRehideEnabled = false
        store.hoverRevealEnabled = true
        store.alwaysHiddenEnabled = true
        store.showSeparators = false
        store.globalHotkeyEnabled = true
        store.globalHotkeyKeyCode = 11
        store.globalHotkeyModifiersRaw = 0x0900
        store.revealAllOnOptionClick = false
        store.autoRehideDelaySeconds = 999
        store.hoverRevealPollingIntervalSeconds = 999

        store.restoreDefaults()

        #expect(store.autoRehideEnabled == false)
        #expect(store.autoRehideDelaySeconds == AppConstants.defaultAutoRehideDelaySeconds)
        #expect(store.hoverRevealEnabled == false)
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.defaultHoverRevealPollingIntervalSeconds)
        #expect(store.alwaysHiddenEnabled == false)
        #expect(store.showSeparators == true)
        #expect(store.globalHotkeyEnabled == false)
        #expect(store.globalHotkeyKeyCode == nil)
        #expect(store.globalHotkeyModifiersRaw == nil)
        #expect(store.revealAllOnOptionClick == true)
    }

    // MARK: Phase 4 fields

    @Test func phase4DefaultsAreRegistered() {
        let suiteName = "SettingsStoreTests.phase4.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(store.proModeEnabled == false)
        #expect(store.accessibilityDiscoveryEnabled == false)
        #expect(store.lastAccessibilityPermissionStatus == nil)
        #expect(store.lastScreenCapturePermissionStatus == nil)
        #expect(store.menuBarScanIntervalSeconds == AppConstants.defaultMenuBarScanIntervalSeconds)
        #expect(store.renderedIconCaptureEnabled == false)
        #expect(store.renderedIconRevealSweepEnabled == false)
    }

    @Test func phase4FieldsPersist() {
        let suiteName = "SettingsStoreTests.phase4persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        store.lastAccessibilityPermissionStatus = AccessibilityPermissionStatus.granted.rawValue
        store.lastScreenCapturePermissionStatus = ScreenCapturePermissionStatus.granted.rawValue
        store.menuBarScanIntervalSeconds = 4.5
        store.renderedIconCaptureEnabled = true
        store.renderedIconRevealSweepEnabled = true

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.proModeEnabled == true)
        #expect(reloaded.accessibilityDiscoveryEnabled == true)
        #expect(reloaded.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue)
        #expect(reloaded.lastScreenCapturePermissionStatus == ScreenCapturePermissionStatus.granted.rawValue)
        #expect(reloaded.menuBarScanIntervalSeconds == 4.5)
        #expect(reloaded.renderedIconCaptureEnabled == true)
        #expect(reloaded.renderedIconRevealSweepEnabled == true)
    }

    @Test func invalidMenuBarScanIntervalClamped() {
        let suiteName = "SettingsStoreTests.scanClamp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.menuBarScanIntervalSeconds = 0
        #expect(store.menuBarScanIntervalSeconds == AppConstants.minMenuBarScanIntervalSeconds)

        store.menuBarScanIntervalSeconds = 999
        #expect(store.menuBarScanIntervalSeconds == AppConstants.maxMenuBarScanIntervalSeconds)

        store.menuBarScanIntervalSeconds = .nan
        #expect(store.menuBarScanIntervalSeconds == AppConstants.defaultMenuBarScanIntervalSeconds)

        store.menuBarScanIntervalSeconds = .infinity
        #expect(store.menuBarScanIntervalSeconds == AppConstants.maxMenuBarScanIntervalSeconds)

        store.menuBarScanIntervalSeconds = -.infinity
        #expect(store.menuBarScanIntervalSeconds == AppConstants.minMenuBarScanIntervalSeconds)
    }

    @Test func restoreDefaultsResetsPhase4() {
        let suiteName = "SettingsStoreTests.restore4.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.proModeEnabled = true
        store.accessibilityDiscoveryEnabled = true
        store.lastAccessibilityPermissionStatus = AccessibilityPermissionStatus.granted.rawValue
        store.lastScreenCapturePermissionStatus = ScreenCapturePermissionStatus.granted.rawValue
        store.menuBarScanIntervalSeconds = 12
        store.renderedIconCaptureEnabled = true
        store.renderedIconRevealSweepEnabled = true

        store.restoreDefaults()

        #expect(store.proModeEnabled == false)
        #expect(store.accessibilityDiscoveryEnabled == false)
        #expect(store.lastAccessibilityPermissionStatus == nil)
        #expect(store.lastScreenCapturePermissionStatus == nil)
        #expect(store.menuBarScanIntervalSeconds == AppConstants.defaultMenuBarScanIntervalSeconds)
        #expect(store.renderedIconCaptureEnabled == false)
        #expect(store.renderedIconRevealSweepEnabled == false)
    }

    // MARK: Phase 3 fields

    @Test func startCollapsedDefaultsFalseAndPersists() {
        let suiteName = "SettingsStoreTests.startCollapsed.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        #expect(store.startCollapsed == false)

        store.startCollapsed = true
        store.isCollapsed = false

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.startCollapsed == true)
        #expect(reloaded.isCollapsed == false)
    }

    @Test func onboardingFlagPersists() {
        let suiteName = "SettingsStoreTests.onboarding.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        #expect(store.hasCompletedOnboarding == false)

        store.hasCompletedOnboarding = true
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.hasCompletedOnboarding == true)

        store.hasCompletedOnboarding = false
        let reloaded2 = SettingsStore(defaults: defaults)
        #expect(reloaded2.hasCompletedOnboarding == false)
    }

    @Test func restoreDefaultsResetsPhase3Fields() {
        let suiteName = "SettingsStoreTests.restore3.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.hasCompletedOnboarding = true
        store.launchAtLoginEnabled = true
        store.startCollapsed = true
        store.isCollapsed = true

        store.restoreDefaults()

        #expect(store.hasCompletedOnboarding == false)
        #expect(store.launchAtLoginEnabled == false)
        #expect(store.settingsMigrationVersion == AppConstants.currentSettingsMigrationVersion)
        #expect(store.v01SafeDefaultsNoticePending == false)
        #expect(store.startCollapsed == false)
        #expect(store.isCollapsed == false)
    }

    // MARK: Phase 6-8 fields

    @Test func phase6To8DefaultsAreRegistered() {
        let suiteName = "SettingsStoreTests.phase678.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        #expect(store.secondBarEnabled == true)
        #expect(store.secondBarPrimaryClickEnabled == false)
        #expect(store.secondBarShowHiddenItems == true)
        #expect(store.secondBarShowAlwaysHiddenItems == true)
        #expect(store.secondBarAutoCloseAfterSelection == true)
        #expect(store.effectiveSecondBarPositionMode() == .belowMenuBar)
        #expect(store.secondBarIconSize == AppConstants.defaultSecondBarIconSize)
        #expect(store.iconMovingEnabled == false)
        #expect(store.iconMovingRequireConfirmation == true)
        #expect(store.iconMovingMaxRetries == AppConstants.defaultIconMovingMaxRetries)
        #expect(store.iconMovingDragDuration == AppConstants.defaultIconMovingDragDuration)
        #expect(store.iconMovingAllowSystemItems == false)
        #expect(store.smartTriggersEnabled == false)
        #expect(store.automationPaused == true)
    }

    @Test func phase6To8FieldsPersistAndClamp() {
        let suiteName = "SettingsStoreTests.phase678persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.secondBarEnabled = false
        store.secondBarPrimaryClickEnabled = true
        store.secondBarPositionModeRaw = SecondBarPositionMode.nearMouse.rawValue
        store.secondBarIconSize = 999
        store.iconMovingEnabled = true
        store.iconMovingMaxRetries = 999
        store.iconMovingDragDuration = 999
        store.smartTriggersEnabled = true
        store.automationPaused = true

        let reloaded = SettingsStore(defaults: defaults)

        #expect(reloaded.secondBarEnabled == false)
        #expect(reloaded.secondBarPrimaryClickEnabled == true)
        #expect(reloaded.effectiveSecondBarPositionMode() == .nearMouse)
        #expect(reloaded.secondBarIconSize == AppConstants.maxSecondBarIconSize)
        #expect(reloaded.iconMovingEnabled == true)
        #expect(reloaded.iconMovingMaxRetries == AppConstants.maxIconMovingMaxRetries)
        #expect(reloaded.iconMovingDragDuration == AppConstants.maxIconMovingDragDuration)
        #expect(reloaded.smartTriggersEnabled == true)
        #expect(reloaded.automationPaused == true)
    }

    @Test func restoreDefaultsResetsPhase6To8Fields() {
        let suiteName = "SettingsStoreTests.restore678.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.secondBarEnabled = false
        store.secondBarPrimaryClickEnabled = true
        store.secondBarPositionModeRaw = SecondBarPositionMode.lastPosition.rawValue
        store.secondBarIconSize = 60
        store.iconMovingEnabled = true
        store.iconMovingConfirmationSuppressed = true
        store.iconMovingAllowSystemItems = true
        store.smartTriggersEnabled = true
        store.automationPaused = true

        store.restoreDefaults()

        #expect(store.secondBarEnabled == true)
        #expect(store.secondBarPrimaryClickEnabled == false)
        #expect(store.effectiveSecondBarPositionMode() == .belowMenuBar)
        #expect(store.secondBarIconSize == AppConstants.defaultSecondBarIconSize)
        #expect(store.iconMovingEnabled == false)
        #expect(store.iconMovingConfirmationSuppressed == false)
        #expect(store.iconMovingAllowSystemItems == false)
        #expect(store.smartTriggersEnabled == false)
        #expect(store.automationPaused == true)
    }

    @Test func restoreDefaultsRemovesOptionalDefaults() {
        let suiteName = "SettingsStoreTests.restoreOptionals.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let optionalKeys: [SettingsStore.Key] = [
            .collapsedSeparatorLengthOverride,
            .lastAccessibilityPermissionStatus,
            .lastScreenCapturePermissionStatus,
            .searchHotkeyKeyCode,
            .searchHotkeyModifiersRaw,
            .globalHotkeyKeyCode,
            .globalHotkeyModifiersRaw,
            .dogfoodRunID
        ]

        let store = SettingsStore(defaults: defaults)
        store.collapsedSeparatorLengthOverride = 120
        store.lastAccessibilityPermissionStatus = AccessibilityPermissionStatus.granted.rawValue
        store.lastScreenCapturePermissionStatus = ScreenCapturePermissionStatus.granted.rawValue
        store.searchHotkeyKeyCode = 3
        store.searchHotkeyModifiersRaw = 0x0100
        store.globalHotkeyKeyCode = 11
        store.globalHotkeyModifiersRaw = 0x0900
        store.dogfoodRunID = "dogfood-2026-06-28-120000"
        for key in optionalKeys {
            #expect(defaults.object(forKey: key.rawValue) != nil)
        }

        store.restoreDefaults()

        #expect(store.collapsedSeparatorLengthOverride == nil)
        #expect(store.lastAccessibilityPermissionStatus == nil)
        #expect(store.lastScreenCapturePermissionStatus == nil)
        #expect(store.searchHotkeyKeyCode == nil)
        #expect(store.searchHotkeyModifiersRaw == nil)
        #expect(store.globalHotkeyKeyCode == nil)
        #expect(store.globalHotkeyModifiersRaw == nil)
        #expect(store.dogfoodRunID == nil)
        for key in optionalKeys {
            #expect(defaults.object(forKey: key.rawValue) == nil)
        }

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.collapsedSeparatorLengthOverride == nil)
        #expect(reloaded.lastAccessibilityPermissionStatus == nil)
        #expect(reloaded.lastScreenCapturePermissionStatus == nil)
        #expect(reloaded.searchHotkeyKeyCode == nil)
        #expect(reloaded.searchHotkeyModifiersRaw == nil)
        #expect(reloaded.globalHotkeyKeyCode == nil)
        #expect(reloaded.globalHotkeyModifiersRaw == nil)
        #expect(reloaded.dogfoodRunID == nil)
    }

    @Test func restoreDefaultsResetsDogfoodFields() {
        let suiteName = "SettingsStoreTests.restoreDogfood.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.dogfoodModeEnabled = true
        store.dogfoodRunID = "dogfood-2026-06-28-120000"
        store.dogfoodNotesEnabled = false

        store.restoreDefaults()

        #expect(store.dogfoodModeEnabled == false)
        #expect(store.dogfoodRunID == nil)
        #expect(store.dogfoodNotesEnabled == true)
    }

    @Test func invalidPersistedClampedValuesAreRepairedOnLoad() {
        let suiteName = "SettingsStoreTests.clampOnLoad.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(-100, forKey: SettingsStore.Key.autoRehideDelaySeconds.rawValue)
        defaults.set(999, forKey: SettingsStore.Key.hoverRevealPollingIntervalSeconds.rawValue)
        defaults.set(Double.nan, forKey: SettingsStore.Key.menuBarScanIntervalSeconds.rawValue)
        defaults.set(999, forKey: SettingsStore.Key.secondBarIconSize.rawValue)
        defaults.set(-100, forKey: SettingsStore.Key.iconMovingMaxRetries.rawValue)
        defaults.set(Double.infinity, forKey: SettingsStore.Key.iconMovingDragDuration.rawValue)

        let store = SettingsStore(defaults: defaults)

        #expect(store.autoRehideDelaySeconds == AppConstants.minAutoRehideDelaySeconds)
        #expect(store.hoverRevealPollingIntervalSeconds == AppConstants.maxHoverRevealPollingIntervalSeconds)
        #expect(store.menuBarScanIntervalSeconds == AppConstants.defaultMenuBarScanIntervalSeconds)
        #expect(store.secondBarIconSize == AppConstants.maxSecondBarIconSize)
        #expect(store.iconMovingMaxRetries == AppConstants.minIconMovingMaxRetries)
        #expect(store.iconMovingDragDuration == AppConstants.maxIconMovingDragDuration)

        #expect(defaults.double(forKey: SettingsStore.Key.autoRehideDelaySeconds.rawValue) == AppConstants.minAutoRehideDelaySeconds)
        #expect(defaults.double(forKey: SettingsStore.Key.hoverRevealPollingIntervalSeconds.rawValue) == AppConstants.maxHoverRevealPollingIntervalSeconds)
        #expect(defaults.double(forKey: SettingsStore.Key.menuBarScanIntervalSeconds.rawValue) == AppConstants.defaultMenuBarScanIntervalSeconds)
        #expect(defaults.double(forKey: SettingsStore.Key.secondBarIconSize.rawValue) == AppConstants.maxSecondBarIconSize)
        #expect(defaults.integer(forKey: SettingsStore.Key.iconMovingMaxRetries.rawValue) == AppConstants.minIconMovingMaxRetries)
        #expect(defaults.double(forKey: SettingsStore.Key.iconMovingDragDuration.rawValue) == AppConstants.maxIconMovingDragDuration)
    }
}
