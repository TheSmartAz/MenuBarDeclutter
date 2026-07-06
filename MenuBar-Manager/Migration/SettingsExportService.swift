import Foundation

/// Service for exporting settings to a JSON package.
@MainActor
final class SettingsExportService {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let appVersionProvider: () -> String
    private let now: () -> Date

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        appVersionProvider: @escaping () -> String = { AppConstants.appVersion },
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.appVersionProvider = appVersionProvider
        self.now = now
    }

    /// Create an export package from current settings.
    func createExportPackage(
        profiles: [ProfileModel] = [],
        groups: [IconGroup] = [],
        hotkeyBindings: [HotkeyBinding] = [],
        spacerItems: [SpacerItemModel] = [],
        workspaceSnapshot: WorkspaceStoreSnapshot? = nil,
        includeAXSnapshots: Bool = false
    ) -> SettingsExportPackage {
        let settings = exportSettingsDict()

        let privateAccessPolicy = PrivateAccessPolicyExport(
            isEnabled: settingsStore.privateAccessEnabled,
            protectAlwaysHidden: settingsStore.privateAccessProtectAlwaysHidden,
            protectSecondBar: settingsStore.privateAccessProtectSecondBar,
            protectFindIcon: settingsStore.privateAccessProtectFindIcon,
            protectIconMoving: settingsStore.privateAccessProtectIconMoving,
            protectSpacingLabs: settingsStore.privateAccessProtectSpacingLabs,
            protectProfileApply: settingsStore.privateAccessProtectProfileApply,
            protectAutomationCommands: settingsStore.privateAccessProtectAutomationCommands,
            protectedGroupsRequireAuth: settingsStore.protectedGroupsRequireAuth,
            unlockDurationSeconds: settingsStore.privateAccessUnlockDurationSeconds,
            allowDevicePasswordFallback: settingsStore.privateAccessAllowDevicePasswordFallback
        )

        let safeWorkspaceSnapshot = Self.privacySafeWorkspaceSnapshot(workspaceSnapshot)

        return SettingsExportPackage(
            appName: AppConstants.displayName,
            appVersion: appVersionProvider(),
            exportKind: .fullSettings,
            createdAt: now(),
            redactionMode: .privacySafe,
            includedSections: SettingsExportSection.defaultIncludedSections,
            settings: settings,
            omittedSettings: Self.intentionallyOmittedSettings.map(\.rawValue).sorted(),
            profiles: profiles,
            groups: IconGroupImportExport.groupsForExport(groups),
            hotkeyBindings: hotkeyBindings,
            spacerItems: spacerItems,
            workspaceSnapshot: safeWorkspaceSnapshot,
            privateAccessPolicy: privateAccessPolicy,
            includeAXSnapshots: includeAXSnapshots
        )
    }

    /// Encode the package to JSON data.
    func encode(_ package: SettingsExportPackage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    private func exportSettingsDict() -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: SettingsStore.privacySafeExportKeys.compactMap { key in
                guard let value = exportedValue(for: key) else { return nil }
                return (key.rawValue, value)
            }
        )
    }

    private static let intentionallyOmittedSettings = SettingsStore.privacySafeExportOmittedKeys

    private static func privacySafeWorkspaceSnapshot(_ snapshot: WorkspaceStoreSnapshot?) -> WorkspaceStoreSnapshot? {
        guard var snapshot else { return nil }
        snapshot.workspaces = snapshot.workspaces.map(privacySafeWorkspace(_:))
        return snapshot
    }

    private static func privacySafeWorkspace(_ workspace: MenuBarWorkspace) -> MenuBarWorkspace {
        var safe = workspace
        if safe.isProtected {
            safe.name = "Protected Workspace"
        }
        safe.functionItems = safe.functionItems.map(privacySafeWorkspaceItem(_:))
        return safe
    }

    private static func privacySafeWorkspaceItem(_ item: WorkspaceItem) -> WorkspaceItem {
        var safe = item
        safe.displayNameOverride = nil
        if case .menuBarItem(var reference) = safe.kind {
            reference.lastKnownDisplayName = nil
            reference.lastKnownBundleIdentifier = nil
            safe.kind = .menuBarItem(reference)
        }
        return safe
    }

    private func exportedValue(for key: SettingsStore.Key) -> String? {
        if Self.intentionallyOmittedSettings.contains(key) {
            return nil
        }

        switch key {
        case .hasCompletedOnboarding:
            return settingsStore.hasCompletedOnboarding.description
        case .launchAtLoginEnabled,
             .lastKnownAppVersion,
             .settingsMigrationVersion,
             .v01SafeDefaultsNoticePending:
            return nil
        case .appMode:
            return settingsStore.appMode.rawValue
        case .isCollapsed:
            return settingsStore.isCollapsed.description
        case .startCollapsed:
            return settingsStore.startCollapsed.description
        case .expandedSeparatorLength:
            return settingsStore.expandedSeparatorLength.description
        case .collapsedSeparatorLengthOverride:
            return settingsStore.collapsedSeparatorLengthOverride?.description ?? "null"
        case .hasSeenDragHint:
            return settingsStore.hasSeenDragHint.description
        case .showPrimarySeparator:
            return nil
        case .proModeEnabled:
            return settingsStore.proModeEnabled.description
        case .accessibilityDiscoveryEnabled:
            return settingsStore.accessibilityDiscoveryEnabled.description
        case .lastAccessibilityPermissionStatus:
            return nil
        case .menuBarScanIntervalSeconds:
            return settingsStore.menuBarScanIntervalSeconds.description
        case .renderedIconCaptureEnabled:
            return settingsStore.renderedIconCaptureEnabled.description
        case .renderedIconRevealSweepEnabled:
            return settingsStore.renderedIconRevealSweepEnabled.description
        case .searchEnabled:
            return settingsStore.searchEnabled.description
        case .searchHotkeyEnabled:
            return settingsStore.searchHotkeyEnabled.description
        case .searchHotkeyKeyCode:
            return settingsStore.searchHotkeyKeyCode?.description ?? "null"
        case .searchHotkeyModifiersRaw:
            return settingsStore.searchHotkeyModifiersRaw?.description ?? "null"
        case .searchRevealOnSelection:
            return settingsStore.searchRevealOnSelection.description
        case .searchHighlightOnSelection:
            return settingsStore.searchHighlightOnSelection.description
        case .secondBarEnabled:
            return settingsStore.secondBarEnabled.description
        case .secondBarPrimaryClickEnabled:
            return settingsStore.secondBarPrimaryClickEnabled.description
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
            return nil
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
        case .dogfoodModeEnabled, .dogfoodRunID, .dogfoodNotesEnabled:
            return nil
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
            return settingsStore.globalHotkeyKeyCode?.description ?? "null"
        case .globalHotkeyModifiersRaw:
            return settingsStore.globalHotkeyModifiersRaw?.description ?? "null"
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
        case .crowdedRevealAskBeforeSwitching:
            return settingsStore.crowdedRevealAskBeforeSwitching.description
        case .crowdedRescueWorkspaceFallbackPreference:
            return settingsStore.crowdedRescueWorkspaceFallbackPreference
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
        case .menuBarSpacingHasBackup, .menuBarSpacingLastApplyStatus, .menuBarSpacingLastApplyDate:
            return nil
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
        case .privateAccessProtectProfileApply:
            return settingsStore.privateAccessProtectProfileApply.description
        case .privateAccessProtectAutomationCommands:
            return settingsStore.privateAccessProtectAutomationCommands.description
        case .privateAccessUnlockDurationSeconds:
            return settingsStore.privateAccessUnlockDurationSeconds.description
        case .privateAccessLastAuthStatus:
            return nil
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
        case .workspacesPreviewEnabled:
            return settingsStore.workspacesPreviewEnabled.description
        case .functionBarPreviewEnabled:
            return settingsStore.functionBarPreviewEnabled.description
        case .functionBarPrimaryClickEnabled:
            return settingsStore.functionBarPrimaryClickEnabled.description
        case .functionBarPlacementPreference:
            return settingsStore.functionBarPlacementPreference
        case .functionBarShowSetSwitcher:
            return settingsStore.functionBarShowSetSwitcher.description
        case .functionBarShowLabels:
            return settingsStore.functionBarShowLabels.description
        case .functionBarDensity:
            return settingsStore.functionBarDensity
        case .functionBarCloseOnOutsideClick:
            return settingsStore.functionBarCloseOnOutsideClick.description
        case .functionBarKeyboardNavigationEnabled:
            return settingsStore.functionBarKeyboardNavigationEnabled.description
        case .setBuilderPreviewEnabled:
            return settingsStore.setBuilderPreviewEnabled.description
        case .setBuilderDragDropEnabled:
            return settingsStore.setBuilderDragDropEnabled.description
        case .setBuilderShowAdvancedLibraryItems:
            return settingsStore.setBuilderShowAdvancedLibraryItems.description
        case .setBuilderDefaultGroupReferenceMode:
            return settingsStore.setBuilderDefaultGroupReferenceMode
        case .setBuilderShowFunctionBarPreview:
            return settingsStore.setBuilderShowFunctionBarPreview.description
        case .setBuilderAutosaveDrafts:
            return settingsStore.setBuilderAutosaveDrafts.description
        case .setBuilderWarnBeforeLinkedGroupEdits:
            return settingsStore.setBuilderWarnBeforeLinkedGroupEdits.description
        case .infoStripPreviewEnabled:
            return settingsStore.infoStripPreviewEnabled.description
        case .infoStripAutoShowEnabled:
            return settingsStore.infoStripAutoShowEnabled.description
        case .infoStripHoverToFunctionBarEnabled:
            return settingsStore.infoStripHoverToFunctionBarEnabled.description
        case .infoStripCloseOnOutsideClick:
            return settingsStore.infoStripCloseOnOutsideClick.description
        case .infoStripPauseWhenFunctionBarPinned:
            return settingsStore.infoStripPauseWhenFunctionBarPinned.description
        case .infoStripKeyboardNavigationEnabled:
            return settingsStore.infoStripKeyboardNavigationEnabled.description
        case .infoStripShowPreviewBadge:
            return settingsStore.infoStripShowPreviewBadge.description
        }
    }
}
