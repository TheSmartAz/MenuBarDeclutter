import AppKit
import Observation
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case hideReveal
    case arrange
    case findRescue
    case menuBarItems
    case behavior
    case layout
    case search
    case secondBar
    case privateAccess
    case groups
    case hotkeys
    case profiles
    case automation
    case importExport
    case privacy
    case recovery
    case diagnostics
    case advanced
    case workspacesPreview

    var id: String { rawValue }

    static let visibleSidebarSections: [SettingsSection] = [
        .general,
        .hideReveal,
        .arrange,
        .findRescue,
        .workspacesPreview,
        .privacy,
        .recovery,
        .advanced
    ]

    static let moreSidebarSections: [SettingsSection] = [
        .menuBarItems,
        .search,
        .secondBar,
        .groups,
        .hotkeys,
        .profiles,
        .privateAccess,
        .automation,
        .importExport,
        .diagnostics,
        .layout
    ]

    var title: String {
        switch self {
        case .general:
            "General"
        case .hideReveal:
            "Hide & Reveal"
        case .arrange:
            "Arrange"
        case .findRescue:
            "Find & Rescue"
        case .menuBarItems:
            "Menu Bar Items"
        case .behavior:
            "Behavior"
        case .layout:
            "Layout"
        case .search:
            "Search"
        case .secondBar:
            "Second Bar"
        case .privateAccess:
            "Private Access"
        case .groups:
            "Groups"
        case .hotkeys:
            "Hotkeys"
        case .profiles:
            "Profiles"
        case .automation:
            "Automation"
        case .importExport:
            "Import / Export"
        case .privacy:
            "Privacy"
        case .recovery:
            "Recovery"
        case .diagnostics:
            "Diagnostics"
        case .advanced:
            "Advanced"
        case .workspacesPreview:
            "Workspaces"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
        case .hideReveal:
            "eye"
        case .arrange:
            "arrow.up.left.and.arrow.down.right"
        case .findRescue:
            "lifepreserver"
        case .menuBarItems:
            "list.bullet.rectangle"
        case .behavior:
            "slider.horizontal.3"
        case .layout:
            "rectangle.split.3x1"
        case .search:
            "magnifyingglass"
        case .secondBar:
            "menubar.rectangle"
        case .privateAccess:
            "lock.fill"
        case .groups:
            "person.2"
        case .hotkeys:
            "keyboard"
        case .profiles:
            "person.crop.rectangle.stack"
        case .automation:
            "link"
        case .importExport:
            "arrow.up.arrow.down"
        case .privacy:
            "shield.lefthalf.filled"
        case .recovery:
            "cross.case"
        case .diagnostics:
            "waveform.path.ecg"
        case .advanced:
            "chevron.left.forwardslash.chevron.right"
        case .workspacesPreview:
            "rectangle.3.group"
        }
    }
}

private struct SettingsSidebarGroup: Identifiable {
    let title: String
    let sections: [SettingsSection]

    var id: String { title }

    static let all: [SettingsSidebarGroup] = [
        SettingsSidebarGroup(
            title: "MenuBarDeclutter",
            sections: SettingsSection.visibleSidebarSections
        ),
        SettingsSidebarGroup(
            title: "More",
            sections: SettingsSection.moreSidebarSections
        )
    ]
}

private struct SettingsSidebarSectionRow: View {
    let section: SettingsSection

    var body: some View {
        Label(section.title, systemImage: section.systemImage)
            .tag(section)
            .help(section.helpText)
            .accessibilityIdentifier(section.sidebarAccessibilityIdentifier)
    }
}

