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
        case workspaceValidation
    }
}

/// Dry-run result of an import operation.
nonisolated struct SettingsImportDryRun: Equatable, Sendable {
    let addedProfiles: Int
    let modifiedSettings: Int
    let addedGroups: Int
    let addedHotkeys: Int
    let addedSpacers: Int
    let addedWorkspaces: Int
    let conflicts: [ImportConflict]
    let riskyExperimentalFlags: [String]
    let wouldEnableIconMoving: Bool
    let wouldEnableSpacingLabs: Bool
    let wouldEnableSmartTriggers: Bool

    var hasConflicts: Bool { !conflicts.isEmpty }
    var hasRisks: Bool { !riskyExperimentalFlags.isEmpty || wouldEnableIconMoving || wouldEnableSpacingLabs || wouldEnableSmartTriggers }
}

nonisolated enum SettingsImportFailureInjection: Equatable, Sendable {
    case afterSettings
}

nonisolated struct SettingsImportApplyResult: Equatable, Sendable {
    let appliedSettings: Int
    let skippedSettings: Int
    let importedProfiles: Int
    let importedGroups: Int
    let importedHotkeys: Int
    let skippedHotkeys: Int
    let importedSpacers: Int
    let importedWorkspaces: Int
    let skippedExperimentalFlags: [String]

    var importedObjectCount: Int {
        importedProfiles + importedGroups + importedHotkeys + importedSpacers + importedWorkspaces
    }
}

