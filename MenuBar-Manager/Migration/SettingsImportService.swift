import Foundation

/// Import conflict information.
nonisolated struct ImportConflict: Equatable, Sendable {
    let kind: Kind
    let description: String

    enum Kind: String, Sendable {
        case hotkeyConflict
        case experimentalFlag
        case profileNameConflict
        case schemaMismatch
    }
}

/// Dry-run result of an import operation.
nonisolated struct SettingsImportDryRun: Equatable, Sendable {
    let addedProfiles: Int
    let modifiedSettings: Int
    let addedGroups: Int
    let addedHotkeys: Int
    let addedSpacers: Int
    let conflicts: [ImportConflict]
    let riskyExperimentalFlags: [String]
    let wouldEnableIconMoving: Bool
    let wouldEnableSpacingLabs: Bool
    let wouldEnableSmartTriggers: Bool

    var hasConflicts: Bool { !conflicts.isEmpty }
    var hasRisks: Bool { !riskyExperimentalFlags.isEmpty || wouldEnableIconMoving || wouldEnableSpacingLabs || wouldEnableSmartTriggers }
}

nonisolated struct SettingsImportApplyResult: Equatable, Sendable {
    let appliedSettings: Int
    let skippedSettings: Int
    let importedProfiles: Int
    let importedGroups: Int
    let importedHotkeys: Int
    let skippedHotkeys: Int
    let importedSpacers: Int
    let skippedExperimentalFlags: [String]

    var importedObjectCount: Int {
        importedProfiles + importedGroups + importedHotkeys + importedSpacers
    }
}

nonisolated enum SettingsImportApplyError: LocalizedError, Equatable, Sendable {
    case unsupportedPackageVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedPackageVersion(let version):
            "Package version \(version) is not supported for apply."
        }
    }
}