extension SettingsSection {
    var helpText: String {
        switch self {
        case .general:
            "Startup, onboarding, app mode, and app identity."
        case .hideReveal:
            "Collapse, expand, reveal all, auto-rehide, hover reveal, always-hidden zone, and the Basic hotkey."
        case .arrange:
            "Command-drag guide, control and separator placement, placement test, Planner Preview, and Assisted Move."
        case .findRescue:
            "Find Icon, Second Bar, crowded menu rescue, New Items, and lightweight collections."
        case .menuBarItems:
            "Inspect discovered menu bar items, owners, zones, and geometry."
        case .behavior:
            "Auto-rehide, hover reveal, separators, click behavior, and the global hotkey."
        case .layout:
            "Capacity, layout suggestions, Full Menu Bar Mode, spacers, and spacing labs."
        case .search:
            "Find Icon and search hotkey settings."
        case .secondBar:
            "Second Bar behavior, requirements, and presentation."
        case .privateAccess:
            "Authentication boundaries for protected app surfaces."
        case .groups:
            "Create and manage item groups."
        case .hotkeys:
            "Dynamic shortcut bindings for commands, groups, and profiles."
        case .profiles:
            "Profiles and automatic triggers."
        case .automation:
            "App Shortcuts and URL command settings."
        case .importExport:
            "Privacy-safe import, export, backups, and migration."
        case .privacy:
            "Basic Mode, Optional Pro, permissions, and local data policy."
        case .recovery:
            "Safe Mode, reset layout, repair actions, diagnostics export, and health report."
        case .diagnostics:
            "Health checks, logs, live status, and diagnostics export."
        case .advanced:
            "Developer-oriented recovery and Labs controls."
        case .workspacesPreview:
            "Local-only Workspaces, Function Bar, Set Builder, and Info Strip previews."
        }
    }

    var searchKeywords: String {
        "\(title) \(helpText)"
    }
}

@Observable
@MainActor
final class SettingsNavigationModel {
    var selectedSection: SettingsSection? = .general
    var searchText = ""
}

struct SettingsRootView: View {
    @Bindable var navigationModel: SettingsNavigationModel
    @Bindable var settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?
    var launchAtLoginService: LaunchAtLoginService?
    var appSupportPaths: AppSupportPaths
    var diagnosticsExporter: DiagnosticsExporter
    @Bindable var dogfoodStore: DogfoodStore
    var newItemInboxStore: NewMenuBarItemInboxStore? = nil
    var itemMemoryStore: MenuBarItemMemoryStore? = nil
    var placementPreferenceStore: PlacementItemPreferenceStore? = nil
    var accessibilityPermissionService: AccessibilityPermissionService?
    var menuBarScanCoordinator: MenuBarScanCoordinator?
    var profileStore: ProfileStore?
    var triggerService: TriggerService?
    var layoutCoordinator: LayoutCoordinator?
    var groupStore: IconGroupStore?
    var hotkeyBindingStore: HotkeyBindingStore?
    var privateAccessCoordinator: PrivateAccessCoordinator?
    var workspaceSwitchingService: WorkspaceSwitchingService?
    var setBuilderViewModel: SetBuilderViewModel?
    var functionBarController: FunctionBarController?
    var infoStripController: InfoStripController?
    var actions: SettingsActions = .empty
    @State private var isCommandPalettePresented = false
    @State private var isMoreSettingsExpanded = false

