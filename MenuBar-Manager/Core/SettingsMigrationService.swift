import Foundation

struct SettingsMigrationResult: Equatable {
    let didMigrate: Bool
    let fromVersion: String
    let toVersion: String
    let backupURL: URL?
    let repairedKeys: [SettingsStore.Key]

    static func notNeeded(version: String) -> SettingsMigrationResult {
        SettingsMigrationResult(
            didMigrate: false,
            fromVersion: version,
            toVersion: SettingsMigrationService.currentMigrationVersion,
            backupURL: nil,
            repairedKeys: []
        )
    }
}

@MainActor
struct SettingsMigrationService {
    static let currentMigrationVersion = AppConstants.currentSettingsMigrationVersion

    private let settingsStore: SettingsStore
    private let appSupportPaths: AppSupportPaths
    private let diagnosticsLogger: DiagnosticsLogger
    private let fileManager: FileManager
    private let dateProvider: () -> Date

    init(
        settingsStore: SettingsStore,
        appSupportPaths: AppSupportPaths,
        diagnosticsLogger: DiagnosticsLogger,
        fileManager: FileManager = .default,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.appSupportPaths = appSupportPaths
        self.diagnosticsLogger = diagnosticsLogger
        self.fileManager = fileManager
        self.dateProvider = dateProvider
    }

    func migrateIfNeeded() -> SettingsMigrationResult {
        let previousVersion = settingsStore.settingsMigrationVersion
        guard previousVersion != Self.currentMigrationVersion else {
            return .notNeeded(version: previousVersion)
        }

        guard !isFreshInstallWithoutAlphaState(previousVersion: previousVersion) else {
            settingsStore.settingsMigrationVersion = Self.currentMigrationVersion
            return .notNeeded(version: Self.currentMigrationVersion)
        }

        let backupURL = writeBackup(version: previousVersion)
        var repairedKeys: [SettingsStore.Key] = []

        repair(&repairedKeys, .launchAtLoginEnabled) {
            settingsStore.launchAtLoginEnabled = false
        }
        repair(&repairedKeys, .isCollapsed) {
            settingsStore.isCollapsed = false
        }
        repair(&repairedKeys, .startCollapsed) {
            settingsStore.startCollapsed = false
        }
        repair(&repairedKeys, .expandedSeparatorLength) {
            settingsStore.expandedSeparatorLength = Self.safeExpandedSeparatorLength(settingsStore.expandedSeparatorLength)
        }
        if let override = settingsStore.collapsedSeparatorLengthOverride,
           !Self.isSafeCollapsedSeparatorOverride(override) {
            settingsStore.collapsedSeparatorLengthOverride = nil
            repairedKeys.append(.collapsedSeparatorLengthOverride)
        }
        repair(&repairedKeys, .autoRehideEnabled) {
            settingsStore.autoRehideEnabled = false
        }
        repair(&repairedKeys, .hoverRevealEnabled) {
            settingsStore.hoverRevealEnabled = false
        }
        repair(&repairedKeys, .globalHotkeyEnabled) {
            settingsStore.globalHotkeyEnabled = false
        }
        repair(&repairedKeys, .proModeEnabled) {
            settingsStore.proModeEnabled = false
        }
        repair(&repairedKeys, .accessibilityDiscoveryEnabled) {
            settingsStore.accessibilityDiscoveryEnabled = false
        }
        if settingsStore.lastAccessibilityPermissionStatus != nil {
            settingsStore.lastAccessibilityPermissionStatus = nil
            repairedKeys.append(.lastAccessibilityPermissionStatus)
        }
        repair(&repairedKeys, .searchEnabled) {
            settingsStore.searchEnabled = false
        }
        repair(&repairedKeys, .searchHotkeyEnabled) {
            settingsStore.searchHotkeyEnabled = false
        }
        repair(&repairedKeys, .secondBarEnabled) {
            settingsStore.secondBarEnabled = false
        }
        repair(&repairedKeys, .iconMovingEnabled) {
            settingsStore.iconMovingEnabled = false
        }
        repair(&repairedKeys, .iconMovingConfirmationSuppressed) {
            settingsStore.iconMovingConfirmationSuppressed = false
        }
        repair(&repairedKeys, .iconMovingAllowSystemItems) {
            settingsStore.iconMovingAllowSystemItems = false
        }
        repair(&repairedKeys, .smartTriggersEnabled) {
            settingsStore.smartTriggersEnabled = false
        }
        repair(&repairedKeys, .automationPaused) {
            settingsStore.automationPaused = true
        }

        settingsStore.settingsMigrationVersion = Self.currentMigrationVersion
        settingsStore.v01SafeDefaultsNoticePending = true

        diagnosticsLogger.log(
            "Settings migrated to v0.1 safe defaults.",
            level: .info,
            category: .recovery,
            metadata: [
                "fromVersion": previousVersion.isEmpty ? "unknown-alpha" : previousVersion,
                "toVersion": Self.currentMigrationVersion,
                "repairedKeys": repairedKeys.map(\.rawValue).joined(separator: ",")
            ]
        )

        return SettingsMigrationResult(
            didMigrate: true,
            fromVersion: previousVersion,
            toVersion: Self.currentMigrationVersion,
            backupURL: backupURL,
            repairedKeys: repairedKeys
        )
    }

