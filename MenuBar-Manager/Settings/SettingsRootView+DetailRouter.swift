// SettingsRootView detail router: maps the selected SettingsSection to its
// destination settings view. Extracted from SettingsRootView.swift (cleanup
// wave 2). Same-type extension; zero behavior change.

import AppKit
import Observation
import SwiftUI

extension SettingsRootView {
    @ViewBuilder
    func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView(
                settingsStore: settingsStore,
                launchAtLoginService: launchAtLoginService,
                onResetLayout: actions.resetLayout,
                onResetAllSettings: actions.resetAllSettings,
                onShowOnboarding: actions.showOnboarding
            )
        case .hideReveal, .behavior:
            BehaviorSettingsView(settingsStore: settingsStore, onChange: actions.behaviorChanged)
        case .arrange:
            ArrangeSettingsView(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                permissionService: accessibilityPermissionService,
                newItemInboxStore: newItemInboxStore,
                itemMemoryStore: itemMemoryStore,
                placementPreferenceStore: placementPreferenceStore,
                onExpand: {
                    _ = routeSettingsCommand(MenuBarCommand(action: .expand, source: .settings))
                },
                onCollapse: {
                    _ = routeSettingsCommand(MenuBarCommand(action: .collapse, source: .settings))
                },
                onRevealAll: {
                    _ = routeSettingsCommand(MenuBarCommand(action: .revealAll, source: .settings))
                },
                onResetLayout: actions.resetLayout,
                onShowDragHint: actions.showDragHint,
                onOpenRecovery: {
                    navigationModel.selectedSection = .recovery
                },
                onOpenAdvanced: {
                    navigationModel.selectedSection = .advanced
                },
                onPlannerCommand: { action, itemID in
                    routeSettingsCommand(MenuBarCommand(
                        action: action,
                        target: .menuBarItem(id: itemID),
                        source: .settings
                    ))
                },
                onExecuteAssistedMove: actions.executeAssistedMove
            )
        case .findRescue:
            FindAndRescueSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                liveStatus: liveStatus,
                findIconAvailability: commandSummary(for: MenuBarCommand(
                    action: .showFindIcon,
                    source: .settings
                )),
                secondBarAvailability: commandSummary(for: MenuBarCommand(
                    action: .showSecondBar,
                    target: .secondBar,
                    source: .settings
                )),
                newItemCount: liveStatus?.newMenuBarItemReviewCount ?? 0,
                newItemInboxStore: newItemInboxStore,
                placementPreferenceStore: placementPreferenceStore,
                workspaceSwitchingService: workspaceSwitchingService,
                groupStore: groupStore,
                onOpenFindIcon: {
                    _ = routeSettingsCommand(MenuBarCommand(
                        action: .showFindIcon,
                        source: .settings
                    ))
                },
                onOpenSecondBar: {
                    _ = routeSettingsCommand(MenuBarCommand(
                        action: .showSecondBar,
                        target: .secondBar,
                        source: .settings
                    ))
                },
                onOpenSearchSettings: {
                    navigationModel.selectedSection = .search
                },
                onOpenSecondBarSettings: {
                    navigationModel.selectedSection = .secondBar
                },
                onOpenMenuBarItems: {
                    navigationModel.selectedSection = .menuBarItems
                },
                onOpenGroups: {
                    navigationModel.selectedSection = .groups
                },
                onOpenAdvanced: {
                    navigationModel.selectedSection = .advanced
                },
                onOpenArrange: {
                    navigationModel.selectedSection = .arrange
                },
                onOpenPrivacy: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .menuBarItems:
            MenuBarItemsSettingsView(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                scanCoordinator: menuBarScanCoordinator,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .layout:
            if let layoutCoordinator {
                LayoutSettingsView(
                    settingsStore: settingsStore,
                    diagnosticsLogger: diagnosticsLogger,
                    liveStatus: liveStatus,
                    layoutCoordinator: layoutCoordinator
                )
            } else {
                LayoutSettingsView(
                    settingsStore: settingsStore,
                    diagnosticsLogger: diagnosticsLogger,
                    liveStatus: liveStatus
                )
            }
        case .search:
            SearchSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                commandAvailability: commandSummary(for: MenuBarCommand(
                    action: .showFindIcon,
                    source: .statusMenu
                )),
                onChange: actions.searchChanged,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .secondBar:
            SecondBarSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                iconCaptureCoordinator: iconCaptureCoordinator,
                scanCoordinator: menuBarScanCoordinator,
                commandAvailability: commandSummary(for: MenuBarCommand(
                    action: .showSecondBar,
                    target: .secondBar,
                    source: .statusMenu
                )),
                iconPanelAvailability: commandSummary(for: MenuBarCommand(
                    action: .showIconPanel,
                    target: .iconPanel,
                    source: .statusMenu
                )),
                onChange: actions.secondBarChanged,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .privateAccess:
            PrivateAccessSettingsView(
                settingsStore: settingsStore,
                coordinator: privateAccessCoordinator,
                commandAvailabilities: privateAccessCommandSummaries,
                onChange: actions.privacyChanged
            )
        case .groups:
            if let groupStore {
                IconGroupsSettingsView(
                    settingsStore: settingsStore,
                    groupStore: groupStore,
                    snapshots: liveStatus?.scannedMenuBarItems ?? [],
                    proModeAvailable: settingsStore.isProDiscoveryAvailable,
                    onOpenPrivacySettings: {
                        navigationModel.selectedSection = .privacy
                    },
                    commandAvailability: { group in
                        commandSummary(for: MenuBarCommand(
                            action: .showGroupPanel,
                            target: .group(group.id),
                            source: .settings
                        ))
                    },
                    onOpenGroupPanel: { group in
                        routeSettingsCommand(MenuBarCommand(
                            action: .showGroupPanel,
                            target: .group(group.id),
                            source: .settings
                        ))
                    },
                    onRevealGroup: { group in
                        routeSettingsCommand(MenuBarCommand(
                            action: .revealGroup,
                            target: .group(group.id),
                            source: .settings
                        ))
                    },
                    onAssignGroupHotkey: { group, kind in
                        assignGroupHotkey(group, kind: kind)
                    },
                    onGroupsChanged: actions.groupsChanged
                )
            } else {
                ClearGlassSettingsPage("Groups", subtitle: "Group controls are available once group services are attached.") {
                    ClearGlassSection("Groups Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Groups Unavailable",
                            message: "Group services are not attached in this build. Basic Mode remains available.",
                            systemImage: "person.2",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .hotkeys:
            if let hotkeyBindingStore {
                DynamicHotkeysSettingsView(
                    settingsStore: settingsStore,
                    bindingStore: hotkeyBindingStore,
                    groups: groupStore?.groups ?? [],
                    profiles: profileStore?.profiles ?? [],
                    onHotkeysChanged: actions.dynamicHotkeysChanged
                )
            } else {
                ClearGlassSettingsPage("Hotkeys", subtitle: "Dynamic hotkeys are available once the hotkey store is attached.") {
                    ClearGlassSection("Hotkeys Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Hotkeys Unavailable",
                            message: "The dynamic hotkey store is not attached in this build. The stable Basic hotkey is unchanged.",
                            systemImage: "keyboard",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .profiles:
            if let profileStore,
               let triggerService,
               let liveStatus,
               let dryRunProfile = actions.profile.dryRun,
               let applyProfile = actions.profile.apply {
                ProfileListView(
                    profileStore: profileStore,
                    triggerService: triggerService,
                    settingsStore: settingsStore,
                    liveStatus: liveStatus,
                    onDryRun: dryRunProfile,
                    onApply: applyProfile,
                    commandAvailability: { profile in
                        commandSummary(for: MenuBarCommand(
                            action: .applyProfile,
                            target: .profileID(profile.id),
                            source: .settings
                        ))
                    },
                    onTriggersChanged: actions.triggersChanged ?? {}
                )
            } else {
                ClearGlassSettingsPage(
                    "Profiles",
                    subtitle: "Profile controls are available once profile services are attached."
                ) {
                    ClearGlassSection("Profiles Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Profiles Unavailable",
                            message: "Profile services are not attached in this build. Existing Basic Mode controls remain available.",
                            systemImage: "person.crop.rectangle.stack",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .privacy:
            PrivacySettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                iconCaptureCoordinator: iconCaptureCoordinator,
                scanCoordinator: menuBarScanCoordinator,
                onChange: actions.privacyChanged
            )
        case .recovery:
            RecoverySettingsView(
                settingsStore: settingsStore,
                diagnosticsLogger: diagnosticsLogger,
                appSupportPaths: appSupportPaths,
                diagnosticsExporter: diagnosticsExporter,
                liveStatus: liveStatus,
                onRunHealthCheck: actions.runHealthCheck,
                onFixHealthIssues: actions.fixHealthIssues,
                onExpand: actions.expand,
                onRevealAll: actions.revealAll,
                onRecreateStatusItems: actions.recreateStatusItems,
                onDisableAutoRehideTemporarily: actions.disableAutoRehideTemporarily,
                onDisableHoverRevealTemporarily: actions.disableHoverRevealTemporarily,
                onResetCurrentWorkspaceLayout: actions.resetCurrentWorkspaceLayout,
                onRemoveMissingWorkspaceGroupReferences: actions.removeMissingWorkspaceGroupReferences,
                onDiscardSetBuilderDraft: actions.discardSetBuilderDraft,
                onDisableFunctionBarPreview: actions.disableFunctionBarPreview,
                onDisableInfoStripPreview: actions.disableInfoStripPreview,
                onDisableSetBuilderPreview: actions.disableSetBuilderPreview,
                onResetLayout: actions.resetLayout,
                onResetAllSettings: actions.resetAllSettings,
                onResetBasicMode: actions.resetBasicMode,
                onDisableProMode: actions.disableProMode,
                onEnterSafeModeNextLaunch: actions.enterSafeModeNextLaunch,
                onOpenTroubleshootingGuide: actions.openTroubleshootingGuide,
                onOpenDiagnostics: {
                    navigationModel.selectedSection = .diagnostics
                },
                onOpenImportExport: {
                    navigationModel.selectedSection = .importExport
                }
            )
        case .automation:
            AutomationSettingsView(
                settingsStore: settingsStore,
                accessibilityPermissionService: accessibilityPermissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                onChange: actions.automationSettingsChanged
            )
        case .importExport:
            MigrationAssistantRootView(
                settingsStore: settingsStore,
                appSupportPaths: appSupportPaths,
                diagnosticsLogger: diagnosticsLogger,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: layoutCoordinator?.spacerStore,
                workspaceSwitchingService: workspaceSwitchingService,
                onImportApplied: refreshAfterSettingsImport
            )
        case .diagnostics:
            DiagnosticsSettingsView(
                diagnosticsLogger: diagnosticsLogger,
                liveStatus: liveStatus,
                appSupportPaths: appSupportPaths,
                exporter: diagnosticsExporter,
                dogfoodStore: dogfoodStore,
                settingsStore: settingsStore,
                launchAtLoginService: launchAtLoginService,
                scanCoordinator: menuBarScanCoordinator,
                onRunHealthCheck: actions.runHealthCheck,
                onFixHealthIssues: actions.fixHealthIssues,
                onResetBasicMode: actions.resetBasicMode,
                onDisableProMode: actions.disableProMode,
                onEnterSafeModeNextLaunch: actions.enterSafeModeNextLaunch,
                secondBarReadinessDiagnosticsProvider: makeSecondBarReadinessDiagnosticsSnapshot,
                secondBarRuntimeDiagnosticsProvider: makeSecondBarRuntimeDiagnosticsSnapshot,
                workspacePreviewDiagnosticsProvider: makeWorkspacePreviewDiagnosticsSnapshot
            )
        case .advanced:
            AdvancedSettingsView(
                settingsStore: settingsStore,
                appSupportPaths: appSupportPaths,
                onChange: actions.behaviorChanged,
                onAutomationChanged: actions.triggersChanged,
                onResetMovingWarnings: actions.resetMovingWarnings,
                onOpenSection: { section in
                    navigationModel.selectedSection = section
                }
            )
        case .workspacesPreview:
            if let workspaceSwitchingService,
               let setBuilderViewModel,
               let functionBarController,
               let infoStripController {
                WorkspacePreviewSettingsView(
                    settingsStore: settingsStore,
                    liveStatus: liveStatus,
                    switchingService: workspaceSwitchingService,
                    setBuilderViewModel: setBuilderViewModel,
                    functionBarController: functionBarController,
                    infoStripController: infoStripController,
                    knownGroupIDs: Set((groupStore?.groups ?? setBuilderViewModel.groups).map(\.id)),
                    protectedGroupIDs: Set((groupStore?.groups ?? setBuilderViewModel.groups).filter(\.isProtected).map(\.id)),
                    knownProfileIDs: Set(profileStore?.profiles.map(\.id) ?? []),
                    routeCommand: actions.routeCommand,
                    onOpenFindRescue: {
                        navigationModel.selectedSection = .findRescue
                    },
                    onOpenRecovery: {
                        navigationModel.selectedSection = .recovery
                    },
                    applyLayout: actions.applyWorkspaceLayout,
                    isLayoutApplyEnabled: { actions.isWorkspaceLayoutApplyEnabled?() ?? false }
                )
            } else {
                ClearGlassSettingsPage(
                    "Workspaces",
                    subtitle: "Workspaces are available once preview services are attached.",
                    badges: [.experimental, .privacySafe]
                ) {
                    ClearGlassSection("Preview Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Preview Unavailable",
                            message: "Workspace preview services are not attached in this build. Stable settings remain usable.",
                            systemImage: "rectangle.3.group",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        }
    }
}