    var body: some View {
        NavigationSplitView {
            List(selection: $navigationModel.selectedSection) {
                if isFilteringSidebar {
                    ForEach(filteredSidebarGroups) { group in
                        Section(group.title) {
                            ForEach(group.sections) { section in
                                SettingsSidebarSectionRow(section: section)
                            }
                        }
                    }
                } else {
                    Section("MenuBarDeclutter") {
                        ForEach(SettingsSection.visibleSidebarSections) { section in
                            SettingsSidebarSectionRow(section: section)
                        }
                    }

                    DisclosureGroup(isExpanded: $isMoreSettingsExpanded) {
                        ForEach(SettingsSection.moreSidebarSections) { section in
                            SettingsSidebarSectionRow(section: section)
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                            .help("Show deeper settings surfaces.")
                    }
                    .accessibilityIdentifier("settings.sidebar.more")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .searchable(text: $navigationModel.searchText, prompt: "Search Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 226, max: 270)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCommandPalettePresented = true
                    } label: {
                        Label("Find Setting or Action", systemImage: "magnifyingglass")
                    }
                    .keyboardShortcut("k", modifiers: [.command])
                    .help("Find a setting or action")
                    .accessibilityIdentifier("settings.commandPalette.open")
                }
            }
        } detail: {
            detailView(for: selectedSection)
                .accessibilityIdentifier(selectedSection.pageAccessibilityIdentifier)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $isCommandPalettePresented) {
            SettingsCommandPaletteView(
                index: commandPaletteIndex,
                onActivate: activateCommandPaletteEntry
            )
        }
        .onAppear {
            navigationModel.selectedSection = navigationModel.selectedSection ?? .general
            expandMoreSettingsIfNeeded(for: selectedSection)
        }
        .onChange(of: navigationModel.selectedSection) { _, newValue in
            guard let newValue else { return }
            expandMoreSettingsIfNeeded(for: newValue)
        }
    }

    private var selectedSection: SettingsSection {
        navigationModel.selectedSection ?? .general
    }

    private var sidebarSearchQuery: String {
        navigationModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFilteringSidebar: Bool {
        !sidebarSearchQuery.isEmpty
    }

    private var filteredSidebarGroups: [SettingsSidebarGroup] {
        let query = sidebarSearchQuery
        guard !query.isEmpty else { return SettingsSidebarGroup.all }

        return SettingsSidebarGroup.all.compactMap { group in
            let sections = group.title.localizedStandardContains(query)
                ? group.sections
                : group.sections.filter { section in
                    section.title.localizedStandardContains(query)
                        || section.searchKeywords.localizedStandardContains(query)
                }
            guard !sections.isEmpty else { return nil }
            return SettingsSidebarGroup(title: group.title, sections: sections)
        }
    }

    private var commandPaletteIndex: SettingsCommandPaletteIndex {
        SettingsCommandPaletteIndex.make(
            includeDogfood: settingsStore.dogfoodModeEnabled || settingsStore.dogfoodRunID != nil,
            availableActions: availableCommandPaletteActions
        )
    }

    private var availableCommandPaletteActions: Set<SettingsCommandPaletteAction> {
        var availableActions = Set<SettingsCommandPaletteAction>()

        if actions.showOnboarding != nil {
            availableActions.insert(.showOnboarding)
        }
        if actions.showDragHint != nil {
            availableActions.insert(.showDragHint)
        }
        if actions.runHealthCheck != nil {
            availableActions.insert(.runHealthCheck)
        }
        if actions.fixHealthIssues != nil {
            availableActions.insert(.fixHealthIssues)
        }
        if actions.expand != nil {
            availableActions.insert(.expand)
        }
        if actions.revealAll != nil {
            availableActions.insert(.revealAll)
        }
        if actions.recreateStatusItems != nil {
            availableActions.insert(.recreateStatusItems)
        }
        if actions.disableAutoRehideTemporarily != nil {
            availableActions.insert(.disableAutoRehideTemporarily)
        }
        if actions.disableHoverRevealTemporarily != nil {
            availableActions.insert(.disableHoverRevealTemporarily)
        }
        if actions.openTroubleshootingGuide != nil {
            availableActions.insert(.openTroubleshootingGuide)
        }

        return availableActions
    }

    private func activateCommandPaletteEntry(_ entry: SettingsCommandPaletteEntry) {
        if let destination = entry.destination {
            navigationModel.selectedSection = destination
            return
        }

        if let action = entry.action {
            performCommandPaletteAction(action)
        }
    }

    private func performCommandPaletteAction(_ action: SettingsCommandPaletteAction) {
        switch action {
        case .showOnboarding:
            actions.showOnboarding?()
        case .showDragHint:
            actions.showDragHint?()
        case .runHealthCheck:
            actions.runHealthCheck?()
        case .fixHealthIssues:
            actions.fixHealthIssues?()
        case .expand:
            actions.expand?()
        case .revealAll:
            actions.revealAll?()
        case .recreateStatusItems:
            actions.recreateStatusItems?()
        case .disableAutoRehideTemporarily:
            actions.disableAutoRehideTemporarily?()
        case .disableHoverRevealTemporarily:
            actions.disableHoverRevealTemporarily?()
        case .openTroubleshootingGuide:
            actions.openTroubleshootingGuide?()
        }
    }

    private func expandMoreSettingsIfNeeded(for section: SettingsSection) {
        if SettingsSection.moreSidebarSections.contains(section) {
            isMoreSettingsExpanded = true
        }
    }

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
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
                    proModeAvailable: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled,
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
                    }
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

    private func commandSummary(for command: MenuBarCommand) -> MenuBarCommandAvailabilitySummary? {
        guard let availability = actions.commandAvailability?(command) else {
            return nil
        }
        return MenuBarCommandAvailabilitySummary(command: command, availability: availability)
    }

    private func makeWorkspacePreviewDiagnosticsSnapshot() -> DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot? {
        guard let workspaceSwitchingService,
              let setBuilderViewModel,
              let functionBarController,
              let infoStripController else {
            return nil
        }

        let snapshot = workspaceSwitchingService.currentSnapshot()
        let active = workspaceSwitchingService.activeWorkspace()
        let knownGroups = groupStore?.groups ?? setBuilderViewModel.groups
        let workspaceDiagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: Set(knownGroups.map(\.id)),
            protectedGroupIDs: Set(knownGroups.filter(\.isProtected).map(\.id)),
            knownProfileIDs: Set(profileStore?.profiles.map(\.id) ?? []),
            availableMenuBarItemHashes: availableMenuBarItemHashesForWorkspaceDiagnostics()
        )
        let functionDiagnostics = FunctionBarDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            controller: functionBarController
        )
        let infoDiagnostics = InfoStripDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            controller: infoStripController,
            registry: InfoTileProviderRegistry(),
            context: InfoTileContext(
                activeWorkspace: active,
                functionBarVisible: functionDiagnostics.isVisible,
                hiddenItemCount: liveStatus?.menuBarScanHiddenCount,
                alwaysHiddenItemCount: liveStatus?.menuBarScanAlwaysHiddenCount,
                newItemCount: liveStatus?.newMenuBarItemReviewCount,
                healthWarningCount: liveStatus?.healthReport?.issues.count ?? 0,
                latestScanAgeSeconds: nil,
                proDiscoveryAvailable: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled,
                safeModeActive: liveStatus?.safeModeActive ?? false,
                currentDate: Date()
            )
        )

        return DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot(
            workspaces: workspaceDiagnostics,
            functionBar: functionDiagnostics,
            setBuilder: setBuilderViewModel.diagnosticsSnapshot,
            infoStrip: infoDiagnostics
        )
    }

    private func routeSettingsCommand(_ command: MenuBarCommand) -> MenuBarCommandResult {
        actions.routeCommand?(command)
            ?? MenuBarCommandResult.stopped(
                command,
                status: .failed,
                message: "Command router is unavailable.",
                diagnosticReason: "routerUnavailable"
            )
    }

    private func availableMenuBarItemHashesForWorkspaceDiagnostics() -> Set<String>? {
        guard settingsStore.proModeEnabled,
              settingsStore.accessibilityDiscoveryEnabled,
              settingsStore.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue,
              liveStatus?.lastMenuBarScanTime != nil else {
            return nil
        }
        return Set(liveStatus?.scannedMenuBarItems.map(\.id) ?? [])
    }

    private func assignGroupHotkey(
        _ group: IconGroup,
        kind: GroupHotkeyAssignmentKind
    ) -> GroupHotkeyAssignmentResult {
        guard let hotkeyBindingStore else {
            return GroupHotkeyAssignmentResult(
                status: .unavailable,
                message: "Hotkey store is unavailable."
            )
        }

        hotkeyBindingStore.load()
        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: group.id,
            kind: kind,
            existingBindings: hotkeyBindingStore.bindings
        )

        switch plan.operation {
        case .add(let binding):
            hotkeyBindingStore.add(binding: binding)
            actions.dynamicHotkeysChanged?()
        case .enableExisting(let id):
            hotkeyBindingStore.update(id: id) { binding in
                binding.isEnabled = true
            }
            actions.dynamicHotkeysChanged?()
        case .none:
            break
        }

        return plan.result
    }

    private var privateAccessCommandSummaries: [MenuBarCommandAvailabilitySummary] {
        privateAccessCommands.compactMap(commandSummary)
    }

    private var privateAccessCommands: [MenuBarCommand] {
        [
            MenuBarCommand(
                action: .revealAlwaysHiddenZone,
                target: .globalVisibility,
                source: .settings
            ),
            MenuBarCommand(
                action: .showFindIcon,
                source: .statusMenu
            ),
            MenuBarCommand(
                action: .showSecondBar,
                target: .secondBar,
                source: .statusMenu
            ),
            MenuBarCommand(
                action: .showIconPanel,
                target: .iconPanel,
                source: .statusMenu
            ),
            MenuBarCommand(
                action: .experimentalActivateItem,
                target: .menuBarItem(id: "private-access-settings-preview"),
                source: .settings
            ),
            MenuBarCommand(
                action: .spacingPresetApply,
                target: .spacingPreset("private-access-settings-preview"),
                source: .settings
            )
        ]
    }

    private func refreshAfterSettingsImport() {
        actions.behaviorChanged?()
        actions.searchChanged?()
        actions.secondBarChanged?()
        actions.privacyChanged?()
        actions.groupsChanged?()
        actions.dynamicHotkeysChanged?()
        actions.automationSettingsChanged?()
        actions.triggersChanged?()
    }
}