    private func repair(
        _ repairedKeys: inout [SettingsStore.Key],
        _ key: SettingsStore.Key,
        apply: () -> Void
    ) {
        let before = snapshotValue(for: key)
        apply()
        let after = snapshotValue(for: key)
        if before != after {
            repairedKeys.append(key)
        }
    }

    private func writeBackup(version: String) -> URL? {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let timestamp = Self.backupTimestampFormatter.string(from: dateProvider())
            let filename = "settings-before-v0.1-migration-\(timestamp).json"
            let url = appSupportPaths.backupsDirectory.appendingPathComponent(filename)
            let data = try JSONEncoder.prettySorted.encode(backupPayload(version: version))
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            diagnosticsLogger.log(
                "Could not back up settings before migration: \(error.localizedDescription)",
                level: .warning,
                category: .recovery
            )
            return nil
        }
    }

    private func isFreshInstallWithoutAlphaState(previousVersion: String) -> Bool {
        previousVersion.isEmpty &&
            settingsStore.lastKnownAppVersion.isEmpty &&
            settingsStore.hasCompletedOnboarding == false &&
            settingsStore.launchAtLoginEnabled == false &&
            settingsStore.isCollapsed == false &&
            settingsStore.startCollapsed == false &&
            settingsStore.proModeEnabled == false &&
            settingsStore.accessibilityDiscoveryEnabled == false &&
            settingsStore.lastAccessibilityPermissionStatus == nil &&
            settingsStore.searchEnabled == false &&
            settingsStore.secondBarEnabled == false &&
            settingsStore.iconMovingEnabled == false &&
            settingsStore.smartTriggersEnabled == false &&
            settingsStore.automationPaused == true &&
            settingsStore.autoRehideEnabled == false &&
            settingsStore.hoverRevealEnabled == false &&
            settingsStore.globalHotkeyEnabled == false
    }

    private func backupPayload(version: String) -> [String: String] {
        var payload = settingsSnapshot()
        payload["migrationSourceVersion"] = version.isEmpty ? "unknown-alpha" : version
        payload["migrationTargetVersion"] = Self.currentMigrationVersion
        return payload
    }

    private func settingsSnapshot() -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: SettingsStore.Key.allCases.filter { key in
                key != .showPrimarySeparator
            }.map { key in
                (key.rawValue, snapshotValue(for: key))
            }
        )
    }

    private func snapshotValue(for key: SettingsStore.Key) -> String {
        switch key {
        case .hasCompletedOnboarding:
            return settingsStore.hasCompletedOnboarding.description
        case .launchAtLoginEnabled:
            return settingsStore.launchAtLoginEnabled.description
        case .lastKnownAppVersion:
            return settingsStore.lastKnownAppVersion
        case .settingsMigrationVersion:
            return settingsStore.settingsMigrationVersion
        case .v01SafeDefaultsNoticePending:
            return settingsStore.v01SafeDefaultsNoticePending.description
        case .appMode:
            return settingsStore.appMode.rawValue
        case .isCollapsed:
            return settingsStore.isCollapsed.description
        case .startCollapsed:
            return settingsStore.startCollapsed.description
        case .expandedSeparatorLength:
            return settingsStore.expandedSeparatorLength.description
        case .collapsedSeparatorLengthOverride:
            return settingsStore.collapsedSeparatorLengthOverride?.description ?? "nil"
        case .hasSeenDragHint:
            return settingsStore.hasSeenDragHint.description
        case .showPrimarySeparator:
            return settingsStore.showPrimarySeparator.description
        case .proModeEnabled:
            return settingsStore.proModeEnabled.description
        case .accessibilityDiscoveryEnabled:
            return settingsStore.accessibilityDiscoveryEnabled.description
        case .lastAccessibilityPermissionStatus:
            return settingsStore.lastAccessibilityPermissionStatus ?? "nil"
        case .menuBarScanIntervalSeconds:
            return settingsStore.menuBarScanIntervalSeconds.description
        case .searchEnabled:
            return settingsStore.searchEnabled.description
        case .searchHotkeyEnabled:
            return settingsStore.searchHotkeyEnabled.description
        case .searchHotkeyKeyCode:
            return settingsStore.searchHotkeyKeyCode?.description ?? "nil"
        case .searchHotkeyModifiersRaw:
            return settingsStore.searchHotkeyModifiersRaw?.description ?? "nil"
        case .searchRevealOnSelection:
            return settingsStore.searchRevealOnSelection.description
        case .searchHighlightOnSelection:
            return settingsStore.searchHighlightOnSelection.description
        case .secondBarEnabled:
            return settingsStore.secondBarEnabled.description
        case .secondBarShowHiddenItems:
            return settingsStore.secondBarShowHiddenItems.description
        case .secondBarShowAlwaysHiddenItems:
            return settingsStore.secondBarShowAlwaysHiddenItems.description
        case .secondBarAutoCloseAfterSelection:
            return settingsStore.secondBarAutoCloseAfterSelection.description
        case .secondBarPositionModeRaw:
            return settingsStore.secondBarPositionModeRaw
        case .secondBarIconSize:
            return settingsStore.secondBarIconSize.description
        case .secondBarShowLabels:
            return settingsStore.secondBarShowLabels.description
        case .secondBarCloseOnOutsideClick:
            return settingsStore.secondBarCloseOnOutsideClick.description
        case .secondBarActivateOwningAppOnSelection:
            return settingsStore.secondBarActivateOwningAppOnSelection.description
        case .iconMovingEnabled:
            return settingsStore.iconMovingEnabled.description
        case .iconMovingRequireConfirmation:
            return settingsStore.iconMovingRequireConfirmation.description
        case .iconMovingConfirmationSuppressed:
            return settingsStore.iconMovingConfirmationSuppressed.description
        case .iconMovingMaxRetries:
            return settingsStore.iconMovingMaxRetries.description
        case .iconMovingDragDuration:
            return settingsStore.iconMovingDragDuration.description
        case .iconMovingAllowSystemItems:
            return settingsStore.iconMovingAllowSystemItems.description
        case .smartTriggersEnabled:
            return settingsStore.smartTriggersEnabled.description
        case .automationPaused:
            return settingsStore.automationPaused.description
        case .dogfoodModeEnabled:
            return settingsStore.dogfoodModeEnabled.description
        case .dogfoodRunID:
            return settingsStore.dogfoodRunID ?? "nil"
        case .dogfoodNotesEnabled:
            return settingsStore.dogfoodNotesEnabled.description
        case .autoRehideEnabled:
            return settingsStore.autoRehideEnabled.description
        case .autoRehideDelaySeconds:
            return settingsStore.autoRehideDelaySeconds.description
        case .hoverRevealEnabled:
            return settingsStore.hoverRevealEnabled.description
        case .hoverRevealPollingIntervalSeconds:
            return settingsStore.hoverRevealPollingIntervalSeconds.description
        case .alwaysHiddenEnabled:
            return settingsStore.alwaysHiddenEnabled.description
        case .showSeparators:
            return settingsStore.showSeparators.description
        case .globalHotkeyEnabled:
            return settingsStore.globalHotkeyEnabled.description
        case .globalHotkeyKeyCode:
            return settingsStore.globalHotkeyKeyCode?.description ?? "nil"
        case .globalHotkeyModifiersRaw:
            return settingsStore.globalHotkeyModifiersRaw?.description ?? "nil"
        case .revealAllOnOptionClick:
            return settingsStore.revealAllOnOptionClick.description
        case .layoutFeaturesEnabled:
            return settingsStore.layoutFeaturesEnabled.description
        case .fullMenuBarModeEnabled:
            return settingsStore.fullMenuBarModeEnabled.description
        case .crowdedRevealRescueEnabled:
            return settingsStore.crowdedRevealRescueEnabled.description
        case .layoutSuggestionsEnabled:
            return settingsStore.layoutSuggestionsEnabled.description
        case .showCapacityWarnings:
            return settingsStore.showCapacityWarnings.description
        case .fullMenuBarModeAutoExitEnabled:
            return settingsStore.fullMenuBarModeAutoExitEnabled.description
        case .fullMenuBarModeAutoExitSeconds:
            return settingsStore.fullMenuBarModeAutoExitSeconds.description
        case .fullMenuBarModeShowsSecondBar:
            return settingsStore.fullMenuBarModeShowsSecondBar.description
        case .fullMenuBarModeSuspendsAutoRehide:
            return settingsStore.fullMenuBarModeSuspendsAutoRehide.description
        case .fullMenuBarModeShowsSpacerMarkers:
            return settingsStore.fullMenuBarModeShowsSpacerMarkers.description
        case .crowdedRevealAutoOpenSecondBar:
            return settingsStore.crowdedRevealAutoOpenSecondBar.description
        case .crowdedRevealThresholdRatio:
            return settingsStore.crowdedRevealThresholdRatio.description
        case .crowdedRevealRequireProEstimate:
            return settingsStore.crowdedRevealRequireProEstimate.description
        case .spacerItemsEnabled:
            return settingsStore.spacerItemsEnabled.description
        case .showSpacerMarkers:
            return settingsStore.showSpacerMarkers.description
        case .spacerItemsJSONVersion:
            return settingsStore.spacerItemsJSONVersion.description
        case .menuBarSpacingLabsEnabled:
            return settingsStore.menuBarSpacingLabsEnabled.description
        case .menuBarSpacingPreset:
            return settingsStore.menuBarSpacingPreset
        case .menuBarSpacingCustomItemSpacing:
            return settingsStore.menuBarSpacingCustomItemSpacing.description
        case .menuBarSpacingCustomSelectionPadding:
            return settingsStore.menuBarSpacingCustomSelectionPadding.description
        case .menuBarSpacingHasBackup:
            return settingsStore.menuBarSpacingHasBackup.description
        case .menuBarSpacingLastApplyStatus:
            return settingsStore.menuBarSpacingLastApplyStatus ?? "nil"
        case .menuBarSpacingLastApplyDate:
            return settingsStore.menuBarSpacingLastApplyDate?.description ?? "nil"
        case .groupsEnabled:
            return settingsStore.groupsEnabled.description
        case .groupStatusItemsEnabled:
            return settingsStore.groupStatusItemsEnabled.description
        case .protectedGroupsRequireAuth:
            return settingsStore.protectedGroupsRequireAuth.description
        case .groupsJSONVersion:
            return settingsStore.groupsJSONVersion.description
        case .privateAccessEnabled:
            return settingsStore.privateAccessEnabled.description
        case .privateAccessProtectAlwaysHidden:
            return settingsStore.privateAccessProtectAlwaysHidden.description
        case .privateAccessProtectSecondBar:
            return settingsStore.privateAccessProtectSecondBar.description
        case .privateAccessProtectFindIcon:
            return settingsStore.privateAccessProtectFindIcon.description
        case .privateAccessProtectIconMoving:
            return settingsStore.privateAccessProtectIconMoving.description
        case .privateAccessProtectSpacingLabs:
            return settingsStore.privateAccessProtectSpacingLabs.description
        case .privateAccessUnlockDurationSeconds:
            return settingsStore.privateAccessUnlockDurationSeconds.description
        case .privateAccessLastAuthStatus:
            return settingsStore.privateAccessLastAuthStatus ?? "nil"
        case .privateAccessAllowDevicePasswordFallback:
            return settingsStore.privateAccessAllowDevicePasswordFallback.description
        case .appIntentsEnabled:
            return settingsStore.appIntentsEnabled.description
        case .appIntentsCanApplyProfiles:
            return settingsStore.appIntentsCanApplyProfiles.description
        case .appIntentsCanAccessLabs:
            return settingsStore.appIntentsCanAccessLabs.description
        case .dynamicHotkeysEnabled:
            return settingsStore.dynamicHotkeysEnabled.description
        case .maxDynamicHotkeys:
            return settingsStore.maxDynamicHotkeys.description
        }
    }

    private static func safeExpandedSeparatorLength(_ value: Double) -> Double {
        guard value.isFinite else { return AppConstants.defaultExpandedSeparatorLength }
        return min(max(value, 8), 240)
    }

    private static func isSafeCollapsedSeparatorOverride(_ value: Double) -> Bool {
        value.isFinite &&
            value >= AppConstants.collapsedSeparatorMinimumLength &&
            value <= AppConstants.collapsedSeparatorMaximumLength
    }

    @MainActor
    private static let backupTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

private extension JSONEncoder {
    static var prettySorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