/// Service for importing settings from a JSON package.
@MainActor
final class SettingsImportService {
    private let diagnosticsLogger: DiagnosticsLogger

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Decode a package from JSON data.
    func decode(data: Data) throws -> SettingsExportPackage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SettingsExportPackage.self, from: data)
    }

    /// Perform a dry-run analysis of what the import would change.
    func dryRun(
        package: SettingsExportPackage,
        existingHotkeyBindings: [HotkeyBinding] = [],
        importExperimentalSettings: Bool = false
    ) -> SettingsImportDryRun {
        var conflicts: [ImportConflict] = []
        var riskyFlags: [String] = []

        // Check for hotkey conflicts
        for newBinding in package.hotkeyBindings {
            if HotkeyConflictDetector.wouldConflict(newBinding, in: existingHotkeyBindings) {
                conflicts.append(ImportConflict(
                    kind: .hotkeyConflict,
                    description: "Hotkey binding '\(newBinding.label)' conflicts with an existing binding."
                ))
            }
        }

        // Check for experimental flags
        let wouldEnableIconMoving = package.settings["iconMovingEnabled"] == "true"
        let wouldEnableSpacingLabs = package.settings["menuBarSpacingLabsEnabled"] == "true"
        let wouldEnableSmartTriggers = package.settings["smartTriggersEnabled"] == "true"

        if wouldEnableIconMoving {
            riskyFlags.append("Icon moving would be enabled.")
        }
        if wouldEnableSpacingLabs {
            riskyFlags.append("Menu Bar Spacing Labs would be enabled.")
        }
        if wouldEnableSmartTriggers {
            riskyFlags.append("Smart triggers would be enabled.")
        }

        if !importExperimentalSettings {
            for flag in riskyFlags {
                conflicts.append(ImportConflict(kind: .experimentalFlag, description: flag))
            }
        }

        // Schema check
        if package.packageVersion != 1 {
            conflicts.append(ImportConflict(
                kind: .schemaMismatch,
                description: "Package version \(package.packageVersion) may not be fully supported."
            ))
        }

        return SettingsImportDryRun(
            addedProfiles: package.profiles.count,
            modifiedSettings: package.settings.count,
            addedGroups: package.groups.count,
            addedHotkeys: package.hotkeyBindings.count,
            addedSpacers: package.spacerItems.count,
            conflicts: conflicts,
            riskyExperimentalFlags: riskyFlags,
            wouldEnableIconMoving: wouldEnableIconMoving,
            wouldEnableSpacingLabs: wouldEnableSpacingLabs,
            wouldEnableSmartTriggers: wouldEnableSmartTriggers
        )
    }

    /// Apply a decoded package after the UI has already created a local backup.
    /// Import is intentionally merge-by-identity and never deletes local-only
    /// profiles, groups, hotkeys, or spacers.
    func apply(
        package: SettingsExportPackage,
        settingsStore: SettingsStore,
        profileStore: ProfileStore? = nil,
        groupStore: IconGroupStore? = nil,
        hotkeyBindingStore: HotkeyBindingStore? = nil,
        spacerItemStore: SpacerItemStore? = nil,
        importExperimentalSettings: Bool = false
    ) throws -> SettingsImportApplyResult {
        guard package.packageVersion == 1 else {
            throw SettingsImportApplyError.unsupportedPackageVersion(package.packageVersion)
        }

        var appliedSettings = 0
        var skippedSettings = 0
        var skippedExperimentalFlags: [String] = []

        for (rawKey, rawValue) in package.settings.sorted(by: { $0.key < $1.key }) {
            guard let key = SettingsStore.Key(rawValue: rawKey) else {
                skippedSettings += 1
                continue
            }

            switch applySetting(
                key,
                rawValue: rawValue,
                to: settingsStore,
                importExperimentalSettings: importExperimentalSettings
            ) {
            case .applied:
                appliedSettings += 1
            case .skipped:
                skippedSettings += 1
            case .skippedExperimental(let label):
                skippedSettings += 1
                skippedExperimentalFlags.append(label)
            }
        }

        let importedProfiles = importProfiles(package.profiles, into: profileStore)
        let importedGroups = importGroups(package.groups, into: groupStore)
        let hotkeyResult = importHotkeys(package.hotkeyBindings, into: hotkeyBindingStore)
        let importedSpacers = importSpacers(package.spacerItems, into: spacerItemStore)

        let result = SettingsImportApplyResult(
            appliedSettings: appliedSettings,
            skippedSettings: skippedSettings,
            importedProfiles: importedProfiles,
            importedGroups: importedGroups,
            importedHotkeys: hotkeyResult.imported,
            skippedHotkeys: hotkeyResult.skipped,
            importedSpacers: importedSpacers,
            skippedExperimentalFlags: skippedExperimentalFlags
        )

        diagnosticsLogger.log(
            "Settings import applied.",
            category: .recovery,
            metadata: [
                "appliedSettings": "\(result.appliedSettings)",
                "skippedSettings": "\(result.skippedSettings)",
                "importedProfiles": "\(result.importedProfiles)",
                "importedGroups": "\(result.importedGroups)",
                "importedHotkeys": "\(result.importedHotkeys)",
                "skippedHotkeys": "\(result.skippedHotkeys)",
                "importedSpacers": "\(result.importedSpacers)",
                "skippedExperimentalFlags": "\(result.skippedExperimentalFlags.count)"
            ]
        )

        return result
    }

    private enum SettingApplyOutcome {
        case applied
        case skipped
        case skippedExperimental(String)
    }

    private func applySetting(
        _ key: SettingsStore.Key,
        rawValue: String,
        to settingsStore: SettingsStore,
        importExperimentalSettings: Bool
    ) -> SettingApplyOutcome {
        switch key {
        case .lastKnownAppVersion,
             .settingsMigrationVersion,
             .v01SafeDefaultsNoticePending,
             .showPrimarySeparator,
             .launchAtLoginEnabled,
             .lastAccessibilityPermissionStatus,
             .iconMovingConfirmationSuppressed,
             .dogfoodModeEnabled,
             .dogfoodRunID,
             .dogfoodNotesEnabled,
             .menuBarSpacingHasBackup,
             .menuBarSpacingLastApplyStatus,
             .menuBarSpacingLastApplyDate,
             .privateAccessLastAuthStatus:
            return .skipped
        case .hasCompletedOnboarding:
            return applyBool(rawValue) { settingsStore.hasCompletedOnboarding = $0 }
        case .appMode:
            guard let mode = SettingsStore.AppMode(rawValue: rawValue) else { return .skipped }
            settingsStore.appMode = mode
            return .applied
        case .isCollapsed:
            return applyBool(rawValue) { settingsStore.isCollapsed = $0 }
        case .startCollapsed:
            return applyBool(rawValue) { settingsStore.startCollapsed = $0 }
        case .expandedSeparatorLength:
            return applyDouble(rawValue) { settingsStore.expandedSeparatorLength = $0 }
        case .collapsedSeparatorLengthOverride:
            return applyOptionalDouble(rawValue) { settingsStore.collapsedSeparatorLengthOverride = $0 }
        case .hasSeenDragHint:
            return applyBool(rawValue) { settingsStore.hasSeenDragHint = $0 }
        case .proModeEnabled:
            return applyBool(rawValue) { settingsStore.proModeEnabled = $0 }
        case .accessibilityDiscoveryEnabled:
            return applyBool(rawValue) { settingsStore.accessibilityDiscoveryEnabled = $0 }
        case .menuBarScanIntervalSeconds:
            return applyDouble(rawValue) { settingsStore.menuBarScanIntervalSeconds = $0 }
        case .searchEnabled:
            return applyBool(rawValue) { settingsStore.searchEnabled = $0 }
        case .searchHotkeyEnabled:
            return applyBool(rawValue) { settingsStore.searchHotkeyEnabled = $0 }
        case .searchHotkeyKeyCode:
            return applyOptionalInt(rawValue) { settingsStore.searchHotkeyKeyCode = $0 }
        case .searchHotkeyModifiersRaw:
            return applyOptionalUInt(rawValue) { settingsStore.searchHotkeyModifiersRaw = $0 }
        case .searchRevealOnSelection:
            return applyBool(rawValue) { settingsStore.searchRevealOnSelection = $0 }
        case .searchHighlightOnSelection:
            return applyBool(rawValue) { settingsStore.searchHighlightOnSelection = $0 }
        case .secondBarEnabled:
            return applyBool(rawValue) { settingsStore.secondBarEnabled = $0 }
        case .secondBarShowHiddenItems:
            return applyBool(rawValue) { settingsStore.secondBarShowHiddenItems = $0 }
        case .secondBarShowAlwaysHiddenItems:
            return applyBool(rawValue) { settingsStore.secondBarShowAlwaysHiddenItems = $0 }
        case .secondBarAutoCloseAfterSelection:
            return applyBool(rawValue) { settingsStore.secondBarAutoCloseAfterSelection = $0 }
        case .secondBarPositionModeRaw:
            settingsStore.secondBarPositionModeRaw = rawValue
            return .applied
        case .secondBarIconSize:
            return applyDouble(rawValue) { settingsStore.secondBarIconSize = $0 }
        case .secondBarShowLabels:
            return applyBool(rawValue) { settingsStore.secondBarShowLabels = $0 }
        case .secondBarCloseOnOutsideClick:
            return applyBool(rawValue) { settingsStore.secondBarCloseOnOutsideClick = $0 }
        case .secondBarActivateOwningAppOnSelection:
            return applyBool(rawValue) { settingsStore.secondBarActivateOwningAppOnSelection = $0 }
        case .iconMovingEnabled:
            guard let value = bool(from: rawValue) else { return .skipped }
            if value && !importExperimentalSettings {
                return .skippedExperimental("Icon Moving")
            }
            settingsStore.iconMovingEnabled = value
            return .applied
        case .iconMovingRequireConfirmation:
            return applyBool(rawValue) { settingsStore.iconMovingRequireConfirmation = $0 }
        case .iconMovingMaxRetries:
            return applyInt(rawValue) { settingsStore.iconMovingMaxRetries = $0 }
        case .iconMovingDragDuration:
            return applyDouble(rawValue) { settingsStore.iconMovingDragDuration = $0 }
        case .iconMovingAllowSystemItems:
            return applyBool(rawValue) { settingsStore.iconMovingAllowSystemItems = $0 }
        case .smartTriggersEnabled:
            guard let value = bool(from: rawValue) else { return .skipped }
            if value && !importExperimentalSettings {
                return .skippedExperimental("Smart Triggers")
            }
            settingsStore.smartTriggersEnabled = value
            return .applied
        case .automationPaused:
            return applyBool(rawValue) { settingsStore.automationPaused = $0 }
        case .autoRehideEnabled:
            return applyBool(rawValue) { settingsStore.autoRehideEnabled = $0 }
        case .autoRehideDelaySeconds:
            return applyDouble(rawValue) { settingsStore.autoRehideDelaySeconds = $0 }
        case .hoverRevealEnabled:
            return applyBool(rawValue) { settingsStore.hoverRevealEnabled = $0 }
        case .hoverRevealPollingIntervalSeconds:
            return applyDouble(rawValue) { settingsStore.hoverRevealPollingIntervalSeconds = $0 }
        case .alwaysHiddenEnabled:
            return applyBool(rawValue) { settingsStore.alwaysHiddenEnabled = $0 }
        case .showSeparators:
            return applyBool(rawValue) { settingsStore.showSeparators = $0 }
        case .globalHotkeyEnabled:
            return applyBool(rawValue) { settingsStore.globalHotkeyEnabled = $0 }
        case .globalHotkeyKeyCode:
            return applyOptionalInt(rawValue) { settingsStore.globalHotkeyKeyCode = $0 }
        case .globalHotkeyModifiersRaw:
            return applyOptionalUInt(rawValue) { settingsStore.globalHotkeyModifiersRaw = $0 }
        case .revealAllOnOptionClick:
            return applyBool(rawValue) { settingsStore.revealAllOnOptionClick = $0 }
        case .layoutFeaturesEnabled:
            return applyBool(rawValue) { settingsStore.layoutFeaturesEnabled = $0 }
        case .fullMenuBarModeEnabled:
            return applyBool(rawValue) { settingsStore.fullMenuBarModeEnabled = $0 }
        case .crowdedRevealRescueEnabled:
            return applyBool(rawValue) { settingsStore.crowdedRevealRescueEnabled = $0 }
        case .layoutSuggestionsEnabled:
            return applyBool(rawValue) { settingsStore.layoutSuggestionsEnabled = $0 }
        case .showCapacityWarnings:
            return applyBool(rawValue) { settingsStore.showCapacityWarnings = $0 }
        case .fullMenuBarModeAutoExitEnabled:
            return applyBool(rawValue) { settingsStore.fullMenuBarModeAutoExitEnabled = $0 }
        case .fullMenuBarModeAutoExitSeconds:
            return applyDouble(rawValue) { settingsStore.fullMenuBarModeAutoExitSeconds = $0 }
        case .fullMenuBarModeShowsSecondBar:
            return applyBool(rawValue) { settingsStore.fullMenuBarModeShowsSecondBar = $0 }
        case .fullMenuBarModeSuspendsAutoRehide:
            return applyBool(rawValue) { settingsStore.fullMenuBarModeSuspendsAutoRehide = $0 }
        case .fullMenuBarModeShowsSpacerMarkers:
            return applyBool(rawValue) { settingsStore.fullMenuBarModeShowsSpacerMarkers = $0 }
        case .crowdedRevealAutoOpenSecondBar:
            return applyBool(rawValue) { settingsStore.crowdedRevealAutoOpenSecondBar = $0 }
        case .crowdedRevealThresholdRatio:
            return applyDouble(rawValue) { settingsStore.crowdedRevealThresholdRatio = $0 }
        case .crowdedRevealRequireProEstimate:
            return applyBool(rawValue) { settingsStore.crowdedRevealRequireProEstimate = $0 }
        case .spacerItemsEnabled:
            return applyBool(rawValue) { settingsStore.spacerItemsEnabled = $0 }
        case .showSpacerMarkers:
            return applyBool(rawValue) { settingsStore.showSpacerMarkers = $0 }
        case .spacerItemsJSONVersion:
            return applyInt(rawValue) { settingsStore.spacerItemsJSONVersion = $0 }
        case .menuBarSpacingLabsEnabled:
            guard let value = bool(from: rawValue) else { return .skipped }
            if value && !importExperimentalSettings {
                return .skippedExperimental("Menu Bar Spacing Labs")
            }
            settingsStore.menuBarSpacingLabsEnabled = value
            return .applied
        case .menuBarSpacingPreset:
            settingsStore.menuBarSpacingPreset = rawValue
            return .applied
        case .menuBarSpacingCustomItemSpacing:
            return applyInt(rawValue) { settingsStore.menuBarSpacingCustomItemSpacing = $0 }
        case .menuBarSpacingCustomSelectionPadding:
            return applyInt(rawValue) { settingsStore.menuBarSpacingCustomSelectionPadding = $0 }
        case .groupsEnabled:
            return applyBool(rawValue) { settingsStore.groupsEnabled = $0 }
        case .groupStatusItemsEnabled:
            return applyBool(rawValue) { settingsStore.groupStatusItemsEnabled = $0 }
        case .protectedGroupsRequireAuth:
            return applyBool(rawValue) { settingsStore.protectedGroupsRequireAuth = $0 }
        case .groupsJSONVersion:
            return applyInt(rawValue) { settingsStore.groupsJSONVersion = $0 }
        case .privateAccessEnabled:
            return applyBool(rawValue) { settingsStore.privateAccessEnabled = $0 }
        case .privateAccessProtectAlwaysHidden:
            return applyBool(rawValue) { settingsStore.privateAccessProtectAlwaysHidden = $0 }
        case .privateAccessProtectSecondBar:
            return applyBool(rawValue) { settingsStore.privateAccessProtectSecondBar = $0 }
        case .privateAccessProtectFindIcon:
            return applyBool(rawValue) { settingsStore.privateAccessProtectFindIcon = $0 }
        case .privateAccessProtectIconMoving:
            return applyBool(rawValue) { settingsStore.privateAccessProtectIconMoving = $0 }
        case .privateAccessProtectSpacingLabs:
            return applyBool(rawValue) { settingsStore.privateAccessProtectSpacingLabs = $0 }
        case .privateAccessUnlockDurationSeconds:
            return applyDouble(rawValue) { settingsStore.privateAccessUnlockDurationSeconds = $0 }
        case .privateAccessAllowDevicePasswordFallback:
            return applyBool(rawValue) { settingsStore.privateAccessAllowDevicePasswordFallback = $0 }
        case .appIntentsEnabled:
            return applyBool(rawValue) { settingsStore.appIntentsEnabled = $0 }
        case .appIntentsCanApplyProfiles:
            return applyBool(rawValue) { settingsStore.appIntentsCanApplyProfiles = $0 }
        case .appIntentsCanAccessLabs:
            return applyBool(rawValue) { settingsStore.appIntentsCanAccessLabs = $0 }
        case .dynamicHotkeysEnabled:
            return applyBool(rawValue) { settingsStore.dynamicHotkeysEnabled = $0 }
        case .maxDynamicHotkeys:
            return applyInt(rawValue) { settingsStore.maxDynamicHotkeys = max(0, $0) }
        }
    }

    private func importProfiles(_ profiles: [ProfileModel], into store: ProfileStore?) -> Int {
        guard let store, !profiles.isEmpty else { return 0 }
        store.load()
        store.importProfiles(profiles)
        return profiles.count
    }

    private func importGroups(_ groups: [IconGroup], into store: IconGroupStore?) -> Int {
        guard let store, !groups.isEmpty else { return 0 }
        store.load()
        store.importGroups(groups)
        return groups.count
    }

    private func importHotkeys(
        _ hotkeys: [HotkeyBinding],
        into store: HotkeyBindingStore?
    ) -> (imported: Int, skipped: Int) {
        guard let store, !hotkeys.isEmpty else { return (0, hotkeys.count) }
        store.load()
        var bindings = store.bindings
        var imported = 0
        var skipped = 0

        for hotkey in hotkeys {
            if HotkeyConflictDetector.wouldConflict(hotkey, in: bindings) {
                skipped += 1
                continue
            }
            if let index = bindings.firstIndex(where: { $0.id == hotkey.id }) {
                bindings[index] = hotkey
            } else {
                bindings.append(hotkey)
            }
            imported += 1
        }

        store.replaceAll(bindings)
        return (imported, skipped)
    }

    private func importSpacers(_ spacers: [SpacerItemModel], into store: SpacerItemStore?) -> Int {
        guard let store, !spacers.isEmpty else { return 0 }
        store.load()
        store.importItems(spacers)
        return spacers.count
    }

    private func applyBool(_ rawValue: String, assign: (Bool) -> Void) -> SettingApplyOutcome {
        guard let value = bool(from: rawValue) else { return .skipped }
        assign(value)
        return .applied
    }

    private func applyInt(_ rawValue: String, assign: (Int) -> Void) -> SettingApplyOutcome {
        guard let value = Int(rawValue) else { return .skipped }
        assign(value)
        return .applied
    }

    private func applyUInt(_ rawValue: String, assign: (UInt) -> Void) -> SettingApplyOutcome {
        guard let value = UInt(rawValue) else { return .skipped }
        assign(value)
        return .applied
    }

    private func applyDouble(_ rawValue: String, assign: (Double) -> Void) -> SettingApplyOutcome {
        guard let value = Double(rawValue) else { return .skipped }
        assign(value)
        return .applied
    }

    private func applyOptionalInt(_ rawValue: String, assign: (Int?) -> Void) -> SettingApplyOutcome {
        if isNullLiteral(rawValue) {
            assign(nil)
            return .applied
        }
        return applyInt(rawValue) { assign($0) }
    }

    private func applyOptionalUInt(_ rawValue: String, assign: (UInt?) -> Void) -> SettingApplyOutcome {
        if isNullLiteral(rawValue) {
            assign(nil)
            return .applied
        }
        return applyUInt(rawValue) { assign($0) }
    }

    private func applyOptionalDouble(_ rawValue: String, assign: (Double?) -> Void) -> SettingApplyOutcome {
        if isNullLiteral(rawValue) {
            assign(nil)
            return .applied
        }
        return applyDouble(rawValue) { assign($0) }
    }

    private func bool(from rawValue: String) -> Bool? {
        switch rawValue.lowercased() {
        case "true":
            true
        case "false":
            false
        default:
            nil
        }
    }

    private func isNullLiteral(_ rawValue: String) -> Bool {
        rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "null"
    }
}