extension SettingsSection {
    var pageAccessibilityIdentifier: String {
        "settings.page.\(rawValue)"
    }

    var sidebarAccessibilityIdentifier: String {
        "settings.sidebar.\(rawValue)"
    }
}

struct ClearGlassSettingsPage<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let badges: [ClearGlassBadgeStyle]
    private let sectionAnchors: [ClearGlassPageAnchor]
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        badges: [ClearGlassBadgeStyle] = [],
        sectionAnchors: [ClearGlassPageAnchor] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badges = badges
        self.sectionAnchors = sectionAnchors
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 9) {
                        ClearGlassPageHeader(title: title, subtitle: subtitle, badges: badges)

                        if sectionAnchors.count > 1 {
                            ClearGlassPageAnchorBar(anchors: sectionAnchors) { anchor in
                                scroll(to: anchor, using: proxy)
                            }
                        }
                    }
                    .id(ClearGlassPageAnchor.top.targetID)

                    content
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: 980, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .accessibilityIdentifier("settings.page.scroll")
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func scroll(to anchor: ClearGlassPageAnchor, using proxy: ScrollViewProxy) {
        if accessibilityReduceMotion {
            proxy.scrollTo(anchor.targetID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(anchor.targetID, anchor: .top)
            }
        }
    }
}