nonisolated enum SettingsImportApplyError: LocalizedError, Equatable, Sendable {
    case unsupportedPackageVersion(Int)
    case simulatedFailureAfterSettings
    case rollbackFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedPackageVersion(let version):
            "Package version \(version) is not supported for apply."
        case .simulatedFailureAfterSettings:
            "Simulated failure after settings apply."
        case .rollbackFailed(let reason):
            "Import failed and rollback did not complete: \(reason)"
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
        selectedSections: Set<SettingsExportSection> = SettingsExportSection.restorableSections,
        importExperimentalSettings: Bool = false
    ) -> SettingsImportDryRun {
        var conflicts: [ImportConflict] = []
        var riskyFlags: [String] = []
        let selectedSections = effectiveSelectedSections(for: package, requestedSections: selectedSections)

        // Check for hotkey conflicts
        if selectedSections.contains(.hotkeys) {
            for newBinding in package.hotkeyBindings {
                if HotkeyConflictDetector.wouldConflict(newBinding, in: existingHotkeyBindings) {
                    conflicts.append(ImportConflict(
                        kind: .hotkeyConflict,
                        description: "Hotkey binding '\(newBinding.label)' conflicts with an existing binding."
                    ))
                }
            }
        }

        // Check for experimental flags
        let wouldEnableIconMoving = selectedSections.contains(.settings) && package.settings["iconMovingEnabled"] == "true"
        let wouldEnableSpacingLabs = selectedSections.contains(.settings) && package.settings["menuBarSpacingLabsEnabled"] == "true"
        let wouldEnableSmartTriggers = selectedSections.contains(.settings) && package.settings["smartTriggersEnabled"] == "true"
        let previewGateRisks = selectedSections.contains(.settings)
            ? Self.previewGateLabelsEnabled(by: package.settings)
            : []

        if wouldEnableIconMoving {
            riskyFlags.append("Icon moving would be enabled.")
        }
        if wouldEnableSpacingLabs {
            riskyFlags.append("Menu Bar Spacing Labs would be enabled.")
        }
        if wouldEnableSmartTriggers {
            riskyFlags.append("Smart triggers would be enabled.")
        }
        riskyFlags.append(contentsOf: previewGateRisks.map { "\($0) would be enabled." })

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

        let workspaceImport = selectedSections.contains(.workspaces)
            ? validatedWorkspaceImport(package.workspaceSnapshot)
            : nil
        if let workspaceImport, workspaceImport.didRepair {
            conflicts.append(ImportConflict(
                kind: .workspaceValidation,
                description: "Workspace data would be repaired during import (\(workspaceImport.issueCount) issue(s))."
            ))
        }

        return SettingsImportDryRun(
            addedProfiles: selectedSections.contains(.profiles) ? package.profiles.count : 0,
            modifiedSettings: selectedSections.contains(.settings) ? package.settings.count : 0,
            addedGroups: selectedSections.contains(.groups) ? package.groups.count : 0,
            addedHotkeys: selectedSections.contains(.hotkeys) ? package.hotkeyBindings.count : 0,
            addedSpacers: selectedSections.contains(.spacers) ? package.spacerItems.count : 0,
            addedWorkspaces: workspaceImport?.snapshot.workspaces.count ?? 0,
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
        workspaceImportHandler: ((WorkspaceStoreSnapshot) throws -> Void)? = nil,
        importExperimentalSettings: Bool = false,
        selectedSections: Set<SettingsExportSection> = SettingsExportSection.restorableSections,
        failureInjection: SettingsImportFailureInjection? = nil
    ) throws -> SettingsImportApplyResult {
        guard package.packageVersion == 1 else {
            throw SettingsImportApplyError.unsupportedPackageVersion(package.packageVersion)
        }

        var appliedSettings = 0
        var skippedSettings = 0
        var skippedExperimentalFlags: [String] = []
        let selectedSections = effectiveSelectedSections(for: package, requestedSections: selectedSections)

        if selectedSections.contains(.settings) {
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
        }

        if failureInjection == .afterSettings {
            throw SettingsImportApplyError.simulatedFailureAfterSettings
        }

        let importedProfiles = selectedSections.contains(.profiles)
            ? importProfiles(package.profiles, into: profileStore)
            : 0
        let importedGroups = selectedSections.contains(.groups)
            ? importGroups(package.groups, into: groupStore)
            : 0
        let hotkeyResult = selectedSections.contains(.hotkeys)
            ? importHotkeys(package.hotkeyBindings, into: hotkeyBindingStore)
            : (imported: 0, skipped: 0)
        let importedSpacers = selectedSections.contains(.spacers)
            ? importSpacers(package.spacerItems, into: spacerItemStore)
            : 0
        let importedWorkspaces = try selectedSections.contains(.workspaces)
            ? importWorkspaces(package.workspaceSnapshot, using: workspaceImportHandler)
            : 0

        let result = SettingsImportApplyResult(
            appliedSettings: appliedSettings,
            skippedSettings: skippedSettings,
            importedProfiles: importedProfiles,
            importedGroups: importedGroups,
            importedHotkeys: hotkeyResult.imported,
            skippedHotkeys: hotkeyResult.skipped,
            importedSpacers: importedSpacers,
            importedWorkspaces: importedWorkspaces,
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
                "importedWorkspaces": "\(result.importedWorkspaces)",
                "skippedExperimentalFlags": "\(result.skippedExperimentalFlags.count)"
            ]
        )

        return result
    }

    /// Create a local backup before applying a package. If application fails
    /// after mutation starts, the previous package snapshot is restored.
    func applyWithBackup(
        package: SettingsExportPackage,
        currentPackage: SettingsExportPackage,
        backupService: ImportBackupService,
        settingsStore: SettingsStore,
        profileStore: ProfileStore? = nil,
        groupStore: IconGroupStore? = nil,
        hotkeyBindingStore: HotkeyBindingStore? = nil,
        spacerItemStore: SpacerItemStore? = nil,
        workspaceImportHandler: ((WorkspaceStoreSnapshot) throws -> Void)? = nil,
        importExperimentalSettings: Bool = false,
        selectedSections: Set<SettingsExportSection> = SettingsExportSection.restorableSections,
        backupLabel: String = "pre-import",
        failureInjection: SettingsImportFailureInjection? = nil
    ) throws -> SettingsImportApplyResult {
        let currentData = try encode(currentPackage)
        _ = try backupService.createBackup(data: currentData, label: backupLabel)

        do {
            return try apply(
                package: package,
                settingsStore: settingsStore,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: spacerItemStore,
                workspaceImportHandler: workspaceImportHandler,
                importExperimentalSettings: importExperimentalSettings,
                selectedSections: selectedSections,
                failureInjection: failureInjection
            )
        } catch {
            do {
                try restoreSnapshot(
                    package: currentPackage,
                    settingsStore: settingsStore,
                    profileStore: profileStore,
                    groupStore: groupStore,
                    hotkeyBindingStore: hotkeyBindingStore,
                    spacerItemStore: spacerItemStore,
                    workspaceImportHandler: workspaceImportHandler
                )
            } catch {
                throw SettingsImportApplyError.rollbackFailed(error.localizedDescription)
            }
            throw error
        }
    }

    private enum SettingApplyOutcome {
        case applied
        case skipped
        case skippedExperimental(String)
    }

    private func encode(_ package: SettingsExportPackage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    private func restoreSnapshot(
        package: SettingsExportPackage,
        settingsStore: SettingsStore,
        profileStore: ProfileStore?,
        groupStore: IconGroupStore?,
        hotkeyBindingStore: HotkeyBindingStore?,
        spacerItemStore: SpacerItemStore?,
        workspaceImportHandler: ((WorkspaceStoreSnapshot) throws -> Void)?
    ) throws {
        _ = try apply(
            package: package,
            settingsStore: settingsStore,
            importExperimentalSettings: true,
            selectedSections: [.settings]
        )
        profileStore?.replaceAll(package.profiles)
        groupStore?.replaceAll(package.groups)
        hotkeyBindingStore?.replaceAll(package.hotkeyBindings)
        spacerItemStore?.replaceAll(package.spacerItems)
        if let workspaceSnapshot = package.workspaceSnapshot {
            try workspaceImportHandler?(workspaceSnapshot)
        }
    }

    private func effectiveSelectedSections(
        for package: SettingsExportPackage,
        requestedSections: Set<SettingsExportSection>
    ) -> Set<SettingsExportSection> {
        let restorableIncludedSections = Set(package.includedSections)
            .intersection(SettingsExportSection.restorableSections)
        let availableSections = restorableIncludedSections.isEmpty
            ? SettingsExportSection.restorableSections
            : restorableIncludedSections
        return requestedSections
            .intersection(SettingsExportSection.restorableSections)
            .intersection(availableSections)
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
        case .crowdedRevealAskBeforeSwitching:
            return applyBool(rawValue) { settingsStore.crowdedRevealAskBeforeSwitching = $0 }
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
        case .privateAccessProtectProfileApply:
            return applyBool(rawValue) { settingsStore.privateAccessProtectProfileApply = $0 }
        case .privateAccessProtectAutomationCommands:
            return applyBool(rawValue) { settingsStore.privateAccessProtectAutomationCommands = $0 }
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
        case .workspacesPreviewEnabled:
            guard shouldApplyPreviewGate(rawValue, importExperimentalSettings: importExperimentalSettings) else {
                return .skippedExperimental("Workspaces Preview")
            }
            return applyBool(rawValue) { settingsStore.workspacesPreviewEnabled = $0 }
        case .functionBarPreviewEnabled:
            guard shouldApplyPreviewGate(rawValue, importExperimentalSettings: importExperimentalSettings) else {
                return .skippedExperimental("Function Bar Preview")
            }
            return applyBool(rawValue) { settingsStore.functionBarPreviewEnabled = $0 }
        case .functionBarPrimaryClickEnabled:
            guard shouldApplyPreviewGate(rawValue, importExperimentalSettings: importExperimentalSettings) else {
                return .skippedExperimental("Function Bar Primary Click")
            }
            return applyBool(rawValue) { settingsStore.functionBarPrimaryClickEnabled = $0 }
        case .functionBarPlacementPreference:
            settingsStore.functionBarPlacementPreference = FunctionBarPlacementPreference(rawValue: rawValue)?.rawValue
                ?? FunctionBarPlacementPreference.belowMenuBarIcon.rawValue
            return .applied
        case .functionBarShowSetSwitcher:
            return applyBool(rawValue) { settingsStore.functionBarShowSetSwitcher = $0 }
        case .functionBarShowLabels:
            return applyBool(rawValue) { settingsStore.functionBarShowLabels = $0 }
        case .functionBarDensity:
            settingsStore.functionBarDensity = FunctionBarDensity(rawValue: rawValue)?.rawValue
                ?? FunctionBarDensity.regular.rawValue
            return .applied
        case .functionBarCloseOnOutsideClick:
            return applyBool(rawValue) { settingsStore.functionBarCloseOnOutsideClick = $0 }
        case .functionBarKeyboardNavigationEnabled:
            return applyBool(rawValue) { settingsStore.functionBarKeyboardNavigationEnabled = $0 }
        case .setBuilderPreviewEnabled:
            guard shouldApplyPreviewGate(rawValue, importExperimentalSettings: importExperimentalSettings) else {
                return .skippedExperimental("Set Builder Preview")
            }
            return applyBool(rawValue) { settingsStore.setBuilderPreviewEnabled = $0 }
        case .setBuilderDragDropEnabled:
            return applyBool(rawValue) { settingsStore.setBuilderDragDropEnabled = $0 }
        case .setBuilderShowAdvancedLibraryItems:
            return applyBool(rawValue) { settingsStore.setBuilderShowAdvancedLibraryItems = $0 }
        case .setBuilderDefaultGroupReferenceMode:
            settingsStore.setBuilderDefaultGroupReferenceMode = rawValue
            return .applied
        case .setBuilderShowFunctionBarPreview:
            return applyBool(rawValue) { settingsStore.setBuilderShowFunctionBarPreview = $0 }
        case .setBuilderAutosaveDrafts:
            return applyBool(rawValue) { settingsStore.setBuilderAutosaveDrafts = $0 }
        case .setBuilderWarnBeforeLinkedGroupEdits:
            return applyBool(rawValue) { settingsStore.setBuilderWarnBeforeLinkedGroupEdits = $0 }
        case .infoStripPreviewEnabled:
            guard shouldApplyPreviewGate(rawValue, importExperimentalSettings: importExperimentalSettings) else {
                return .skippedExperimental("Info Strip Preview")
            }
            return applyBool(rawValue) { settingsStore.infoStripPreviewEnabled = $0 }
        case .infoStripAutoShowEnabled:
            guard shouldApplyPreviewGate(rawValue, importExperimentalSettings: importExperimentalSettings) else {
                return .skippedExperimental("Info Strip Auto-show")
            }
            return applyBool(rawValue) { settingsStore.infoStripAutoShowEnabled = $0 }
        case .infoStripHoverToFunctionBarEnabled:
            return applyBool(rawValue) { settingsStore.infoStripHoverToFunctionBarEnabled = $0 }
        case .infoStripCloseOnOutsideClick:
            return applyBool(rawValue) { settingsStore.infoStripCloseOnOutsideClick = $0 }
        case .infoStripPauseWhenFunctionBarPinned:
            return applyBool(rawValue) { settingsStore.infoStripPauseWhenFunctionBarPinned = $0 }
        case .infoStripKeyboardNavigationEnabled:
            return applyBool(rawValue) { settingsStore.infoStripKeyboardNavigationEnabled = $0 }
        case .infoStripShowPreviewBadge:
            return applyBool(rawValue) { settingsStore.infoStripShowPreviewBadge = $0 }
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

    private func importWorkspaces(
        _ snapshot: WorkspaceStoreSnapshot?,
        using handler: ((WorkspaceStoreSnapshot) throws -> Void)?
    ) throws -> Int {
        guard let snapshot, let handler else { return 0 }
        guard let workspaceImport = validatedWorkspaceImport(snapshot) else { return 0 }
        try handler(workspaceImport.snapshot)
        return workspaceImport.snapshot.workspaces.count
    }

    private func validatedWorkspaceImport(_ snapshot: WorkspaceStoreSnapshot?) -> WorkspaceImportValidation? {
        guard let snapshot else { return nil }

        let validation = WorkspaceValidation.validate(
            workspaces: snapshot.workspaces,
            activeWorkspaceID: snapshot.activeWorkspaceID
        )
        var repaired = snapshot
        repaired.schemaVersion = WorkspaceStoreSnapshot.currentSchemaVersion
        repaired.workspaces = validation.repairedWorkspaces
        repaired.activeWorkspaceID = validation.selectedActiveWorkspaceID

        let didMigrate = snapshot.schemaVersion != WorkspaceStoreSnapshot.currentSchemaVersion
            || snapshot.workspaces.contains { $0.schemaVersion != MenuBarWorkspace.currentSchemaVersion }

        return WorkspaceImportValidation(
            snapshot: repaired,
            issueCount: validation.issues.reduce(0) { $0 + $1.count },
            didRepair: validation.didRepair || didMigrate
        )
    }

    private func applyBool(_ rawValue: String, assign: (Bool) -> Void) -> SettingApplyOutcome {
        guard let value = bool(from: rawValue) else { return .skipped }
        assign(value)
        return .applied
    }

    private static let previewGateImportLabels: [(key: SettingsStore.Key, label: String)] = [
        (.workspacesPreviewEnabled, "Workspaces Preview"),
        (.functionBarPreviewEnabled, "Function Bar Preview"),
        (.functionBarPrimaryClickEnabled, "Function Bar Primary Click"),
        (.setBuilderPreviewEnabled, "Set Builder Preview"),
        (.infoStripPreviewEnabled, "Info Strip Preview"),
        (.infoStripAutoShowEnabled, "Info Strip Auto-show")
    ]

    private static func previewGateLabelsEnabled(by settings: [String: String]) -> [String] {
        previewGateImportLabels.compactMap { entry in
            settings[entry.key.rawValue]?.lowercased() == "true" ? entry.label : nil
        }
    }

    private func shouldApplyPreviewGate(_ rawValue: String, importExperimentalSettings: Bool) -> Bool {
        guard bool(from: rawValue) == true else { return true }
        return importExperimentalSettings
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

private struct WorkspaceImportValidation {
    let snapshot: WorkspaceStoreSnapshot
    let issueCount: Int
    let didRepair: Bool
}