struct ClearGlassPageAnchor: Identifiable, Hashable {
    let title: String
    let systemImage: String
    let targetID: String

    var id: String { targetID }

    init(_ title: String, systemImage: String, targetID: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.targetID = targetID ?? title
    }

    static let top = ClearGlassPageAnchor("Top", systemImage: "arrow.up", targetID: "settings.page.top")
}

struct ClearGlassPageAnchorBar: View {
    let anchors: [ClearGlassPageAnchor]
    let onSelect: (ClearGlassPageAnchor) -> Void

    private var allAnchors: [ClearGlassPageAnchor] {
        [ClearGlassPageAnchor.top] + anchors
    }

    var body: some View {
        if anchors.count > 1 {
            compactAnchorMenu
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Page sections")
        }
    }

    private var compactAnchorMenu: some View {
        Menu {
            ForEach(allAnchors) { anchor in
                Button {
                    onSelect(anchor)
                } label: {
                    Label(anchor.title, systemImage: anchor.systemImage)
                }
            }
        } label: {
            Label("Sections", systemImage: "list.bullet")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("Jump to page section")
        .accessibilityHint("Opens a menu of sections on this settings page.")
    }
}

struct ClearGlassSection<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let anchorID: String?
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        anchorID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.anchorID = anchorID
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(anchorID ?? title)
    }
}

struct ClearGlassPaneLayout<Primary: View, Detail: View>: View {
    private let primaryWidth: CGFloat
    private let spacing: CGFloat
    @ViewBuilder private let primary: Primary
    @ViewBuilder private let detail: Detail

    init(
        primaryWidth: CGFloat = 280,
        spacing: CGFloat = 14,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder detail: () -> Detail
    ) {
        self.primaryWidth = primaryWidth
        self.spacing = spacing
        self.primary = primary()
        self.detail = detail()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                primary
                    .frame(width: primaryWidth)

                detail
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: spacing) {
                primary
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                detail
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct ClearGlassButtonGrid<Content: View>: View {
    private let minimumItemWidth: CGFloat
    private let spacing: CGFloat
    @ViewBuilder private let content: Content

    init(
        minimumItemWidth: CGFloat = 150,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumItemWidth = minimumItemWidth
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumItemWidth), spacing: spacing)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ClearGlassControlRow<Accessory: View>: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let iconTint: Color
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint
        self.accessory = accessory()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalRow
            verticalRow
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var horizontalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            iconView

            labelContent
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            accessory
                .fixedSize()
                .layoutPriority(1)
        }
    }

    private var verticalRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 10) {
                iconView

                labelContent
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            accessory
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var iconView: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(iconTint)
            .frame(width: 20)
    }

    private var labelContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension ClearGlassControlRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint
        ) {
            EmptyView()
        }
    }
}

struct ClearGlassValueRow<ValueContent: View>: View {
    private let title: String
    private let subtitle: String?
    @ViewBuilder private let value: ValueContent

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder value: () -> ValueContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalRow
            verticalRow
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var horizontalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            labelContent

            Spacer(minLength: 16)

            value
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var verticalRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            labelContent

            value
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var labelContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ClearGlassSliderRow: View {
    private let title: String
    private let subtitle: String?
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let valueSuffix: String
    private let valueFractionLength: Int
    private let valueWidth: CGFloat

    init(
        _ title: String,
        subtitle: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        valueSuffix: String = "",
        valueFractionLength: Int = 0,
        valueWidth: CGFloat = 58
    ) {
        self.title = title
        self.subtitle = subtitle
        _value = value
        self.range = range
        self.step = step
        self.valueSuffix = valueSuffix
        self.valueFractionLength = valueFractionLength
        self.valueWidth = valueWidth
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 180, alignment: .leading)

            Spacer(minLength: 16)

            Slider(value: $value, in: range, step: step)
                .frame(maxWidth: 320)

            Text(formattedValue)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: valueWidth, alignment: .trailing)
        }
        .padding(.vertical, 7)
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(valueFractionLength))) + valueSuffix
    }
}

struct ClearGlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.55))
            .frame(height: 0.5)
            .padding(.leading, 34)
    }
}

struct ClearGlassInlineMessage: View {
    let text: String
    var systemImage: String = "info.circle"
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(style.tint)
                .frame(width: 18)

            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.background, in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(style.border, lineWidth: 0.5)
        }
    }
}

struct ClearGlassStatusValue: View {
    let text: String
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(style.tint)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.callout)
                .foregroundStyle(style.foreground)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

struct KeyboardShortcutToken: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
            }
            .accessibilityLabel("Keyboard shortcut \(text)")
    }
}

struct CommandAvailabilityRow: View {
    let summary: MenuBarCommandAvailabilitySummary

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: summary.systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(summary.tone.clearGlassTint)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ClearGlassStatusValue(
                    text: summary.statusText,
                    style: summary.tone.clearGlassStyle
                )

                Text(summary.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension MenuBarCommandAvailabilityTone {
    var clearGlassStyle: ClearGlassStatusStyle {
        switch self {
        case .success:
            .success
        case .warning:
            .warning
        case .danger:
            .danger
        case .info:
            .info
        case .secondary:
            .secondary
        }
    }

    var clearGlassTint: Color {
        clearGlassStyle.tint
    }
}

enum ClearGlassStatusStyle {
    case success
    case warning
    case danger
    case info
    case secondary

    var tint: Color {
        switch self {
        case .success:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        case .info:
            .blue
        case .secondary:
            .secondary
        }
    }

    var foreground: Color {
        switch self {
        case .success:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        case .info:
            .blue
        case .secondary:
            .secondary
        }
    }

    var background: Color {
        switch self {
        case .success:
            Color.green.opacity(0.08)
        case .warning:
            Color.orange.opacity(0.10)
        case .danger:
            Color.red.opacity(0.08)
        case .info:
            Color.accentColor.opacity(0.08)
        case .secondary:
            Color(nsColor: .quaternaryLabelColor).opacity(0.10)
        }
    }

    var border: Color {
        switch self {
        case .success:
            Color.green.opacity(0.22)
        case .warning:
            Color.orange.opacity(0.26)
        case .danger:
            Color.red.opacity(0.22)
        case .info:
            Color.accentColor.opacity(0.20)
        case .secondary:
            Color(nsColor: .separatorColor).opacity(0.45)
        }
    }
}

struct ClearGlassBadge: View {
    let style: ClearGlassBadgeStyle

    var body: some View {
        Label(style.title, systemImage: style.systemImage)
            .font(.caption)
            .foregroundStyle(style.tint)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(style.tint.opacity(0.08), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(style.tint.opacity(0.18), lineWidth: 0.5)
            }
    }
}

enum ClearGlassBadgeStyle: Hashable {
    case basicMode
    case privacySafe
    case proMode
    case accessibilityRequired
    case diagnostics
    case stable
    case preview
    case labs
    case experimental
    case unavailable
    case deferred
    case actionNeeded

    init(featureStatus: FeatureStatus) {
        switch featureStatus {
        case .stable:
            self = .stable
        case .preview:
            self = .preview
        case .labs:
            self = .labs
        case .experimental:
            self = .experimental
        case .disabled, .unavailable:
            self = .unavailable
        case .deferred:
            self = .deferred
        }
    }

    var title: String {
        switch self {
        case .basicMode:
            "Basic Mode"
        case .privacySafe:
            "Privacy Safe"
        case .proMode:
            "Optional Pro"
        case .accessibilityRequired:
            "Unavailable"
        case .diagnostics:
            "Diagnostics"
        case .stable:
            FeatureStatus.stable.title
        case .preview:
            FeatureStatus.preview.title
        case .labs:
            FeatureStatus.labs.title
        case .experimental:
            FeatureStatus.labs.title
        case .unavailable:
            FeatureStatus.unavailable.title
        case .deferred:
            FeatureStatus.deferred.title
        case .actionNeeded:
            "Action Needed"
        }
    }

    var systemImage: String {
        switch self {
        case .basicMode:
            "checkmark.shield"
        case .privacySafe:
            "shield.lefthalf.filled"
        case .proMode:
            "star"
        case .accessibilityRequired:
            "figure.circle"
        case .diagnostics:
            "waveform.path.ecg"
        case .stable:
            FeatureStatus.stable.systemImage
        case .preview:
            FeatureStatus.preview.systemImage
        case .labs:
            FeatureStatus.labs.systemImage
        case .experimental:
            FeatureStatus.labs.systemImage
        case .unavailable:
            FeatureStatus.unavailable.systemImage
        case .deferred:
            FeatureStatus.deferred.systemImage
        case .actionNeeded:
            "exclamationmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .basicMode, .privacySafe:
            .green
        case .proMode:
            .accentColor
        case .accessibilityRequired:
            DesignTokens.SemanticTone.permissionRequired.foregroundStyle
        case .diagnostics:
            .secondary
        case .stable:
            FeatureStatus.stable.tint
        case .preview:
            FeatureStatus.preview.tint
        case .labs:
            FeatureStatus.labs.tint
        case .experimental:
            FeatureStatus.labs.tint
        case .unavailable:
            FeatureStatus.unavailable.tint
        case .deferred:
            FeatureStatus.deferred.tint
        case .actionNeeded:
            .red
        }
    }
}

private struct ClearGlassPageHeader: View {
    let title: String
    let subtitle: String?
    let badges: [ClearGlassBadgeStyle]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    titleText
                    badgeStrip
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    titleText
                    badgeStrip
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleText: some View {
        Text(title)
            .font(.largeTitle)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var badgeStrip: some View {
        if !visibleBadges.isEmpty {
            HStack(spacing: 7) {
                ForEach(visibleBadges, id: \.self) { badge in
                    ClearGlassBadge(style: badge)
                }
            }
        }
    }

    private var visibleBadges: [ClearGlassBadgeStyle] {
        let actionable = badges
            .filter { !$0.isQuietHeaderBadge }
            .sorted { $0.headerPriority < $1.headerPriority }

        if !actionable.isEmpty {
            return Array(actionable.prefix(1))
        }

        for preferred in [ClearGlassBadgeStyle.basicMode, .privacySafe, .stable] where badges.contains(preferred) {
            return [preferred]
        }

        return Array(badges.prefix(1))
    }
}

private extension ClearGlassBadgeStyle {
    var isQuietHeaderBadge: Bool {
        switch self {
        case .basicMode, .privacySafe, .stable:
            true
        case .proMode,
             .accessibilityRequired,
             .diagnostics,
             .preview,
             .labs,
             .experimental,
             .unavailable,
             .deferred,
             .actionNeeded:
            false
        }
    }

    var headerPriority: Int {
        switch self {
        case .actionNeeded:
            0
        case .accessibilityRequired:
            1
        case .proMode:
            2
        case .labs:
            3
        case .experimental:
            4
        case .preview:
            5
        case .unavailable:
            6
        case .deferred:
            7
        case .diagnostics:
            8
        case .basicMode, .privacySafe, .stable:
            20
        }
    }
}

#Preview {
    SettingsRootView(
        navigationModel: SettingsNavigationModel(),
        settingsStore: SettingsStore(),
        diagnosticsLogger: DiagnosticsLogger(),
        liveStatus: nil,
        appSupportPaths: AppSupportPaths(),
        diagnosticsExporter: DiagnosticsExporter(),
        dogfoodStore: DogfoodStore(appSupportPaths: AppSupportPaths())
    )
}
